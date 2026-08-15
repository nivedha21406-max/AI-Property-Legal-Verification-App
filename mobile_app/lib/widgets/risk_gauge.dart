import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiskGauge extends StatelessWidget {
  final double score; // 0-100
  final String level;
  final double size;

  const RiskGauge({super.key, required this.score, required this.level, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riskColor(level);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(score: score, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w800, color: color),
              ),
              Text(
                level,
                style: TextStyle(
                  fontSize: size * 0.09,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = -pi * 1.25;
    const sweepTotal = pi * 1.5;

    final bgPaint = Paint()
      ..color = const Color(0xFFE9EBF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepTotal, false, bgPaint);
    final sweep = sweepTotal * (score.clamp(0, 100) / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
