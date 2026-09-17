import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../models/exercise.dart';
import '../../models/workout_template.dart';
import '../../services/db.dart';
import '../../widgets/common.dart';
import 'exercise_picker_page.dart';

/// 训练模板编辑页
class TemplateEditPage extends StatefulWidget {
  final WorkoutTemplate? template;

  const TemplateEditPage({super.key, this.template});

  @override
  State<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends State<TemplateEditPage> {
  late final TextEditingController _name;
  late int _cycleDays;
  late bool _restAfter;
  late List<TemplateDay> _days;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _cycleDays = t?.cycleDays ?? 3;
    _restAfter = (t?.restAfter ?? 1) == 1;
    _days = t != null
        ? [for (final d in t.days) _copyDay(d)]
        : [
            for (var i = 1; i <= 3; i++) TemplateDay(day: i),
          ];
  }

  TemplateDay _copyDay(TemplateDay d) => TemplateDay(
        day: d.day,
        rest: d.rest,
        exercises: [
          for (final e in d.exercises)
            TemplateExercise(
                exerciseId: e.exerciseId,
                name: e.name,
                sets: e.sets,
                reps: e.reps,
                weight: e.weight),
        ],
      );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _rebuildDays() {
    final days = <TemplateDay>[];
    for (var i = 1; i <= _cycleDays; i++) {
      TemplateDay? existing;
      for (final d in _days) {
        if (d.day == i) {
          existing = d;
          break;
        }
      }
      days.add(existing ?? TemplateDay(day: i));
    }
    setState(() => _days = days);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      appBar: AppBar(title: Text(widget.template == null ? '新建模板' : '编辑模板')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: '模板名称（如：三分化·推拉腿）'),
            style: TextStyle(fontSize: 14.5, color: textColor),
          ),
          const SizedBox(height: 14),
          MCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('循环天数',
                        style: TextStyle(fontSize: 13.5, color: textColor)),
                    const Spacer(),
                    _stepBtn(Icons.remove, () {
                      if (_cycleDays > 1) {
                        _cycleDays--;
                        _rebuildDays();
                      }
                    }),
                    SizedBox(
                      width: 40,
                      child: Text('$_cycleDays 天',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                    ),
                    _stepBtn(Icons.add, () {
                      if (_cycleDays < 7) {
                        _cycleDays++;
                        _rebuildDays();
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('循环结束后安排休息日',
                      style: TextStyle(fontSize: 13.5, color: textColor)),
                  subtitle: Text('例如 3 天循环，第 4 天休息',
                      style: TextStyle(fontSize: 11.5, color: subColor)),
                  value: _restAfter,
                  onChanged: (v) => setState(() => _restAfter = v),
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final d in _days) ...[
            SectionTitle(
              '训练日 ${d.day}',
              trailing: Row(
                children: [
                  TextButton(
                    onPressed: () => _addExerciseTo(d),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 15, color: AppColors.primary),
                        SizedBox(width: 2),
                        Text('添加动作',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MCard(
              padding: EdgeInsets.zero,
              child: d.exercises.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                          child: Text('暂无动作，点击右上角添加',
                              style: TextStyle(fontSize: 12, color: subColor))),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < d.exercises.length; i++)
                          _exRow(d, i, textColor, subColor),
                      ],
                    ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('保存模板'),
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

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.bgLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _exRow(TemplateDay day, int i, Color textColor, Color subColor) {
    final ex = day.exercises[i];
    final isLast = i == day.exercises.length - 1;
    return InkWell(
      onTap: () => _editExercise(day, ex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.name,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text('目标 ${ex.sets}组 × ${ex.reps}次 × ${FmtNum(ex.weight)}kg',
                      style: TextStyle(fontSize: 11.5, color: subColor)),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _deleteExercise(day, ex),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close,
                    size: 16, color: subColor.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String FmtNum(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  Future<void> _addExerciseTo(TemplateDay day) async {
    final ex = await Navigator.of(context).push<ExerciseItem>(
      MaterialPageRoute(builder: (_) => const ExercisePickerPage()),
    );
    if (ex == null || !mounted) return;
    setState(() {
      day.exercises.add(TemplateExercise(
          exerciseId: ex.id, name: ex.name, sets: 3, reps: 10, weight: 0));
    });
  }

  Future<void> _editExercise(TemplateDay day, TemplateExercise ex) async {
    final repsCtrl = TextEditingController(text: '${ex.reps}');
    final setsCtrl = TextEditingController(text: '${ex.sets}');
    final wtCtrl = TextEditingController(text: ex.weight == 0 ? '0' : FmtNum(ex.weight));
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ex.name,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dField(setsCtrl, '目标组数'),
            const SizedBox(height: 10),
            _dField(repsCtrl, '目标次数'),
            const SizedBox(height: 10),
            _dField(wtCtrl, '参考重量 kg'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Color(0xFF8B919B)))),
          TextButton(
            onPressed: () {
              setState(() {
                ex.sets = int.tryParse(setsCtrl.text) ?? ex.sets;
                ex.reps = int.tryParse(repsCtrl.text) ?? ex.reps;
                ex.weight = double.tryParse(wtCtrl.text) ?? ex.weight;
              });
              Navigator.pop(ctx);
            },
            child: Text('确定',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: hint, isDense: true),
    );
  }

  void _deleteExercise(TemplateDay day, TemplateExercise ex) {
    setState(() => day.exercises.remove(ex));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, '请输入模板名称');
      return;
    }
    final t = WorkoutTemplate(
      id: widget.template?.id,
      name: name,
      cycleDays: _cycleDays,
      restAfter: _restAfter ? 1 : 0,
      days: _days,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
    );
    final db = DatabaseService.instance;
    if (t.id != null) {
      await db.updateTemplate(t);
    } else {
      await db.insertTemplate(t);
    }
    await Haptics.success();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
