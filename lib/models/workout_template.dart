import 'dart:convert';

/// 模板中的预设动作（目标组数/次数参考）
class TemplateExercise {
  final int? exerciseId; // null = 自定义动作名
  final String name;
  int sets;
  int reps;
  double weight;

  TemplateExercise({
    this.exerciseId,
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
  });

  Map<String, Object?> toJson() => {
        'exercise_id': exerciseId,
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };

  factory TemplateExercise.fromJson(Map<String, Object?> j) =>
      TemplateExercise(
        exerciseId: j['exercise_id'] as int?,
        name: (j['name'] as String?) ?? '',
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        reps: (j['reps'] as num?)?.toInt() ?? 10,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
      );
}

/// 模板中的一个训练日
class TemplateDay {
  int day; // 第几天（1 起）
  bool rest; // 是否为休息日
  List<TemplateExercise> exercises;

  TemplateDay({
    required this.day,
    this.rest = false,
    List<TemplateExercise>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, Object?> toJson() => {
        'day': day,
        'rest': rest ? 1 : 0,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory TemplateDay.fromJson(Map<String, Object?> j) => TemplateDay(
        day: (j['day'] as num?)?.toInt() ?? 1,
        rest: ((j['rest'] as num?) ?? 0) == 1,
        exercises: ((j['exercises'] as List?) ?? [])
            .map((e) => TemplateExercise.fromJson(e as Map<String, Object?>))
            .toList(),
      );
}

/// 分化训练模板
class WorkoutTemplate {
  final int? id;
  final String name;
  int cycleDays; // 循环训练天数
  int restAfter; // 每循环后休息天数（0/1）
  List<TemplateDay> days;
  final DateTime createdAt;

  WorkoutTemplate({
    this.id,
    required this.name,
    this.cycleDays = 3,
    this.restAfter = 1,
    List<TemplateDay>? days,
    DateTime? createdAt,
  })  : days = days ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'cycle_days': cycleDays,
        'rest_after': restAfter,
        'structure': jsonEncode(days.map((d) => d.toJson()).toList()),
        'created_at': createdAt.toIso8601String(),
      };

  factory WorkoutTemplate.fromRow(Map<String, Object?> r) => WorkoutTemplate(
        id: r['id'] as int?,
        name: r['name'] as String,
        cycleDays: (r['cycle_days'] as int?) ?? 3,
        restAfter: (r['rest_after'] as int?) ?? 1,
        days: _parseDays(r['structure']),
        createdAt:
            DateTime.tryParse((r['created_at'] as String?) ?? '') ?? DateTime.now(),
      );

  static List<TemplateDay> _parseDays(Object? v) {
    if (v == null) return [];
    try {
      return (jsonDecode(v as String) as List)
          .map((e) => TemplateDay.fromJson(e as Map<String, Object?>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 某日期属于第几个训练日（以模板创建日为循环锚点）
  int? dayIndexFor(DateTime date) {
    if (days.isEmpty) return null;
    final anchor = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = date.difference(anchor).inDays;
    final cycleLen = cycleDays + restAfter;
    if (cycleLen <= 0) return 0;
    var idx = ((diff % cycleLen) + cycleLen) % cycleLen;
    if (idx >= days.length) idx = days.length - 1;
    return idx;
  }
}
