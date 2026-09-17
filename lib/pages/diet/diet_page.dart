import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/food.dart';
import '../../models/weight_record.dart';
import '../../services/db.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/particle_burst.dart';
import '../../widgets/pie_chart.dart';
import '../../widgets/ring_progress.dart';
import 'add_food_sheet.dart';

/// 饮食模块：营养仪表盘 + 餐次记录
class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  DateTime _date = Fmt.today();
  List<MealEntry> _meals = [];
  MealTotals _totals = MealTotals.zero();
  final Set<int> _expanded = {};
  // V1.7.5 基础代谢
  double? _heightCm;
  int? _age;
  String _gender = 'male';
  double? _weightKg;

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
    final meals = await db.mealsForDate(_date);
    final totals = await db.totalsForDate(_date);
    // V1.7.5 基础代谢数据：身高/年龄/性别 + 最新体重
    final height = double.tryParse(await db.getSetting('height_cm') ?? '');
    final age = int.tryParse(await db.getSetting('age') ?? '');
    final gender = await db.getSetting('gender') ?? 'male';
    final weight = await db.latestWeight();
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _totals = totals;
      _heightCm = height;
      _age = age;
      _gender = gender;
      _weightKg = weight;
    });
  }

  /// V1.7.5 Mifflin-StJeor 基础代谢
  double? get _bmr {
    final w = _weightKg, h = _heightCm, a = _age;
    if (w == null || h == null || a == null) return null;
    if (w <= 0 || h <= 0 || a <= 0) return null;
    final base = 10 * w + 6.25 * h - 5 * a;
    return _gender == 'female' ? base - 161 : base + 5;
  }

  /// V1.7.5 编辑身体数据（身高/年龄/性别）
  Future<void> _editBody() async {
    final hCtrl = TextEditingController(
        text: _heightCm != null ? Fmt.num(_heightCm!, digits: 0) : '');
    final aCtrl = TextEditingController(text: _age?.toString() ?? '');
    var gender = _gender;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFFE9EBEF)
            : const Color(0xFF3C434E);
        final sc = Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF9AA1AC)
            : const Color(0xFF8B919B);
        return StatefulBuilder(builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('身体数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tc))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(
                  controller: hCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '身高（cm）'),
                  style: TextStyle(fontSize: 14, color: tc),
                )),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: aCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '年龄'),
                  style: TextStyle(fontSize: 14, color: tc),
                )),
              ]),
              const SizedBox(height: 12),
              Text('性别', style: TextStyle(fontSize: 12, color: sc)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'male', label: Text('男')),
                  ButtonSegment(value: 'female', label: Text('女')),
                ],
                selected: {gender},
                onSelectionChanged: (s) => setS(() => gender = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              Text(_weightKg == null
                  ? '体重未记录，请先在我的-体重记录中录入'
                  : '体重自动同步：${Fmt.num(_weightKg!, digits: 1)} kg（去体重记录更新）',
                  style: TextStyle(fontSize: 11, color: sc)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 46, child: FilledButton(
                onPressed: () {
                  if (hCtrl.text.trim().isEmpty || aCtrl.text.trim().isEmpty) {
                    showToast(ctx, '请填写身高和年龄');
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('保存', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
            ],
          ),
        ));
      },
    );
    if (saved == true) {
      final db = DatabaseService.instance;
      await db.setSetting('height_cm', hCtrl.text.trim());
      await db.setSetting('age', aCtrl.text.trim());
      await db.setSetting('gender', gender);
      context.read<AppState>().bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final goals = context.select<AppState, Goals>((s) => s.goals);
    // V1.7.6 热量目标 = 基础代谢（未设置身体数据时回退到用户目标）
    final kcalTarget = _bmr ?? goals.kcal;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🍚 饮食',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  _DateSwitcher(
                    date: _date,
                    onChange: (d) {
                      setState(() => _date = d);
                      _load();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(_date.year == Fmt.today().year &&
                      _date.month == Fmt.today().month &&
                      _date.day == Fmt.today().day
                  ? '今天也要好好吃饭'
                  : Fmt.dayLabel(_date),
                  style: TextStyle(fontSize: 13, color: subColor)),
              const SizedBox(height: 14),
              // 营养仪表盘
              MCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // V1.7 营养环呼吸动画：数据更新时带弹性入场
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.94, end: 1.0),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutBack,
                          key: ValueKey(
                              _totals.kcal.round() ^ _totals.protein.round()),
                          builder: (_, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: RingProgress(
                            value: kcalTarget <= 0
                                ? 0
                                : _totals.kcal / kcalTarget,
                            size: 128,
                            strokeWidth: 13,
                            color: AppColors.kcalColor,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(Fmt.kcal(_totals.kcal),
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: textColor)),
                                Text('/ ${Fmt.kcal(kcalTarget)} kcal',
                                    style: TextStyle(
                                        fontSize: 11, color: subColor)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              _miniRow('蛋白质', _totals.protein,
                                  goals.protein, AppColors.proteinColor, 'g'),
                              const SizedBox(height: 14),
                              _miniRow('脂肪', _totals.fat, goals.fat,
                                  AppColors.fatColor, 'g'),
                              const SizedBox(height: 14),
                              _miniRow('碳水', _totals.carb, goals.carb,
                                  AppColors.carbColor, 'g'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 剩余量提示条
                    _remainingBar(kcalTarget, subColor),
                    const SizedBox(height: 14),
                    // 宏量营养素饼图入口
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showMacroPie(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pie_chart_outline,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('查看宏量营养素供能比',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // V1.7.5 基础代谢与热量缺口
              const SizedBox(height: 12),
              _bmrCard(textColor, subColor),
              // 餐次
              for (final mt in MealType.values) ...[
                SectionTitle(
                  mt.label,
                  trailing: GestureDetector(
                    onTap: () => _addFood(mt),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text('添加',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                _MealCard(
                  type: mt,
                  entries: _meals
                      .where((e) => e.mealType == mt)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                  expanded: _expanded.contains(mt.index),
                  onExpand: () {
                    setState(() {
                      if (!_expanded.remove(mt.index)) {
                        _expanded.add(mt.index);
                      }
                    });
                  },
                  onDelete: (e) => _deleteMeal(e),
                  onEdit: (e) => _editMeal(e),
                ),
              ],
              const SizedBox(height: 10),
              Center(
                child: Text('数据仅保存在本机 · 解夏制作',
                    style: TextStyle(fontSize: 11, color: subColor.withValues(alpha: 0.8))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniRow(String label, double value, double target, Color color, String unit) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final ratio = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: subColor)),
            Text('${Fmt.num(value, digits: 0)} / ${Fmt.num(target, digits: 0)} $unit',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: subColor.withValues(alpha: 0.13),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // V1.7.5 基础代谢卡（Mifflin-StJeor 公式 + 热量缺口）
  Widget _bmrCard(Color textColor, Color subColor) {
    final bmr = _bmr;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (bmr == null) {
      return MCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.local_fire_department_outlined,
              size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text('设置身高体重，自动计算基础代谢与热量缺口',
                style: TextStyle(fontSize: 12.5, color: subColor)),
          ),
          TextButton(onPressed: _editBody, child: const Text('去设置')),
        ]),
      );
    }
    final intake = _totals.kcal;
    final deficit = bmr - intake; // 正 = 缺口
    final color = deficit >= 0 ? AppColors.sage : AppColors.prioHigh;
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.local_fire_department, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('基础代谢', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor)),
          const Spacer(),
          InkWell(
            onTap: _editBody,
            borderRadius: BorderRadius.circular(8),
            child: Icon(Icons.edit_outlined, size: 15, color: subColor),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _bmrStat('基础代谢', '${Fmt.kcal(bmr)} /天',
                '身高 ${Fmt.num(_heightCm!, digits: 0)}cm · ${_age}岁 · ${_gender == 'male' ? '男' : '女'}',
                textColor, subColor),
          ),
          Expanded(
            child: _bmrStat('今日摄入', '${Fmt.kcal(intake)}',
                '来自今日饮食记录', textColor, subColor),
          ),
          Expanded(
            child: _bmrStat('热量缺口', deficit >= 0 ? '${Fmt.kcal(deficit)}' : '超${Fmt.kcal(-deficit)}',
                deficit >= 0 ? '摄入低于代谢' : '摄入高于代谢',
                deficit >= 0 ? AppColors.sage : AppColors.prioHigh, subColor),
          ),
        ]),
      ]),
    );
  }

  Widget _bmrStat(String label, String value, String sub, Color tc, Color sc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10.5, color: tc.withValues(alpha: 0.55))),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tc)),
      Text(sub, style: TextStyle(fontSize: 9.5, color: sc), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _remainingBar(double kcalTarget, Color subColor) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final remaining = kcalTarget - _totals.kcal;
    final over = remaining < 0;
    final ratio = kcalTarget <= 0 ? 0.0 : (_totals.kcal / kcalTarget).clamp(0.0, 1.0);
    final gradient = LinearGradient(colors: over
        ? [const Color(0xFFD97B6C), const Color(0xFFE8936B)]
        : [AppColors.doneAll, AppColors.carbColor]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(over ? '已超目标' : '还可摄入',
                style: TextStyle(fontSize: 12, color: subColor)),
            Text(over ? '超出 ${Fmt.kcal(remaining.abs())} kcal' : '${Fmt.kcal(remaining)} kcal 剩余',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: over ? const Color(0xFFD97B6C) : textColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: subColor.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation(
                  over ? const Color(0xFFD97B6C) : AppColors.doneAll),
            ),
          ),
        ),
        // 渐变提示
        const SizedBox(height: 4),
        Container(
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: gradient,
          ),
        ),
      ],
    );
  }

  void _showMacroPie() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: MacroPie(
          protein: _totals.protein,
          carb: _totals.carb,
          fat: _totals.fat,
        ),
      ),
    );
  }

  Future<void> _addFood(MealType mt) async {
    final result = await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFoodSheet(mealType: mt, date: _date),
    );
    if (result != null) {
      await DatabaseService.instance.insertMeal(result);
      context.read<AppState>().bump();
      ParticleOverlay.show(context); // V1.7 粒子
    }
  }

  Future<void> _deleteMeal(MealEntry e) async {
    final ok = await confirmDialog(context,
        title: '删除记录',
        message: '删除「${e.name}」这条记录？',
        confirmText: '删除',
        confirmColor: AppColors.prioHigh);
    if (ok) {
      await DatabaseService.instance.deleteMeal(e.id!);
      context.read<AppState>().bump();
    }
  }

  // V1.7.8 点记录直接改克数：按每 100g 营养自动换算，不用删了重加
  Future<void> _editMeal(MealEntry e) async {
    final db = DatabaseService.instance;
    final ctrl = TextEditingController(text: Fmt.num(e.grams, digits: 0));
    // 由当前记录反推每 100g 营养
    final per100 = e.grams <= 0
        ? 0.0
        : e.kcal / e.grams * 100;
    final newGrams = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final tc = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
        final sc = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
        return AlertDialog(
          title: Text('修改「${e.name}」食量',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '食用量 (g)'),
              ),
              const SizedBox(height: 6),
              Text('每100g ≈ ${Fmt.kcal(per100)} kcal，输入克数自动换算',
                  style: TextStyle(fontSize: 11, color: sc)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消',
                    style: TextStyle(color: Color(0xFF8B919B)))),
            TextButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text);
                Navigator.pop(ctx, v == null || v <= 0 ? null : v);
              },
              child: Text('确定',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    if (newGrams == null || !mounted) return;
    final ratio = newGrams / e.grams;
    await db.updateMeal(MealEntry(
      id: e.id,
      date: e.date,
      mealType: e.mealType,
      foodId: e.foodId,
      name: e.name,
      grams: newGrams,
      kcal: e.kcal * ratio,
      protein: e.protein * ratio,
      carb: e.carb * ratio,
      fat: e.fat * ratio,
      createdAt: e.createdAt,
    ));
    await Haptics.tap();
    if (!mounted) return;
    context.read<AppState>().bump();
  }
}

