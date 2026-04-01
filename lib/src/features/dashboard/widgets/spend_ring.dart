import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_typography.dart';
import '../../../core/money.dart';

class SpendRing extends StatelessWidget {
  const SpendRing({
    super.key,
    required this.spentCents,
    required this.limitCents,
    required this.limitLabel,
  });

  final int spentCents;
  final int limitCents;
  final String limitLabel;

  @override
  Widget build(BuildContext context) {
    final pct = limitCents <= 0 ? 0.0 : spentCents / limitCents;
    final usedLabel = '${(pct * 100).round()}% used';

    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = (screenWidth * 0.42).clamp(140.0, 200.0);
    final mainFontSize = (ringSize * 0.12).clamp(16.0, 24.0);
    final subFontSize = (ringSize * 0.055).clamp(9.0, 11.0);

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: CustomPaint(
        painter: _RingPainter(pct: pct),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Money.formatCents(spentCents),
                style: AppTypography.serifAmount(
                  size: mainFontSize,
                  color: AppColors.text,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of ${Money.formatCents(limitCents)} $limitLabel',
                style: AppTypography.monoLabel(size: subFontSize, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
              ),
              const SizedBox(height: 4),
              Text(
                usedLabel,
                style: AppTypography.monoLabel(size: subFontSize, color: AppColors.green, weight: FontWeight.w600, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.pct});

  final double pct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 12;
    const stroke = 14.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.card
      ..strokeCap = StrokeCap.round;

    final okPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.green
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, r, bgPaint);

    final start = -math.pi / 2;

    if (pct <= 0) return;

    final capped = pct.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, 2 * math.pi * capped, false, okPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct;
}

