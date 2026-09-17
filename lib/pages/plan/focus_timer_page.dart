import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../widgets/particle_burst.dart';

/// V1.7 番茄钟：25/5 专注计时，完成触发粒子与震动
class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage>
    with TickerProviderStateMixin {
  static const _presets = [15, 25, 45];
  int _minutes = 25;
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;
  bool _breakMode = false;
  Timer? _timer;
  late final AnimationController _ringCtrl;
  int _focusCount = 0;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  void _setMinutes(int m) {
    if (_running) return;
    setState(() {
      _minutes = m;
      _remaining = Duration(minutes: m);
      _breakMode = false;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          t.cancel();
          _running = false;
          _onComplete();
        }
      });
    });
  }

  void _onComplete() {
    Haptics.success();
    if (mounted) ParticleOverlay.show(context);
    setState(() {
      _focusCount++;
      _breakMode = !_breakMode;
      _minutes = _breakMode ? 5 : _presets.contains(_minutes) ? _minutes : 25;
      _remaining = Duration(minutes: _minutes);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_breakMode ? '☕ 专注完成，休息 5 分钟' : '🌱 休息结束，开始下一轮专注'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = Duration(minutes: _minutes);
    });
  }

  String get _mmss {
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _ratio => _remaining.inSeconds /
      (Duration(minutes: _minutes).inSeconds.clamp(1, 9999));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tc = dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final sc = dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);
    final color = _breakMode ? AppColors.sage : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_breakMode ? '休息中' : '番茄钟'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(children: [
        const SizedBox(height: 10),
        // 预设时长
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final m in _presets) ...[
              ChoiceChip(
                label: Text('$m 分钟', style: const TextStyle(fontSize: 12.5)),
                selected: _minutes == m && !_breakMode,
                onSelected: (_) => _setMinutes(m),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 24),
        // 圆环计时
        SizedBox(
          width: 240,
          height: 240,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _ratio),
            duration: const Duration(milliseconds: 500),
            builder: (context, v, _) => AnimatedBuilder(
              animation: _ringCtrl,
              builder: (context, _) {
                final pulse = _running ? 1.0 + _ringCtrl.value * 0.02 : 1.0;
                return Transform.scale(
                  scale: pulse,
                  child: CustomPaint(
                    painter: _TimerRingPainter(v, color, dark),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_mmss,
                              style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: tc,
                                  fontFeatures: const [FontFeature.tabularFigures()])),
                          const SizedBox(height: 4),
                          Text(_breakMode ? '休息一下' : '专注中 · 第 $_focusCount 轮',
                              style: TextStyle(fontSize: 12, color: sc)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _reset,
              icon: const Icon(Icons.replay),
              iconSize: 22,
              tooltip: '重置',
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 92,
              height: 92,
              child: FilledButton(
                onPressed: _toggle,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(_running ? Icons.pause : Icons.play_arrow,
                    size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            IconButton.filledTonal(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('番茄钟'),
                    content: const Text('番茄工作法：25 分钟专注 + 5 分钟休息循环。\n专注时手机放远一点效果更好。'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('知道了')),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              iconSize: 22,
              tooltip: '说明',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('完成 $_focusCount 轮专注 · 累计 ${_focusCount * _minutes} 分钟',
            style: TextStyle(fontSize: 12, color: sc)),
      ]),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double ratio;
  final Color color;
  final bool dark;

  _TimerRingPainter(this.ratio, this.color, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 10;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = dark ? const Color(0xFF333A46) : const Color(0xFFEDEDEB);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        math.pi * 2 * ratio, false, fg);
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.ratio != ratio || old.color != color;
}
