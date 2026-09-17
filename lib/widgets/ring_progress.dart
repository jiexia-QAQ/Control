import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 环形进度（CustomPainter 自绘，用于营养摄入等）
class RingProgress extends StatelessWidget {
  final double value; // 0..1（可超过 1，颜色转红）
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? center;
  final Duration duration;

  const RingProgress({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 11,
    this.color = const Color(0xFF7C8B9D),
    this.trackColor = const Color(0xFFEDEDEB),
    this.center,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    final over = value > 1.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: over ? 1.0 : value.clamp(0, 1)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              value: v,
              strokeWidth: strokeWidth,
              color: over
                  ? const Color(0xFFD97B6C)
                  : Color.lerp(color, const Color(0xFFE8936B), v * 0.35)!,
              trackColor: trackColor,
            ),
            child: Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (value > 0.001) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}