class _DateSwitcher extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChange;

  const _DateSwitcher({required this.date, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _btn(context, Icons.chevron_left, () => onChange(Fmt.addDays(date, -1))),
          // V1.7.5 点击日期展开月份选择，快速跳转任意月份
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _pickMonth(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${date.year}年${date.month}月',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  Icon(Icons.expand_more,
                      size: 15,
                      color: dark
                          ? const Color(0xFF9AA1AC)
                          : const Color(0xFF8B919B)),
                ],
              ),
            ),
          ),
          _btn(context, Icons.chevron_right, () => onChange(Fmt.addDays(date, 1))),
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => _MonthDayPickerSheet(date: date),
    );
    if (picked != null) {
      onChange(picked);
    }
  }

  Widget _btn(BuildContext context, IconData icon, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 17, color: subColor),
      ),
    );
  }
}

/// V1.7.6 月历选择器：复用 MonthCalendar（左右滑动/箭头切月），点选日期即跳转
class _MonthDayPickerSheet extends StatefulWidget {
  final DateTime date;

  const _MonthDayPickerSheet({required this.date});

  @override
  State<_MonthDayPickerSheet> createState() => _MonthDayPickerSheetState();
}

class _MonthDayPickerSheetState extends State<_MonthDayPickerSheet> {
  Key _calKey = UniqueKey(); // 回到今天时重建日历

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tc = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final sc = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final now = DateTime.now();
    final isCurrentMonth = widget.date.year == now.year &&
        widget.date.month == now.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('选择日期',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: tc)),
              const Spacer(),
              if (!isCurrentMonth)
                TextButton(
                  onPressed: () =>
                      setState(() => _calKey = UniqueKey()),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  child: Text('回到今天',
                      style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 18, color: sc),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          // 月历：左右滑动或箭头切换月份，点选日期跳转
          MonthCalendar(
            key: _calKey,
            selected: widget.date,
            onSelect: (d) => Navigator.pop(context, d),
          ),
        ],
      ),
    );
  }
}

