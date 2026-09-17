import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 柔和弥散阴影（莫兰迪风格）
BoxDecoration softShadow(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: dark ? AppColors.cardDark : AppColors.cardLight,
    borderRadius: BorderRadius.circular(16),
    boxShadow: dark
        ? const []
        : [
            BoxShadow(
              color: const Color(0xFF7C8B9D).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
  );
}

/// 白卡片
class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? radius;

  const MCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      margin: margin,
      decoration: softShadow(context).copyWith(
        borderRadius: radius ?? BorderRadius.circular(16),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

/// 分区标题
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final String? emoji; // V1.3：emoji 前缀
  const SectionTitle(this.text, {super.key, this.trailing, this.emoji});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: dark
                  ? const Color(0xFFE9EBEF)
                  : const Color(0xFF3C434E),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 空状态
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? hint;
  final Widget? action;
  final String? emoji; // V1.3：emoji（提供时显示在 icon 之上、text 大字号）

  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.hint,
    this.action,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sub = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.blush.withValues(alpha: 0.32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: AppColors.primary),
              ),
              if (emoji != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(emoji!,
                      style: const TextStyle(fontSize: 22, height: 1.0)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? const Color(0xFFE9EBEF)
                      : const Color(0xFF3C434E))),
          if (hint != null) ...[
            const SizedBox(height: 5),
            Text(hint!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: sub)),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

/// 圆角操作菜单（长按弹出）
Future<T?> showActionSheet<T>(
  BuildContext context,
  List<({IconData icon, String label, Color? color})> actions,
) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      final textColor =
          dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions)
                ListTile(
                  leading: Icon(a.icon, color: a.color ?? textColor, size: 21),
                  title: Text(a.label,
                      style: TextStyle(
                          fontSize: 14.5,
                          color: a.color ?? textColor,
                          fontWeight: FontWeight.w500)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(context, a.label),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// 通用确认对话框
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确认',
  Color? confirmColor,
}) async {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final textColor =
      dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
      content: Text(message,
          style: TextStyle(
              fontSize: 13.5,
              color: dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B),
              height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消', style: TextStyle(color: Color(0xFF8B919B))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText,
              style: TextStyle(
                  color: confirmColor ?? AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 轻提示
void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1600)));
}
