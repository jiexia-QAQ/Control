import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/plan.dart';
import 'db.dart';

/// 计划提醒服务（V1.4）：本地通知，按 remind_at 调度，与系统日历/时钟联动
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// 初始化：请求权限 + 加载时区 + 恢复调度
  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);

    // Android 13+ 运行时通知权限
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _ready = true;
  }

  Future<void> refreshAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final plans = await DatabaseService.instance.allPlans();
    for (final p in plans) {
      await _schedulePlan(p);
    }
  }

  /// 为单个计划调度提醒。通知 id = planId * 10 + 槽位（单日 0，重复=星期几 1..7）
  Future<void> _schedulePlan(Plan plan) async {
    final t = _parseTime(plan.remindAt);
    if (plan.id == null || t == null) return;

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'plan_remind',
        '计划提醒',
        channelDescription: '计划到点提醒，督促打卡',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (plan.isRepeat) {
      // 重复计划：为每个选中星期几调度「每周该天 HH:mm」重复通知
      for (final wd in plan.repeatDays) {
        final now = tz.TZDateTime.now(tz.local);
        var next = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, t.$1, t.$2);
        // 对齐到下一个目标星期几（ISO: 1=周一..7=周日）
        var diff = wd - next.weekday;
        if (diff < 0) diff += 7;
        next = next.add(Duration(days: diff));
        if (next.isBefore(now)) next = next.add(const Duration(days: 7));
        await _plugin.zonedSchedule(
          plan.id! * 10 + wd,
          '该打卡了 · ${plan.name}',
          plan.note.isEmpty ? '小习惯，大改变' : plan.note,
          next,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else if (plan.date != null) {
      // 单日计划：当天提醒一次
      final d = DateTime.parse(plan.date!);
      var next = tz.TZDateTime(tz.local, d.year, d.month, d.day, t.$1, t.$2);
      if (next.isBefore(tz.TZDateTime.now(tz.local))) return; // 已过期不调度
      await _plugin.zonedSchedule(
        plan.id! * 10,
        '该打卡了 · ${plan.name}',
        plan.note.isEmpty ? '小习惯，大改变' : plan.note,
        next,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// 解析 "HH:mm" → (hour, minute)；非法返回 null
  (int, int)? _parseTime(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (h, m);
  }
}
