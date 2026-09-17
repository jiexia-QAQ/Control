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
import '../../widgets/particle_burst.dart';

/// 分类 emoji
const _expEmoji = {
  '餐饮': '🍜', '购物': '🛍️', '出行': '🚕', '居住': '🏠',
  '娱乐': '🎮', '医疗': '💊', '教育': '📚', '其他': '📦',
};
const _incEmoji = {
  '工资': '💰', '兼职': '💼', '理财': '📈', '红包': '🧧', '其他': '📦',
};

/// V1.6 记账主页：财务仪表盘 + 记录 + 借贷
class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  double _balance = 0, _initialAssets = 0;
  double _monthIncome = 0, _monthExpense = 0;
  double _creditRemaining = 0;
  double _budget = 0; // V1.7 月度预算
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<CreditBill> _bills = [];
  List<WishItem> _wishes = []; // V1.6 愿望清单

  final GlobalKey _incomeKey = GlobalKey();
  final GlobalKey _expenseKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 数据变更（其他页面记账/本页操作）后刷新
    context.select<AppState, int>((s) => s.tick);
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final balance = await db.currentBalance();
    final init = await db.getInitialAssets();
    final mi = await db.totalIncomesOfMonth(_month);
    final me = await db.totalExpensesOfMonth(_month);
    final credit = await db.creditRemainingTotal();
    final exps = await db.expensesOfMonth(_month);
    final incs = await db.incomesOfMonth(_month);
    final bills = await db.creditBills();
    final wishes = await db.wishItems(); // V1.6 愿望清单
    final budget = await db.getMonthlyBudget(); // V1.7 预算
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _initialAssets = init;
      _monthIncome = mi;
      _monthExpense = me;
      _creditRemaining = credit;
      _budget = budget;
      _expenses = exps;
      _incomes = incs;
      _bills = bills;
      _wishes = wishes;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _loading = true;
    });
    _load();
  }

  /// 快速记账入口
  Future<void> _openEntry({required bool isIncome}) async {
    await Haptics.tap();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntrySheet(isIncome: isIncome, defaultDate: _month),
    );
    if (saved == true) {
      context.read<AppState>().bump();
      // 粒子爆发：按钮位置
      final ctx = isIncome ? _incomeKey.currentContext : _expenseKey.currentContext;
      if (ctx != null) {
        ParticleBurst.maybeOf(ctx);
      }
    }
  }

  /// 借贷管理
  Future<void> _openCredit() async {
    await Haptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreditSheet(),
    );
    context.read<AppState>().bump();
  }

  /// 设定初始资产
  Future<void> _setInitialAssets() async {
    final ctrl = TextEditingController(text: _initialAssets == 0 ? '' : Fmt.num(_initialAssets, digits: 0));
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置初始总资产'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: '现有存款 / 总资产（元）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final n = double.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, n ?? 0);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (v != null) {
      await DatabaseService.instance.setInitialAssets(v);
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
    final ratio = _monthIncome > 0 ? (_monthExpense / _monthIncome).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Text('💰 记账',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('数据仅存本地',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sage)),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openCredit,
                    icon: const Icon(Icons.credit_score_outlined, size: 16),
                    label: const Text('借贷'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                        children: [
                          _balanceCard(dark, textColor, subColor),
                          const SizedBox(height: 12),
                          _monthRow(dark, textColor, subColor, ratio),
                          if (_budget > 0) ...[
                            const SizedBox(height: 12),
                            _budgetBar(dark, textColor, subColor),
                          ],
                          const SizedBox(height: 12),
                          _wishCard(dark, textColor, subColor), // V1.6 愿望清单
                          if (_bills.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _creditCard(dark, textColor, subColor),
                          ],
                          const SizedBox(height: 12),
                          _recordList(dark, textColor, subColor),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      // 底部快捷记账
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: _QuickBtn(
                  key: _expenseKey,
                  color: AppColors.prioHigh,
                  emoji: '➖',
                  label: '记支出',
                  onTap: () => _openEntry(isIncome: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickBtn(
                  key: _incomeKey,
                  color: AppColors.sage,
                  emoji: '➕',
                  label: '记收入',
                  onTap: () => _openEntry(isIncome: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 仪表盘卡片 ----------
  Widget _balanceCard(bool dark, Color textColor, Color subColor) {
    return MCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('当前余额',
                  style: TextStyle(fontSize: 12.5, color: subColor)),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _setInitialAssets,
                child: Text(
                  _initialAssets > 0 ? '初始资产 ¥${Fmt.num(_initialAssets, digits: 0)} 修改' : '设定初始资产',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // V1.7 iOS 风格数字滚动
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.25), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: Text(
              '¥${Fmt.num(_balance)}',
              key: ValueKey(_balance),
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                height: 1.1),
          ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('本月收入', _monthIncome, AppColors.sage, textColor),
              const SizedBox(width: 16),
              _miniStat('本月支出', _monthExpense, AppColors.prioHigh, textColor),
              const Spacer(),
              if (_creditRemaining > 0)
                _miniStat('借贷待还', _creditRemaining, AppColors.accent, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double v, Color c, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10.5, color: textColor.withValues(alpha: 0.55))),
        const SizedBox(height: 2),
        Text('¥${Fmt.num(v)}',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c)),
      ],
    );
  }

  // ---------- 收支比进度环 ----------
  Widget _monthRow(bool dark, Color textColor, Color subColor, double ratio) {
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CustomPaint(
                painter: _RingPainter(v, AppColors.primary, AppColors.prioHigh),
                child: Center(
                  child: Text('${(v * 100).round()}%',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本月支出 / 收入',
                    style: TextStyle(fontSize: 12.5, color: subColor)),
                const SizedBox(height: 6),
                Text(ratio >= 1
                    ? '支出已超过收入，注意控制 💡'
                    : '支出占收入的 ${(ratio * 100).round()}%，节奏不错',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 4),
                Text('收入 ¥${Fmt.num(_monthIncome)} · 支出 ¥${Fmt.num(_monthExpense)}',
                    style: TextStyle(fontSize: 11, color: subColor)),
              ],
            ),
          ),
          // 月份切换
          Column(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              Text('${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11.5, color: textColor)),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- 愿望清单 V1.6 ----------
  Widget _wishCard(bool dark, Color textColor, Color subColor) {
    final unachieved = _wishes.where((w) => !w.achieved).toList();
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🎯 愿望清单',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const Spacer(),
              TextButton.icon(
                onPressed: _openWishSheet,
                icon: Icon(Icons.favorite_border, size: 16, color: AppColors.rose),
                label: Text(unachieved.isEmpty ? '添加心愿' : '管理',
                    style: TextStyle(fontSize: 12, color: AppColors.rose)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (unachieved.isEmpty)
            Text('想买的东西记下来，心心念念也要自律预算 💭',
                style: TextStyle(fontSize: 11.5, color: subColor))
          else ...[
            for (var i = 0; i < unachieved.length && i < 3; i++) ...[
              _wishRow(unachieved[i], textColor, subColor),
              if (i < unachieved.length - 1 && i < 2)
                const SizedBox(height: 8),
            ],
            if (unachieved.length > 3)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openWishSheet,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('还有 ${unachieved.length - 3} 个心愿 · 查看全部 ›',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _wishRow(WishItem w, Color textColor, Color subColor) {
    final emoji = wishEmoji[w.category] ?? '🎁';
    final prioColors = [AppColors.prioLow, AppColors.prioMid, AppColors.prioHigh];
    final prioColor = prioColors[w.priority.clamp(0, 2)];
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: prioColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 2),
              Text('${w.category} · ${w.priorityLabel}优先${w.price > 0 ? ' · ¥${Fmt.num(w.price)}' : ''}',
                  style: TextStyle(fontSize: 11, color: subColor)),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _markWish(w),
          child: Icon(Icons.check_circle_outline, size: 20, color: AppColors.sage.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Future<void> _markWish(WishItem w) async {
    await DatabaseService.instance.updateWishItem(WishItem(
      id: w.id, name: w.name, price: w.price, category: w.category,
      priority: w.priority, note: w.note, achieved: true,
    ));
    showToast(context, '🎉 愿望达成！${w.name}');
    context.read<AppState>().bump();
  }

  Future<void> _openWishSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _WishSheet(),
    );
    context.read<AppState>().bump();
  }

  // ---------- V1.7 月度预算 ----------
  Future<void> _setBudget() async {
    final ctrl = TextEditingController(
        text: _budget > 0 ? Fmt.num(_budget, digits: 0) : '');
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置月度预算'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '每月支出预算（元）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
              onPressed: () {
                final n = double.tryParse(ctrl.text.trim());
                Navigator.pop(ctx, n ?? 0);
              },
              child: const Text('保存')),
        ],
      ),
    );
    if (v != null) {
      await DatabaseService.instance.setMonthlyBudget(v);
      context.read<AppState>().bump();
    }
  }

  Widget _budgetBar(bool dark, Color textColor, Color subColor) {
    final ratio = _budget <= 0 ? 0.0 : (_monthExpense / _budget).clamp(0.0, 1.0);
    final over = _monthExpense > _budget;
    final color = over ? AppColors.prioHigh : AppColors.primary;
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('💼 月度预算', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor)),
          const Spacer(),
          Text(over ? '超支 ¥${Fmt.num(_monthExpense - _budget)}' : '剩余 ¥${Fmt.num(_budget - _monthExpense)}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: over ? AppColors.prioHigh : AppColors.sage)),
          const SizedBox(width: 4),
          InkWell(
            onTap: _setBudget,
            borderRadius: BorderRadius.circular(8),
            child: Icon(Icons.edit_outlined, size: 15, color: subColor),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text('已用 ¥${Fmt.num(_monthExpense)} / ¥${Fmt.num(_budget)}（${(ratio * 100).round()}%）',
            style: TextStyle(fontSize: 11, color: subColor)),
      ]),
    );
  }

  // ---------- 借贷卡片（V1.8.1 去掉到期，强调总数） ----------
  Widget _creditCard(bool dark, Color textColor, Color subColor) {
    final unpaid = _bills.where((b) => !b.paid).toList();
    final paidTotal = _bills
        .where((b) => b.paid)
        .fold<double>(0, (s, b) => s + b.amount);
    final totalAll = unpaid.fold<double>(0, (s, b) => s + b.amount);
    return MCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💳 借贷',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const Spacer(),
              Text('${unpaid.length} 笔待还',
                  style: TextStyle(fontSize: 11.5, color: subColor)),
            ],
          ),
          const SizedBox(height: 10),
          // 总数强调
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('待还总额',
                    style: TextStyle(fontSize: 10.5, color: subColor)),
                const SizedBox(height: 3),
                Text('¥${Fmt.num(_creditRemaining)}',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        height: 1.1)),
              ]),
              const Spacer(),
              if (paidTotal > 0)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('已还清',
                      style: TextStyle(fontSize: 10.5, color: subColor)),
                  const SizedBox(height: 3),
                  Text('¥${Fmt.num(paidTotal)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sage)),
                ]),
            ],
          ),
          if (unpaid.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            for (final b in unpaid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(b.provider,
                        style: TextStyle(fontSize: 13, color: textColor)),
                    const Spacer(),
                    Text('¥${Fmt.num(b.remaining)}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    if (b.amount > 0) ...[
                      const SizedBox(width: 4),
                      Text('/ ¥${Fmt.num(b.amount)}',
                          style: TextStyle(fontSize: 11, color: subColor)),
                    ],
                  ],
                ),
              ),
            if (totalAll > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalAll == 0
                      ? 0
                      : ((totalAll - _creditRemaining) / totalAll)
                          .clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(AppColors.sage),
                ),
              ),
          ],
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _openCredit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('管理借贷（花呗/白条/信用卡） ›',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 记录列表 ----------
  Widget _recordList(bool dark, Color textColor, Color subColor) {
    // 合并本月记录，按日期分组
    final items = <(String date, String emoji, String name, String sub, double amount, bool isIncome, int? id, bool isExpense)>[];
    for (final e in _expenses) {
      items.add((e.date, _expEmoji[e.category] ?? '📦', e.category,
          [e.account, e.note].where((s) => s.isNotEmpty).join(' · '), -e.amount,
          false, e.id, true));
    }
    for (final i in _incomes) {
      items.add((i.date, _incEmoji[i.category] ?? '📦', i.category,
          [i.account, i.note].where((s) => s.isNotEmpty).join(' · '), i.amount,
          true, i.id, false));
    }
    items.sort((a, b) => b.$1.compareTo(a.$1));
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        emoji: '🧾',
        text: '本月还没有记录',
        hint: '点下方「记支出 / 记收入」开始记账',
      );
    }
    // 按日期分组
    final groups = <String, List<(String, String, String, String, double, bool, int?, bool)>>{};
    for (final it in items) {
      groups.putIfAbsent(it.$1, () => []).add(it);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text('本月明细',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
        ),
        MCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final d in dates) ...[
                _dayHeader(d, dark, textColor, subColor),
                for (final it in groups[d]!) _recordRow(it, textColor, subColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayHeader(String d, bool dark, Color textColor, Color subColor) {
    final dt = Fmt.parse(d);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Text('${dt.month}月${dt.day}日 ${Fmt.cnWeekday(dt)}',
              style: TextStyle(fontSize: 11, color: subColor)),
        ],
      ),
    );
  }

  Widget _recordRow(
      (String, String, String, String, double, bool, int?, bool) it,
      Color textColor,
      Color subColor) {
    final isIncome = it.$6;
    final amountColor = isIncome ? AppColors.sage : AppColors.prioHigh;
    final sign = isIncome ? '+' : '-';
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: amountColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
            child: Text(it.$3 == '其他' ? it.$2 : it.$2,
                style: const TextStyle(fontSize: 16))),
      ),
      title: Text(it.$3, style: TextStyle(fontSize: 13.5, color: textColor)),
      subtitle: it.$4.isEmpty
          ? null
          : Text(it.$4, style: TextStyle(fontSize: 11, color: subColor)),
      trailing: Text('$sign¥${Fmt.num(it.$5.abs())}',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor)),
      onLongPress: () async {
        final db = DatabaseService.instance;
        final ok = await confirmDialog(context,
            title: '删除记录',
            message: '确定删除这笔${isIncome ? '收入' : '支出'}吗？',
            confirmText: '删除',
            confirmColor: AppColors.prioHigh);
        if (ok) {
          if (isIncome) {
            await db.deleteIncome(it.$7!);
          } else {
            await db.deleteExpense(it.$7!);
          }
          context.read<AppState>().bump();
        }
      },
    );
  }
}

