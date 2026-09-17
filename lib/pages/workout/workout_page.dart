import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/exercise.dart';
import '../../services/db.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/particle_burst.dart';
import '../../widgets/week_calendar.dart';
import 'exercise_picker_page.dart';
import 'template_list_page.dart';

/// 锻炼模块：训练日志 + 模板系统 + 休息日
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  List<WorkoutLog> _logs = [];
  Set<String> _rests = {};
  Set<String> _dumbbells = {};
  bool _isRest = false;
  bool _loading = true;

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
    final s = Fmt.addDays(_day, -45);
    final e = Fmt.addDays(_day, 45);
    final results = await Future.wait([
      db.logsForDate(_day),
      db.isRestDay(_day),
      db.restDaysInRange(s, e),
      db.workoutDatesInRange(s, e),
    ]);
    if (!mounted) return;
    setState(() {
      _logs = (results[0] as List<WorkoutLog>)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _isRest = results[1] as bool;
      _rests = results[2] as Set<String>;
      _dumbbells = results[3] as Set<String>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💪 锻炼',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Row(
                    children: [
                      _headerBtn(
                        icon: Icons.layers_outlined,
                        label: '模板',
                        onTap: () => _openTemplates(),
                      ),
                      const SizedBox(width: 8),
                      _headerBtn(
                        icon: _isRest
                            ? Icons.beach_access
                            : Icons.self_improvement,
                        label: _isRest ? '休息日' : '休息',
                        onTap: () => _toggleRest(),
                        active: _isRest,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('与计划共用日历 · ${Fmt.dayLabel(_day)}',
                  style: TextStyle(fontSize: 13, color: subColor)),
              const SizedBox(height: 10),
              MCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: WeekCalendar(
                  selected: _day,
                  onSelect: (d) => context.read<AppState>().selectDate(d),
                  dumbbells: _dumbbells,
                  restDays: _rests,
                  showRest: true,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.primary)),
                )
              else if (_isRest)
                _restView(textColor, subColor)
              else if (_logs.isEmpty)
                _emptyView(textColor, subColor)
              else
                for (final log in _logs) ...[
                  _LogCard(
                    key: ValueKey(log.id),
                    log: log,
                    onChanged: (updated) => _saveLog(updated),
                    onDelete: () => _deleteLog(log),
                  ),
                  const SizedBox(height: 12),
                ],
              if (!_isRest && !_loading) ...[
                const SizedBox(height: 6),
                _addAction(textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============ 视图 ============

  Widget _headerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: active
          ? AppColors.sage.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.slate),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _restView(Color textColor, Color subColor) {
    return MCard(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(Icons.self_improvement, size: 46, color: AppColors.sage),
          const SizedBox(height: 14),
          Text('今天是休息日',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 6),
          Text('好好恢复，肌肉在休息中生长',
              style: TextStyle(fontSize: 12.5, color: subColor)),
          const SizedBox(height: 6),
          Text('休息日不记录训练',
              style: TextStyle(fontSize: 11.5, color: subColor.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _emptyView(Color textColor, Color subColor) {
    return MCard(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.fitness_center, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text('💪', style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text('今天还没开练',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 6),
          Text('动起来，哪怕只有 10 分钟，也值得记录',
              style: TextStyle(fontSize: 12.5, color: subColor)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _loadFromTemplate(),
                icon: const Icon(Icons.layers_outlined, size: 17),
                label: const Text('从模板加载'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _addExercise(),
                icon: const Icon(Icons.add, size: 17),
                label: const Text('开始空训练'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addAction(Color textColor) {
    return OutlinedButton.icon(
      onPressed: () => _addExercise(),
      icon: const Icon(Icons.add, size: 17),
      label: const Text('添加动作'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ============ 行为 ============

  Future<void> _toggleRest() async {
    final db = DatabaseService.instance;
    final newVal = !_isRest;
    if (newVal && _logs.isNotEmpty) {
      final ok = await confirmDialog(context,
          title: '标记为休息日',
          message: '该日期已有训练记录，标记休息日将清除这些记录。',
          confirmText: '清除并标记',
          confirmColor: AppColors.prioHigh);
      if (!ok) return;
      for (final l in _logs) {
        await db.deleteLog(l.id!);
      }
    }
    await db.setRestDay(_day, newVal);
    await Haptics.tap();
    context.read<AppState>().bump();
  }

  Future<void> _addExercise() async {
    final ex = await Navigator.of(context).push<ExerciseItem>(
      MaterialPageRoute(builder: (_) => const ExercisePickerPage()),
    );
    if (ex == null || !mounted) return;
    final db = DatabaseService.instance;
    final existing = await db.logsForDate(_day);
    await db.insertLog(WorkoutLog(
      date: Fmt.d(_day),
      exerciseId: ex.id,
      exerciseName: ex.name,
      part: ex.part,
      equipment: ex.equipment,
      sets: [WorkoutSet(no: 1, reps: 10, weight: 0)],
      sortOrder: existing.length,
    ));
    await Haptics.success();
    context.read<AppState>().bump();
    if (mounted) ParticleOverlay.show(context); // V1.7 粒子
  }

  Future<void> _saveLog(WorkoutLog log) async {
    await DatabaseService.instance.updateLog(log);
    context.read<AppState>().bump();
  }

  Future<void> _deleteLog(WorkoutLog log) async {
    final ok = await confirmDialog(context,
        title: '删除动作',
        message: '删除「${log.exerciseName}」的所有组记录？',
        confirmText: '删除',
        confirmColor: AppColors.prioHigh);
    if (!ok) return;
    await DatabaseService.instance.deleteLog(log.id!);
    context.read<AppState>().bump();
  }

  Future<void> _loadFromTemplate() async {
    await Haptics.tap();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TemplateListPage(loadForDate: true)),
    );
    // 返回后刷新（模板可能已加载）
    context.read<AppState>().bump();
  }

  Future<void> _openTemplates() async {
    await Haptics.tap();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TemplateListPage()),
    );
    context.read<AppState>().bump();
  }
}

/// 单条训练动作卡片（组次编辑）
class _LogCard extends StatefulWidget {
  final WorkoutLog log;
  final ValueChanged<WorkoutLog> onChanged;
  final VoidCallback onDelete;

  const _LogCard({
    super.key,
    required this.log,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  late List<TextEditingController> _reps;
  late List<TextEditingController> _weight;
  late TextEditingController _note;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    _reps = [
      for (final s in widget.log.sets)
        TextEditingController(text: '${s.reps}')
    ];
    _weight = [
      for (final s in widget.log.sets)
        TextEditingController(
            text: s.weight == 0 ? '0' : Fmt.num(s.weight))
    ];
    _note = TextEditingController(text: widget.log.note);
  }

  @override
  void didUpdateWidget(_LogCard old) {
    super.didUpdateWidget(old);
    if (old.log.sets.length != widget.log.sets.length ||
        old.log.id != widget.log.id) {
      for (final c in [..._reps, ..._weight]) {
        c.dispose();
      }
      _note.dispose();
      _sync();
    }
  }

  @override
  void dispose() {
    for (final c in [..._reps, ..._weight]) {
      c.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  WorkoutLog _build() {
    final sets = <WorkoutSet>[];
    for (var i = 0; i < widget.log.sets.length; i++) {
      sets.add(WorkoutSet(
        no: i + 1,
        reps: int.tryParse(_reps[i].text) ?? 0,
        weight: double.tryParse(_weight[i].text) ?? 0,
      ));
    }
    return WorkoutLog(
      id: widget.log.id,
      date: widget.log.date,
      templateId: widget.log.templateId,
      exerciseId: widget.log.exerciseId,
      exerciseName: widget.log.exerciseName,
      part: widget.log.part,
      equipment: widget.log.equipment,
      sets: sets,
      note: _note.text.trim(),
      sortOrder: widget.log.sortOrder,
    );
  }

  void _save() => widget.onChanged(_build());

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final log = widget.log;

    return MCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.slate.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(log.part.isEmpty ? '动作' : log.part,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(log.exerciseName,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
              ),
              if (log.equipment.isNotEmpty)
                Text(log.equipment,
                    style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: widget.onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 17, color: subColor.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 表头
          Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                  flex: 3,
                  child: Text('次数',
                      style: TextStyle(fontSize: 11, color: subColor))),
              Expanded(
                  flex: 3,
                  child: Text('重量 kg',
                      style: TextStyle(fontSize: 11, color: subColor))),
              const SizedBox(width: 30),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < widget.log.sets.length; i++)
            Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}',
                      style: TextStyle(fontSize: 12.5, color: subColor)),
                ),
                Expanded(
                  flex: 3,
                  child: _numField(_reps[i]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _numField(_weight[i]),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      widget.log.sets.removeAt(i);
                    });
                    _sync();
                    _save();
                  },
                  icon: Icon(Icons.remove_circle_outline,
                      size: 18, color: AppColors.prioHigh.withValues(alpha: 0.85)),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          // 添加组 + 备注
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  final last = widget.log.sets.isEmpty
                      ? WorkoutSet(no: 1, reps: 10, weight: 0)
                      : widget.log.sets.last;
                  setState(() {
                    widget.log.sets.add(WorkoutSet(
                      no: widget.log.sets.length + 1,
                      reps: last.reps,
                      weight: last.weight,
                    ));
                  });
                  _sync();
                  _save();
                },
                icon: const Icon(Icons.add, size: 15),
                label: const Text('加一组'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: subColor),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _note,
                onChanged: (_) => _save(),
                decoration: InputDecoration(
                  hintText: '训练备注（如：慢离心）',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                style: TextStyle(fontSize: 13, color: textColor),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      onChanged: (_) => _save(),
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      ),
    );
  }
}
