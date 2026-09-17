import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 粒子爆发（V1.6）：从触发点飞出与当前皮肤同色系的小粒子。
/// 用法：包住触发 widget，调用 [burst] 播放一次。
class ParticleBurst extends StatefulWidget {
  final Widget child;
  const ParticleBurst({super.key, required this.child});

  /// 从子节点 context 找到最近的粒子宿主并触发一次爆发
  static bool maybeOf(BuildContext context) {
    final s = context.findAncestorStateOfType<_ParticleBurstState>();
    if (s == null) return false;
    s.burst();
    return true;
  }

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 播放一次粒子爆发
  void burst() {
    setState(() => _active = true);
    _ctrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_active)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(120, 120),
                painter: _BurstPainter(_ctrl.value,
                    color: AppColors.primary,
                    accent: AppColors.accent,
                    rose: AppColors.rose),
              );
            },
          ),
      ],
    );
  }
}

/// 粒子画笔：12 颗粒子向外飞散 + 收缩 + 淡出
class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;
  final Color accent;
  final Color rose;

  _BurstPainter(this.t, {required this.color, required this.accent, required this.rose});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final palette = [color, accent, rose, AppColors.sage];
    final rand = math.Random(7);
    for (var i = 0; i < 12; i++) {
      final a = (math.pi * 2 / 12) * i + (rand.nextDouble() - 0.5) * 0.4;
      final dist = 10 + t * 46;
      final r = (3.2 * (1 - t) + 0.8).clamp(0.5, 6.0);
      final p = palette[i % palette.length].withValues(alpha: (1 - t) * 0.9);
      canvas.drawCircle(
        c + Offset(math.cos(a) * dist, math.sin(a) * dist),
        r,
        Paint()..color = p,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// 首页顶部低透明度浮动光点（V1.6）：缓慢上浮 + 呼吸，不干扰阅读。
class FloatingParticles extends StatefulWidget {
  final double height;
  const FloatingParticles({super.key, this.height = 120});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _FloatingPainter(_ctrl.value,
                color: AppColors.accent.withValues(alpha: 0.35)),
          );
        },
      ),
    );
  }
}

/// 全屏粒子覆盖层：在页面中心弹出 16 颗当前皮肤色粒子，自动消失
class ParticleOverlay {
  ParticleOverlay._();

  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        return IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 650),
            onEnd: () => entry.remove(),
            builder: (ctx, t, _) {
              return SizedBox.expand(
                child: CustomPaint(painter: _OverlayPainter(t)),
              );
            },
          ),
        );
      },
    );
    overlay.insert(entry);
  }
}

class _OverlayPainter extends CustomPainter {
  final double t;
  _OverlayPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height * 0.35;
    final palette = [
      AppColors.primary, AppColors.accent, AppColors.sage, AppColors.rose,
      AppColors.accent, AppColors.primary, AppColors.sage,
    ];
    final rand = math.Random(13);
    for (var i = 0; i < 16; i++) {
      final a = (math.pi * 2 / 16) * i + (rand.nextDouble() - 0.5) * 0.5;
      final dist = 14 + t * 90;
      final r = (5.0 * (1 - t) + 0.6).clamp(0.8, 7.0);
      final dx = cx + math.cos(a) * dist;
      final dy = cy + math.sin(a) * dist * 0.6;
      final alpha = (1 - t) * 0.85;
      canvas.drawCircle(
        Offset(dx, dy), r,
        Paint()..color = palette[i % palette.length].withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.t != t;
}
/// 16 颗光点：缓慢上浮 + 横向微摆 + 闪烁
class _FloatingPainter extends CustomPainter {
  final double t;
  final Color color;

  _FloatingPainter(this.t, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final palette = [color, AppColors.primary.withValues(alpha: 0.25), AppColors.rose.withValues(alpha: 0.30)];
    for (var i = 0; i < 16; i++) {
      final phase = rand.nextDouble();
      final x = rand.nextDouble() * size.width;
      final yBase = rand.nextDouble() * size.height;
      final speed = 0.4 + rand.nextDouble() * 0.8;
      // 上浮：t 周期循环，y 从底部缓慢移到顶部
      final y = (yBase - t * speed * size.height) % size.height;
      final wobble = math.sin(t * math.pi * 2 * (1 + rand.nextDouble()) + phase * 6) * 6;
      final alpha = (math.sin(t * math.pi * 2 * 2 + phase * 4) * 0.5 + 0.5) * 0.5 + 0.15;
      final r = 1.2 + rand.nextDouble() * 2.2;
      canvas.drawCircle(
        Offset(x + wobble, y),
        r,
        Paint()
          ..color = palette[i % palette.length].withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_FloatingPainter old) => old.t != t;
}
