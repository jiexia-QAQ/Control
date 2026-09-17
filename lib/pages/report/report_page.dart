import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/accounting.dart';
import '../../services/db.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// V1.7 数据报告：周/月概览 + 年度热力图 + 阶段目标
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _loading = true;
  int _weekChecks = 0, _weekPlans = 0;
  int _monthChecks = 0, _monthPlans = 0;
  int _monthWorkouts = 0, _totalWorkouts = 0;
  double _monthExpense = 0, _monthIncome = 0, _balance = 0;
  double? _latestWeight;
  Map<String, (int, int)> _heat = {};
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.select<AppState, int>((s) => s.tick);
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // 周
    final weekMap = await db.rangePlanProgress(monday, today);
    var wc = 0, wp = 0;
    weekMap.forEach((_, pr) {
      wp += pr.$2;
      wc += pr.$1;
    });
    // 月
    final mc = await db.checkDaysOfMonth(today);
    final mp = await db.totalPlansOfMonth(today);
    // 其它
    final mw = await db.workoutsOfMonth(today);
    final tw = await db.totalWorkouts();
    final me = await db.totalExpensesOfMonth(today);
    final mi = await db.totalIncomesOfMonth(today);
    final bal = await db.currentBalance();
    final w = await db.latestWeight();
    // 热力图：过去 364 天
    final heat = await db.rangePlanProgress(
        today.subtract(const Duration(days: 363)), today);
    final goals = await db.goals();

    if (!mounted) return;
    setState(() {
      _weekChecks = wc;
      _weekPlans = wp;
      _monthChecks = mc;
      _monthPlans = mp;
      _monthWorkouts = mw;
      _totalWorkouts = tw;
      _monthExpense = me;
      _monthIncome = mi;
      _balance = bal;
      _latestWeight = w;
      _heat = heat;
      _goals = goals;
      _loading = false;
    });
  }

  Future<void> _addGoal() async {
    final nameCtrl = TextEditingController();
    var type = 'weight';
    final targetCtrl = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final tc = Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFFE9EBEF)
            : const Color(0xFF3C434E);
        return StatefulBuilder(builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Text('添加阶段目标',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tc))),
            const SizedBox(height: 14),
            TextField(controller: nameCtrl, autofocus: true,
                decoration: const InputDecoration(hintText: '目标名称（如：月底瘦到 68kg）'),
                style: TextStyle(fontSize: 14, color: tc)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'weight', label: Text('体重')),
                  ButtonSegment(value: 'balance', label: Text('余额')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setS(() => type = s.first),
                style: ButtonStyle(visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12))),
              )),
            ]),
            const SizedBox(height: 10),
            TextField(controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: type == 'weight' ? '目标体重（kg）' : '目标余额（元）'),
                style: TextStyle(fontSize: 14, color: tc)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 46, child: FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || targetCtrl.text.trim().isEmpty) {
                  showToast(ctx, '请填写完整');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('保存目标', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
          ]),
        ));
      },
    );
    if (saved == true) {
      final db = DatabaseService.instance;
      final start = type == 'weight'
          ? (await db.latestWeight() ?? 0)
          : await db.currentBalance();
      await db.insertGoal(Goal(
        name: nameCtrl.text.trim(),
        type: type,
        target: double.tryParse(targetCtrl.text.trim()) ?? 0,
        start: start,
      ));
      context.read<AppState>().bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final weekRate = _weekPlans == 0 ? 0.0 : _weekChecks / _weekPlans;
    final monthRate = _monthPlans == 0 ? 0.0 : _monthChecks / _monthPlans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据报告'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  // 周概览
                  _overviewCard('本周', weekRate, _weekChecks, _weekPlans,
                      _monthWorkouts, textColor, subColor, dark),
                  const SizedBox(height: 12),
                  // 月概览
                  _monthCard(textColor, subColor, dark, monthRate),
                  const SizedBox(height: 12),
                  // 阶段目标
                  _goalsCard(textColor, subColor, dark),
                  const SizedBox(height: 12),
                  // 年度热力图
                  _heatCard(textColor, subColor, dark),
                ],
              ),
            ),
    );
  }

  Widget _overviewCard(String title, double rate, int checks, int plans,
      int workouts, Color tc, Color sc, bool dark) {
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('📊 $title概览', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc)),
          const Spacer(),
          Text('完成率 ${(rate * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _bigStat('打卡天数', '$checks 天', '本月计划 $plans 项', tc, sc)),
          Expanded(child: _bigStat('训练次数', '$workouts 次', '累计 ${_totalWorkouts} 次', tc, sc)),
          Expanded(child: _bigStat('本月支出', '¥${Fmt.num(_monthExpense)}', '收入 ¥${Fmt.num(_monthIncome)}', tc, sc)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 7,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ]),
    );
  }

  Widget _monthCard(Color tc, Color sc, bool dark, double monthRate) {
    final weightText = _latestWeight == null
        ? '未记录'
        : '${Fmt.num(_latestWeight!, digits: 1)} kg';
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📅 本月数据', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _bigStat('打卡率', '${(monthRate * 100).round()}%', '本月完成 ${_monthChecks} 天', tc, sc)),
          Expanded(child: _bigStat('最新体重', weightText, _latestWeight == null ? '去我的页记录' : '', tc, sc)),
          Expanded(child: _bigStat('当前余额', '¥${Fmt.num(_balance)}', '含借贷待还', tc, sc)),
        ]),
      ]),
    );
  }

  Widget _bigStat(String label, String value, String sub, Color tc, Color sc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10.5, color: tc.withValues(alpha: 0.55))),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tc)),
      Text(sub, style: TextStyle(fontSize: 10, color: sc), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _goalsCard(Color tc, Color sc, bool dark) {
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🎯 阶段目标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc)),
          const Spacer(),
          TextButton.icon(onPressed: _addGoal, icon: const Icon(Icons.add, size: 16), label: const Text('添加')),
        ]),
        if (_goals.isEmpty)
          Text('设定目标（体重/余额），数据自动联动进度', style: TextStyle(fontSize: 11.5, color: sc))
        else
          for (final g in _goals) _goalRow(g, tc, sc, dark),
      ]),
    );
  }

  Widget _goalRow(Goal g, Color tc, Color sc, bool dark) {
    final isWeight = g.type == 'weight';
    final cur = isWeight ? (_latestWeight ?? 0) : _balance;
    // 进度：从 start 到 target 的线性进度
    final span = (g.target - g.start).abs();
    final progress = span == 0 ? 0.0 : ((cur - g.start) / (g.target - g.start)).clamp(0.0, 1.0);
    final reached = progress >= 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onLongPress: () async {
          final ok = await confirmDialog(context, title: '删除目标',
              message: '确定删除「${g.name}」吗？', confirmText: '删除', confirmColor: AppColors.prioHigh);
          if (ok) {
            await DatabaseService.instance.deleteGoal(g.id!);
            context.read<AppState>().bump();
          }
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(g.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tc)),
            const Spacer(),
            Text(reached ? '✅ 达成' : '${isWeight ? '' : '¥'}${Fmt.num(cur, digits: isWeight ? 1 : 0)} / ${isWeight ? '' : '¥'}${Fmt.num(g.target, digits: isWeight ? 1 : 0)}',
                style: TextStyle(fontSize: 11.5, color: reached ? AppColors.sage : sc)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(reached ? AppColors.sage : AppColors.primary),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _heatCard(Color tc, Color sc, bool dark) {
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🔥 年度自律热力图', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc)),
        const SizedBox(height: 4),
        Text('每天颜色越深 = 完成度越高', style: TextStyle(fontSize: 11, color: sc)),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 53 / 14,
          child: CustomPaint(
            painter: _HeatPainter(_heat,
                dark: dark, primary: AppColors.primary),
          ),
        ),
      ]),
    );
  }
}

