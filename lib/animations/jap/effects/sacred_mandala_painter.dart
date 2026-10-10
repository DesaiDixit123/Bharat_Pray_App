import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Divine Sacred Mandala & Yantra Formation Painter.
/// Unfolds a radiant sacred geometric Sri Yantra mandala at [revealPoint]
/// featuring dual counter-rotating sacred lotus chakras, radiating sunburst beams,
/// beaded golden rings, and an illuminated central sacred Bindu/Om.
class SacredMandalaPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final Offset revealPoint;
  final double seed;

  SacredMandalaPainter({
    required this.progress,
    required this.revealPoint,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final targetX = revealPoint.dx.clamp(45.0, size.width - 45.0);
    final targetY = revealPoint.dy.clamp(45.0, size.height - 45.0);
    final center = Offset(targetX, targetY);

    double alpha = 1.0;
    double scale = 1.0;

    if (progress < 0.30) {
      final t = (progress / 0.30).clamp(0.0, 1.0);
      scale = Curves.easeOutBack.transform(t);
      alpha = Curves.easeOutQuad.transform(t);
    } else if (progress < 0.70) {
      final pulseT = (progress - 0.30) / 0.40;
      scale = 1.0 + math.sin(pulseT * math.pi * 2) * 0.03;
      alpha = 1.0;
    } else {
      final outT = ((progress - 0.70) / 0.30).clamp(0.0, 1.0);
      scale = 1.0 + (outT * 0.20);
      alpha = (1.0 - Curves.easeInQuad.transform(outT)).clamp(0.0, 1.0);
    }

    if (alpha <= 0.01) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    // 1. Radiant central golden aura
    final auraRadius = 42.0;
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: alpha * 0.45),
          const Color(0xFFFF9800).withValues(alpha: alpha * 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: auraRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(Offset.zero, auraRadius, auraPaint);

    // 2. Divine Radiating Sun Rays (16 Golden Beams)
    final rayCount = 16;
    final rayRotation = progress * 0.35;
    final rayLength = 36.0 + math.sin(progress * math.pi * 4) * 4.0;
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) + rayRotation;
      final p1 = Offset(math.cos(angle) * 22.0, math.sin(angle) * 22.0);
      final p2 = Offset(math.cos(angle) * rayLength, math.sin(angle) * rayLength);
      canvas.drawLine(p1, p2, rayPaint);
    }

    // 3. Outer 12-Petal Sacred Lotus Chakra (Rotating Counter-Clockwise)
    final outerPetalCount = 12;
    final outerRotation = -progress * 0.50;
    final outerPetalLength = 30.0;

    final outerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.90);

    for (int i = 0; i < outerPetalCount; i++) {
      final angle = (i * 2 * math.pi / outerPetalCount) + outerRotation;
      canvas.save();
      canvas.rotate(angle);

      final petalPath = Path()
        ..moveTo(0, 16.0)
        ..quadraticBezierTo(7.0, 23.0, 0, outerPetalLength)
        ..quadraticBezierTo(-7.0, 23.0, 0, 16.0);

      canvas.drawPath(petalPath, outerStroke);
      canvas.restore();
    }

    // 4. Beaded Golden Pearl Ring (16 Sacred Golden Dots)
    final dotCount = 16;
    final dotRingRadius = 20.0;
    final dotPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: alpha * 0.95);

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi / dotCount) + outerRotation;
      final px = math.cos(angle) * dotRingRadius;
      final py = math.sin(angle) * dotRingRadius;
      canvas.drawCircle(Offset(px, py), 1.5, dotPaint);
    }

    // Concentric Golden Rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.85);
    canvas.drawCircle(Offset.zero, 16.0, ringPaint);
    canvas.drawCircle(Offset.zero, 24.0, ringPaint);

    // 5. Inner 8-Star Sacred Sri Yantra Geometry (Rotating Clockwise)
    final innerRotation = progress * 0.65;
    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: alpha * 0.95);

    canvas.save();
    canvas.rotate(innerRotation);
    // Two interlocking equilateral squares / 8-pointed star
    final starSize = 12.0;
    final r1 = Rect.fromCenter(center: Offset.zero, width: starSize * 2, height: starSize * 2);
    canvas.drawRect(r1, innerStroke);
    canvas.save();
    canvas.rotate(math.pi / 4);
    canvas.drawRect(r1, innerStroke);
    canvas.restore();
    canvas.restore();

    // 6. Central Glowing Bindu with Sacred Om Glyph
    final binduPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset.zero, 4.0, binduPaint);

    final omSpan = TextSpan(
      text: 'ॐ',
      style: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha: alpha),
        shadows: [
          Shadow(
            color: const Color(0xFFFFD700).withValues(alpha: alpha),
            blurRadius: 8.0,
          ),
        ],
      ),
    );
    final omTp = TextPainter(
      text: omSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    omTp.paint(canvas, Offset(-omTp.width / 2, -omTp.height / 2));

    canvas.restore();

    // 7. Shimmering Golden Yantra Dust Particles
    _drawYantraDust(canvas, center, progress, alpha);
  }

  void _drawYantraDust(Canvas canvas, Offset center, double t, double alpha) {
    const int count = 12;
    for (int i = 0; i < count; i++) {
      final pSeed = seed + (i * 0.85);
      final angle = (i * 2 * math.pi / count) + (t * 2.5) + pSeed;
      final dist = 28.0 + (t * 28.0) + (i % 5) * 3.0;

      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;

      final pAlpha = (math.sin(t * math.pi) * 0.80 * alpha).clamp(0.0, 1.0);
      if (pAlpha <= 0.01) continue;

      final pPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: pAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(px, py), 1.8, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SacredMandalaPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.revealPoint != revealPoint;
}
