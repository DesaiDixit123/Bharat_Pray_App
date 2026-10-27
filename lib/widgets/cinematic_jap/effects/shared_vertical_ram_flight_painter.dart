import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders a single sacred glowing "राम" Devanagari text that moves slowly
/// upward in a straight, peaceful vertical path for the 4 new animation effects.
///
/// CRITICAL SPECIFICATION (Section 3A of Master Prompt):
/// - Only ONE moving "राम" text at a time.
/// - Straight vertical path from bottom to top.
/// - Saffron-gold colour with soft divine glow.
/// - Smooth arrival bloom and fade-out.
class SharedVerticalRamFlightPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Offset startPoint;
  final Offset targetPoint;
  final Size screenSize;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  SharedVerticalRamFlightPainter({
    required this.progress,
    required this.startPoint,
    required this.targetPoint,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // Straight vertical path: x matches startPoint.dx, y travels from startPoint.dy to targetPoint.dy
    final double startY = startPoint.dy;
    final double endY = targetPoint.dy;
    final double verticalX = startPoint.dx;
    final double totalDistance = (startY - endY).abs();

    double currentY = startY;
    double opacity = 1.0;
    double scale = 1.0;

    // Multi-phase smooth timeline:
    // 0.00..0.12: Emergence & fade-in with soft golden ripple
    // 0.12..0.72: Meditative, constant upward straight vertical translation
    // 0.72..0.88: Arrival pause & soft radiant golden bloom
    // 0.88..1.00: Smooth fade-out
    if (progress < 0.12) {
      final t = (progress / 0.12).clamp(0.0, 1.0);
      currentY = startY;
      opacity = Curves.easeOut.transform(t);
      scale = 0.50 + (0.50 * t);

      // Expanding golden baseline ripple ring
      final double rippleRadius = 12.0 + (32.0 * t);
      final double rippleAlpha = (1.0 - t) * 0.70;
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFFFFB300).withValues(alpha: rippleAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(Offset(verticalX, startY), rippleRadius, ripplePaint);
    } else if (progress < 0.72) {
      final t = ((progress - 0.12) / 0.60).clamp(0.0, 1.0);
      final curvedT = Curves.easeInOutCubic.transform(t);
      currentY = startY - (totalDistance * curvedT);
      opacity = 1.0;
      scale = 1.0 + (0.05 * math.sin(t * math.pi));
    } else if (progress < 0.88) {
      currentY = endY;
      final t = ((progress - 0.72) / 0.16).clamp(0.0, 1.0);
      opacity = 1.0;
      scale = 1.0 + (0.12 * math.sin(t * math.pi));
    } else {
      currentY = endY;
      final t = ((progress - 0.88) / 0.12).clamp(0.0, 1.0);
      opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
      scale = 1.0 - (0.15 * t);
    }

    final currentPos = Offset(verticalX, currentY);

    // Subtle, elegant vertical trailing golden sparks
    if (progress >= 0.12 && progress < 0.86) {
      const int particleCount = 8;
      final sparkPaint = Paint()..style = PaintingStyle.fill;

      for (int i = 1; i <= particleCount; i++) {
        final sparkY = currentY + (i * 12.0);
        if (sparkY <= startY) {
          final pRatio = 1.0 - (i / (particleCount + 1));
          final pAlpha = (pRatio * 0.75 * opacity).clamp(0.0, 1.0);
          final pRadius = math.max(1.0, 3.0 * pRatio);
          final pColor = (i % 2 == 0)
              ? const Color(0xFFFFD700)
              : const Color(0xFFFF9900);

          sparkPaint.color = pColor.withValues(alpha: pAlpha);
          canvas.drawCircle(Offset(verticalX, sparkY), pRadius, sparkPaint);
        }
      }
    }

    // Soft arrival golden bloom burst
    if (progress >= 0.72) {
      final burstT = ((progress - 0.72) / 0.28).clamp(0.0, 1.0);
      final burstRadius = 20.0 + (45.0 * burstT);
      final burstAlpha = ((1.0 - burstT) * 0.80).clamp(0.0, 1.0);

      final burstPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(verticalX, endY),
          burstRadius,
          [
            const Color(0xFFFFE082).withValues(alpha: burstAlpha),
            const Color(0xFFFF9900).withValues(alpha: burstAlpha * 0.45),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(Offset(verticalX, endY), burstRadius, burstPaint);
    }

    // Soft saffron-gold outer aura behind "राम"
    final haloPaint = Paint()
      ..shader = ui.Gradient.radial(
        currentPos,
        36.0 * scale,
        [
          const Color(0xFFFFB300).withValues(alpha: 0.65 * opacity),
          const Color(0xFFFF7700).withValues(alpha: 0.35 * opacity),
          Colors.transparent,
        ],
        [0.0, 0.50, 1.0],
      );
    canvas.drawCircle(currentPos, 36.0 * scale, haloPaint);

    // Layout and render single "राम" text
    _textPainter.text = TextSpan(
      text: 'राम',
      style: GoogleFonts.notoSerifDevanagari(
        fontSize: 25.0 * scale,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFFF8E7).withValues(alpha: opacity),
        shadows: [
          Shadow(
            color: const Color(0xFFFF9900).withValues(alpha: 0.95 * opacity),
            blurRadius: 18.0,
          ),
          Shadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.85 * opacity),
            blurRadius: 10.0,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.80 * opacity),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
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
  bool shouldRepaint(covariant SharedVerticalRamFlightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.targetPoint != targetPoint;
  }
}
