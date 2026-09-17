import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';

/// 共享周历组件（计划/锻炼模块共用）
/// - 左右滑动切换周
/// - 今天：主色圆形背景强调
/// - 可选：完成度圆点 / 哑铃训练标记 / 休息日置灰
class WeekCalendar extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final Map<String, Color>? dots; // date -> 圆点颜色
  final Set<String>? dumbbells; // 有训练记录的日期
  final Set<String>? restDays; // 休息日
  final bool showRest;

  const WeekCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.dots,
    this.dumbbells,
    this.restDays,
    this.showRest = false,
  });

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  static final _epoch = DateTime(2020, 1, 6); // 周一
  late int _page;
  late PageController _controller;

  int _weekIndex(DateTime d) {
    final diff = DateTime(d.year, d.month, d.day).difference(_epoch).inDays;
    return (diff / 7).floor();
  }

  DateTime _weekStart(int idx) => Fmt.addDays(_epoch, idx * 7);

  @override
  void initState() {
    super.initState();
    _page = _weekIndex(widget.selected);
    _controller = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(WeekCalendar old) {
    super.didUpdateWidget(old);
    final idx = _weekIndex(widget.selected);
    if (idx != _page && _controller.hasClients) {
      _page = idx;
      _controller.animateToPage(idx,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Fmt.weekLabel(_weekStart(_page)),
                style: TextStyle(fontSize: 13, color: subColor)),
            Row(children: [
              _arrow(Icons.chevron_left, -1),
              _arrow(Icons.chevron_right, 1),
            ]),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text('${'一二三四五六日'[i]}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: subColor,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 74,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) {
              _page = i;
              setState(() {});
            },
            itemBuilder: (context, idx) {
              final start = _weekStart(idx);
              return Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(child: _dayCell(Fmt.addDays(start, d))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, int delta) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _controller.animateToPage(
          _page + delta,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 17, color: subColor),
      ),
    );
  }

  Widget _dayCell(DateTime day) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final isSel = day.year == widget.selected.year &&
        day.month == widget.selected.month &&
        day.day == widget.selected.day;
    final isToday = day.year == Fmt.today().year &&
        day.month == Fmt.today().month &&
        day.day == Fmt.today().day;
    final isRest = widget.showRest && (widget.restDays?.contains(Fmt.d(day)) ?? false);

    final dotColor = widget.dots?[Fmt.d(day)];
    final hasDumbbell = widget.dumbbells?.contains(Fmt.d(day)) ?? false;

    return InkWell(
      onTap: () => widget.onSelect(day),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primary
                  : isToday
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSel
                    ? Colors.white
                    : isRest
                        ? subColor.withValues(alpha: 0.45)
                        : isToday
                            ? AppColors.primary
                            : subColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dotColor != null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (hasDumbbell)
                  Icon(Icons.fitness_center,
                      size: 11, color: AppColors.primary)
                else if (isRest)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: subColor.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Container(width: 6, height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
