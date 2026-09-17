/// 内置/自定义食物（营养值为每 100g）
class FoodItem {
  final int? id;
  final String name;
  final String category;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final String pinyin;
  final bool isCustom;
  final String imagePath; // V1.8 自定义食物照片（本机路径，空=无）

  FoodItem({
    this.id,
    required this.name,
    this.category = '',
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    this.pinyin = '',
    this.isCustom = false,
    this.imagePath = '',
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'kcal': kcal,
        'protein': protein,
        'carb': carb,
        'fat': fat,
        'pinyin': pinyin,
        'is_custom': isCustom ? 1 : 0,
        if (imagePath.isNotEmpty) 'image_path': imagePath,
      };

  factory FoodItem.fromRow(Map<String, Object?> r) => FoodItem(
        id: r['id'] as int?,
        name: r['name'] as String,
        category: (r['category'] as String?) ?? '',
        kcal: (r['kcal'] as num?)?.toDouble() ?? 0,
        protein: (r['protein'] as num?)?.toDouble() ?? 0,
        carb: (r['carb'] as num?)?.toDouble() ?? 0,
        fat: (r['fat'] as num?)?.toDouble() ?? 0,
        pinyin: (r['pinyin'] as String?) ?? '',
        isCustom: ((r['is_custom'] as int?) ?? 0) == 1,
        imagePath: (r['image_path'] as String?) ?? '',
      );
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => '早餐',
        MealType.lunch => '午餐',
        MealType.dinner => '晚餐',
        MealType.snack => '加餐',
      };
}

/// 一餐中的一条食物记录
class MealEntry {
  final int? id;
  final String date;
  final MealType mealType;
  final int? foodId;
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final DateTime createdAt;

  MealEntry({
    this.id,
    required this.date,
    required this.mealType,
    this.foodId,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'date': date,
        'meal_type': mealType.index,
        'food_id': foodId,
        'name': name,
        'grams': grams,
        'kcal': kcal,
        'protein': protein,
        'carb': carb,
        'fat': fat,
        'created_at': createdAt.toIso8601String(),
      };

  factory MealEntry.fromRow(Map<String, Object?> r) => MealEntry(
        id: r['id'] as int?,
        date: r['date'] as String,
        mealType: MealType.values[(r['meal_type'] as int?) ?? 0],
        foodId: r['food_id'] as int?,
        name: r['name'] as String,
        grams: (r['grams'] as num?)?.toDouble() ?? 0,
        kcal: (r['kcal'] as num?)?.toDouble() ?? 0,
        protein: (r['protein'] as num?)?.toDouble() ?? 0,
        carb: (r['carb'] as num?)?.toDouble() ?? 0,
        fat: (r['fat'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '') ??
            DateTime.now(),
      );
}

class MealTotals {
  final double kcal, protein, carb, fat;
  MealTotals(this.kcal, this.protein, this.carb, this.fat);
  MealTotals.zero() : this(0, 0, 0, 0);
  MealTotals operator +(MealTotals o) =>
      MealTotals(kcal + o.kcal, protein + o.protein, carb + o.carb, fat + o.fat);
  MealTotals operator -(MealTotals o) =>
      MealTotals(kcal - o.kcal, protein - o.protein, carb - o.carb, fat - o.fat);
  static MealTotals sum(List<MealEntry> es) {
    var t = MealTotals.zero();
    for (final e in es) {
      t = t +
          MealTotals(e.kcal, e.protein, e.carb, e.fat);
    }
    return t;
  }
}
