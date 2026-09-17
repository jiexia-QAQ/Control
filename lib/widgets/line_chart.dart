import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 体重趋势折线图（CustomPainter 自绘，支持触摸提示）
class TrendLineChart extends StatefulWidget {
  final List<(DateTime, double)> points;
  final String unit;

  const TrendLineChart({super.key, required this.points, this.unit = 'kg'});

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _hoverIndex;
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grid = dark ? const Color(0xFF3A414C) : const Color(0xFFECECE9);
    final textColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final lineColor = AppColors.primary;
    final pts = widget.points;

    if (pts.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('暂无数据，先记录一条体重吧',
              style: TextStyle(color: textColor, fontSize: 13)),
        ),
      );
    }

    return GestureDetector(
      key: _key,
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _hit(d.localPosition),
      onTapUp: (_) => setState(() => _hoverIndex = null),
      onPanDown: (d) => _hit(d.localPosition),
      onPanUpdate: (d) => _hit(d.localPosition),
      onPanEnd: (_) => setState(() => _hoverIndex = null),
      child: SizedBox(
        height: 190,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final padL = 34.0, padR = 10.0, padT = 24.0, padB = 28.0;
          final iw = w - padL - padR;
          final ih = h - padT - padB;

          var minV = double.infinity, maxV = double.negativeInfinity;
          for (final p in pts) {
            if (p.$2 < minV) minV = p.$2;
            if (p.$2 > maxV) maxV = p.$2;
          }
          final range = (maxV - minV).abs() < 0.01 ? 1.0 : maxV - minV;
          minV -= range * 0.15;
          maxV += range * 0.15;

          Offset pos(int i) {
            final x = padL + (pts.length == 1 ? iw / 2 : iw * i / (pts.length - 1));
            final y = padT + ih * (1 - (pts[i].$2 - minV) / (maxV - minV));
            return Offset(x, y);
          }

          return CustomPaint(
            painter: _ChartPainter(
              pts: pts,
              pos: pos,
              minV: minV,
              maxV: maxV,
              grid: grid,
              lineColor: lineColor,
              textColor: textColor,
              hover: _hoverIndex,
              unit: widget.unit,
            ),
            child: Stack(
              children: [
                // 触摸热区
                Positioned.fill(
                  child: Listener(
                    onPointerMove: (e) => _hit(e.localPosition),
                    onPointerDown: (e) => _hit(e.localPosition),
                    onPointerUp: (_) => setState(() => _hoverIndex = null),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _hit(Offset local) {
    if (widget.points.isEmpty) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final padL = 34.0, padR = 10.0;
    final iw = size.width - padL - padR;
    final pts = widget.points;
    final idx = ((local.dx - padL) / iw * (pts.length - 1)).round().clamp(0, pts.length - 1);
    if (idx != _hoverIndex) setState(() => _hoverIndex = idx);
  }
}

class _ChartPainter extends CustomPainter {
  final List<(DateTime, double)> pts;
  final Offset Function(int) pos;
  final double minV, maxV;
  final Color grid, lineColor, textColor;
  final int? hover;
  final String unit;

  _ChartPainter({
    required this.pts,
    required this.pos,
    required this.minV,
    required this.maxV,
    required this.grid,
    required this.lineColor,
    required this.textColor,
    required this.hover,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 34.0, padR = 10.0, padT = 24.0, padB = 28.0;
    final ih = size.height - padT - padB;

    // 网格 + Y 轴标签
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = padT + ih * i / 4;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
      final v = maxV - (maxV - minV) * i / 4;
      _text(canvas, v.toStringAsFixed(1), Offset(padL - 6, y - 7),
          textColor, alignRight: true);
    }

    // X 轴日期标签（首/中/尾）
    if (pts.length > 1) {
      for (final i in [0, pts.length ~/ 2, pts.length - 1]) {
        final o = pos(i);
        _text(canvas, '${pts[i].$1.month}/${pts[i].$1.day}',
            Offset(o.dx, size.height - padB + 8), textColor,
            alignCenter: true);
      }
    } else {
      _text(canvas, '${pts[0].$1.month}/${pts[0].$1.day}',
          Offset(size.width / 2, size.height - padB + 8), textColor,
          alignCenter: true);
    }

    if (pts.length == 1) {
      final o = pos(0);
      canvas.drawCircle(o, 4.5, Paint()..color = lineColor);
      return;
    }

    // 折线
    final path = Path()..moveTo(pos(0).dx, pos(0).dy);
    for (var i = 1; i < pts.length; i++) {
      final o = pos(i);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = lineColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 数据点
    final dot = Paint()..color = lineColor;
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pos(i), 3.2, dot);
    }

    // 触摸提示
    if (hover != null && hover! >= 0 && hover! < pts.length) {
      final o = pos(hover!);
      canvas.drawCircle(o, 5.5, Paint()..color = lineColor);
      canvas.drawCircle(
          o, 8.5, Paint()..color = lineColor.withValues(alpha: 0.25));
      final label = '${pts[hover!].$2.toStringAsFixed(1)}$unit  ${pts[hover!].$1.month}/${pts[hover!].$1.day}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final tw = tp.width + 12;
      final th = tp.height + 8;
      var dx = o.dx - tw / 2;
      dx = dx.clamp(4.0, size.width - tw - 4);
      var dy = o.dy - th - 10;
      if (dy < 2) dy = o.dy + 12;
      final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, dy, tw, th), const Radius.circular(7));
      canvas.drawRRect(rr, Paint()..color = lineColor.withValues(alpha: 0.92));
      tp.paint(canvas, Offset(dx + 6, dy + 4));
    }
  }

  void _text(Canvas canvas, String s, Offset at, Color color,
      {bool alignRight = false, bool alignCenter = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? at.dx - tp.width
        : alignCenter
            ? at.dx - tp.width / 2
            : at.dx;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.hover != hover || old.pts != pts;
}
