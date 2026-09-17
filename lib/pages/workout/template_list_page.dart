import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/exercise.dart';
import '../../models/workout_template.dart';
import '../../services/db.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'template_edit_page.dart';

/// 训练模板列表
/// [loadForDate] 为 true 时点击模板直接为当前选中日期加载
class TemplateListPage extends StatefulWidget {
  final bool loadForDate;

  const TemplateListPage({super.key, this.loadForDate = false});

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  List<WorkoutTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await DatabaseService.instance.allTemplates();
    if (!mounted) return;
    setState(() => _templates = t);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loadForDate ? '选择模板加载' : '训练模板'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('新建模板'),
      ),
      body: _templates.isEmpty
          ? EmptyState(
              icon: Icons.layers_outlined,
              emoji: '🏋️',
              text: '还没有训练模板',
              hint: '内置了三/四/五分化示例模板，也可以自定义\n长按模板可编辑或删除 · 第一次训练，从一个模板开始吧',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
              itemCount: _templates.length,
              itemBuilder: (context, i) {
                final t = _templates[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: dark ? const Color(0xFF2C313B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (widget.loadForDate) {
                          _loadForDate(t);
                        } else {
                          _openEditor(t);
                        }
                      },
                      onLongPress: () => _menu(t),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(Icons.layers,
                                  size: 19, color: AppColors.primary),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name,
                                      style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t.cycleDays} 天循环'
                                    '${t.restAfter > 0 ? ' · 循环后休 ${t.restAfter} 天' : ''}'
                                    ' · ${t.days.where((d) => !d.rest).length} 个训练日'
                                    ' · ${t.days.fold<int>(0, (s, d) => s + d.exercises.length)} 个动作',
                                    style:
                                        TextStyle(fontSize: 11.5, color: subColor),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: [
                                      for (final d in t.days)
                                        if (!d.rest)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.slate
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'D${d.day} ${d.exercises.length}动',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.slate,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.sage
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text('休',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6B8B77),
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 19,
                                color: subColor.withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditor([WorkoutTemplate? t]) async {
    await Haptics.tap();
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TemplateEditPage(template: t)),
    );
    _load();
  }

  Future<void> _menu(WorkoutTemplate t) async {
    final action = await showActionSheet(context, [
      (icon: Icons.edit_outlined, label: '编辑', color: null),
      (icon: Icons.delete_outline, label: '删除模板', color: AppColors.prioHigh),
    ]);
    if (action == null || !mounted) return;
    if (action == '编辑') {
      await _openEditor(t);
    } else if (action == '删除模板') {
      final ok = await confirmDialog(context,
          title: '删除模板',
          message: '删除「${t.name}」？已生成的训练记录不受影响。',
          confirmText: '删除',
          confirmColor: AppColors.prioHigh);
      if (ok) {
        await DatabaseService.instance.deleteTemplate(t.id!);
        _load();
      }
    }
  }

  Future<void> _loadForDate(WorkoutTemplate t) async {
    final day = context.read<AppState>().selectedDate;
    final idx = t.dayIndexFor(day) ?? 0;
    final tDay = t.days[idx];
    if (tDay.rest) {
      showToast(context, '该日期对应模板的休息日，无需训练');
      return;
    }
    final db = DatabaseService.instance;
    final existing = await db.logsForDate(day);
    final ds = Fmt.d(day);
    var order = existing.length;
    final library = await db.allExercises();
    String partOf(String name) {
      for (final e in library) {
        if (e.name == name) return e.part;
      }
      return '';
    }

    for (final te in tDay.exercises) {
      await db.insertLog(WorkoutLog(
        date: ds,
        templateId: t.id,
        exerciseId: te.exerciseId,
        exerciseName: te.name,
        part: partOf(te.name),
        sets: [
          for (var n = 1; n <= te.sets; n++)
            WorkoutSet(no: n, reps: te.reps, weight: te.weight),
        ],
        sortOrder: order++,
      ));
    }
    await Haptics.success();
    if (!mounted) return;
    showToast(context,
        '已加载「${t.name}」训练日 ${tDay.day} · ${tDay.exercises.length} 个动作');
    Navigator.pop(context);
  }
}
