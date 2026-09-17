import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/weight_record.dart';
import '../../services/db.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/line_chart.dart';
import '../report/report_page.dart';
import 'about_page.dart';
import 'achievements_page.dart';
import 'goals_page.dart';
import 'settings_page.dart';
import 'weight_page.dart';

/// 我的模块：个人概要 + 体重趋势 + 目标 + 数据管理
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _streak = 0;
  int _workoutCount = 0;
  double _dietRate = 0;
  List<WeightRecord> _weights = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tick = context.select<AppState, int>((s) => s.tick);
    _load(tick);
  }

  Future<void> _load([int? tick]) async {
    final db = DatabaseService.instance;
    final goals = context.read<AppState>().goals;
    final results = await Future.wait([
      db.getStreak(),
      db.workoutCountThisWeek(),
      db.dietComplianceThisWeek(goals),
      db.allWeights(),
    ]);
    if (!mounted) return;
    setState(() {
      _streak = results[0] as int;
      _workoutCount = results[1] as int;
      _dietRate = results[2] as double;
      _weights = results[3] as List<WeightRecord>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final monthStart = Fmt.addDays(Fmt.today(), -30);
    final monthWeights = _weights
        .where((w) => !Fmt.parse(w.date).isBefore(monthStart))
        .map((w) => (Fmt.parse(w.date), w.weight))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Row(
                children: [
                  Text('🌸 我的',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  const Spacer(),
                  Text('Control v1.8',
                      style: TextStyle(fontSize: 12, color: subColor)),
                ],
              ),
              const SizedBox(height: 4),
              Text('自律是一场长跑', style: TextStyle(fontSize: 13, color: subColor)),
              const SizedBox(height: 14),
              if (_loading)
                Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.primary)),
                )
              else ...[
                // 激励卡片
                Row(
                  children: [
                    _statCard(Icons.local_fire_department, '$_streak',
                        '连续打卡(天)', AppColors.accent),
                    const SizedBox(width: 10),
                    _statCard(Icons.fitness_center, '$_workoutCount',
                        '本周训练(次)', AppColors.primary),
                    const SizedBox(width: 10),
                    _statCard(
                        Icons.restaurant,
                        '${(_dietRate * 100).round()}%',
                        '饮食达标率',
                        AppColors.sage),
                  ],
                ),
                const SizedBox(height: 14),
                // 体重
                SectionTitle(
                  '体重趋势',
                  trailing: TextButton(
                    onPressed: () => _openWeight(),
                    child: Text('全部记录 ›',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.primary)),
                  ),
                ),
                MCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('近 30 天',
                              style: TextStyle(fontSize: 12.5, color: subColor)),
                          Text(
                            _weights.isEmpty
                                ? '暂无记录'
                                : '最新 ${Fmt.weight(_weights.last.weight)} kg',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TrendLineChart(points: monthWeights, unit: 'kg'),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openWeight(),
                          icon: const Icon(Icons.add, size: 17),
                          label: const Text('记录体重'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.5)),
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _entry(Icons.flag_outlined, '目标设置', '热量与营养素目标、每周训练天数',
                    () => _openPage(const GoalsPage())),
                _entry(Icons.monitor_weight_outlined, '体重记录', '查看历史与趋势',
                    () => _openPage(const WeightPage())),
                _entry(Icons.bar_chart_outlined, '数据报告', '周/月概览与年度热力图', // V1.7
                    () => _openPage(const ReportPage())),
                _entry(Icons.emoji_events_outlined, '成就徽章', '打卡与里程碑', // V1.7
                    () => _openPage(const AchievementsPage())),
                _entry(Icons.settings_outlined, '设置', '主题、触觉、数据管理',
                    () => _openPage(const SettingsPage())),
                _entry(Icons.info_outline, '关于 Control', '版本信息',
                    () => _openPage(const AboutPage())),
                const SizedBox(height: 16),
                Center(
                  child: Text('解夏制作 · 数据仅存于本机',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: subColor.withValues(alpha: 0.85))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return Expanded(
      child: MCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 7),
            Text(value,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: subColor)),
          ],
        ),
      ),
    );
  }

  Widget _entry(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: MCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11.5, color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 19, color: subColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _openWeight() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WeightPage()),
    );
    _load();
  }
}
