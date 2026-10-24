import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ram_path_calculator.dart';

/// Renders the single sacred glowing "राम" text emerging from the center of the circular mala
/// and traveling slowly along the curved trajectory to the target reveal position.
/// CRITICAL: Exactly ONE animated "राम" text exists at any given time.
class SingleRamFlightPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 over ~3.5 seconds
  final Offset malaCenter;
  final Offset targetPoint;
  final Size screenSize;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  SingleRamFlightPainter({
    required this.progress,
    required this.malaCenter,
    required this.targetPoint,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // 1. Build and measure the trajectory path from the center of the mala to the target
    final path = RamPathCalculator.computeTrajectoryPath(
      screenSize: size,
      malaCenter: malaCenter,
      targetPoint: targetPoint,
    );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final totalLength = metric.length;

    // 2. Slow & Divine Multi-Phase Timeline:
    // 0.00..0.15: Emergence at center of circular mala with expanding golden ripple ring
    // 0.15..0.65: Slow upward movement towards the top
    // 0.65..0.80: Smooth curved bend towards the right / target position
    // 0.80..0.90: Arrival pause at target with radiant golden bloom burst
    // 0.90..1.00: Gentle dissolution into golden light

    double currentDistance = 0.0;
    double opacity = 1.0;
    double scale = 1.0;

    if (progress < 0.15) {
      final t = (progress / 0.15).clamp(0.0, 1.0);
      currentDistance = 0.0;
      opacity = Curves.easeOut.transform(t);
      scale = 0.45 + (0.55 * t);

      // Draw expanding golden ripple ring at the center of the circular mala
      final double rippleRadius = 14.0 + (36.0 * t);
      final double rippleAlpha = (1.0 - t) * 0.75;
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFFFB300).withValues(alpha: rippleAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawCircle(malaCenter, rippleRadius, ripplePaint);
    } else if (progress < 0.65) {
      // Slow upward movement out of the mala
      final t = ((progress - 0.15) / 0.50).clamp(0.0, 1.0);
      final curvedT = Curves.easeInOutCubic.transform(t);
      currentDistance = totalLength * (curvedT * 0.72);
      opacity = 1.0;
      scale = 1.0 + (0.06 * math.sin(t * math.pi));
    } else if (progress < 0.80) {
      // Smooth curved bend towards the right / target
      final t = ((progress - 0.65) / 0.15).clamp(0.0, 1.0);
      final curvedT = Curves.easeInOutQuad.transform(t);
      currentDistance = totalLength * (0.72 + (0.28 * curvedT));
      opacity = 1.0;
      scale = 1.0;
    } else if (progress < 0.90) {
      // Arrival pause & radiant bloom at target point
      currentDistance = totalLength;
      final t = ((progress - 0.80) / 0.10).clamp(0.0, 1.0);
      opacity = 1.0;
      scale = 1.0 + (0.16 * math.sin(t * math.pi)); // Gentle arrival breathing pulse
    } else {
      // Slow fade-out and dissolution into golden dust
      currentDistance = totalLength;
      final t = ((progress - 0.90) / 0.10).clamp(0.0, 1.0);
      opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
      scale = 1.0 - (0.15 * t);
    }

    final tangent = metric.getTangentForOffset(currentDistance);
    final currentPos = tangent?.position ?? malaCenter;

    // 3. Draw subtle, elegant golden particle trail trailing behind moving "राम"
    if (progress >= 0.14 && progress < 0.88) {
      const int particleCount = 9;
      final trailPaint = Paint()..style = PaintingStyle.fill;

      for (int i = 1; i <= particleCount; i++) {
        final lagDistance = math.max(0.0, currentDistance - (i * 14.0));
        final lagTangent = metric.getTangentForOffset(lagDistance);
        if (lagTangent != null) {
          final pRatio = 1.0 - (i / (particleCount + 1));
          final pAlpha = (pRatio * 0.80 * opacity).clamp(0.0, 1.0);
          final pRadius = math.max(1.0, 3.4 * pRatio);

          // Alternating warm saffron and gold sparks
          final pColor = (i % 2 == 0)
              ? const Color(0xFFFFD700)
              : const Color(0xFFFF9900);

          trailPaint.color = pColor.withValues(alpha: pAlpha);
          canvas.drawCircle(lagTangent.position, pRadius, trailPaint);

          // Subtle spark halo
          trailPaint.color = pColor.withValues(alpha: pAlpha * 0.35);
          canvas.drawCircle(lagTangent.position, pRadius * 2.2, trailPaint);
        }
      }
    }

    // 4. Draw arrival golden bloom burst at target point
    if (progress >= 0.78) {
      final burstT = ((progress - 0.78) / 0.22).clamp(0.0, 1.0);
      final burstRadius = 24.0 + (50.0 * burstT);
      final burstAlpha = ((1.0 - burstT) * 0.88).clamp(0.0, 1.0);

      final burstPaint = Paint()
        ..shader = ui.Gradient.radial(
          targetPoint,
          burstRadius,
          [
            const Color(0xFFFFE082).withValues(alpha: burstAlpha),
            const Color(0xFFFF9900).withValues(alpha: burstAlpha * 0.50),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(targetPoint, burstRadius, burstPaint);
    }

    // 5. Draw glowing saffron-gold outer aura behind the single "राम"
    final haloPaint = Paint()
      ..shader = ui.Gradient.radial(
        currentPos,
        32.0 * scale,
        [
          const Color(0xFFFFB300).withValues(alpha: 0.68 * opacity),
          const Color(0xFFFF7700).withValues(alpha: 0.28 * opacity),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(currentPos, 32.0 * scale, haloPaint);

    // 6. Draw the single glowing Devanagari "राम"
    _textPainter.text = TextSpan(
      text: 'राम',
      style: GoogleFonts.notoSerifDevanagari(
        fontSize: 34.0 * scale,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFFF8E1).withValues(alpha: opacity),
        shadows: [
          Shadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.95 * opacity),
            blurRadius: 20.0,
          ),
          Shadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.90 * opacity),
            blurRadius: 10.0,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.60 * opacity),
            blurRadius: 4.0,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
    );

    _textPainter.layout();
    final textOffset = Offset(
      currentPos.dx - (_textPainter.width / 2),
      currentPos.dy - (_textPainter.height / 2),
    );
    _textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant SingleRamFlightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.malaCenter != malaCenter ||
        oldDelegate.targetPoint != targetPoint ||
        oldDelegate.screenSize != screenSize;
  }
}
