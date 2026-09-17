import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/plan.dart';

/// 新建/编辑计划表单
class PlanEditSheet extends StatefulWidget {
  final Plan? plan;
  final DateTime defaultDate;

  const PlanEditSheet({super.key, this.plan, required this.defaultDate});

  @override
  State<PlanEditSheet> createState() => _PlanEditSheetState();
}

class _PlanEditSheetState extends State<PlanEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _time;
  late int _priority;
  late String _type; // V1.7: 'daily' 单日 | 'repeat' 重复 | 'once' 一次性
  late DateTime _date;
  late Set<int> _repeatDays;
  late bool _remindEnabled; // V1.4
  late TimeOfDay _remindTime; // V1.4

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _note = TextEditingController(text: p?.note ?? '');
    _time = TextEditingController(text: p?.timeLabel ?? '');
    _priority = p?.priority ?? 1;
    _type = p?.type ?? (p?.isRepeat ?? false ? 'repeat' : 'daily');
    _date = p?.date != null ? Fmt.parse(p!.date!) : widget.defaultDate;
    _repeatDays = (p?.repeatDays ?? const []).toSet();
    _remindEnabled = p?.remindAt != null;
    _remindTime = _parseRemind(p?.remindAt) ?? const TimeOfDay(hour: 8, minute: 0);
  }

  static TimeOfDay? _parseRemind(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtRemind(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.plan == null ? '新建计划' : '编辑计划',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              autofocus: widget.plan == null,
              decoration: const InputDecoration(hintText: '计划名称（如：晨跑 5 公里）'),
              style: TextStyle(fontSize: 14.5, color: textColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(hintText: '备注（可选）'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 12),
            // 时间段（独立一行）
            TextField(
              controller: _time,
              decoration: const InputDecoration(hintText: '时间段（可选，如 07:00）'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 12),
            // V1.7 类型选择（独占一行，三选项均分全宽，避免文字换行）
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('单日')),
                  ButtonSegment(value: 'repeat', label: Text('重复')),
                  ButtonSegment(value: 'once', label: Text('一次性')),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
                expandedInsets: EdgeInsets.zero,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            // V1.4 计划提醒（一次性任务无提醒）
            if (_type != 'once') ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _remindEnabled = !_remindEnabled),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _remindEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 18,
                        color: _remindEnabled
                            ? AppColors.accent
                            : subColor,
                      ),
                      const SizedBox(width: 10),
                      Text('提醒我',
                          style: TextStyle(fontSize: 13.5, color: textColor)),
                      const Spacer(),
                      if (_remindEnabled)
                        GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _remindTime,
                              helpText: '选择提醒时间',
                            );
                            if (t != null) setState(() => _remindTime = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.blush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_fmtRemind(_remindTime),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent)),
                          ),
                        )
                      else
                        Text('到点提醒打卡',
                            style: TextStyle(fontSize: 11.5, color: subColor)),
                      const SizedBox(width: 4),
                      Switch(
                        value: _remindEnabled,
                        onChanged: (v) => setState(() => _remindEnabled = v),
                        activeThumbColor: AppColors.accent,
                        activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('优先级', style: TextStyle(fontSize: 12.5, color: subColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                _prioChip(0, '低', AppColors.prioLow),
                const SizedBox(width: 10),
                _prioChip(1, '中', AppColors.prioMid),
                const SizedBox(width: 10),
                _prioChip(2, '高', AppColors.prioHigh),
              ],
            ),
            const SizedBox(height: 16),
            if (_type == 'once')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Text('📌', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('一次性任务不按日期存在，以事情本身是否完成为准，完成后仍可取消',
                          style: TextStyle(fontSize: 11.5, color: subColor)),
                    ),
                  ],
                ),
              )
            else if (_type == 'repeat') ...[
              Text('重复规则', style: TextStyle(fontSize: 12.5, color: subColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    _dayChip(d, textColor),
                ],
              ),
              if (_repeatDays.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('至少选择一天', style: TextStyle(fontSize: 11.5, color: AppColors.prioHigh)),
                ),
            ] else
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    helpText: '选择计划日期',
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 17, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(Fmt.dayLabel(_date),
                          style: TextStyle(fontSize: 14, color: textColor)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(widget.plan == null ? '保存计划' : '保存修改',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prioChip(int p, String label, Color color) {
    final sel = _priority == p;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _priority = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.14) : Colors.transparent,
            border: Border.all(
              color: sel ? color : Colors.transparent,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayChip(int weekday, Color textColor) {
    final sel = _repeatDays.contains(weekday);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          if (sel) {
            _repeatDays.remove(weekday);
          } else {
            _repeatDays.add(weekday);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel
              ? AppColors.primary
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('一二三四五六日'[weekday - 1],
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: sel ? Colors.white : textColor,
            )),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入计划名称')));
      return;
    }
    if (_type == 'repeat' && _repeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重复计划至少选择一天')));
      return;
    }
    final isRepeat = _type == 'repeat';
    final plan = Plan(
      id: widget.plan?.id,
      name: name,
      note: _note.text.trim(),
      priority: _priority,
      timeLabel: _time.text.trim(),
      remindAt: (_type != 'once' && _remindEnabled) ? _fmtRemind(_remindTime) : null,
      isRepeat: isRepeat,
      date: isRepeat
          ? null
          : Fmt.d(_type == 'once' ? DateTime.now() : _date),
      repeatDays: isRepeat ? (_repeatDays.toList()..sort()) : const <int>[],
      type: _type,
      doneOnce: widget.plan?.doneOnce ?? false,
    );
    await Haptics.success();
    Navigator.pop(context, plan);
  }
}