/// 单个餐次卡片（可展开）
class _MealCard extends StatelessWidget {
  final MealType type;
  final List<MealEntry> entries;
  final bool expanded;
  final VoidCallback onExpand;
  final ValueChanged<MealEntry> onDelete;
  final ValueChanged<MealEntry> onEdit; // V1.7.8 点条目改克数

  const _MealCard({
    required this.type,
    required this.entries,
    required this.expanded,
    required this.onExpand,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final totals = MealTotals.sum(entries);

    return MCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: dark ? 0.2 : 0.9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_typeIcon(type),
                        size: 16, color: const Color(0xFFB08A5F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${type.label} · ${entries.length} 项',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        const SizedBox(height: 2),
                        Text(entries.isEmpty
                            ? '还没有记录'
                            : '蛋白${Fmt.num(totals.protein, digits: 1)}g · 脂肪${Fmt.num(totals.fat, digits: 1)}g · 碳水${Fmt.num(totals.carb, digits: 1)}g',
                            style: TextStyle(fontSize: 11.5, color: subColor)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 20, color: subColor),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: entries.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const Divider(),
                      for (final e in entries)
                        _entryRow(e, subColor, textColor, onDelete, onEdit),
                      // V1.7.8 交互提示
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Row(children: [
                          Icon(Icons.touch_app_outlined,
                              size: 11, color: subColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text('点记录改食量 · 长按删除',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: subColor.withValues(alpha: 0.7))),
                        ]),
                      ),
                    ],
                  ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _entryRow(MealEntry e, Color sub, Color text,
      ValueChanged<MealEntry> onDel, ValueChanged<MealEntry> onEdit) {
    return InkWell(
      onTap: () => onEdit(e),
      onLongPress: () => onDel(e),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Row(
          children: [
            Expanded(
              child: Text(e.name,
                  style: TextStyle(fontSize: 13.5, color: text)),
            ),
            Text('${Fmt.num(e.grams, digits: 0)}g',
                style: TextStyle(fontSize: 11.5, color: sub)),
            const SizedBox(width: 12),
            Text('${Fmt.kcal(e.kcal)} kcal',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kcalColor)),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(MealType t) => switch (t) {
        MealType.breakfast => Icons.wb_sunny_outlined,
        MealType.lunch => Icons.lunch_dining_outlined,
        MealType.dinner => Icons.dinner_dining_outlined,
        MealType.snack => Icons.icecream_outlined,
      };
}
