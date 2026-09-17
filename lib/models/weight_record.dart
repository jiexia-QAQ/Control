/// 体重记录
class WeightRecord {
  final int? id;
  final String date;
  final double weight;

  WeightRecord({this.id, required this.date, required this.weight});

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'date': date,
        'weight': weight,
      };

  factory WeightRecord.fromRow(Map<String, Object?> r) => WeightRecord(
        id: r['id'] as int?,
        date: r['date'] as String,
        weight: (r['weight'] as num).toDouble(),
      );
}

/// 目标设置
class Goals {
  double kcal;
  double protein;
  double carb;
  double fat;
  int weeklyWorkoutDays;

  Goals({
    this.kcal = 1800,
    this.protein = 90,
    this.carb = 220,
    this.fat = 60,
    this.weeklyWorkoutDays = 3,
  });

  Map<String, Object?> toMap() => {
        'kcal': kcal,
        'protein': protein,
        'carb': carb,
        'fat': fat,
        'weekly_workout_days': weeklyWorkoutDays,
      };

  factory Goals.fromMap(Map<String, Object?> m) => Goals(
        kcal: (m['kcal'] as num?)?.toDouble() ?? 1800,
        protein: (m['protein'] as num?)?.toDouble() ?? 90,
        carb: (m['carb'] as num?)?.toDouble() ?? 220,
        fat: (m['fat'] as num?)?.toDouble() ?? 60,
        weeklyWorkoutDays: (m['weekly_workout_days'] as num?)?.toInt() ?? 3,
      );
}
