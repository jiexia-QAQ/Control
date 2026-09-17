import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../models/weight_record.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// 目标设置页
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carb;
  late final TextEditingController _fat;
  late int _weeklyDays;

  @override
  void initState() {
    super.initState();
    final g = context.read<AppState>().goals;
    _kcal = TextEditingController(text: g.kcal.round().toString());
    _protein = TextEditingController(text: g.protein.round().toString());
    _carb = TextEditingController(text: g.carb.round().toString());
    _fat = TextEditingController(text: g.fat.round().toString());
    _weeklyDays = g.weeklyWorkoutDays;
  }

  @override
  void dispose() {
    _kcal.dispose();
    _protein.dispose();
    _carb.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      appBar: AppBar(title: const Text('目标设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          MCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('每日营养目标',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 6),
                Text('按性别年龄与活动量调整，建议参考膳食指南',
                    style: TextStyle(fontSize: 11.5, color: subColor)),
                const SizedBox(height: 16),
                _field(_kcal, '每日热量目标 (kcal)', Icons.local_fire_department),
                const SizedBox(height: 12),
                _field(_protein, '蛋白质 (g)', Icons.water_drop_outlined),
                const SizedBox(height: 12),
                _field(_carb, '碳水 (g)', Icons.grain_outlined),
                const SizedBox(height: 12),
                _field(_fat, '脂肪 (g)', Icons.opacity_outlined),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('训练目标',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 4),
                Text('每周训练天数', style: TextStyle(fontSize: 12.5, color: subColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var d = 1; d <= 7; d++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () =>
                                setState(() => _weeklyDays = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _weeklyDays == d
                                    ? AppColors.primary
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : AppColors.bgLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$d',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _weeklyDays == d
                                        ? Colors.white
                                        : textColor,
                                  )),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('保存目标'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 17, color: AppColors.primary),
      ),
      style: TextStyle(fontSize: 14, color: textColor),
    );
  }

  Future<void> _save() async {
    final g = Goals(
      kcal: double.tryParse(_kcal.text) ?? 1800,
      protein: double.tryParse(_protein.text) ?? 90,
      carb: double.tryParse(_carb.text) ?? 220,
      fat: double.tryParse(_fat.text) ?? 60,
      weeklyWorkoutDays: _weeklyDays,
    );
    await context.read<AppState>().saveGoals(g);
    await Haptics.success();
    if (!mounted) return;
    showToast(context, '目标已保存');
    Navigator.pop(context);
  }
}
