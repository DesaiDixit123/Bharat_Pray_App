import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vibrant, intense Divine Energy Formation Painter.
/// Intense celestial cosmic light sparks and energetic radiant beams
/// converge sharply into [revealPoint] and detonate into a blazing golden shockwave.
/// Strictly restricted within the card border so nothing bleeds outside.
class DivineEnergyPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final Offset revealPoint;
  final double seed;

  late final List<_EnergySpark> _sparks;

  DivineEnergyPainter({
    required this.progress,
    required this.revealPoint,
    required this.seed,
  }) {
    final rng = math.Random((seed * 7777).toInt());
    _sparks = List.generate(42, (i) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final startDist = 45.0 + rng.nextDouble() * 95.0;
      final spiralSpeed = 1.8 + rng.nextDouble() * 2.5;
      final size = 2.5 + rng.nextDouble() * 3.5;
      // Vibrant intense colors: Electric Gold, Vivid Saffron, Blazing Solar Yellow
      final color = rng.nextBool()
          ? (rng.nextBool() ? const Color(0xFFFFEA00) : const Color(0xFFFFD700))
          : (rng.nextBool() ? const Color(0xFFFF6D00) : const Color(0xFFFF9100));
      return _EnergySpark(
        angle: angle,
        startDist: startDist,
        spiralSpeed: spiralSpeed,
        size: size,
        color: color,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // Strict border restriction: Clip strictly to card bounds!
    final cardRRect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24));
    canvas.clipRRect(cardRRect);

    final targetX = revealPoint.dx.clamp(40.0, size.width - 40.0);
    final targetY = revealPoint.dy.clamp(40.0, size.height - 40.0);
    final center = Offset(targetX, targetY);

    // 1. Inward converging energetic light particles (0.0 to 0.58)
    if (progress < 0.60) {
      final gatherT = (progress / 0.58).clamp(0.0, 1.0);
      final curveT = Curves.easeInQuad.transform(gatherT);

      for (final sp in _sparks) {
        final curDist = sp.startDist * (1.0 - curveT);
        final curAngle = sp.angle + (curveT * sp.spiralSpeed * math.pi);
        final px = center.dx + math.cos(curAngle) * curDist;
        final py = center.dy + math.sin(curAngle) * curDist;

        // Vibrant intense spark with bright white core
        final sparkPaint = Paint()
          ..color = sp.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
        canvas.drawCircle(Offset(px, py), sp.size, sparkPaint);

        // Electric core dot
        canvas.drawCircle(
          Offset(px, py),
          sp.size * 0.45,
          Paint()..color = Colors.white,
        );

        // Radiant trail line pointing towards center
        if (gatherT > 0.30) {
          final trailLength = 8.0 * gatherT;
          final trailPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = sp.color.withValues(alpha: 0.75);
          canvas.drawLine(
            Offset(px, py),
            Offset(
              px - math.cos(curAngle) * trailLength,
              py - math.sin(curAngle) * trailLength,
            ),
            trailPaint,
          );
        }
      }

      // Blazing central orb gathering light at revealPoint
      final orbAlpha = (gatherT * 0.95).clamp(0.0, 0.95);
      final orbRadius = 10.0 + (gatherT * 22.0);
      final orbPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFFFFEA00).withValues(alpha: orbAlpha),
            const Color(0xFFFF6D00).withValues(alpha: orbAlpha * 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: orbRadius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(center, orbRadius, orbPaint);
    }

    // 2. Intense burst shockwave & blazing beams from revealPoint (0.55 to 0.95)
    if (progress >= 0.55) {
      final burstT = ((progress - 0.55) / 0.40).clamp(0.0, 1.0);
      final maxRingRadius = 75.0;
      final ringRadius = Curves.easeOutCubic.transform(burstT) * maxRingRadius;
      final ringAlpha = (1.0 - burstT).clamp(0.0, 1.0);

      // Blazing primary golden shockwave ring
      final shockwavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - burstT) * 7.0 + 2.5
        ..color = const Color(0xFFFFEA00).withValues(alpha: ringAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(center, ringRadius, shockwavePaint);

      // Saffron outer electric ring
      final outerRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFFF6D00).withValues(alpha: ringAlpha * 0.85);
      canvas.drawCircle(center, ringRadius * 0.82, outerRingPaint);

      // 8 Radiant intense light rays shooting outward
      const int rayCount = 8;
      final rayLength = 45.0 * (1.0 - burstT * 0.3);
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - burstT)
        ..color = const Color(0xFFFFD700).withValues(alpha: ringAlpha);

      for (int i = 0; i < rayCount; i++) {
        final angle = (i * 2 * math.pi / rayCount) + (burstT * 0.6);
        final p1 = Offset(center.dx + math.cos(angle) * 10.0, center.dy + math.sin(angle) * 10.0);
        final p2 = Offset(center.dx + math.cos(angle) * rayLength, center.dy + math.sin(angle) * rayLength);
        canvas.drawLine(p1, p2, rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DivineEnergyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.revealPoint != revealPoint;
}

class _EnergySpark {
  final double angle;
  final double startDist;
  final double spiralSpeed;
  final double size;
  final Color color;

  _EnergySpark({
    required this.angle,
    required this.startDist,
    required this.spiralSpeed,
    required this.size,
    required this.color,
  });
}
