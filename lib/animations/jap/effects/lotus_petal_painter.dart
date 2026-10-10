import 'dart:math' as math;
import 'package:flutter/material.dart';

class LotusPetalPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final double seed;

  late final List<_LotusPetalData> _petals;

  LotusPetalPainter({
    required this.progress,
    required this.seed,
  }) {
    final rng = math.Random((seed * 9999).toInt());
    _petals = List.generate(36, (i) {
      // Screen edge spawn (0: top, 1: bottom, 2: left, 3: right)
      final edge = rng.nextInt(4);
      double sx = 0, sy = 0;
      switch (edge) {
        case 0:
          sx = rng.nextDouble() * 360;
          sy = -40;
          break;
        case 1:
          sx = rng.nextDouble() * 360;
          sy = 560;
          break;
        case 2:
          sx = -40;
          sy = rng.nextDouble() * 520;
          break;
        case 3:
          sx = 400;
          sy = rng.nextDouble() * 520;
          break;
      }
      final targetRadius = 40.0 + rng.nextDouble() * 110.0;
      final targetAngle = rng.nextDouble() * 2 * math.pi;
      final size = 14.0 + rng.nextDouble() * 18.0;
      final spinSpeed = (rng.nextDouble() * 4.0 - 2.0);
      final isGolden = rng.nextDouble() < 0.35;
      final color = isGolden
          ? const Color(0xFFFFD54F)
          : (rng.nextBool() ? const Color(0xFFFF80AB) : const Color(0xFFF48FB1));

      return _LotusPetalData(
        startX: sx,
        startY: sy,
        targetRadius: targetRadius,
        targetAngle: targetAngle,
        size: size,
        spinSpeed: spinSpeed,
        color: color,
        delayFrac: rng.nextDouble() * 0.22,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height * 0.46);

    // 1. Reveal mask expanding as petals swirl around center (0.0 to 0.85)
    final revealT = (progress / 0.82).clamp(0.0, 1.0);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.72;
    final currentRadius = Curves.easeInOutCubic.transform(revealT) * maxRadius;

    if (progress < 0.95) {
      final veilAlpha = (0.92 * (1.0 - (progress / 0.90))).clamp(0.0, 0.92);
      if (veilAlpha > 0.02) {
        canvas.saveLayer(rect, Paint());
        canvas.drawRect(
          rect,
          Paint()..color = const Color(0xFF160A18).withValues(alpha: veilAlpha),
        );

        final erasePaint = Paint()
          ..blendMode = BlendMode.dstOut
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32.0);
        canvas.drawCircle(center, currentRadius, erasePaint);
        canvas.restore();
      }
    }

    // 2. Petal Animation Timeline:
    // 0.0 - 0.45: Petals rush in from edges towards the center vortex
    // 0.45 - 0.75: Swirl dynamically in a circular sacred halo around the deity
    // 0.75 - 1.0: Shower gently downward, dispersing with subtle lingering float
    for (final p in _petals) {
      if (progress < p.delayFrac) continue;
      final effectiveT = ((progress - p.delayFrac) / (1.0 - p.delayFrac)).clamp(0.0, 1.0);

      double px, py;
      double currentAlpha = 0.95;

      if (effectiveT < 0.45) {
        // Flying inward
        final t = effectiveT / 0.45;
        final curveT = Curves.easeOutCubic.transform(t);
        final vortexX = center.dx + math.cos(p.targetAngle) * p.targetRadius;
        final vortexY = center.dy + math.sin(p.targetAngle) * p.targetRadius;
        px = p.startX + (vortexX - p.startX) * curveT;
        py = p.startY + (vortexY - p.startY) * curveT;
      } else if (effectiveT < 0.75) {
        // Swirling in circle
        final swirlProgress = (effectiveT - 0.45) / 0.30;
        final angle = p.targetAngle + (swirlProgress * math.pi * 1.5);
        final r = p.targetRadius * (1.0 + math.sin(swirlProgress * math.pi) * 0.25);
        px = center.dx + math.cos(angle) * r;
        py = center.dy + math.sin(angle) * r;
      } else {
        // Falling down & floating off
        final fallProgress = (effectiveT - 0.75) / 0.25;
        final finalAngle = p.targetAngle + (math.pi * 1.5);
        final startX = center.dx + math.cos(finalAngle) * p.targetRadius;
        final startY = center.dy + math.sin(finalAngle) * p.targetRadius;
        px = startX + math.sin(fallProgress * math.pi * 2) * 20.0;
        py = startY + (fallProgress * 180.0);
        currentAlpha = (1.0 - fallProgress * 0.85).clamp(0.0, 1.0);
      }

      final rot = (effectiveT * p.spinSpeed * math.pi * 2) + p.targetAngle;
      _drawSingleLotusPetal(canvas, Offset(px, py), p.size, rot, p.color, currentAlpha);
    }

    // 3. Finishing golden glow (0.85 to 1.0)
    if (progress >= 0.85) {
      final t = (progress - 0.85) / 0.15;
      final alpha = math.sin(t * math.pi) * 0.22;
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFFF80AB).withValues(alpha: alpha * 0.6),
            const Color(0xFFFFD700).withValues(alpha: alpha),
          ],
          stops: const [0.65, 0.88, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, glowPaint);
    }
  }

  void _drawSingleLotusPetal(
    Canvas canvas,
    Offset pos,
    double size,
    double rotation,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0.02) return;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    // Natural curved teardrop lotus petal path
    final path = Path();
    path.moveTo(0, -size / 2); // petal tip
    path.cubicTo(size * 0.55, -size * 0.15, size * 0.45, size * 0.45, 0, size / 2); // base
    path.cubicTo(-size * 0.45, size * 0.45, -size * 0.55, -size * 0.15, 0, -size / 2);
    path.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Petal central spine vein
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, -size * 0.4), Offset(0, size * 0.35), veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LotusPetalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LotusPetalData {
  final double startX;
  final double startY;
  final double targetRadius;
  final double targetAngle;
  final double size;
  final double spinSpeed;
  final Color color;
  final double delayFrac;

  _LotusPetalData({
    required this.startX,
    required this.startY,
    required this.targetRadius,
    required this.targetAngle,
    required this.size,
    required this.spinSpeed,
    required this.color,
    required this.delayFrac,
  });
}
