import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// 关于页：版本 + 简介 + 解夏制作（连续点击 logo 5 次触发彩蛋）
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _tapCount = 0;
  DateTime _firstTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _onLogoTap() {
    final now = DateTime.now();
    // 2 秒内连续点击才计数
    if (now.difference(_firstTap).inSeconds > 2) {
      _tapCount = 0;
    }
    _firstTap = now;
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      _showEgg();
    } else if (_tapCount >= 3) {
      Haptics.tap(); // 反馈即将触发
    }
  }

  void _showEgg() {
    Haptics.success();
    showToast(context, '你发现了彩蛋 · 每个小坚持，都值得被记住');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        dark ? const Color(0xFFE9EBEF) : const Color(0xFF3C434E);
    final subColor =
        dark ? const Color(0xFF9AA1AC) : const Color(0xFF8B919B);

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        children: [
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _onLogoTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF2C313B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: dark
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF7C8B9D).withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: CustomPaint(
                  painter: _AboutLogoPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text('Control',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: textColor)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('v1.8',
                style: TextStyle(fontSize: 13, color: subColor)),
          ),
          const SizedBox(height: 24),
          Text(
            'Control 是一款极简自律管理应用，将每日计划、饮食记录、健身训练与身体数据整合于一体，'
            '打造个人自律控制中心。所有数据仅保存在本机，无注册、无广告、完全离线可用。',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5,
                height: 1.7,
                color: dark
                    ? const Color(0xFFC5CBD4)
                    : const Color(0xFF5C636E)),
          ),
          const SizedBox(height: 10),
          Text(
            '支持：计划打卡与重复习惯 · 200+ 食物营养库 · 三/四/五分化训练模板 · 体重趋势 · 数据备份恢复',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, height: 1.6, color: subColor),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Container(
                  width: 3,
                  height: 26,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text('解夏制作',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('以克制与温度，陪伴你的自律',
                    style: TextStyle(fontSize: 11, color: subColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final rOut = r * 0.88;

    // V1.4 小太阳：8 条光芒 + 中心暖橙圆
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rOut * 0.12
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round;
    final r0 = rOut * 0.44;
    final r1 = rOut * 0.80;
    for (var i = 0; i < 8; i++) {
      final a = (math.pi * 2 / 8) * i;
      final dx = math.cos(a);
      final dy = math.sin(a);
      canvas.drawLine(c + Offset(r0 * dx, r0 * dy),
          c + Offset(r1 * dx, r1 * dy), rayPaint);
    }

    // 中心暖橙圆
    canvas.drawCircle(c, rOut * 0.28, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(_AboutLogoPainter old) => false;
}
