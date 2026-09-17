/// 日期与数值工具（不引入 intl，保持体积）
class Fmt {
  Fmt._();

  /// yyyy-MM-dd
  static String d(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$day';
  }

  static DateTime parse(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime addDays(DateTime dt, int days) =>
      DateTime(dt.year, dt.month, dt.day + days);

  /// 周一为一周起点
  static DateTime startOfWeek(DateTime dt) {
    final wd = dt.weekday; // Mon=1..Sun=7
    return addDays(dt, 1 - wd);
  }

  static List<DateTime> weekDays(DateTime dt) {
    final s = startOfWeek(dt);
    return List.generate(7, (i) => addDays(s, i));
  }

  static String monthLabel(DateTime dt) =>
      '${dt.year}年${dt.month}月';

  static String weekLabel(DateTime dt) {
    final s = startOfWeek(dt);
    final e = addDays(s, 6);
    return '${s.month}/${s.day} - ${e.month}/${e.day}';
  }

  static String dayLabel(DateTime dt) =>
      '${dt.month}月${dt.day}日 ${cnWeekday(dt)}';

  static const _weekCn = ['一', '二', '三', '四', '五', '六', '日'];
  static String cnWeekday(DateTime dt) => '周${_weekCn[dt.weekday - 1]}';

  /// 去掉多余小数位
  static String num(double v, {int digits = 1}) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(digits);
  }

  /// 卡路里取整显示
  static String kcal(double v) => v.round().toString();

  static String weight(double v) => v.toStringAsFixed(1);
}
