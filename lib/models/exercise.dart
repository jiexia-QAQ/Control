import 'dart:convert';

/// 训练动作库条目
class ExerciseItem {
  final int? id;
  final String name;
  final String part; // 胸/背/肩/腿/二头/三头/腹/全身
  final String part2; // 次要部位
  final String equipment; // 杠铃/哑铃/绳索/器械/自重/壶铃/其他
  final String desc;
  final String pinyin;
  final bool isCustom; // 用户自定义动作（V1.3）

  ExerciseItem({
    this.id,
    required this.name,
    required this.part,
    this.part2 = '',
    this.equipment = '',
    this.desc = '',
    this.pinyin = '',
    this.isCustom = false,
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'part': part,
        'part2': part2,
        'equipment': equipment,
        'desc': desc,
        'pinyin': pinyin,
        'is_custom': isCustom ? 1 : 0,
      };

  factory ExerciseItem.fromRow(Map<String, Object?> r) => ExerciseItem(
        id: r['id'] as int?,
        name: r['name'] as String,
        part: r['part'] as String,
        part2: (r['part2'] as String?) ?? '',
        equipment: (r['equipment'] as String?) ?? '',
        desc: (r['desc'] as String?) ?? '',
        pinyin: (r['pinyin'] as String?) ?? '',
        isCustom: ((r['is_custom'] as num?) ?? 0) == 1,
      );
}

/// 一组训练数据
class WorkoutSet {
  int no;
  int reps;
  double weight; // kg
  String note;

  WorkoutSet({required this.no, this.reps = 10, this.weight = 0, this.note = ''});

  Map<String, Object?> toJson() => {
        'no': no,
        'reps': reps,
        'weight': weight,
        'note': note,
      };

  factory WorkoutSet.fromJson(Map<String, Object?> j) => WorkoutSet(
        no: (j['no'] as num?)?.toInt() ?? 1,
        reps: (j['reps'] as num?)?.toInt() ?? 10,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        note: (j['note'] as String?) ?? '',
      );
}

/// 某日某动作的训练日志
class WorkoutLog {
  final int? id;
  final String date;
  final int? templateId;
  final int? exerciseId;
  final String exerciseName;
  final String part;
  final String equipment;
  List<WorkoutSet> sets;
  String note;
  int sortOrder;

  WorkoutLog({
    this.id,
    required this.date,
    this.templateId,
    this.exerciseId,
    required this.exerciseName,
    this.part = '',
    this.equipment = '',
    List<WorkoutSet>? sets,
    this.note = '',
    this.sortOrder = 0,
  }) : sets = sets ?? [];

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'date': date,
        'template_id': templateId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'part': part,
        'equipment': equipment,
        'sets_json': jsonEncode(sets.map((s) => s.toJson()).toList()),
        'note': note,
        'sort_order': sortOrder,
      };

  factory WorkoutLog.fromRow(Map<String, Object?> r) => WorkoutLog(
        id: r['id'] as int?,
        date: r['date'] as String,
        templateId: r['template_id'] as int?,
        exerciseId: r['exercise_id'] as int?,
        exerciseName: r['exercise_name'] as String,
        part: (r['part'] as String?) ?? '',
        equipment: (r['equipment'] as String?) ?? '',
        sets: _parseSets(r['sets_json']),
        note: (r['note'] as String?) ?? '',
        sortOrder: (r['sort_order'] as int?) ?? 0,
      );

  static List<WorkoutSet> _parseSets(Object? v) {
    if (v == null) return [];
    try {
      return (jsonDecode(v as String) as List)
          .map((e) => WorkoutSet.fromJson(e as Map<String, Object?>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
