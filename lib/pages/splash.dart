import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'shell.dart';

/// 启动屏：品牌标识 + 解夏制作
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ShellPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween(begin: 0.82, end: 1.0).animate(
                    CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)),
                child: const _LogoMark(size: 88),
              ),
            ),
            const SizedBox(height: 26),
            FadeTransition(
              opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
              child: Text('Control',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      color: textColor)),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
              child: Text('掌控每一天的自律',
                  style: TextStyle(fontSize: 13, color: subColor, letterSpacing: 2)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            '解夏制作  v1.8',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: subColor, letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}

/// 品牌 Logo：日冕同心环，外环=自律闭环，暖橙弧=掌控进度，中心点=当下
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final padding = r * 0.10;
    final rOut = r - padding;

    // V1.4 小太阳：8 条光芒 + 中心暖橙圆
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rOut * 0.14
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round;
    final r0 = rOut * 0.42;
    final r1 = rOut * 0.78;
    for (var i = 0; i < 8; i++) {
      final a = (math.pi * 2 / 8) * i;
      final dx = math.cos(a);
      final dy = math.sin(a);
      canvas.drawLine(c + Offset(r0 * dx, r0 * dy),
          c + Offset(r1 * dx, r1 * dy), rayPaint);
    }

    // 中心圆（暖杏橙焦点）
    canvas.drawCircle(c, rOut * 0.30, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}
