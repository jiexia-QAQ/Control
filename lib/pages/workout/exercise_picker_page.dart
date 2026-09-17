import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';

import '../../core/theme.dart';
import '../../models/exercise.dart';
import '../../services/db.dart';
import '../../widgets/common.dart';

const exerciseParts = ['胸', '背', '肩', '腿', '二头', '三头', '腹', '全身'];
const exerciseEquipment = ['杠铃', '哑铃', '绳索', '器械', '自重', '壶铃', '其他'];

/// 动作库选择页：搜索 + 部位筛选 + 自定义动作（V1.3）
class ExercisePickerPage extends StatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  final TextEditingController _q = TextEditingController();
  Timer? _debounce;
  String? _part;
  List<ExerciseItem> _results = [];

  @override
  void initState() {
    super.initState();
    _q.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), _search);
    });
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final r = await DatabaseService.instance
        .searchExercises(_q.text, part: _part);
    if (!mounted) return;
    setState(() => _results = r);
  }

  /// 新建 / 编辑自定义动作（existing != null 时为编辑）
  Future<void> _openExerciseSheet({ExerciseItem? existing}) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.desc ?? '');
    var part = existing?.part ?? exerciseParts.first;
    var equipment = existing?.equipment ?? exerciseEquipment.first;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor =
            dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
        final subColor =
            dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    isEdit ? '编辑动作' : '新建自定义动作',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  autofocus: !isEdit,
                  decoration: const InputDecoration(
                      hintText: '动作名称，如：俯卧撑、高位下拉'),
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: part,
                        decoration: const InputDecoration(labelText: '部位'),
                        style: TextStyle(fontSize: 14, color: textColor),
                        items: [
                          for (final p in exerciseParts)
                            DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) => setSheet(() => part = v ?? part),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: equipment,
                        decoration: const InputDecoration(labelText: '器械'),
                        style: TextStyle(fontSize: 14, color: textColor),
                        items: [
                          for (final e in exerciseEquipment)
                            DropdownMenuItem(value: e, child: Text(e)),
                        ],
                        onChanged: (v) =>
                            setSheet(() => equipment = v ?? equipment),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      hintText: '备注（可选）：动作要领、组次安排等'),
                  style: TextStyle(fontSize: 13.5, color: textColor),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        showToast(ctx, '动作名称不能为空');
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: Text(isEdit ? '保存修改' : '添加到动作库',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text('自定义动作会自动出现在动作库中，训练时可直接选用',
                      style: TextStyle(fontSize: 11, color: subColor)),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true || !mounted) return;

    final db = DatabaseService.instance;
    final item = ExerciseItem(
      id: existing?.id,
      name: nameCtrl.text.trim(),
      part: part,
      equipment: equipment,
      desc: descCtrl.text.trim(),
      pinyin: PinyinHelper.getShortPinyin(nameCtrl.text.trim()),
      isCustom: true,
    );
    if (isEdit) {
      await db.updateCustomExercise(item);
      showToast(context, '已保存修改');
    } else {
      await db.insertCustomExercise(item);
      showToast(context, '已添加到动作库');
    }
    _search();
  }

  /// 长按自定义动作：编辑 / 删除
  Future<void> _onLongPress(ExerciseItem e) async {
    if (!e.isCustom) {
      showToast(context, '内置动作不可编辑，可长按自定义动作管理');
      return;
    }
    final action = await showActionSheet(context, [
      (icon: Icons.edit_outlined, label: '编辑', color: null),
      (icon: Icons.delete_outline, label: '删除动作', color: AppColors.prioHigh),
    ]);
    if (action == null || !mounted) return;
    switch (action) {
      case '编辑':
        await _openExerciseSheet(existing: e);
        break;
      case '删除动作':
        final ok = await confirmDialog(context,
            title: '删除动作',
            message: '确定删除「${e.name}」吗？已保存的训练记录不受影响。',
            confirmText: '删除',
            confirmColor: AppColors.prioHigh);
        if (ok) {
          await DatabaseService.instance.deleteCustomExercise(e.id!);
          showToast(context, '已删除');
          _search();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择动作'),
        actions: [
          TextButton.icon(
            onPressed: () => _openExerciseSheet(),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('新建动作'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                hintText: '搜索动作（汉字 / 拼音 / 器械）',
                prefixIcon: Icon(Icons.search, size: 19),
              ),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _partChip('全部', _part == null, () {
                  setState(() => _part = null);
                  _search();
                }),
                for (final p in exerciseParts)
                  _partChip(p, _part == p, () {
                    setState(() => _part = p);
                    _search();
                  }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final e = _results[i];
                return _exCard(e);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _partChip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        selected: sel,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _exCard(ExerciseItem e) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: dark ? const Color(0xFF2C313B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, e),
          onLongPress: () => _onLongPress(e),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (e.isCustom ? AppColors.accent : AppColors.slate)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                      e.isCustom ? Icons.auto_awesome : Icons.fitness_center,
                      size: 16,
                      color: e.isCustom ? AppColors.accent : AppColors.slate),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(e.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                          ),
                          if (e.isCustom) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.blush,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('自定义',
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [e.part, if (e.part2.isNotEmpty) e.part2, e.equipment]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline,
                    size: 19, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