/// 年度热力图：53 周 × 7 天，GitHub 风格
class _HeatPainter extends CustomPainter {
  final Map<String, (int, int)> data;
  final bool dark;
  final Color primary;

  _HeatPainter(this.data, {required this.dark, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 9.0, gap = 3.0;
    final cols = 53;
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(const Duration(days: 363));
    final dayCount = 364;
    final emptyColor = dark
        ? const Color(0xFF2C313B)
        : const Color(0xFFECEBE7);
    final lv1 = primary.withValues(alpha: 0.28);
    final lv2 = primary.withValues(alpha: 0.55);
    final lv3 = primary.withValues(alpha: 0.8);
    final lv4 = primary;

    for (var i = 0; i < dayCount; i++) {
      final d = start.add(Duration(days: i));
      final col = i ~/ 7;
      final row = i % 7;
      final x = 1 + col * (cell + gap);
      final y = 1 + row * (cell + gap);
      final key = Fmt.d(d);
      final pr = data[key];
      Color color = emptyColor;
      if (pr != null && pr.$2 > 0) {
        final r = pr.$1 / pr.$2;
        color = r >= 1.0
            ? lv4
            : r >= 0.66
                ? lv3
                : r >= 0.33
                    ? lv2
                    : lv1;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cell, cell), Radius.circular(2)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) => old.data != data;
}
