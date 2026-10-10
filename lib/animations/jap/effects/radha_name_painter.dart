import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../jap_mantra_helper.dart';

/// Clean devotional Radha Name Reveal.
/// The sacred name "राधा" jumps into view with a joyful devotional bounce,
/// glows warmly in divine gold, and cleanly disappears.
/// Zero lingering petals, zero complex residual shapes.
class RadhaNamePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final Offset revealPoint;
  final double seed;

  RadhaNamePainter({
    required this.progress,
    required this.revealPoint,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final targetX = revealPoint.dx.clamp(45.0, size.width - 45.0);
    final targetY = revealPoint.dy.clamp(45.0, size.height - 45.0);

    // Animation timeline:
    // 0.0 to 0.40: Joyful devotional jump-in with bounce
    // 0.40 to 0.65: Sits and glows in radiant divine golden warmth
    // 0.65 to 0.95: Cleanly disappears / fades out
    double alpha = 1.0;
    double scale = 1.0;
    double jumpOffsetY = 0.0;

    if (progress < 0.40) {
      final t = (progress / 0.40).clamp(0.0, 1.0);
      scale = 0.40 + Curves.easeOutBack.transform(t) * 0.60;
      alpha = Curves.easeOutQuad.transform(t);
      // Arc jump
      jumpOffsetY = -30.0 * math.sin(t * math.pi);
    } else if (progress < 0.65) {
      final pulseT = (progress - 0.40) / 0.25;
      scale = 1.0 + math.sin(pulseT * math.pi * 2) * 0.04;
      alpha = 1.0;
      jumpOffsetY = 0.0;
    } else {
      final outT = ((progress - 0.65) / 0.30).clamp(0.0, 1.0);
      scale = 1.0 + (outT * 0.15);
      alpha = (1.0 - Curves.easeInQuad.transform(outT)).clamp(0.0, 1.0);
      jumpOffsetY = -15.0 * outT;
    }

    if (alpha <= 0.01) return;

    final center = Offset(targetX, targetY + jumpOffsetY);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    // Gentle radiant aura behind the text
    final glowRadius = 38.0;
    final glowRect = Rect.fromCircle(center: Offset.zero, radius: glowRadius);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: alpha * 0.45),
          const Color(0xFFFF8F00).withValues(alpha: alpha * 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(glowRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(Offset.zero, glowRadius, glowPaint);

    // Sacred name "राधा" in bold Devanagari typography
    final textSpan = TextSpan(
      text: 'राधा',
      style: JapMantraHelper.getMantraTextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w900,
        color: Colors.white.withValues(alpha: alpha),
        shadows: [
          Shadow(
            color: const Color(0xFFFFD700).withValues(alpha: alpha * 0.95),
            blurRadius: 18.0,
          ),
          Shadow(
            color: const Color(0xFFFF8F00).withValues(alpha: alpha * 0.85),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
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

  @override
  bool shouldRepaint(covariant RadhaNamePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.revealPoint != revealPoint;
}
