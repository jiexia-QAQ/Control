import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/plan.dart';
import '../../services/db.dart';
import '../../services/insight_service.dart';
import '../../services/reminder_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/week_calendar.dart';
import 'focus_timer_page.dart';
import 'plan_edit_sheet.dart';

/// 计划模块：日历联动 + 计划清单 + 打卡
class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  bool _monthView = false;
  List<Plan> _plans = [];
  Map<String, PlanRecord> _records = {};
  List<Plan> _oncePlans = []; // V1.7 一次性任务
  final Set<int> _onceFading = {}; // V1.7.1 完成待消失的一次性任务
  Map<String, (int, int)> _progress = {}; // date -> (total, done)
  int _total = 0, _done = 0;
  bool _loading = true;
  int? _burstPlanId; // 触发粒子动画的计划
  Insight? _insight; // V1.5 实时洞察卡片

  DateTime get _day =>
      context.select<AppState, DateTime>((s) => s.selectedDate);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tick = context.select<AppState, int>((s) => s.tick);
    _load(tick);
  }

  Future<void> _load([int? tick]) async {
    final db = DatabaseService.instance;
    final day = _day;
    final plans = await db.plansForDate(day);
    final records = await db.recordsForDate(day);
    final oncePlans = (await db.oncePlans())
        .where((p) => !p.doneOnce) // V1.7.1 已完成的不再显示
        .toList();
    // 覆盖 ±45 天的日历圆点
    final start = Fmt.addDays(day, -45);
    final end = Fmt.addDays(day, 45);
    final progress = await db.rangePlanProgress(start, end);

    if (!mounted) return;
    setState(() {
      _plans = plans;
      _records = records;
      _oncePlans = oncePlans;
      _progress = progress;
      _total = 0;
      _done = 0;
      for (final p in plans) {
        final rec = records[p.id.toString()];
        if (rec?.skipped ?? false) continue;
        _total++;
        if (rec?.done ?? false) _done++;
      }
      _loading = false;
    });

    // V1.5 实时洞察（失败静默，不影响主流程）
    try {
      final ins = await InsightService.instance.pick();
      if (mounted && ins.text != _insight?.text) {
        setState(() => _insight = ins);
      }
    } catch (_) {}
  }

  Color? _dotColorFor(String date) {
    final pr = _progress[date];
    if (pr == null || pr.$1 == 0) return null;
    if (pr.$1 == pr.$2) return AppColors.doneAll;
    if (pr.$2 > 0) return AppColors.donePart;
    return AppColors.doneNone;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    final donePlans = _plans.where((p) {
      final rec = _records[p.id.toString()];
      return rec?.done ?? false;
    }).toList();
    final activePlans = _plans.where((p) {
      final rec = _records[p.id.toString()];
      return !(rec?.done ?? false);
    }).toList();
    final sorted = [...activePlans, ...donePlans];
    final ratio = _total == 0 ? 0.0 : _done / _total;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(),
        tooltip: '新建计划',
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('☀️ 计划',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  // V1.7 番茄钟入口
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const FocusTimerPage()),
                    ),
                    icon: Icon(Icons.timer_outlined,
                        color: AppColors.accent),
                    tooltip: '番茄钟',
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('周')),
                      ButtonSegment(value: true, label: Text('月')),
                    ],
                    selected: {_monthView},
                    onSelectionChanged: (s) =>
                        setState(() => _monthView = s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStateProperty.all(
                          const TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(Fmt.dayLabel(_day),
                  style: TextStyle(fontSize: 13, color: subColor)),
              const SizedBox(height: 10),
              MCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: _monthView
                    ? MonthCalendar(
                        selected: _day,
                        onSelect: (d) =>
                            context.read<AppState>().selectDate(d),
                        dots: _dotMap(),
                      )
                    : WeekCalendar(
                        selected: _day,
                        onSelect: (d) =>
                            context.read<AppState>().selectDate(d),
                        dots: _dotMap(),
                      ),
              ),
              const SizedBox(height: 6),
              // V1.5 实时洞察卡片
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                    child: child,
                  ),
                ),
                child: _insight == null
                    ? const SizedBox.shrink()
                    : _InsightCard(key: ValueKey(_insight!.text), insight: _insight!),
              ),
              _progressBar(textColor, ratio),
              if (_loading)
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.primary)),
                )
              else if (sorted.isEmpty && _visibleOnce.isEmpty)
                EmptyState(
                  icon: Icons.event_note_outlined,
                  emoji: '🌱',
                  text: '今天还没安排',
                  hint: '从一个小目标开始，完成它会有小惊喜',
                )
              else ...[
                // V1.7.1 一次性任务置顶：完成即消失，未完成一直存在
                if (_visibleOnce.isNotEmpty) ...[
                  _onceHeader(textColor, subColor),
                  for (final p in _visibleOnce) ...[
                    _buildOnceTile(p, textColor, subColor),
                    const SizedBox(height: 10),
                  ],
                  if (sorted.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                      child: Row(children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 8),
                        Text('今日计划',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textColor)),
                        const Spacer(),
                        Text(_total == 0 ? '' : '$_done / $_total',
                            style: TextStyle(fontSize: 11.5, color: subColor)),
                      ]),
                    ),
                ],
                for (final p in sorted) ...[
                  _PlanTile(
                    plan: p,
                    record: _records[p.id.toString()],
                    burst: _burstPlanId == p.id,
                    onToggle: () => _toggle(p),
                    onLongPress: () => _menu(p),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // V1.7.1 待办区显示列表：未完成 + 正在淡出的
  List<Plan> get _visibleOnce => _oncePlans
      .where((p) => !p.doneOnce || _onceFading.contains(p.id))
      .toList();

  /// 待办区俏皮标题（文案轮换）
  Widget _onceHeader(Color textColor, Color subColor) {
    const msgs = [
      '摸鱼前先清掉它',
      '就差这件了，冲',
      '完成它，奖励自己',
      '堆着也是堆着',
    ];
    final idx = DateTime.now().millisecondsSinceEpoch ~/ 60000 % msgs.length;
    final left = _visibleOnce.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Row(children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text('📌 待办 $left',
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor)),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(anim),
                    child: child)),
            child: Text(msgs[idx],
                key: ValueKey(idx),
                style: TextStyle(fontSize: 11, color: subColor)),
          ),
        ),
      ]),
    );
  }

  /// 一次性任务卡片：完成淡出动画 + 打勾粒子
  Widget _buildOnceTile(Plan p, Color textColor, Color subColor) {
    final fading = _onceFading.contains(p.id);
    final tile = _PlanTile(
      plan: p,
      record: null,
      onceDone: p.doneOnce,
      burst: _burstPlanId == p.id,
      onToggle: () => _toggle(p),
      onLongPress: () => _menu(p),
    );
    if (!fading) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, -14 * (1 - v)),
          child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
        ),
      ),
      child: tile,
    );
  }

  Map<String, Color> _dotMap() {
    final m = <String, Color>{};
    _progress.forEach((date, pr) {
      final c = _dotColorFor(date);
      if (c != null) m[date] = c;
    });
    return m;
  }

  Widget _progressBar(Color textColor, double ratio) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final allDone = _total > 0 && ratio >= 1.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('今日完成度',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              if (allDone) ...[
                AnimatedScale(
                  scale: allDone ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: allDone ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.blush,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✦',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                  height: 1.2)),
                          const SizedBox(width: 3),
                          Text('今日全勤',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(_total == 0 ? '暂无计划' : '$_done/$_total',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: subColor.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreate() async {
    await Haptics.tap();
    final result = await showModalBottomSheet<Plan>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlanEditSheet(defaultDate: _day),
    );
    if (result != null) {
      await DatabaseService.instance.insertPlan(result);
      await ReminderService.instance.refreshAll(); // V1.4 刷新提醒调度
      context.read<AppState>().bump();
    }
  }

  Future<void> _toggle(Plan plan) async {
    // V1.7 一次性任务：不写 plan_records，直接改 done_once
    if (plan.type == 'once') {
      // 完成淡出期间再点 = 撤销
      if (plan.doneOnce || _onceFading.contains(plan.id)) {
        setState(() => _onceFading.remove(plan.id!));
        await DatabaseService.instance.setOnceDone(plan.id!, false);
        await Haptics.tap();
        showToast(context, '↩️ 已撤销：${plan.name}');
        context.read<AppState>().bump();
        return;
      }
      setState(() {
        _burstPlanId = plan.id;
        _onceFading.add(plan.id!);
      });
      await DatabaseService.instance.setOnceDone(plan.id!, true);
      await Haptics.success();
      showToast(context, '✨ 搞定一件：${plan.name}');
      // 淡出动画结束后从列表移除（完成即消失）
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _oncePlans.removeWhere((p) => p.id == plan.id);
          _onceFading.remove(plan.id!);
          _burstPlanId = null;
        });
        // 全部清空时彩蛋
        if (_oncePlans.isEmpty && mounted) {
          showToast(context, '🎉 待办全部清空，今天的你很棒');
        }
      });
      context.read<AppState>().bump();
      return;
    }
    final db = DatabaseService.instance;
    final rec = _records[plan.id.toString()];
    final newDone = !(rec?.done ?? false);
    setState(() {
      if (newDone) _burstPlanId = plan.id;
    });
    await db.setPlanDone(plan.id!, _day, newDone);
    await Haptics.success();
    if (newDone) {
      Future.delayed(const Duration(milliseconds: 650),
          () => setState(() => _burstPlanId = null));
    }

    // V1.2 彩蛋：全部计划完成时随机鼓励文案
    final nowDone = _done + (newDone ? 1 : 0);
    if (newDone && _total > 0 && nowDone >= _total) {
      _showAllDoneToast();
    }

    context.read<AppState>().bump();
  }

  /// 全勤彩蛋文案（轮换 4 条，避免每次一样；V1.3 加 emoji）
  void _showAllDoneToast() {
    final msgs = const [
      '🎉 今日全勤 · 好样的，给自己鼓个掌',
      '✨ 圆满的一天 · 自律的小齿轮又转了一格',
      '🌟 100% · 明天再接再厉，小习惯也会发光',
      '☕ 今日份自律到账 · 你比想象中更稳',
    ];
    final i = DateTime.now().millisecondsSinceEpoch % msgs.length;
    if (mounted) showToast(context, msgs[i]);
  }

  Future<void> _menu(Plan plan) async {
    final db = DatabaseService.instance;
    final rec = _records[plan.id.toString()];
    final isSkipped = rec?.skipped ?? false;
    final action = await showActionSheet(context, [
      (icon: Icons.edit_outlined, label: '编辑', color: null),
      (icon: Icons.skip_next_outlined,
          label: isSkipped ? '取消跳过' : '跳过当天',
          color: AppColors.sage),
      (icon: Icons.delete_outline, label: '删除计划', color: AppColors.prioHigh),
    ]);
    if (action == null || !mounted) return;
    switch (action) {
      case '编辑':
        final result = await showModalBottomSheet<Plan>(
          context: context,
          isScrollControlled: true,
          builder: (_) => PlanEditSheet(plan: plan, defaultDate: _day),
        );
        if (result != null) {
          await db.updatePlan(result);
          await ReminderService.instance.refreshAll(); // V1.4
          context.read<AppState>().bump();
        }
        break;
      case '跳过当天':
      case '取消跳过':
        await db.setPlanSkipped(plan.id!, _day, !isSkipped);
        await Haptics.tap();
        context.read<AppState>().bump();
        break;
      case '删除计划':
        final ok = await confirmDialog(context,
            title: '删除计划',
            message: '确定删除「${plan.name}」吗？相关打卡记录将一并删除。',
            confirmText: '删除',
            confirmColor: AppColors.prioHigh);
        if (ok) {
          await db.deletePlan(plan.id!);
          await ReminderService.instance.refreshAll(); // V1.4
          context.read<AppState>().bump();
        }
        break;
    }
  }
}

