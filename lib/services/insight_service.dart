import 'package:flutter/material.dart';

import '../core/utils.dart';
import 'db.dart';

/// 一条实时洞察
class Insight {
  final String emoji;
  final String text;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onTap;

  const Insight({
    required this.emoji,
    required this.text,
    required this.actionLabel,
    required this.icon,
    this.onTap,
  });
}

/// Shell 页 Tab 切换的全局回调（由 shell.dart 绑定，供洞察卡片跳转）
class ShellTabSwitcher {
  ShellTabSwitcher._();
  static void Function(int)? _cb;
  static void bind(void Function(int) cb) => _cb = cb;
  static void switchTo(int tab) => _cb?.call(tab);
  static void clear() => _cb = null;
}

/// 实时洞察服务（V1.5）：打开 App 第一眼看到轻提醒。
/// 纯本地规则计算，零依赖；按优先级评估，取第一条命中。
class InsightService {
  InsightService._();
  static final InsightService instance = InsightService._();

  /// 计算当前最值得展示的一条洞察（无任何命中返回默认鼓励）
  Future<Insight> pick() async {
    final db = DatabaseService.instance;
    final goals = await db.getGoals();
    final today = Fmt.today();

    // 规则 1：连续未训练提醒（间隔 ≥3 天）
    final lastW = await db.lastWorkoutDate();
    if (lastW != null) {
      final gap = today.difference(Fmt.parse(Fmt.d(lastW))).inDays;
      if (gap >= 3) {
        return Insight(
          emoji: '🏋️',
          text: '已经 $gap 天没训练了，动 10 分钟也好',
          actionLabel: '去锻炼',
          icon: Icons.fitness_center_outlined,
          onTap: () => ShellTabSwitcher.switchTo(1),
        );
      }
    }

    // 规则 2：本周蛋白质摄入偏低（< 目标 60%）
    final avgProtein = await db.avgProteinThisWeek();
    if (avgProtein > 0 && goals.protein > 0 && avgProtein < goals.protein * 0.6) {
      return Insight(
        emoji: '🍗',
        text: '本周蛋白质摄入偏少，来点鸡胸肉或虾仁？',
        actionLabel: '去记饮食',
        icon: Icons.restaurant_outlined,
        onTap: () => ShellTabSwitcher.switchTo(1),
      );
    }

    // 规则 3：连续打卡 streak（≥3 天）
    final streak = await db.getStreak();
    if (streak >= 3) {
      return Insight(
        emoji: '🔥',
        text: '已连续打卡 $streak 天，势头正好，别断',
        actionLabel: '继续加油',
        icon: Icons.local_fire_department_outlined,
      );
    }

    // 规则 4：今日计划未完成
    final plans = await db.plansForDate(today);
    if (plans.isNotEmpty) {
      final records = await db.recordsForDate(today);
      var done = 0, total = 0;
      for (final p in plans) {
        final rec = records[p.id.toString()];
        if (rec?.skipped ?? false) continue;
        total++;
        if (rec?.done ?? false) done++;
      }
      if (total > 0 && done < total) {
        return Insight(
          emoji: '🌱',
          text: '今天的计划还有 ${total - done} 项没完成，加油',
          actionLabel: '去打卡',
          icon: Icons.event_note_outlined,
          onTap: () => ShellTabSwitcher.switchTo(0),
        );
      }
    }

    // 默认：鼓励
    return Insight(
      emoji: '✨',
      text: '今天一切顺利，继续保持这份节奏',
      actionLabel: '好',
      icon: Icons.auto_awesome_outlined,
    );
  }
}
