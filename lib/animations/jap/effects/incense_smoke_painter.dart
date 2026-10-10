import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dense fragrant dhoop incense smoke painter.
/// ZERO red/orange spots! Pure, dense, billowing sacred incense smoke curls
/// wafting and curling upwards from the newly revealed image tile [revealPoint].
class IncenseSmokePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final Offset revealPoint;
  final double seed;

  IncenseSmokePainter({
    required this.progress,
    required this.revealPoint,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final origin = revealPoint;

    // Zero red spot! Pure dense fragrant dhoop smoke!
    // 1. Dense billowing smoke puffs right at the source (expanding and wafting up)
    _drawBillowingSourcePuffs(canvas, origin, progress);

    // 2. Multiple dense curling smoke streams rising upwards from revealPoint
    // Main dense core stream
    _drawDenseCurlingStream(
      canvas: canvas,
      origin: origin,
      t: progress,
      phaseShift: 0.0,
      maxRiseHeight: 125.0,
      strokeWidth: 26.0,
      baseColor: const Color(0xFFFFFFFF),
      baseAlpha: 0.78,
      lateralDrift: -14.0,
    );

    // Second dense billowing stream (slight offset for volume)
    _drawDenseCurlingStream(
      canvas: canvas,
      origin: origin,
      t: progress,
      phaseShift: 2.3,
      maxRiseHeight: 140.0,
      strokeWidth: 28.0,
      baseColor: const Color(0xFFF5F5F5),
      baseAlpha: 0.70,
      lateralDrift: 18.0,
    );

    // Third atmospheric incense stream
    _drawDenseCurlingStream(
      canvas: canvas,
      origin: origin,
      t: progress,
      phaseShift: 4.5,
      maxRiseHeight: 110.0,
      strokeWidth: 22.0,
      baseColor: const Color(0xFFECEFF1),
      baseAlpha: 0.65,
      lateralDrift: 2.0,
    );

    // 3. Volumetric smoke cloud puffs floating upward
    _drawRisingSmokeClouds(canvas, origin, progress);
  }

  void _drawBillowingSourcePuffs(Canvas canvas, Offset origin, double t) {
    final puffAlpha = (math.sin(t * math.pi) * 0.72).clamp(0.0, 0.72);
    if (puffAlpha <= 0.01) return;

    // Overlapping dense soft smoke puffs right at the source
    const List<Offset> offsets = [
      Offset(0, 0),
      Offset(-5, -6),
      Offset(6, -8),
      Offset(-2, -14),
      Offset(4, -18),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final off = offsets[i];
      final radius = 12.0 + (i * 3.5) + (t * 8.0);
      final puffPaint = Paint()
        ..color = const Color(0xFFFAFAFA).withValues(alpha: puffAlpha * (0.85 - i * 0.10))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + i * 1.5);

      canvas.drawCircle(Offset(origin.dx + off.dx, origin.dy + off.dy), radius, puffPaint);
    }
  }

  void _drawDenseCurlingStream({
    required Canvas canvas,
    required Offset origin,
    required double t,
    required double phaseShift,
    required double maxRiseHeight,
    required double strokeWidth,
    required Color baseColor,
    required double baseAlpha,
    required double lateralDrift,
  }) {
    final riseProgress = Curves.easeOutCubic.transform((t / 0.82).clamp(0.0, 1.0));
    final currentHeight = maxRiseHeight * riseProgress;
    if (currentHeight <= 2.0) return;

    final streamAlpha = (baseAlpha * (1.0 - (t * 0.45))).clamp(0.0, 1.0);
    final path = Path();
    path.moveTo(origin.dx, origin.dy);

    const int points = 26;
    for (int i = 1; i <= points; i++) {
      final frac = i / points;
      final curY = origin.dy - (currentHeight * frac);

      // Natural billowing wave as it wafts upward
      final spread = 8.0 + (frac * 32.0);
      final wave = math.sin((frac * 4.8) - (t * 6.0) + phaseShift + seed) * spread;
      final drift = lateralDrift * frac * frac;

      final curX = origin.dx + wave + drift;
      path.lineTo(curX, curY);
    }

    // Outer dense smoke plume
    final smokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + (t * 14.0)
      ..color = baseColor.withValues(alpha: streamAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11.0);
    canvas.drawPath(path, smokePaint);

    // Inner dense core
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (strokeWidth * 0.50) + (t * 6.0)
      ..color = Colors.white.withValues(alpha: streamAlpha * 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawPath(path, corePaint);
  }

  void _drawRisingSmokeClouds(Canvas canvas, Offset origin, double t) {
    const int puffCount = 10;
    for (int i = 0; i < puffCount; i++) {
      final pSeed = seed + (i * 1.618);
      final pProgress = (t * 1.1 + (i / puffCount)) % 1.0;

      final pAlpha = (math.sin(pProgress * math.pi) * 0.65 * (1.0 - t * 0.4)).clamp(0.0, 1.0);
      if (pAlpha <= 0.01) continue;

      final pRise = pProgress * 115.0;
      final pSpread = math.sin(pProgress * 3.5 + pSeed) * (18.0 + i * 3.0);
      final px = origin.dx + pSpread;
      final py = origin.dy - pRise;

      final pRadius = 6.0 + (pProgress * 12.0);
      final pPaint = Paint()
        ..color = const Color(0xFFF5F5F5).withValues(alpha: pAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      canvas.drawCircle(Offset(px, py), pRadius, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant IncenseSmokePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.revealPoint != revealPoint;
}
