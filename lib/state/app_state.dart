import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/weight_record.dart';
import '../services/db.dart';

/// 全局应用状态：主题、触觉、目标、共享选中日期、数据版本号
class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String appTheme = 'morandi'; // V1.5：'morandi' | 'cute'
  bool hapticsEnabled = true;
  Goals goals = Goals();
  DateTime selectedDate = Fmt.today();
  bool ready = false;
  int tick = 0; // 数据变更版本号，页面据此刷新

  Future<void> init() async {
    final db = DatabaseService.instance;
    final tm = await db.getSetting('theme_mode');
    themeMode = switch (tm) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    appTheme = (await db.getSetting('app_theme')) ?? 'morandi';
    AppColors.apply(appTheme);
    hapticsEnabled = (await db.getSetting('haptics')) != '0';
    Haptics.enabled = hapticsEnabled;
    goals = await db.getGoals();
    ready = true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    notifyListeners();
    DatabaseService.instance
        .setSetting('theme_mode', m.name)
        .then((_) {});
  }

  /// V1.5 切换主题风格（莫兰迪 / 可爱粉彩）
  void setAppTheme(String style) {
    appTheme = style;
    AppColors.apply(style);
    notifyListeners();
    DatabaseService.instance.setSetting('app_theme', style).then((_) {});
  }

  void setHaptics(bool v) {
    hapticsEnabled = v;
    Haptics.enabled = v;
    notifyListeners();
    DatabaseService.instance.setSetting('haptics', v ? '1' : '0').then((_) {});
  }

  Future<void> saveGoals(Goals g) async {
    goals = g;
    notifyListeners();
    await DatabaseService.instance.saveGoals(g);
  }

  void selectDate(DateTime d) {
    if (selectedDate.year == d.year &&
        selectedDate.month == d.month &&
        selectedDate.day == d.day) {
      return;
    }
    selectedDate = d;
    notifyListeners();
  }

  /// 数据变更后调用，触发各页面重载
  void bump() {
    tick++;
    notifyListeners();
  }
}
