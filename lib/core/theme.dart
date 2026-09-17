import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Control 全局设计语言 —— 莫兰迪低饱和色系 / 可爱粉彩双主题
///
/// 色值为运行时可变字段：启动时由 [AppColors.apply] 按所选主题赋值，
/// 所有页面引用自动跟随主题切换。
class AppColors {
  AppColors._();

  static String current = 'morandi'; // 'morandi' | 'cute'

  // 主色：雾霭蓝灰
  static Color primary = const Color(0xFF7C8B9D);
  // 强调色：暖杏橙
  static Color accent = const Color(0xFFE8936B);
  // 鼠尾草绿（次级主色）
  static Color sage = const Color(0xFF9CAF9F);
  // 深蓝灰（锻炼模块点缀）
  static Color slate = const Color(0xFF4A5568);
  // 淡奶油（饮食模块点缀）
  static Color cream = const Color(0xFFF3EDE3);

  // 浅色背景 / 卡片
  static Color bgLight = const Color(0xFFF7F6F4);
  static Color cardLight = const Color(0xFFFFFFFF);

  // 深色背景 / 卡片
  static Color bgDark = const Color(0xFF22262E);
  static Color cardDark = const Color(0xFF2C313B);

  // 文本
  static Color textPrimaryLight = const Color(0xFF3C434E);
  static Color textSecondaryLight = const Color(0xFF8B919B);
  static Color textPrimaryDark = const Color(0xFFE9EBEF);
  static Color textSecondaryDark = const Color(0xFF9AA1AC);

  // 优先级：高(红) / 中(橙) / 低(灰)（语义色，不随主题变）
  static const prioHigh = Color(0xFFD97B6C);
  static const prioMid = Color(0xFFE8936B);
  static const prioLow = Color(0xFFAEB4BC);

  // 营养四色（语义色）
  static const kcalColor = Color(0xFFE8936B);
  static const proteinColor = Color(0xFF7C8B9D);
  static const carbColor = Color(0xFF9CAF9F);
  static const fatColor = Color(0xFFD9B36A);

  // 完成度圆点（语义色）
  static const doneAll = Color(0xFF7FA88E);
  static const donePart = Color(0xFFE0C066);
  static const doneNone = Color(0xFFC9CDD3);

  // 点缀色
  static Color blush = const Color(0xFFF0C9BE);
  static Color butter = const Color(0xFFF2E4C4);
  static Color rose = const Color(0xFFE6A89B);

  /// 应用主题色板：'morandi' 莫兰迪 / 'cute' 可爱粉彩 / 'mist' 雾蓝暮光 / 'emerald' 青绿（V1.6）
  static void apply(String style) {
    current = style;
    switch (style) {
      case 'cute':
        primary = const Color(0xFFEF9DB4);
        accent = const Color(0xFFF5B94F);
        sage = const Color(0xFFA9D8C9);
        slate = const Color(0xFF8C7BAE);
        cream = const Color(0xFFFFF1E6);
        bgLight = const Color(0xFFFFF8F6);
        bgDark = const Color(0xFF2B2536);
        cardDark = const Color(0xFF372F44);
        textPrimaryLight = const Color(0xFF4A3B4A);
        textSecondaryLight = const Color(0xFF9A8A98);
        textPrimaryDark = const Color(0xFFF0EAF2);
        textSecondaryDark = const Color(0xFFA99FAC);
        blush = const Color(0xFFFFE3E9);
        butter = const Color(0xFFFFF3D6);
        rose = const Color(0xFFF7B2C2);
      case 'mist':
        // 雾蓝暮光：晨雾蓝 + 暮色暖沙，冷静克制（V1.6）
        primary = const Color(0xFF7B94B5);
        accent = const Color(0xFFC9A27E);
        sage = const Color(0xFF8FAE9B);
        slate = const Color(0xFF5A6A80);
        cream = const Color(0xFFEFE9E0);
        bgLight = const Color(0xFFF4F6FA);
        bgDark = const Color(0xFF232A36);
        cardDark = const Color(0xFF2E3747);
        textPrimaryLight = const Color(0xFF3A4454);
        textSecondaryLight = const Color(0xFF8A93A3);
        textPrimaryDark = const Color(0xFFE8ECF4);
        textSecondaryDark = const Color(0xFF9BA4B5);
        blush = const Color(0xFFE4DCD2);
        butter = const Color(0xFFF0E6D6);
        rose = const Color(0xFFD8C0B0);
      case 'emerald':
        // 青绿：山间青绿 + 暖金，清新高级（V1.6）
        primary = const Color(0xFF4C8C7C);
        accent = const Color(0xFFD9A441);
        sage = const Color(0xFF7FB5A3);
        slate = const Color(0xFF3F5F57);
        cream = const Color(0xFFF2EEE0);
        bgLight = const Color(0xFFF4FAF7);
        bgDark = const Color(0xFF1F2A28);
        cardDark = const Color(0xFF293836);
        textPrimaryLight = const Color(0xFF33443F);
        textSecondaryLight = const Color(0xFF85948F);
        textPrimaryDark = const Color(0xFFE6F0EC);
        textSecondaryDark = const Color(0xFF98A8A3);
        blush = const Color(0xFFDFEDE5);
        butter = const Color(0xFFF6EDD6);
        rose = const Color(0xFFCDB79A);
      default: // morandi
        primary = const Color(0xFF7C8B9D);
        accent = const Color(0xFFE8936B);
        sage = const Color(0xFF9CAF9F);
        slate = const Color(0xFF4A5568);
        cream = const Color(0xFFF3EDE3);
        bgLight = const Color(0xFFF7F6F4);
        bgDark = const Color(0xFF22262E);
        cardDark = const Color(0xFF2C313B);
        textPrimaryLight = const Color(0xFF3C434E);
        textSecondaryLight = const Color(0xFF8B919B);
        textPrimaryDark = const Color(0xFFE9EBEF);
        textSecondaryDark = const Color(0xFF9AA1AC);
        blush = const Color(0xFFF0C9BE);
        butter = const Color(0xFFF2E4C4);
        rose = const Color(0xFFE6A89B);
    }
    cardLight = const Color(0xFFFFFFFF);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark
        ? const Color(0xFF93A2B4)
        : AppColors.primary;

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: primary,
        secondary: AppColors.accent,
        tertiary: AppColors.blush,
        surface: card,
      ),
      fontFamily: null, // 系统原生无衬线（Roboto / HarmonyOS Sans）
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
          )
          .copyWith(
            headlineSmall: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: 0.2,
            ),
            titleLarge: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            titleMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
            bodySmall: TextStyle(fontSize: 12, color: textSecondary),
            labelMedium: TextStyle(fontSize: 12, color: textSecondary),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      // V1.4 灵动动画：全 App 统一 iOS 风格页面切换（左右滑动 + 缩放）
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF262B34) : Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            color: sel ? AppColors.primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? AppColors.primary : textSecondary,
            size: 23,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF3A414C) : const Color(0xFF3C434E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.bgLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        side: BorderSide.none,
        labelStyle: TextStyle(fontSize: 12, color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
      ),
    );
  }
}
