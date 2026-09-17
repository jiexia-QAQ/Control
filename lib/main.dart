import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'pages/splash.dart';
import 'services/reminder_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 全面屏 / 手势导航适配（ColorOS 等）
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final appState = AppState();
  await appState.init(); // 初始化数据库与种子数据（内部应用所选主题色板）

  // V1.4 计划提醒：初始化通知通道并恢复调度
  try {
    await ReminderService.instance.init();
    await ReminderService.instance.refreshAll();
  } catch (_) {
    // 通知不可用时静默降级，不影响主功能
  }

  AppColors.apply(appState.appTheme); // 兜底：确保主题色板已应用

  runApp(ControlApp(appState: appState));
}

class ControlApp extends StatelessWidget {
  final AppState appState;

  const ControlApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'Control',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: app.themeMode,
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              final navColor =
                  dark ? AppColors.bgDark : AppColors.bgLight;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      dark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      dark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: navColor,
                  systemNavigationBarIconBrightness:
                      dark ? Brightness.light : Brightness.dark,
                  systemNavigationBarContrastEnforced: false,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