/// 单条计划卡片
class _PlanTile extends StatefulWidget {
  final Plan plan;
  final PlanRecord? record;
  final bool onceDone; // V1.7 一次性任务完成态
  final bool burst;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const _PlanTile({
    required this.plan,
    required this.record,
    this.onceDone = false,
    required this.burst,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  State<_PlanTile> createState() => _PlanTileState();
}

class _PlanTileState extends State<_PlanTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstCtrl;
  late final Animation<double> _burstAnim;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _burstAnim =
        CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_PlanTile old) {
    super.didUpdateWidget(old);
    if (widget.burst && !old.burst) {
      _burstCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.plan;
    final done = widget.onceDone || (widget.record?.done ?? false);
    final skipped = widget.record?.skipped ?? false;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final prioColor = switch (p.priority) {
      0 => AppColors.prioLow,
      2 => AppColors.prioHigh,
      _ => AppColors.prioMid,
    };

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: skipped ? 0.55 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(0, 13, 14, 13),
          decoration: softShadow(context),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 优先级左侧边条
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 4,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: skipped ? subColor.withValues(alpha: 0.3) : prioColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // 打卡圆钮 + 粒子
                SizedBox(
                  width: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.burst)
                        AnimatedBuilder(
                          animation: _burstCtrl,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(44, 44),
                              painter: _BurstPainter(_burstAnim.value,
                                  color: AppColors.primary),
                            );
                          },
                        ),
                      _CheckButton(
                        done: done,
                        skipped: skipped,
                        onTap: widget.onToggle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: done
                                    ? subColor
                                    : textColor,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: subColor,
                              ),
                              child: Text(p.name),
                            ),
                          ),
                          if (p.isRepeat) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.sage.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('重复',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6B8B77))),
                            ),
                          ],
                          if (p.type == 'once') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('一次性',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.accent)),
                            ),
                          ],
                          if (skipped) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: subColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('已跳过',
                                  style:
                                      TextStyle(fontSize: 10, color: subColor)),
                            ),
                          ],
                        ],
                      ),
                      if (p.note.isNotEmpty || p.timeLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (p.timeLabel.isNotEmpty) ...[
                              Icon(Icons.schedule,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(p.timeLabel,
                                  style: TextStyle(
                                      fontSize: 11.5, color: subColor)),
                              const SizedBox(width: 10),
                            ],
                            if (p.note.isNotEmpty)
                              Flexible(
                                child: Text(p.note,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5, color: subColor)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 打卡圆形复选框（弹性缩放动画）
class _CheckButton extends StatelessWidget {
  final bool done;
  final bool skipped;
  final VoidCallback onTap;

  const _CheckButton(
      {required this.done, required this.skipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: done ? 1 : 0.86,
        duration: const Duration(milliseconds: 280),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.accent
                : Colors.transparent,
            border: Border.all(
              color: done ? AppColors.accent : AppColors.primary.withValues(alpha: 0.7),
              width: 2,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// V1.5 实时洞察卡片：渐变底 + emoji + 动作
class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final gradient = dark
        ? [AppColors.primary.withValues(alpha: 0.18), AppColors.blush.withValues(alpha: 0.10)]
        : [AppColors.primary.withValues(alpha: 0.08), AppColors.blush.withValues(alpha: 0.35)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: insight.onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    insight.actionLabel,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 打卡成功粒子爆发
class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;

  _BurstPainter(this.t, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color.withValues(alpha: (1 - t) * 0.55);
    for (var i = 0; i < 5; i++) {
      final angle = i * (3.1415926 * 2 / 5);
      final dist = 8 + t * 20;
      final r = 2.2 * (1 - t) + 0.6;
      if (r <= 0) continue;
      canvas.drawCircle(
        center +
            Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
