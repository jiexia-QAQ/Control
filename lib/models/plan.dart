import 'dart:convert';

/// 计划模板（单日 / 重复 / 一次性）
class Plan {
  final int? id;
  final String name;
  final String note;
  final int priority; // 0低 1中 2高
  final String timeLabel;
  final String? remindAt; // V1.4 提醒时间 "HH:mm"，null=不提醒
  final bool isRepeat;
  final String? date; // 单日计划：yyyy-MM-dd；重复计划为 null；一次性存创建日
  final List<int> repeatDays; // ISO: 1=周一 .. 7=周日
  final String type; // V1.7: 'daily' 单日 | 'repeat' 重复 | 'once' 一次性
  final bool doneOnce; // V1.7: 一次性任务完成标记

  Plan({
    this.id,
    required this.name,
    this.note = '',
    this.priority = 1,
    this.timeLabel = '',
    this.remindAt,
    this.isRepeat = false,
    this.date,
    this.repeatDays = const [],
    this.type = 'daily',
    this.doneOnce = false,
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'note': note,
        'priority': priority,
        'time_label': timeLabel,
        'remind_at': remindAt,
        'is_repeat': isRepeat ? 1 : 0,
        'date': date,
        'repeat_days': jsonEncode(repeatDays),
        'type': type,
        'done_once': doneOnce ? 1 : 0,
      };

  factory Plan.fromRow(Map<String, Object?> r) => Plan(
        id: r['id'] as int?,
        name: r['name'] as String,
        note: (r['note'] as String?) ?? '',
        priority: (r['priority'] as int?) ?? 1,
        timeLabel: (r['time_label'] as String?) ?? '',
        remindAt: r['remind_at'] as String?,
        isRepeat: ((r['is_repeat'] as int?) ?? 0) == 1,
        date: r['date'] as String?,
        repeatDays: _parseInts(r['repeat_days']),
        type: (r['type'] as String?) ?? _legacyType(r),
        doneOnce: ((r['done_once'] as int?) ?? 0) == 1,
      );

  /// 旧数据兼容：无 type 列时按 is_repeat 推导
  static String _legacyType(Map<String, Object?> r) =>
      ((r['is_repeat'] as int?) ?? 0) == 1 ? 'repeat' : 'daily';

  static List<int> _parseInts(Object? v) {
    if (v == null) return const [];
    try {
      return (jsonDecode(v as String) as List).map((e) => e as int).toList();
    } catch (_) {
      return const [];
    }
  }

  /// 某日是否激活（一次性任务不按日期激活）
  bool activeOn(DateTime day) {
    if (type == 'once') return false;
    if (isRepeat) {
      return repeatDays.contains(day.weekday);
    }
    return date != null && date == FmtStr.d(day);
  }

  Map<String, Object?> toBackup() => toRow();
  factory Plan.fromBackup(Map<String, Object?> m) => Plan.fromRow(m);
}

/// 依赖注入避免循环 import
class FmtStr {
  FmtStr._();
  static String d(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$day';
  }
}

/// 计划实例打卡状态
class PlanRecord {
  final int? id;
  final int planId;
  final String date;
  bool done;
  bool skipped;

  PlanRecord({
    this.id,
    required this.planId,
    required this.date,
    this.done = false,
    this.skipped = false,
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'plan_id': planId,
        'date': date,
        'done': done ? 1 : 0,
        'skipped': skipped ? 1 : 0,
      };

  factory PlanRecord.fromRow(Map<String, Object?> r) => PlanRecord(
        id: r['id'] as int?,
        planId: r['plan_id'] as int,
        date: r['date'] as String,
        done: ((r['done'] as int?) ?? 0) == 1,
        skipped: ((r['skipped'] as int?) ?? 0) == 1,
      );

  Map<String, Object?> toBackup() => toRow();
  factory PlanRecord.fromBackup(Map<String, Object?> m) =>
      PlanRecord.fromRow(m);
}
