import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 宏量营养素饼图（环形）+ 图例
class MacroPie extends StatelessWidget {
  final double protein, carb, fat;
  final double size;

  const MacroPie({
    super.key,
    required this.protein,
    required this.carb,
    required this.fat,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + carb + fat;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    final items = [
      ('蛋白质', protein, const Color(0xFF7C8B9D)),
      ('碳水', carb, const Color(0xFF9CAF9F)),
      ('脂肪', fat, const Color(0xFFD9B36A)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _PiePainter(items: items, progress: t),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total == 0 ? '--' : '${total.round()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    Text('总供能 (kcal)', style: TextStyle(fontSize: 11, color: subColor)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final it in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: it.$3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${it.$1} ${total == 0 ? 0 : (it.$2 / total * 100).round()}%',
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<(String, double, Color)> items;
  final double progress;

  _PiePainter({required this.items, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<double>(0, (s, i) => s + i.$2);
    if (total <= 0) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = const Color(0xFFEDEDEB);
      canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2 - 8, track);
      return;
    }
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    for (final it in items) {
      final sweep = it.$2 / total * math.pi * 2 * progress;
      if (sweep <= 0.001) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = it.$3
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep - 0.02, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.progress != progress || old.items != items;
}