/// 快速记账按钮（按压缩放 96% + 触觉 + 粒子宿主）
class _QuickBtn extends StatefulWidget {
  final Color color;
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(
      {super.key,
      required this.color,
      required this.emoji,
      required this.label,
      required this.onTap});

  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return ParticleBurst(
      child: GestureDetector(
        onTapDown: (_) {
          Haptics.tap();
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 收支进度环
class _RingPainter extends CustomPainter {
  final double ratio;
  final Color trackColor;
  final Color valueColor;
  _RingPainter(this.ratio, this.trackColor, this.valueColor);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = trackColor.withValues(alpha: 0.15)
      ..strokeCap = StrokeCap.round;
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = valueColor
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -1.5708,
        math.pi * 2 * ratio, false, value);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ratio != ratio;
}

// ============ 手动记账 sheet ============

class _EntrySheet extends StatefulWidget {
  final bool isIncome;
  final DateTime defaultDate;
  const _EntrySheet({required this.isIncome, required this.defaultDate});

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late String _account;
  late DateTime _date;
  final GlobalKey _burstKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
    _category = (widget.isIncome ? incomeCategories : expenseCategories).first;
    _account = accountOptions.first;
    _date = widget.defaultDate;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt <= 0) {
      showToast(context, '请输入有效金额');
      return;
    }
    final db = DatabaseService.instance;
    if (widget.isIncome) {
      await db.insertIncome(Income(
        date: Fmt.d(_date),
        amount: amt,
        category: _category,
        note: _note.text.trim(),
        account: _account,
      ));
    } else {
      await db.insertExpense(Expense(
        date: Fmt.d(_date),
        amount: amt,
        category: _category,
        note: _note.text.trim(),
        account: _account,
      ));
    }
    await Haptics.success();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final cats = widget.isIncome ? incomeCategories : expenseCategories;
    final emojiMap = widget.isIncome ? _incEmoji : _expEmoji;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(widget.isIncome ? '记一笔收入' : '记一笔支出',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  hintText: '金额（元）', prefixText: '¥ '),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 14),
            Text('分类', style: TextStyle(fontSize: 12.5, color: textColor.withValues(alpha: 0.7))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    label: Text('${emojiMap[c] ?? ''} $c',
                        style: const TextStyle(fontSize: 12)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('账户', style: TextStyle(fontSize: 12.5, color: textColor.withValues(alpha: 0.7))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in accountOptions)
                  ChoiceChip(
                    label: Text(a, style: const TextStyle(fontSize: 12)),
                    selected: _account == a,
                    onSelected: (_) => setState(() => _account = a),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              decoration: const InputDecoration(hintText: '备注（可选）'),
              style: TextStyle(fontSize: 13.5, color: textColor),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  helpText: '选择日期',
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(Fmt.dayLabel(_date),
                        style: TextStyle(fontSize: 13.5, color: textColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ParticleBurst(
              key: _burstKey,
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.isIncome
                        ? AppColors.sage
                        : AppColors.prioHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('保存 · 记${widget.isIncome ? '收入' : '支出'}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('🔒 记录只保存在本机，不会上传',
                  style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5))),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ 借贷管理 sheet ============

class _CreditSheet extends StatefulWidget {
  const _CreditSheet();

  @override
  State<_CreditSheet> createState() => _CreditSheetState();
}

class _CreditSheetState extends State<_CreditSheet> {
  List<CreditBill> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bills = await DatabaseService.instance.creditBills();
    if (!mounted) return;
    setState(() {
      _bills = bills;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final provider = TextEditingController(text: '花呗');
    final amount = TextEditingController();
    final remaining = TextEditingController();
    final note = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor =
            dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text('添加借贷账单',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: provider.text,
                  decoration: const InputDecoration(labelText: '渠道'),
                  style: TextStyle(fontSize: 14, color: textColor),
                  items: [
                    for (final p in creditProviders)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setSheet(() => provider.text = v ?? '花呗'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: '账单金额'),
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: remaining,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: '剩余应还'),
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(hintText: '备注（可选）'),
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () {
                      final a = double.tryParse(amount.text.trim());
                      final r = double.tryParse(remaining.text.trim());
                      if (a == null || a <= 0 || r == null || r < 0) {
                        showToast(ctx, '请输入有效金额');
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('保存账单',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (saved == true) {
      final a = double.tryParse(amount.text.trim()) ?? 0;
      final r = double.tryParse(remaining.text.trim()) ?? a;
      await DatabaseService.instance.insertCreditBill(CreditBill(
        provider: provider.text,
        amount: a,
        remaining: r,
        dueDate: Fmt.d(DateTime.now()),
        note: note.text.trim(),
      ));
      _load();
    }
  }

  Future<void> _markPaid(CreditBill b) async {
    await DatabaseService.instance
        .updateCreditBill(CreditBill(
      id: b.id,
      provider: b.provider,
      amount: b.amount,
      remaining: 0,
      dueDate: b.dueDate,
      note: b.note,
      paid: true,
      source: b.source,
    ));
    showToast(context, '已标记还清 🎉');
    _load();
  }

  Future<void> _delete(CreditBill b) async {
    final ok = await confirmDialog(context,
        title: '删除账单',
        message: '确定删除「${b.provider} ${Fmt.num(b.amount)} 元」这条借贷记录吗？',
        confirmText: '删除',
        confirmColor: AppColors.prioHigh);
    if (ok) {
      await DatabaseService.instance.deleteCreditBill(b.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Text('💳 借贷管理',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bills.isEmpty
                    ? EmptyState(
                        icon: Icons.credit_score_outlined,
                        emoji: '💳',
                        text: '还没有借贷账单',
                        hint: '花呗 / 白条 / 信用卡还款，点右上角添加')
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                        itemCount: _bills.length,
                        itemBuilder: (context, i) {
                          final b = _bills[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: dark
                                  ? const Color(0xFF2C313B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: b.paid ? null : () => _markPaid(b),
                                onLongPress: () => _delete(b),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: const Center(
                                            child: Text('💳',
                                                style: TextStyle(
                                                    fontSize: 15))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${b.provider} · ¥${Fmt.num(b.amount)}'
                                              '${b.paid ? '（已还清）' : ''}',
                                              style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: b.paid
                                                      ? subColor
                                                      : textColor),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '剩 ¥${Fmt.num(b.remaining)} / ¥${Fmt.num(b.amount)}'
                                              '${b.note.isEmpty ? '' : ' · ${b.note}'}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: subColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!b.paid)
                                        Text('点按还清',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============ 愿望清单管理 sheet ============

class _WishSheet extends StatefulWidget {
  const _WishSheet();

  @override
  State<_WishSheet> createState() => _WishSheetState();
}

class _WishSheetState extends State<_WishSheet> {
  List<WishItem> _wishes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wishes = await DatabaseService.instance.wishItems();
    if (!mounted) return;
    setState(() { _wishes = wishes; _loading = false; });
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var cat = '其他';
    var prio = 1;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final tc = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
        return StatefulBuilder(builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Text('添加心愿', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tc))),
            const SizedBox(height: 14),
            TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(hintText: '想要什么？'), style: TextStyle(fontSize: 14, color: tc)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '价格（元）'), style: TextStyle(fontSize: 14, color: tc))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: '备注（可选）'), style: TextStyle(fontSize: 14, color: tc))),
            ]),
            const SizedBox(height: 12),
            Text('种类', style: TextStyle(fontSize: 12, color: tc.withValues(alpha: 0.7))),
            Wrap(spacing: 5, runSpacing: 5, children: [
              for (final c in wishCategories)
                ChoiceChip(label: Text('${wishEmoji[c] ?? ''} $c', style: const TextStyle(fontSize: 11.5)), selected: cat == c, onSelected: (_) => setS(() => cat = c), showCheckmark: false, visualDensity: VisualDensity.compact),
            ]),
            const SizedBox(height: 10),
            Text('优先级', style: TextStyle(fontSize: 12, color: tc.withValues(alpha: 0.7))),
            Row(children: [
              for (var i = 0; i < 3; i++)
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(const ['低', '中', '高'][i], style: const TextStyle(fontSize: 12)), selected: prio == i, onSelected: (_) => setS(() => prio = i), showCheckmark: false, visualDensity: VisualDensity.compact)),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 46, child: FilledButton(
              onPressed: () { if (nameCtrl.text.trim().isEmpty) { showToast(ctx, '请输入名称'); return; } Navigator.pop(ctx, true); },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('保存', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
          ]),
        ));
      },
    );
    if (saved == true) {
      await DatabaseService.instance.insertWishItem(WishItem(
        name: nameCtrl.text.trim(), price: double.tryParse(priceCtrl.text.trim()) ?? 0,
        category: cat, priority: prio, note: noteCtrl.text.trim(),
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tc = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final sc = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return DraggableScrollableSheet(expand: false, initialChildSize: 0.75, maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 6), child: Row(children: [
          Text('🎯 愿望清单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tc)),
          const Spacer(),
          TextButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 18), label: const Text('添加')),
        ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _wishes.isEmpty
            ? EmptyState(icon: Icons.favorite_border, emoji: '🎯', text: '还没有心愿', hint: '想买什么就记下来吧')
            : ListView.builder(controller: scrollCtrl, padding: const EdgeInsets.fromLTRB(18, 4, 18, 20), itemCount: _wishes.length,
                itemBuilder: (context, i) {
                  final w = _wishes[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(
                    color: dark ? const Color(0xFF2C313B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(borderRadius: BorderRadius.circular(14),
                      onTap: w.achieved ? null : () async {
                        await DatabaseService.instance.updateWishItem(WishItem(id: w.id, name: w.name, price: w.price, category: w.category, priority: w.priority, note: w.note, achieved: true));
                        showToast(context, '🎉 ${w.name} 已实现！'); _load();
                      },
                      onLongPress: () async {
                        final ok = await confirmDialog(context, title: '删除心愿', message: '确定删除「${w.name}」吗？', confirmText: '删除', confirmColor: AppColors.prioHigh);
                        if (ok) { await DatabaseService.instance.deleteWishItem(w.id!); _load(); }
                      },
                      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                        Container(width: 34, height: 34,
                          decoration: BoxDecoration(color: (w.achieved ? AppColors.sage : AppColors.accent).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                          child: Center(child: Text(w.achieved ? '✅' : (wishEmoji[w.category] ?? '🎁'), style: const TextStyle(fontSize: 15)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(w.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: w.achieved ? sc : tc)),
                          const SizedBox(height: 2),
                          Text(['${w.priorityLabel}优先', w.category, if (w.price > 0) '¥${Fmt.num(w.price)}', w.note].where((s) => s.isNotEmpty).join(' · '), style: TextStyle(fontSize: 11, color: sc)),
                        ])),
                      ])),
                    ),
                  ));
                },
              ),
        ),
      ]),
    );
  }
}
