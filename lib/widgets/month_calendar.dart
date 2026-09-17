import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';

/// 月历（计划模块月历视图），左右滑动切换月份
class MonthCalendar extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final Map<String, Color>? dots;

  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.dots,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late int _page;
  late PageController _controller;
  static final _epoch = DateTime(2024, 1);

  int _monthIndex(DateTime d) =>
      (d.year - _epoch.year) * 12 + (d.month - _epoch.month);
  DateTime _monthStart(int idx) => DateTime(_epoch.year + idx ~/ 12, idx % 12 + 1, 1);

  @override
  void initState() {
    super.initState();
    _page = _monthIndex(widget.selected);
    _controller = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(MonthCalendar old) {
    super.didUpdateWidget(old);
    final idx = _monthIndex(widget.selected);
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
    final month = _monthStart(_page);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Fmt.monthLabel(month),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? const Color(0xFFE9EBEF)
                        : const Color(0xFF3C434E))),
            Row(children: [
              _arrow(Icons.chevron_left, -1),
              _arrow(Icons.chevron_right, 1),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text('日一二三四五六'[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: subColor)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) {
              _page = i;
              setState(() {});
            },
            itemBuilder: (context, idx) {
              final m = _monthStart(idx);
              return _buildMonth(m);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonth(DateTime m) {
    final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
    final firstWd = DateTime(m.year, m.month, 1).weekday % 7; // 周日=0
    final cells = <Widget>[];
    for (var i = 0; i < firstWd; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_dayCell(DateTime(m.year, m.month, d)));
    }
    return GridView.count(
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.92,
      children: cells,
    );
  }

  Widget _arrow(IconData icon, int delta) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _controller.animateToPage(_page + delta,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic);
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
    final dotColor = widget.dots?[Fmt.d(day)];

    return InkWell(
      onTap: () => widget.onSelect(day),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
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
                fontSize: 13.5,
                fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSel
                    ? Colors.white
                    : isToday
                        ? AppColors.primary
                        : subColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
