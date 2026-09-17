import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/db.dart';
import '../../widgets/common.dart';

/// V1.7 成就徽章：本地里程碑，数据达标即解锁
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  bool _loading = true;
  int _streak = 0, _workouts = 0, _entries = 0, _wishesDone = 0;
  double _balance = 0;
  double? _weight;

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final streak = await db.streakDays(DateTime.now());
    final workouts = await db.totalWorkouts();
    final entries = await db.totalEntries();
    final wishes = await db.totalWishesDone();
    final balance = await db.currentBalance();
    final weight = await db.latestWeight();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _workouts = workouts;
      _entries = entries;
      _wishesDone = wishes;
      _balance = balance;
      _weight = weight;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tc = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final sc = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    final badges = <(String emoji, String name, String desc, bool unlocked)>[
      ('🌱', '初试牛刀', '首次完成打卡', _streak >= 1),
      ('🔥', '一周坚持', '连续打卡 7 天', _streak >= 7),
      ('⚡', '月度铁人', '连续打卡 30 天', _streak >= 30),
      ('🏆', '百日修行', '连续打卡 100 天', _streak >= 100),
      ('💪', '运动新星', '累计训练 10 次', _workouts >= 10),
      ('🏋️', '健身达人', '累计训练 50 次', _workouts >= 50),
      ('🧾', '记录控', '累计记账 50 笔', _entries >= 50),
      ('💎', '理财大师', '累计记账 200 笔', _entries >= 200),
      ('🎁', '愿望成真', '实现 3 个心愿', _wishesDone >= 3),
      ('💰', '攒钱高手', '余额达 10000 元', _balance >= 10000),
      ('📉', '自律管理', '记录体重并坚持使用', _weight != null),
      ('🎯', '目标猎手', '达成任意阶段目标', _balance >= 1000),
    ];
    final unlockedCount = badges.where((b) => b.$4).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就徽章'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  MCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Text('🏅', style: TextStyle(fontSize: 30)),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('已解锁 $unlockedCount / ${badges.length}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tc)),
                        const SizedBox(height: 3),
                        Text('当前连续打卡 $_streak 天 · 累计训练 $_workouts 次',
                            style: TextStyle(fontSize: 11.5, color: sc)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                    children: [
                      for (final b in badges) _badgeTile(b.$1, b.$2, b.$3, b.$4, dark, tc, sc),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _badgeTile(String emoji, String name, String desc, bool unlocked,
      bool dark, Color tc, Color sc) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.cream.withValues(alpha: dark ? 0.14 : 0.7)
            : (dark ? const Color(0xFF2C313B) : const Color(0xFFF2F1EE)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: unlocked
                ? AppColors.accent.withValues(alpha: 0.4)
                : (dark ? const Color(0xFF3A404C) : const Color(0xFFE3E2DE)),
            width: 0.6),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: TextStyle(fontSize: 26, color: unlocked ? null : Colors.black26)),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: unlocked ? tc : sc.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 9.5, color: sc),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
