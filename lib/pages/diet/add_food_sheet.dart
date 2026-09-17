import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/food.dart';
import '../../services/db.dart';
import '../../widgets/common.dart';

/// 添加食物：内置库搜索（拼音/汉字/分类）+ 最近 + 手动输入
class AddFoodSheet extends StatefulWidget {
  final MealType mealType;
  final DateTime date;

  const AddFoodSheet({super.key, required this.mealType, required this.date});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  bool _manual = false;
  final TextEditingController _q = TextEditingController();
  Timer? _debounce;
  List<String> _categories = [];
  String? _category;
  List<FoodItem> _results = [];
  List<FoodItem> _recent = [];
  bool _searching = false;

  // 手动输入控制器
  final _mName = TextEditingController();
  final _mGrams = TextEditingController(text: '100');
  final _mProtein = TextEditingController();
  final _mCarb = TextEditingController();
  final _mFat = TextEditingController();
  String _imagePath = ''; // V1.8 自定义食物照片

  @override
  void initState() {
    super.initState();
    _init();
    _q.addListener(_onQuery);
  }

  Future<void> _init() async {
    final db = DatabaseService.instance;
    final cats = await db.foodCategories();
    final recent = await db.recentFoods();
    final results = await db.searchFoods('');
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _recent = recent;
      _results = results;
    });
  }

  void _onQuery() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    setState(() => _searching = true);
    final db = DatabaseService.instance;
    final r = await db.searchFoods(q, category: _category);
    if (!mounted) return;
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _mName.dispose();
    _mGrams.dispose();
    _mProtein.dispose();
    _mCarb.dispose();
    _mFat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('添加食物 · ${widget.mealType.label}',
                    style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('搜索库')),
                    ButtonSegment(value: true, label: Text('手动')),
                  ],
                  selected: {_manual},
                  onSelectionChanged: (s) => setState(() => _manual = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!_manual) _buildSearch(textColor, subColor)
            else _buildManual(textColor, subColor),
          ],
        ),
      ),
    );
  }

  // ============ 搜索库 ============

  Widget _buildSearch(Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _q,
          decoration: const InputDecoration(
            hintText: '搜索食物（支持汉字 / 拼音首字母）',
            prefixIcon: Icon(Icons.search, size: 19),
          ),
          style: TextStyle(fontSize: 14, color: textColor),
        ),
        const SizedBox(height: 10),
        // 分类筛选
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _catChip('全部', _category == null, () {
                setState(() => _category = null);
                _search();
              }),
              for (final c in _categories)
                _catChip(c, _category == c, () {
                  setState(() => _category = c);
                  _search();
                }),
            ],
          ),
        ),
        // 最近使用
        if (_recent.isNotEmpty && _q.text.trim().isEmpty && _category == null) ...[
          const SizedBox(height: 12),
          Text('最近使用', style: TextStyle(fontSize: 12, color: subColor)),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in _recent)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(f.name,
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => _pickFood(f),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_searching)
          Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary)),
          )
        else if (_results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(22),
            child: Center(
                child: Text('未找到相关食物，可切换"手动"输入',
                    style: TextStyle(fontSize: 12.5, color: subColor))),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final f = _results[i];
                return InkWell(
                  onTap: () => _pickFood(f),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // V1.8 缩略图
                        if (f.imagePath.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(f.imagePath),
                                width: 40, height: 40, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: textColor)),
                              const SizedBox(height: 2),
                              Text(
                                  '${f.category} · 每100g：${Fmt.kcal(f.kcal)}kcal 蛋白${Fmt.num(f.protein)}g 脂肪${Fmt.num(f.fat)}g 碳水${Fmt.num(f.carb)}g',
                                  style: TextStyle(
                                      fontSize: 11, color: subColor)),
                            ],
                          ),
                        ),
                        Icon(Icons.add_circle_outline,
                            size: 19, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _catChip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: sel,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ============ 手动输入 ============

  // V1.8 拍照/相册选图：拷贝到应用文档目录持久保存
  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src == null || !mounted) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: src,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      // 复制到持久目录 food_images/
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'food_images'));
      if (!await folder.exists()) await folder.create(recursive: true);
      final dest = p.join(folder.path,
          '${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(picked.path).copy(dest);
      if (!mounted) return;
      setState(() => _imagePath = dest);
      await Haptics.tap();
    } catch (_) {
      if (mounted) showToast(context, '照片加载失败，请重试');
    }
  }

  Widget _buildManual(Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // V1.8 拍照/相册
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickImage,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: _imagePath.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 22, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text('拍照',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.primary)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_imagePath),
                            width: 72, height: 72, fit: BoxFit.cover),
                      ),
              ),
            ),
            if (_imagePath.isNotEmpty)
              IconButton(
                onPressed: () => setState(() => _imagePath = ''),
                icon: Icon(Icons.close, size: 16, color: subColor),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('拍下食物照片，下次一眼认出它\n（可选，拍照或从相册选择）',
                  style: TextStyle(fontSize: 11.5, color: subColor, height: 1.5)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mName,
          decoration: const InputDecoration(hintText: '食物名称（如：自制三明治）'),
          style: TextStyle(fontSize: 14, color: textColor),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mGrams,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '重量 (g)'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _mProtein,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '蛋白质 (g)'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mFat,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '脂肪 (g)'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _mCarb,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '碳水 (g)'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('按每 100g 营养入库：以后吃任意克数都会自动按比例换算',
            style: TextStyle(fontSize: 11, color: subColor)),
        Text('热量 = 4×蛋白 + 4×碳水 + 9×脂肪 自动计算',
            style: TextStyle(fontSize: 11, color: subColor)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saveManual,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('保存并记录',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ============ 行为 ============

  Future<void> _pickFood(FoodItem f) async {
    await DatabaseService.instance.bumpFoodUsage(f.id!);
    final grams = await _gramsDialog(f.name);
    if (grams == null || !mounted) return;
    final ratio = grams / 100;
    Navigator.pop(
      context,
      MealEntry(
        date: Fmt.d(widget.date),
        mealType: widget.mealType,
        foodId: f.id,
        name: f.name,
        grams: grams,
        kcal: f.kcal * ratio,
        protein: f.protein * ratio,
        carb: f.carb * ratio,
        fat: f.fat * ratio,
      ),
    );
  }

  Future<double?> _gramsDialog(String name) async {
    final ctrl = TextEditingController(text: '100');
    final r = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: '食用量 (g)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消',
                  style: TextStyle(color: Color(0xFF8B919B)))),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              Navigator.pop(ctx, v == null || v <= 0 ? 100 : v);
            },
            child: Text('确定',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return r;
  }

  Future<void> _saveManual() async {
    final name = _mName.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入食物名称')));
      return;
    }
    final grams = double.tryParse(_mGrams.text) ?? 100;
    final protein = double.tryParse(_mProtein.text) ?? 0;
    final carb = double.tryParse(_mCarb.text) ?? 0;
    final fat = double.tryParse(_mFat.text) ?? 0;
    if (grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重量需大于 0')));
      return;
    }
    // 每 100g 营养
    final ratio100 = 100 / grams;
    final db = DatabaseService.instance;
    final foodId = await db.insertCustomFood(FoodItem(
      name: name,
      category: '自定义',
      kcal: (4 * protein + 4 * carb + 9 * fat) * ratio100,
      protein: protein * ratio100,
      carb: carb * ratio100,
      fat: fat * ratio100,
      pinyin: '',
      isCustom: true,
      imagePath: _imagePath, // V1.8 照片
    ));
    if (!mounted) return;
    // V1.7.7 保存后不再默认添加 100g，询问要添加的克数
    final grams2 = await _addAfterSaveDialog(name);
    if (!mounted) return;
    if (grams2 == null) {
      // 只保存，不添加
      Navigator.pop(context);
      showToast(context, '已保存到食物库，可在搜索中选择添加');
      return;
    }
    final ratio2 = grams2 / 100;
    Navigator.pop(
      context,
      MealEntry(
        date: Fmt.d(widget.date),
        mealType: widget.mealType,
        foodId: foodId,
        name: name,
        grams: grams2,
        kcal: (4 * protein + 4 * carb + 9 * fat) * ratio2,
        protein: protein * ratio2,
        carb: carb * ratio2,
        fat: fat * ratio2,
      ),
    );
  }

  /// 保存自定义食物后：输入添加克数；留空/取消 = 只保存不添加
  Future<double?> _addAfterSaveDialog(String name) async {
    final ctrl = TextEditingController();
    final r = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('已保存「$name」',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('要直接记录到这一餐吗？', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(hintText: '食用量 (g)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // 只保存
            child: const Text('暂不添加',
                style: TextStyle(color: Color(0xFF8B919B))),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              Navigator.pop(ctx, v == null || v <= 0 ? null : v);
            },
            child: Text('确定添加',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return r;
  }
}
