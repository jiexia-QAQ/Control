import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/db.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'about_page.dart';

/// 设置页：主题 / 触觉 / 数据导出导入 / 清除数据
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          SectionTitle('外观', emoji: '🎨'),
          // V1.5/V1.6 主题风格（四款皮肤，即时预览）
          MCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                _styleRow('morandi', '莫兰迪', '沉稳低调 · 低饱和', '🌿', app),
                _styleRow('cute', '可爱粉彩', '软萌元气 · 多 emoji', '🎀', app),
                _styleRow('mist', '雾蓝暮光', '晨雾蓝 × 暮色暖沙', '🌫️', app),
                _styleRow('emerald', '青绿', '山间青绿 × 暖金', '🌱', app),
              ],
            ),
          ),
          const SizedBox(height: 10),
          MCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                _radioRow('随系统', '跟随系统深浅色', ThemeMode.system, app),
                _radioRow('浅色', '温暖米白', ThemeMode.light, app),
                _radioRow('深色', '沉静深灰', ThemeMode.dark, app),
              ],
            ),
          ),
          SectionTitle('交互'),
          MCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('触觉反馈',
                  style: TextStyle(fontSize: 14, color: textColor)),
              subtitle: Text('打卡与关键操作时轻微振动',
                  style: TextStyle(fontSize: 11.5, color: subColor)),
              value: app.hapticsEnabled,
              onChanged: app.setHaptics,
            ),
          ),
          SectionTitle('数据备份'),
          MCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.upload_outlined,
                      size: 21, color: AppColors.primary),
                  title: Text('导出数据',
                      style: TextStyle(fontSize: 14, color: textColor)),
                  subtitle: Text('打包为 JSON 备份文件，可分享或保存',
                      style: TextStyle(fontSize: 11.5, color: subColor)),
                  onTap: _busy ? null : _export,
                ),
                Divider(
                    color: dark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download_outlined,
                      size: 21, color: AppColors.primary),
                  title: Text('导入数据',
                      style: TextStyle(fontSize: 14, color: textColor)),
                  subtitle: Text('从备份文件恢复，覆盖前需二次确认',
                      style: TextStyle(fontSize: 11.5, color: subColor)),
                  onTap: _busy ? null : _import,
                ),
              ],
            ),
          ),
          SectionTitle('数据安全'),
          MCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_outlined,
                  size: 21, color: AppColors.prioHigh),
              title: Text('清除所有数据',
                  style: TextStyle(fontSize: 14, color: AppColors.prioHigh)),
              subtitle: Text('删除全部计划、记录与体重数据',
                  style: TextStyle(fontSize: 11.5, color: subColor)),
              onTap: _busy ? null : _clear,
            ),
          ),
          SectionTitle('关于'),
          MCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.info_outline, size: 21, color: AppColors.primary),
              title: Text('关于 Control',
                  style: TextStyle(fontSize: 14, color: textColor)),
              subtitle: const Text('版本 1.8 · 解夏制作',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF8B919B))),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutPage())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioRow(String label, String sub, ThemeMode mode, AppState app) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return RadioListTile<ThemeMode>(
      contentPadding: EdgeInsets.zero,
      value: mode,
      groupValue: app.themeMode,
      onChanged: (m) => app.setThemeMode(m!),
      activeColor: AppColors.primary,
      title: Text(label,
          style: TextStyle(fontSize: 14, color: textColor)),
      subtitle: Text(sub, style: TextStyle(fontSize: 11.5, color: subColor)),
      dense: true,
    );
  }

  /// V1.5 主题风格选择行
  Widget _styleRow(String style, String label, String sub, String emoji,
      AppState app) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final sel = app.appTheme == style;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => app.setAppTheme(style),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(fontSize: 11, color: subColor)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: sel ? AppColors.primary : subColor.withValues(alpha: 0.5),
                  width: 1.6,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============ 导出 / 导入 / 清除 ============

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final json = await DatabaseService.instance.exportBackupJson();
      final dir = await getApplicationDocumentsDirectory();
      final name = 'Control_Backup_${Fmt.d(Fmt.today()).replaceAll('-', '')}.json';
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: 'Control 数据备份 $name',
          subject: 'Control 数据备份',
        ),
      );
      showToast(context, '备份文件已生成：$name');
    } catch (e) {
      if (mounted) showToast(context, '导出失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择 Control 备份文件',
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final String content;
    try {
      content = await File(path).readAsString();
    } catch (_) {
      showToast(context, '无法读取该文件');
      return;
    }

    final ok = await confirmDialog(context,
        title: '导入数据',
        message: '导入将覆盖当前全部数据（计划、饮食、训练、体重），且不可撤销。建议先导出当前数据。',
        confirmText: '覆盖并导入',
        confirmColor: AppColors.prioHigh);
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await DatabaseService.instance.importBackupJson(content);
      final app = context.read<AppState>();
      await app.init(); // 重新加载设置与目标
      app.bump();
      if (mounted) showToast(context, '导入成功');
    } catch (e) {
      if (mounted) showToast(context, '导入失败：${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final ok1 = await confirmDialog(context,
        title: '清除所有数据',
        message: '将删除全部计划、打卡、饮食、训练与体重数据，且不可恢复。',
        confirmText: '继续',
        confirmColor: AppColors.prioHigh);
    if (!ok1) return;
    final ok2 = await confirmDialog(context,
        title: '最后确认',
        message: '再次确认：真的要清除所有数据吗？建议先导出备份。',
        confirmText: '彻底清除',
        confirmColor: AppColors.prioHigh);
    if (!ok2) return;

    await DatabaseService.instance.clearAllData();
    await Haptics.heavy();
    final app = context.read<AppState>();
    await app.init();
    app.bump();
    if (mounted) showToast(context, '已清除所有数据');
  }
}
