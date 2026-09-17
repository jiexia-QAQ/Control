import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/weight_record.dart';
import '../../services/db.dart';
import '../../widgets/common.dart';
import '../../widgets/line_chart.dart';

/// 体重记录页：折线图（周/月/年）+ 历史列表
class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  List<WeightRecord> _records = [];
  String _range = '月'; // 周/月/年

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DatabaseService.instance.allWeights();
    if (!mounted) return;
    setState(() => _records = r);
  }

  List<(DateTime, double)> get _points {
    final start = switch (_range) {
      '周' => Fmt.addDays(Fmt.today(), -7),
      '年' => Fmt.addDays(Fmt.today(), -365),
      _ => Fmt.addDays(Fmt.today(), -30),
    };
    return _records
        .where((w) => !Fmt.parse(w.date).isBefore(start))
        .map((w) => (Fmt.parse(w.date), w.weight))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      appBar: AppBar(title: const Text('体重记录')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('记录体重'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
        children: [
          MCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('体重趋势',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '周', label: Text('周')),
                        ButtonSegment(value: '月', label: Text('月')),
                        ButtonSegment(value: '年', label: Text('年')),
                      ],
                      selected: {_range},
                      onSelectionChanged: (s) =>
                          setState(() => _range = s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 11.5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TrendLineChart(points: _points, unit: 'kg'),
              ],
            ),
          ),
          SectionTitle(
            '历史记录',
            trailing: Text('${_records.length} 条',
                style: TextStyle(fontSize: 12, color: subColor)),
          ),
          if (_records.isEmpty)
            const EmptyState(
                icon: Icons.monitor_weight_outlined,
                emoji: '⚖️',
                text: '还没有体重记录',
                hint: '记录一次，看见趋势 · 每一次记录都是对自己的耐心')
          else
            for (final w in _records.reversed)
              MCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(Fmt.dayLabel(Fmt.parse(w.date)),
                          style: TextStyle(fontSize: 13.5, color: textColor)),
                    ),
                    Text('${Fmt.weight(w.weight)} kg',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    IconButton(
                      onPressed: () => _edit(w),
                      icon: Icon(Icons.edit_outlined,
                          size: 17,
                          color: subColor.withValues(alpha: 0.8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: () => _delete(w),
                      icon: Icon(Icons.delete_outline,
                          size: 17,
                          color: AppColors.prioHigh.withValues(alpha: 0.8)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _add() => _edit(null);

  Future<void> _edit(WeightRecord? w) async {
    final date = w != null ? Fmt.parse(w.date) : Fmt.today();
    final weightCtrl = TextEditingController(
        text: w != null ? Fmt.weight(w.weight) : '');
    final dateCtrl = TextEditingController(text: Fmt.d(date));

    final ok = await showDialog<(DateTime, double)>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: Text(w == null ? '记录体重' : '编辑记录',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) {
                      setSt(() {
                        dateCtrl.text = Fmt.d(d);
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 15, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(dateCtrl.text,
                            style: const TextStyle(fontSize: 13.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '体重 (kg，精确到 0.1)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消',
                      style: TextStyle(color: Color(0xFF8B919B)))),
              TextButton(
                onPressed: () {
                  final v = double.tryParse(weightCtrl.text);
                  if (v == null || v <= 0 || v > 300) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('请输入有效体重')));
                    return;
                  }
                  Navigator.pop(
                    ctx,
                    (
                      Fmt.parse(dateCtrl.text),
                      double.parse(v.toStringAsFixed(1))
                    ),
                  );
                },
                child: Text('保存',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        });
      },
    );

    if (ok == null || !mounted) return;
    final db = DatabaseService.instance;
    if (w == null) {
      await db.insertWeight(WeightRecord(date: Fmt.d(ok.$1), weight: ok.$2));
    } else {
      await db.updateWeight(WeightRecord(
          id: w.id, date: Fmt.d(ok.$1), weight: ok.$2));
    }
    await Haptics.success();
    await _load();
  }

  Future<void> _delete(WeightRecord w) async {
    final ok = await confirmDialog(context,
        title: '删除记录',
        message: '删除 ${Fmt.d(Fmt.parse(w.date))} 的 ${Fmt.weight(w.weight)} kg 记录？',
        confirmText: '删除',
        confirmColor: AppColors.prioHigh);
    if (!ok) return;
    await DatabaseService.instance.deleteWeight(w.id!);
    await _load();
  }
}
