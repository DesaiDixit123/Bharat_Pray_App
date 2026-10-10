import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../jap_mantra_helper.dart';

/// Animated devotional overlay where the sacred chant "राम राम" spreads across the screen:
/// - One prominent large "राम राम" in the center + 6 well-spaced spots.
/// - In the second phase, all words float and smoothly move across the screen into [revealPoint]!
/// - Merges into a burst of golden light at [revealPoint].
class RamSpreadPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final Offset revealPoint;
  final double seed;

  RamSpreadPainter({
    required this.progress,
    required this.revealPoint,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final rng = math.Random((seed * 9999).toInt());

    // 1. Initial scattered positions for the 6 surrounding spots + 1 large center spot
    final List<_RamSpot> initialSpots = [
      _RamSpot(
        offset: Offset(size.width * 0.50, size.height * 0.48),
        fontSize: 36.0,
        isCenter: true,
        text: 'राम राम',
      ),
      _RamSpot(
        offset: Offset(
          size.width * 0.22 + (rng.nextDouble() - 0.5) * 16.0,
          size.height * 0.18 + (rng.nextDouble() - 0.5) * 16.0,
        ),
        fontSize: 19.0,
        isCenter: false,
        text: 'राम राम',
      ),
      _RamSpot(
        offset: Offset(
          size.width * 0.78 + (rng.nextDouble() - 0.5) * 16.0,
          size.height * 0.20 + (rng.nextDouble() - 0.5) * 16.0,
        ),
        fontSize: 20.0,
        isCenter: false,
        text: 'राम राम',
      ),
      _RamSpot(
        offset: Offset(
          size.width * 0.18 + (rng.nextDouble() - 0.5) * 16.0,
          size.height * 0.60 + (rng.nextDouble() - 0.5) * 16.0,
        ),
        fontSize: 18.0,
        isCenter: false,
        text: 'राम राम',
      ),
      _RamSpot(
        offset: Offset(
          size.width * 0.82 + (rng.nextDouble() - 0.5) * 16.0,
          size.height * 0.58 + (rng.nextDouble() - 0.5) * 16.0,
        ),
        fontSize: 19.0,
        isCenter: false,
        text: 'राम राम',
      ),
      _RamSpot(
        offset: Offset(
          size.width * 0.26 + (rng.nextDouble() - 0.5) * 16.0,
          size.height * 0.82 + (rng.nextDouble() - 0.5) * 16.0,
        ),
        fontSize: 18.0,
        isCenter: false,
        text: 'राम राम',
      ),
      _RamSpot(
        offset: Offset(
          size.width * 0.74 + (rng.nextDouble() - 0.5) * 16.0,
          size.height * 0.80 + (rng.nextDouble() - 0.5) * 16.0,
        ),
        fontSize: 20.0,
        isCenter: false,
        text: 'राम राम',
      ),
    ];

    // Master timeline:
    // 0.0 to 0.35: Scale in & appear at their spots
    // 0.35 to 0.80: All words float and move smoothly towards revealPoint!
    // 0.80 to 1.0: Merge and dissolve into light burst at revealPoint
    double alpha = 1.0;
    double convergenceT = 0.0;

    if (progress < 0.35) {
      final inT = (progress / 0.35).clamp(0.0, 1.0);
      alpha = Curves.easeOutQuad.transform(inT);
      convergenceT = 0.0;
    } else if (progress < 0.80) {
      alpha = 1.0;
      final moveT = (progress - 0.35) / 0.45;
      convergenceT = Curves.easeInOutCubic.transform(moveT);
    } else {
      final outT = ((progress - 0.80) / 0.20).clamp(0.0, 1.0);
      alpha = (1.0 - Curves.easeInQuad.transform(outT)).clamp(0.0, 1.0);
      convergenceT = 1.0;
    }

    if (alpha <= 0.01) return;

    final targetX = revealPoint.dx.clamp(40.0, size.width - 40.0);
    final targetY = revealPoint.dy.clamp(40.0, size.height - 40.0);
    final target = Offset(targetX, targetY);

    // 2. Render each floating Ram Ram word moving towards revealPoint
    for (int i = 0; i < initialSpots.length; i++) {
      final spot = initialSpots[i];

      // Interpolate position from origin towards target with floating wave
      final floatWave = math.sin((progress * 7.0) + (i * 1.2)) * (1.0 - convergenceT) * 8.0;
      final curX = spot.offset.dx + (target.dx - spot.offset.dx) * convergenceT;
      final curY = spot.offset.dy + (target.dy - spot.offset.dy) * convergenceT + floatWave;

      final curScale = (1.0 - convergenceT * 0.35) * (spot.isCenter ? 1.0 : 0.88);
      final spotAlpha = (alpha * (spot.isCenter ? 1.0 : 0.85)).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(curX, curY);
      canvas.scale(curScale, curScale);

      // Golden halo behind text
      final glowRadius = spot.fontSize * 1.3;
      final glowRect = Rect.fromCircle(center: Offset.zero, radius: glowRadius);
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: spotAlpha * 0.35),
            const Color(0xFFFF8F00).withValues(alpha: spotAlpha * 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(glowRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(Offset.zero, glowRadius, haloPaint);

      // Text painter
      final textSpan = TextSpan(
        text: spot.text,
        style: JapMantraHelper.getMantraTextStyle(
          fontSize: spot.fontSize,
          fontWeight: spot.isCenter ? FontWeight.w900 : FontWeight.bold,
          color: Colors.white.withValues(alpha: spotAlpha),
          shadows: [
            Shadow(
              color: const Color(0xFFFFD700).withValues(alpha: spotAlpha * 0.95),
              blurRadius: 14.0,
            ),
            Shadow(
              color: const Color(0xFFFF8F00).withValues(alpha: spotAlpha * 0.80),
              blurRadius: 8.0,
            ),
          ],
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // 3. Golden burst when all words merge into revealPoint (0.70 to 0.98)
    if (progress >= 0.70) {
      final burstT = ((progress - 0.70) / 0.28).clamp(0.0, 1.0);
      final burstAlpha = (math.sin(burstT * math.pi) * 0.85).clamp(0.0, 0.85);

      if (burstAlpha > 0.01) {
        final burstRadius = 14.0 + (burstT * 28.0);
        final burstPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: burstAlpha),
              const Color(0xFFFFD700).withValues(alpha: burstAlpha * 0.8),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 1.0],
          ).createShader(Rect.fromCircle(center: target, radius: burstRadius))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(target, burstRadius, burstPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RamSpreadPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.revealPoint != revealPoint;
}

class _RamSpot {
  final Offset offset;
  final double fontSize;
  final bool isCenter;
  final String text;

  _RamSpot({
    required this.offset,
    required this.fontSize,
    required this.isCenter,
    required this.text,
  });
}
