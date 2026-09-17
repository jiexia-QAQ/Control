import 'package:flutter/services.dart';

/// 触觉反馈统一入口（受设置开关控制）
class Haptics {
  Haptics._();

  static bool enabled = true;

  static Future<void> tap() async {
    if (!enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> success() async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    if (!enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
