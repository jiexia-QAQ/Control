import 'dart:convert';

import 'package:lpinyin/lpinyin.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/utils.dart';
import '../data/exercise_data.dart';
import '../data/food_data.dart';
import '../data/template_seeds.dart';
import '../models/exercise.dart';
import '../models/food.dart';
import '../models/plan.dart';
import '../models/weight_record.dart';
import '../models/workout_template.dart';
import '../models/accounting.dart';

/// 数据库版本：升级时递增并在 onUpgrade 中写迁移
const int dbVersion = 9;

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'control.db');
    return openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        note TEXT DEFAULT '',
        priority INTEGER DEFAULT 1,
        time_label TEXT DEFAULT '',
        remind_at TEXT,
        is_repeat INTEGER DEFAULT 0,
        date TEXT,
        repeat_days TEXT DEFAULT '[]',
        type TEXT DEFAULT 'daily',
        done_once INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )''');
    await db.execute('''
      CREATE TABLE plan_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        skipped INTEGER DEFAULT 0,
        UNIQUE(plan_id, date)
      )''');
    await db.execute('''
      CREATE TABLE food_library(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT DEFAULT '',
        kcal REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        carb REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        pinyin TEXT DEFAULT '',
        is_custom INTEGER DEFAULT 0,
        image_path TEXT DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE meal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal_type INTEGER NOT NULL,
        food_id INTEGER,
        name TEXT NOT NULL,
        grams REAL NOT NULL,
        kcal REAL NOT NULL,
        protein REAL NOT NULL,
        carb REAL NOT NULL,
        fat REAL NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      )''');
    await db.execute('''
      CREATE TABLE food_usage(
        food_id INTEGER PRIMARY KEY,
        count INTEGER DEFAULT 0,
        last_used TEXT DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE exercises_library(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        part TEXT NOT NULL,
        part2 TEXT DEFAULT '',
        equipment TEXT DEFAULT '',
        desc TEXT DEFAULT '',
        pinyin TEXT DEFAULT '',
        is_custom INTEGER DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE workout_templates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cycle_days INTEGER DEFAULT 3,
        rest_after INTEGER DEFAULT 1,
        structure TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE workout_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        template_id INTEGER,
        exercise_id INTEGER,
        exercise_name TEXT NOT NULL,
        part TEXT DEFAULT '',
        equipment TEXT DEFAULT '',
        sets_json TEXT DEFAULT '[]',
        note TEXT DEFAULT '',
        sort_order INTEGER DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE rest_days(
        date TEXT PRIMARY KEY
      )''');
    await db.execute('''
      CREATE TABLE weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight REAL NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )''');

    // V1.6 记账三表
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT DEFAULT '其他',
        note TEXT DEFAULT '',
        account TEXT DEFAULT '其他',
        source TEXT DEFAULT 'manual',
        created_at TEXT DEFAULT (datetime('now'))
      )''');
    await db.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT DEFAULT '其他',
        note TEXT DEFAULT '',
        account TEXT DEFAULT '其他',
        source TEXT DEFAULT 'manual',
        created_at TEXT DEFAULT (datetime('now'))
      )''');
    await db.execute('''
      CREATE TABLE credit_bills(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT DEFAULT '其他',
        amount REAL NOT NULL,
        remaining REAL NOT NULL,
        due_date TEXT NOT NULL,
        note TEXT DEFAULT '',
        paid INTEGER DEFAULT 0,
        source TEXT DEFAULT 'manual',
        created_at TEXT DEFAULT (datetime('now'))
      )''');

    // V1.6 愿望清单
    await db.execute('''
      CREATE TABLE wishlist(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL DEFAULT 0,
        category TEXT DEFAULT '其他',
        priority INTEGER DEFAULT 1,
        note TEXT DEFAULT '',
        achieved INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )''');

    // V1.7 阶段目标
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT DEFAULT 'weight',
        target REAL NOT NULL,
        start REAL NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      )''');


    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // v1 → v2（V1.3）：exercises_library 增加 is_custom 列（用户自定义动作）
    if (oldV < 2) {
      await db.execute(
          'ALTER TABLE exercises_library ADD COLUMN is_custom INTEGER DEFAULT 0');
    }
    // v2 → v3（V1.4）：plans 增加 remind_at 列（计划提醒时间）
    if (oldV < 3) {
      await db.execute('ALTER TABLE plans ADD COLUMN remind_at TEXT');
    }
    // v3 → v4（V1.6）：新增记账三表（支出/收入/借贷账单）
    if (oldV < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT DEFAULT '其他',
          note TEXT DEFAULT '',
          account TEXT DEFAULT '其他',
          source TEXT DEFAULT 'manual',
          created_at TEXT DEFAULT (datetime('now'))
        )''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS incomes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT DEFAULT '其他',
          note TEXT DEFAULT '',
          account TEXT DEFAULT '其他',
          source TEXT DEFAULT 'manual',
          created_at TEXT DEFAULT (datetime('now'))
        )''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS credit_bills(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          provider TEXT DEFAULT '其他',
          amount REAL NOT NULL,
          remaining REAL NOT NULL,
          due_date TEXT NOT NULL,
          note TEXT DEFAULT '',
          paid INTEGER DEFAULT 0,
          source TEXT DEFAULT 'manual',
          created_at TEXT DEFAULT (datetime('now'))
        )''');
    }
    // v4 → v5（V1.6 微调）：wishlist 愿望清单
    if (oldV < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wishlist(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL DEFAULT 0,
          category TEXT DEFAULT '其他',
          priority INTEGER DEFAULT 1,
          note TEXT DEFAULT '',
          achieved INTEGER DEFAULT 0,
          created_at TEXT DEFAULT (datetime('now'))
        )''');
    }
    // v5 → v6（V1.7）：plans 加 type/done_once（一次性任务）+ goals 阶段目标
    if (oldV < 6) {
      await db.execute('ALTER TABLE plans ADD COLUMN type TEXT DEFAULT \'daily\'');
      await db.execute('ALTER TABLE plans ADD COLUMN done_once INTEGER DEFAULT 0');
      await db.execute('UPDATE plans SET type = \'repeat\' WHERE is_repeat = 1');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT DEFAULT 'weight',
          target REAL NOT NULL,
          start REAL NOT NULL,
          created_at TEXT DEFAULT (datetime('now'))
        )''');
    }
    // v6 → v7（V1.7.3）：食物库扩充补种（跳过已存在）
    if (oldV < 7) {
      await _seedFoods(db, checkExists: true);
    }
    // v7 → v8（V1.7.4）：食物库扩至 600 种补种
    if (oldV < 8) {
      await _seedFoods(db, checkExists: true);
    }
    // v8 → v9（V1.8）：food_library 加 image_path（自定义食物照片）
    if (oldV < 9) {
      await db.execute(
          "ALTER TABLE food_library ADD COLUMN image_path TEXT DEFAULT ''");
    }
  }

  /// V1.7.3 食物库种子（checkExists=true 时跳过已存在，用于升级补种）
  Future<void> _seedFoods(Database db, {bool checkExists = false}) async {
    for (final f in foodSeedData) {
      if (checkExists) {
        final rows = await db.query('food_library',
            where: 'name = ?', whereArgs: [f[0]], limit: 1);
        if (rows.isNotEmpty) continue;
      }
      await db.insert('food_library', {
        'name': f[0],
        'category': f[1],
        'kcal': f[2],
        'protein': f[3],
        'carb': f[4],
        'fat': f[5],
        'pinyin': PinyinHelper.getShortPinyin(f[0] as String),
        'is_custom': 0,
      });
    }
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    // 食物库（V1.7.3 起走 _seedFoods，兼容补种）
    await _seedFoods(db);

    // 动作库
    for (final e in exerciseSeedData) {
      batch.insert('exercises_library', {
        'name': e[0],
        'part': e[1],
        'part2': e[2],
        'equipment': e[3],
        'desc': e[4],
        'pinyin': PinyinHelper.getShortPinyin(e[0]),
      });
    }
    // 内置训练模板
    for (final t in templateSeeds()) {
      batch.insert('workout_templates', t.toRow()..remove('id'));
    }
    // 默认设置
    batch.insert('settings', {
      'key': 'goals',
      'value': jsonEncode(Goals().toMap()),
    });
    batch.insert('settings', {'key': 'theme_mode', 'value': 'system'});
    batch.insert('settings', {'key': 'haptics', 'value': '1'});

    await batch.commit(noResult: true);
  }

  // ================= 计划 =================

  Future<int> insertPlan(Plan plan) async {
    final db = await database;
    return db.insert('plans', plan.toRow()..remove('id'));
  }

  Future<void> updatePlan(Plan plan) async {
    final db = await database;
    await db.update('plans', plan.toRow(), where: 'id = ?', whereArgs: [plan.id]);
  }

  Future<void> deletePlan(int id) async {
    final db = await database;
    await db.delete('plan_records', where: 'plan_id = ?', whereArgs: [id]);
    await db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Plan>> getPlanById(int id) async {
    final db = await database;
    final rows = await db.query('plans', where: 'id = ?', whereArgs: [id]);
    return rows.map(Plan.fromRow).toList();
  }

  /// 某日激活的计划（单日 + 重复）
  Future<List<Plan>> plansForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query('plans');
    final all = rows.map(Plan.fromRow).toList();
    return all.where((pl) => pl.activeOn(date)).toList()
      ..sort((a, b) {
        if (a.isRepeat != b.isRepeat) return a.isRepeat ? 1 : -1;
        return b.priority.compareTo(a.priority); // V1.7.3 高优先级在前
      });
  }

  Future<List<Plan>> allPlans() async {
    final db = await database;
    final rows = await db.query('plans', orderBy: 'created_at DESC');
    return rows.map(Plan.fromRow).toList();
  }

  // ================= 打卡记录 =================

  Future<Map<String, PlanRecord>> recordsForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query('plan_records', where: 'date = ?', whereArgs: [Fmt.d(date)]);
    return {for (final r in rows) (r['plan_id'] as int).toString(): PlanRecord.fromRow(r)};
  }

  Future<void> setPlanDone(int planId, DateTime date, bool done) async {
    final db = await database;
    final ds = Fmt.d(date);
    final existing = await db.query('plan_records',
        where: 'plan_id = ? AND date = ?', whereArgs: [planId, ds]);
    if (existing.isEmpty) {
      await db.insert('plan_records', {
        'plan_id': planId,
        'date': ds,
        'done': done ? 1 : 0,
        'skipped': 0,
      });
    } else {
      await db.update('plan_records', {'done': done ? 1 : 0, 'skipped': 0},
          where: 'plan_id = ? AND date = ?', whereArgs: [planId, ds]);
    }
  }

  Future<void> setPlanSkipped(int planId, DateTime date, bool skipped) async {
    final db = await database;
    final ds = Fmt.d(date);
    final existing = await db.query('plan_records',
        where: 'plan_id = ? AND date = ?', whereArgs: [planId, ds]);
    if (existing.isEmpty) {
      await db.insert('plan_records', {
        'plan_id': planId,
        'date': ds,
        'done': 0,
        'skipped': skipped ? 1 : 0,
      });
    } else {
      await db.update('plan_records',
          {'done': 0, 'skipped': skipped ? 1 : 0},
          where: 'plan_id = ? AND date = ?', whereArgs: [planId, ds]);
    }
  }

  /// 某日完成度统计：返回 (总数, 已完成) —— 已跳过的计划不计入
  Future<(int, int)> dayPlanProgress(DateTime date) async {
    final plans = await plansForDate(date);
    final recs = await recordsForDate(date);
    var total = 0, done = 0;
    for (final pl in plans) {
      final rec = recs[pl.id.toString()];
      if (rec?.skipped ?? false) continue;
      total++;
      if (rec?.done ?? false) done++;
    }
    return (total, done);
  }

  /// 一段日期内每日完成度：map date -> (total, done)
  Future<Map<String, (int, int)>> rangePlanProgress(DateTime start, DateTime end) async {
    final db = await database;
    final s = Fmt.d(start), e = Fmt.d(end);
    final plans = await db.query('plans');
    final all = plans.map(Plan.fromRow).toList();
    final recRows = await db.query('plan_records',
        where: 'date BETWEEN ? AND ?', whereArgs: [s, e]);
    final recMap = <String, List<PlanRecord>>{};
    for (final r in recRows) {
      final rec = PlanRecord.fromRow(r);
      recMap.putIfAbsent(rec.date, () => []).add(rec);
    }
    final out = <String, (int, int)>{};
    var day = start;
    while (!day.isAfter(end)) {
      final ds = Fmt.d(day);
      var total = 0, done = 0;
      for (final pl in all) {
        if (!pl.activeOn(day)) continue;
        final recs = recMap[ds] ?? [];
        PlanRecord? rec;
        for (final r in recs) {
          if (r.planId == pl.id) {
            rec = r;
            break;
          }
        }
        if (rec?.skipped ?? false) continue;
        total++;
        if (rec?.done ?? false) done++;
      }
      out[ds] = (total, done);
      day = Fmt.addDays(day, 1);
    }
    return out;
  }

  /// 连续打卡天数（含今天；今天未打卡则从昨天起算）
  Future<int> getStreak() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT date FROM plan_records WHERE done = 1 ORDER BY date DESC');
    final dates = rows.map((r) => Fmt.parse(r['date'] as String)).toSet();
    if (dates.isEmpty) return 0;
    var cur = Fmt.today();
    if (!dates.contains(cur)) cur = Fmt.addDays(cur, -1);
    var streak = 0;
    while (dates.contains(cur)) {
      streak++;
      cur = Fmt.addDays(cur, -1);
    }
    return streak;
  }

  // ================= 食物库 =================

  Future<List<FoodItem>> searchFoods(String query, {String? category}) async {
    final db = await database;
    if (query.trim().isEmpty) {
      final rows = category == null
          ? await db.query('food_library', orderBy: 'category, name', limit: 60)
          : await db.query('food_library',
              where: 'category = ?', whereArgs: [category], orderBy: 'name');
      return rows.map(FoodItem.fromRow).toList();
    }
    final q = '%${query.trim()}%';
    final cond = StringBuffer('(name LIKE ? OR pinyin LIKE ? OR category LIKE ?)');
    final args = <Object?>[q, q, q];
    if (category != null) {
      cond.write(' AND category = ?');
      args.add(category);
    }
    final rows = await db.query('food_library',
        where: cond.toString(), whereArgs: args, orderBy: 'category, name', limit: 60);
    return rows.map(FoodItem.fromRow).toList();
  }

  Future<List<String>> foodCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM food_library WHERE category != "" ORDER BY category');
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<int> insertCustomFood(FoodItem food) async {
    final db = await database;
    return db.insert('food_library', food.toRow()..remove('id'));
  }

  /// 高频食物（最近/收藏）
  Future<List<FoodItem>> recentFoods({int limit = 12}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT f.* FROM food_library f
      JOIN food_usage u ON u.food_id = f.id
      ORDER BY u.count DESC, u.last_used DESC
      LIMIT $limit
    ''');
    return rows.map(FoodItem.fromRow).toList();
  }

  Future<void> bumpFoodUsage(int foodId) async {
    final db = await database;
    final now = Fmt.today().toIso8601String();
    final rows = await db.query('food_usage', where: 'food_id = ?', whereArgs: [foodId]);
    if (rows.isEmpty) {
      await db.insert('food_usage', {'food_id': foodId, 'count': 1, 'last_used': now});
    } else {
      await db.update('food_usage', {
        'count': ((rows.first['count'] as int?) ?? 0) + 1,
        'last_used': now,
      }, where: 'food_id = ?', whereArgs: [foodId]);
    }
  }

  // ================= 饮食记录 =================

  Future<int> insertMeal(MealEntry entry) async {
    final db = await database;
    return db.insert('meal_entries', entry.toRow()..remove('id'));
  }

  Future<void> updateMeal(MealEntry entry) async {
    final db = await database;
    await db.update('meal_entries', entry.toRow(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteMeal(int id) async {
    final db = await database;
    await db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealEntry>> mealsForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query('meal_entries',
        where: 'date = ?', whereArgs: [Fmt.d(date)], orderBy: 'meal_type, created_at DESC');
    return rows.map(MealEntry.fromRow).toList();
  }

  Future<MealTotals> totalsForDate(DateTime date) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT SUM(kcal) k, SUM(protein) p, SUM(carb) c, SUM(fat) f FROM meal_entries WHERE date = ?',
        [Fmt.d(date)]);
    final r = rows.first;
    return MealTotals(
      (r['k'] as num?)?.toDouble() ?? 0,
      (r['p'] as num?)?.toDouble() ?? 0,
      (r['c'] as num?)?.toDouble() ?? 0,
      (r['f'] as num?)?.toDouble() ?? 0,
    );
  }

  /// 本周饮食达标率（热量在目标 ±30% 内计达标）
  Future<double> dietComplianceThisWeek(Goals goals) async {
    final db = await database;
    final s = Fmt.startOfWeek(Fmt.today());
    final rows = await db.rawQuery(
        'SELECT date, SUM(kcal) k FROM meal_entries WHERE date >= ? GROUP BY date',
        [Fmt.d(s)]);
    var compliant = 0, days = 0;
    for (var i = 0; i < 7; i++) {
      final ds = Fmt.d(Fmt.addDays(s, i));
      Map<String, Object?>? row;
      for (final r in rows) {
        if (r['date'] == ds) {
          row = r;
          break;
        }
      }
      if (row == null || (row['k'] as num?) == null) continue;
      days++;
      final k = (row['k'] as num).toDouble();
      if (k >= goals.kcal * 0.7 && k <= goals.kcal * 1.3) compliant++;
    }
    return days == 0 ? 0 : compliant / days;
  }

  // ================= 动作库 =================

  Future<List<ExerciseItem>> allExercises() async {
    final db = await database;
    final rows = await db.query('exercises_library',
        orderBy: 'is_custom DESC, part, name');
    return rows.map(ExerciseItem.fromRow).toList();
  }

  Future<List<ExerciseItem>> searchExercises(String query, {String? part}) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final cond = StringBuffer('(name LIKE ? OR pinyin LIKE ? OR equipment LIKE ?)');
    final args = <Object?>[q, q, q];
    if (part != null) {
      cond.write(' AND (part = ? OR part2 = ?)');
      args.add(part);
      args.add(part);
    }
    final rows = await db.query('exercises_library',
        where: cond.toString(),
        whereArgs: args,
        orderBy: 'is_custom DESC, part, name',
        limit: 80);
    return rows.map(ExerciseItem.fromRow).toList();
  }

  Future<List<ExerciseItem>> exercisesByPart(String part) async {
    final db = await database;
    final rows = await db.query('exercises_library',
        where: 'part = ?', whereArgs: [part], orderBy: 'is_custom DESC, name');
    return rows.map(ExerciseItem.fromRow).toList();
  }

  // ===== V1.3 自定义动作 =====

  /// 新建自定义动作，返回新 id
  Future<int> insertCustomExercise(ExerciseItem e) async {
    final db = await database;
    return db.insert('exercises_library', e.toRow()..remove('id'));
  }

  /// 更新自定义动作
  Future<void> updateCustomExercise(ExerciseItem e) async {
    final db = await database;
    await db.update('exercises_library', e.toRow(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  /// 删除自定义动作（同时清理引用它的训练日志动作名以保持记录可读）
  Future<void> deleteCustomExercise(int id) async {
    final db = await database;
    await db.delete('exercises_library', where: 'id = ?', whereArgs: [id]);
  }

  // ================= 训练模板 =================

  // ===== V1.5 实时洞察数据源 =====

  /// 最近一次训练日期（无记录返回 null）
  Future<DateTime?> lastWorkoutDate() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT MAX(date) d FROM workout_logs');
    final d = rows.first['d'] as String?;
    return d == null ? null : Fmt.parse(d);
  }

  /// 近 7 天（含今天）有记录日的平均蛋白质摄入（无记录返回 0）
  Future<double> avgProteinThisWeek() async {
    final db = await database;
    final s = Fmt.addDays(Fmt.today(), -6);
    final rows = await db.rawQuery(
        'SELECT date, AVG(protein) p FROM meal_entries WHERE date >= ? GROUP BY date',
        [Fmt.d(s)]);
    if (rows.isEmpty) return 0;
    var sum = 0.0;
    for (final r in rows) {
      sum += (r['p'] as num?)?.toDouble() ?? 0;
    }
    return sum / rows.length;
  }

  Future<List<WorkoutTemplate>> allTemplates() async {
    final db = await database;
    final rows = await db.query('workout_templates', orderBy: 'created_at');
    return rows.map(WorkoutTemplate.fromRow).toList();
  }

  Future<int> insertTemplate(WorkoutTemplate t) async {
    final db = await database;
    return db.insert('workout_templates', t.toRow()..remove('id'));
  }

  Future<void> updateTemplate(WorkoutTemplate t) async {
    final db = await database;
    await db.update('workout_templates', t.toRow(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTemplate(int id) async {
    final db = await database;
    await db.delete('workout_templates', where: 'id = ?', whereArgs: [id]);
  }

  // ================= 训练日志 =================

  Future<List<WorkoutLog>> logsForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query('workout_logs',
        where: 'date = ?', whereArgs: [Fmt.d(date)], orderBy: 'sort_order');
    return rows.map(WorkoutLog.fromRow).toList();
  }

  Future<int> insertLog(WorkoutLog log) async {
    final db = await database;
    return db.insert('workout_logs', log.toRow()..remove('id'));
  }

  Future<void> updateLog(WorkoutLog log) async {
    final db = await database;
    await db.update('workout_logs', log.toRow(),
        where: 'id = ?', whereArgs: [log.id]);
  }

  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// 某日期是否已有训练记录
  Future<bool> hasWorkout(DateTime date) async {
    final db = await database;
    final rows = await db.query('workout_logs',
        where: 'date = ?', whereArgs: [Fmt.d(date)], limit: 1);
    return rows.isNotEmpty;
  }

  /// 一段时间内的训练日期集合
  Future<Set<String>> workoutDatesInRange(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT date FROM workout_logs WHERE date BETWEEN ? AND ?',
        [Fmt.d(start), Fmt.d(end)]);
    return rows.map((r) => r['date'] as String).toSet();
  }

  /// 本周训练次数
  Future<int> workoutCountThisWeek() async {
    final db = await database;
    final s = Fmt.startOfWeek(Fmt.today());
    final rows = await db.rawQuery(
        'SELECT COUNT(DISTINCT date) c FROM workout_logs WHERE date >= ?', [Fmt.d(s)]);
    return (rows.first['c'] as int?) ?? 0;
  }

  // ================= 休息日 =================

  Future<bool> isRestDay(DateTime date) async {
    final db = await database;
    final rows = await db.query('rest_days',
        where: 'date = ?', whereArgs: [Fmt.d(date)], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> setRestDay(DateTime date, bool rest) async {
    final db = await database;
    final ds = Fmt.d(date);
    if (rest) {
      await db.insert('rest_days', {'date': ds},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('rest_days', where: 'date = ?', whereArgs: [ds]);
    }
  }

  Future<Set<String>> restDaysInRange(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query('rest_days',
        where: 'date BETWEEN ? AND ?', whereArgs: [Fmt.d(start), Fmt.d(end)]);
    return rows.map((r) => r['date'] as String).toSet();
  }

  // ================= 体重 =================

  Future<int> insertWeight(WeightRecord w) async {
    final db = await database;
    return db.insert('weight_records', w.toRow()..remove('id'));
  }

  Future<void> updateWeight(WeightRecord w) async {
    final db = await database;
    await db.update('weight_records', w.toRow(),
        where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteWeight(int id) async {
    final db = await database;
    await db.delete('weight_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WeightRecord>> allWeights() async {
    final db = await database;
    final rows = await db.query('weight_records', orderBy: 'date ASC');
    return rows.map(WeightRecord.fromRow).toList();
  }

  // ================= 设置 =================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Goals> getGoals() async {
    final v = await getSetting('goals');
    if (v == null) return Goals();
    try {
      return Goals.fromMap(jsonDecode(v) as Map<String, Object?>);
    } catch (_) {
      return Goals();
    }
  }

  Future<void> saveGoals(Goals g) async {
    await setSetting('goals', jsonEncode(g.toMap()));
  }

  // ================= 备份 / 恢复 =================

  static const schemaVersion = 1;

  Future<Map<String, Object?>> buildBackup() async {
    final db = await database;
    Future<List<Map<String, Object?>>> all(String t) async => db.query(t);
    return {
      'app': 'Control',
      'app_version': '1.8',
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'plans': await all('plans'),
      'plan_records': await all('plan_records'),
      'food_library_custom': await db.query('food_library',
          where: 'is_custom = 1'),
      'meal_entries': await all('meal_entries'),
      'food_usage': await all('food_usage'),
      'workout_templates': await all('workout_templates'),
      'workout_logs': await all('workout_logs'),
      'rest_days': await all('rest_days'),
      'weight_records': await all('weight_records'),
      'settings': await all('settings'),
      'expenses': await all('expenses'), // V1.6 记账
      'incomes': await all('incomes'),
      'credit_bills': await all('credit_bills'),
      'wishlist': await all('wishlist'), // V1.6 愿望清单
      'goals': await all('goals'), // V1.7 阶段目标
    };
  }

  Future<String> exportBackupJson() async =>
      const JsonEncoder.withIndent('  ').convert(await buildBackup());

  /// 导入备份：校验通过后覆盖现有数据
  Future<String> importBackupJson(String raw) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('文件不是有效的 JSON');
    }
    if (data['app'] != 'Control') throw Exception('这不是 Control 的备份文件');
    final sv = (data['schema_version'] as num?)?.toInt();
    if (sv == null || sv > schemaVersion) {
      throw Exception('备份版本高于当前应用，请先升级 Control');
    }

    final db = await database;
    await db.transaction((txn) async {
      for (final t in [
        'plan_records', 'plans', 'meal_entries', 'food_usage',
        'workout_logs', 'workout_templates', 'rest_days',
        'weight_records', 'settings',
        'expenses', 'incomes', 'credit_bills', 'wishlist', 'goals', // V1.6/1.7
      ]) {
        await txn.delete(t);
      }
      await txn.delete('food_library', where: 'is_custom = 1');

      Future<void> restore(String table, String key) async {
        final rows = (data[key] as List?) ?? [];
        for (final r in rows) {
          final row = Map<String, Object?>.from(r as Map);
          row.remove('id');
          await txn.insert(table, row);
        }
      }

      await restore('plans', 'plans');
      await restore('plan_records', 'plan_records');
      await restore('food_library', 'food_library_custom');
      await restore('meal_entries', 'meal_entries');
      await restore('food_usage', 'food_usage');
      await restore('workout_templates', 'workout_templates');
      await restore('workout_logs', 'workout_logs');
      await restore('rest_days', 'rest_days');
      await restore('weight_records', 'weight_records');
      await restore('settings', 'settings');
      await restore('expenses', 'expenses'); // V1.6
      await restore('incomes', 'incomes');
      await restore('credit_bills', 'credit_bills');
      await restore('wishlist', 'wishlist'); // V1.6 愿望清单
      await restore('goals', 'goals'); // V1.7 阶段目标
    });
    return '恢复完成';
  }

  /// 清除所有用户数据（保留内置库）
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in [
        'plan_records', 'plans', 'meal_entries', 'food_usage',
        'workout_logs', 'workout_templates', 'rest_days', 'weight_records',
        'expenses', 'incomes', 'credit_bills', 'wishlist', 'goals', // V1.6/1.7
      ]) {
        await txn.delete(t);
      }
      await txn.delete('food_library', where: 'is_custom = 1');
      await txn.update('settings', {'value': '1'}, where: 'key = ?', whereArgs: ['haptics']);
    });
  }

  // ================= V1.6 记账 =================

  // ---- 初始资产 ----
  Future<double> getInitialAssets() async {
    final v = await getSetting('initial_assets');
    return double.tryParse(v ?? '') ?? 0;
  }

  Future<void> setInitialAssets(double v) =>
      setSetting('initial_assets', v.toString());

  // ---- 支出 ----
  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return db.insert('expenses', e.toRow()..remove('id'));
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> expensesOfMonth(DateTime month) async {
    final db = await database;
    final s = Fmt.d(DateTime(month.year, month.month, 1));
    final e = Fmt.d(DateTime(month.year, month.month + 1, 1));
    final rows = await db.query('expenses',
        where: 'date >= ? AND date < ?', whereArgs: [s, e], orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromRow).toList();
  }

  Future<List<Expense>> allExpenses({int limit = 60}) async {
    final db = await database;
    final rows = await db.query('expenses',
        orderBy: 'date DESC, id DESC', limit: limit);
    return rows.map(Expense.fromRow).toList();
  }

  Future<double> totalExpenses() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT SUM(amount) s FROM expenses');
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalExpensesOfMonth(DateTime month) async {
    final db = await database;
    final s = Fmt.d(DateTime(month.year, month.month, 1));
    final e = Fmt.d(DateTime(month.year, month.month + 1, 1));
    final rows = await db.rawQuery(
        'SELECT SUM(amount) s FROM expenses WHERE date >= ? AND date < ?', [s, e]);
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  // ---- 收入 ----
  Future<int> insertIncome(Income i) async {
    final db = await database;
    return db.insert('incomes', i.toRow()..remove('id'));
  }

  Future<void> deleteIncome(int id) async {
    final db = await database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> incomesOfMonth(DateTime month) async {
    final db = await database;
    final s = Fmt.d(DateTime(month.year, month.month, 1));
    final e = Fmt.d(DateTime(month.year, month.month + 1, 1));
    final rows = await db.query('incomes',
        where: 'date >= ? AND date < ?', whereArgs: [s, e], orderBy: 'date DESC, id DESC');
    return rows.map(Income.fromRow).toList();
  }

  Future<double> totalIncomes() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT SUM(amount) s FROM incomes');
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalIncomesOfMonth(DateTime month) async {
    final db = await database;
    final s = Fmt.d(DateTime(month.year, month.month, 1));
    final e = Fmt.d(DateTime(month.year, month.month + 1, 1));
    final rows = await db.rawQuery(
        'SELECT SUM(amount) s FROM incomes WHERE date >= ? AND date < ?', [s, e]);
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  // ---- 借贷账单 ----
  Future<int> insertCreditBill(CreditBill b) async {
    final db = await database;
    return db.insert('credit_bills', b.toRow()..remove('id'));
  }

  Future<void> updateCreditBill(CreditBill b) async {
    final db = await database;
    await db.update('credit_bills', b.toRow(),
        where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> deleteCreditBill(int id) async {
    final db = await database;
    await db.delete('credit_bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CreditBill>> creditBills({bool? unpaidOnly}) async {
    final db = await database;
    final rows = unpaidOnly == null
        ? await db.query('credit_bills', orderBy: 'paid ASC, due_date ASC')
        : await db.query('credit_bills',
            where: 'paid = ?', whereArgs: [unpaidOnly ? 0 : 1], orderBy: 'due_date ASC');
    return rows.map(CreditBill.fromRow).toList();
  }

  /// 未还清借贷的剩余应还总额
  Future<double> creditRemainingTotal() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT SUM(remaining) s FROM credit_bills WHERE paid = 0');
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  // ---- 愿望清单 V1.6 ----

  Future<int> insertWishItem(WishItem w) async {
    final db = await database;
    return db.insert('wishlist', w.toRow()..remove('id'));
  }

  Future<void> updateWishItem(WishItem w) async {
    final db = await database;
    await db.update('wishlist', w.toRow(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteWishItem(int id) async {
    final db = await database;
    await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WishItem>> wishItems({bool? onlyUnachieved}) async {
    final db = await database;
    final rows = onlyUnachieved == null
        ? await db.query('wishlist', orderBy: 'priority DESC, id DESC')
        : await db.query('wishlist',
            where: 'achieved = ?',
            whereArgs: [onlyUnachieved ? 0 : 1],
            orderBy: 'priority DESC, id DESC');
    return rows.map(WishItem.fromRow).toList();
  }

  // ---- 阶段目标 V1.7 ----

  Future<int> insertGoal(Goal g) async {
    final db = await database;
    return db.insert('goals', g.toRow()..remove('id'));
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Goal>> goals() async {
    final db = await database;
    final rows = await db.query('goals', orderBy: 'id ASC');
    return rows.map(Goal.fromRow).toList();
  }

  // ---- 一次性任务 V1.7 ----

  Future<List<Plan>> oncePlans() async {
    final db = await database;
    final rows = await db.query('plans',
        where: "type = 'once'", orderBy: 'priority DESC, id DESC');
    return rows.map(Plan.fromRow).toList();
  }

  Future<void> setOnceDone(int planId, bool done) async {
    final db = await database;
    await db.update('plans', {'done_once': done ? 1 : 0},
        where: 'id = ?', whereArgs: [planId]);
  }

  // ---- 月度预算 V1.7 ----

  Future<double> getMonthlyBudget() async {
    final v = await getSetting('monthly_budget');
    return double.tryParse(v ?? '') ?? 0;
  }

  Future<void> setMonthlyBudget(double v) =>
      setSetting('monthly_budget', v.toString());

  // ---- 统计 V1.7（报告/成就共用） ----

  /// 连续打卡天数（截至某日，从最近一天往前数连续完成的天数）
  Future<int> streakDays(DateTime end) async {
    final db = await database;
    var streak = 0;
    for (var i = 0; i < 366; i++) {
      final d = Fmt.d(DateTime(end.year, end.month, end.day - i));
      final rows = await db.rawQuery(
          'SELECT COUNT(*) c FROM plan_records WHERE date = ? AND done = 1', [d]);
      final c = (rows.first['c'] as num).toInt();
      if (c > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// 某月打卡天数（有至少一条 done 记录的日期数）
  Future<int> checkDaysOfMonth(DateTime month) async {
    final db = await database;
    final s = Fmt.d(DateTime(month.year, month.month, 1));
    final e = Fmt.d(DateTime(month.year, month.month + 1, 1));
    final rows = await db.rawQuery(
        'SELECT COUNT(DISTINCT date) c FROM plan_records WHERE date >= ? AND date < ? AND done = 1',
        [s, e]);
    return (rows.first['c'] as num).toInt();
  }

  /// 某月计划总数（激活计划 × 月天数简化：按该月每日激活计划数求和）
  Future<int> totalPlansOfMonth(DateTime month) async {
    final db = await database;
    final all = await db.query('plans', where: "type != 'once'");
    final plans = all.map(Plan.fromRow).toList();
    var total = 0;
    final days = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= days; d++) {
      final day = DateTime(month.year, month.month, d);
      for (final p in plans) {
        if (p.activeOn(day)) total++;
      }
    }
    return total;
  }

  /// 累计训练次数（训练日志条数）
  Future<int> totalWorkouts() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) c FROM workout_logs');
    return (rows.first['c'] as num).toInt();
  }

  /// 累计记账笔数（支出+收入）
  Future<int> totalEntries() async {
    final db = await database;
    final r1 = await db.rawQuery('SELECT COUNT(*) c FROM expenses');
    final r2 = await db.rawQuery('SELECT COUNT(*) c FROM incomes');
    return (r1.first['c'] as num).toInt() + (r2.first['c'] as num).toInt();
  }

  /// 累计实现心愿数
  Future<int> totalWishesDone() async {
    final db = await database;
    final rows =
        await db.rawQuery('SELECT COUNT(*) c FROM wishlist WHERE achieved = 1');
    return (rows.first['c'] as num).toInt();
  }

  /// 最新体重（无记录返回 null）
  Future<double?> latestWeight() async {
    final db = await database;
    final rows = await db.query('weight_records',
        orderBy: 'date DESC', limit: 1);
    if (rows.isEmpty) return null;
    return (rows.first['weight'] as num).toDouble();
  }

  /// 某月训练次数
  Future<int> workoutsOfMonth(DateTime month) async {
    final db = await database;
    final s = Fmt.d(DateTime(month.year, month.month, 1));
    final e = Fmt.d(DateTime(month.year, month.month + 1, 1));
    final rows = await db.rawQuery(
        'SELECT COUNT(*) c FROM workout_logs WHERE date >= ? AND date < ?',
        [s, e]);
    return (rows.first['c'] as num).toInt();
  }

  // ---- 汇总 ----
  /// 当前余额 = 初始资产 + 累计收入 - 累计支出 - 借贷待还
  Future<double> currentBalance() async {
    final init = await getInitialAssets();
    final inc = await totalIncomes();
    final exp = await totalExpenses();
    final credit = await creditRemainingTotal();
    return init + inc - exp - credit;
  }
}
