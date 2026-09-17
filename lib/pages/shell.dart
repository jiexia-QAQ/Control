import 'package:flutter/material.dart';

import '../services/insight_service.dart';
import 'accounting/accounting_page.dart';
import 'diet/diet_page.dart';
import 'plan/plan_page.dart';
import 'profile/profile_page.dart';
import 'workout/workout_page.dart';

/// 主框架：底部五 Tab（V1.6 新增记账），IndexedStack 保留各页面状态
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // V1.7.6：计划0/饮食1/锻炼2/记账3/我的4
    ShellTabSwitcher.bind((i) {
      if (mounted) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    ShellTabSwitcher.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          PlanPage(),
          DietPage(),
          WorkoutPage(),
          AccountingPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: '计划',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: '饮食',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '锻炼',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '记账',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
