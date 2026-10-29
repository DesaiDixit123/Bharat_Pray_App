import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the atmospheric dark temple sanctum with golden ornate pillars,
/// warm flickering oil lamps, and volumetric divine radiance matching the design mockup.
class DhupTempleBackground extends StatelessWidget {
  final double flameFlicker;

  const DhupTempleBackground({
    super.key,
    required this.flameFlicker,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _TempleSanctumPainter(flameFlicker: flameFlicker),
        size: Size.infinite,
      ),
    );
  }
}

class _TempleSanctumPainter extends CustomPainter {
  final double flameFlicker;

  _TempleSanctumPainter({required this.flameFlicker});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Deep sacred sanctum dark background with warm amber center gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.15),
        radius: 1.15,
        colors: const [
          Color(0xFF1A110C),
          Color(0xFF100A08),
          Color(0xFF070403),
          Colors.black,
        ],
        stops: const [0.0, 0.45, 0.80, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Pillar width calculation (roughly 14% of screen on each side)
    final double pillarW = (size.width * 0.16).clamp(52.0, 85.0);

    // 3. Left Temple Column
    _drawTemplePillar(canvas, size, 0.0, pillarW, isLeft: true);

    // 4. Right Temple Column
    _drawTemplePillar(canvas, size, size.width - pillarW, pillarW, isLeft: false);

    // 5. Altar Base Platform at Bottom
    _drawAltarBase(canvas, size);
  }

  void _drawTemplePillar(
    Canvas canvas,
    Size size,
    double x,
    double width, {
    required bool isLeft,
  }) {
    final pillarRect = Rect.fromLTWH(x, 0, width, size.height);

    // Pillar base shading (gold/bronze stone columns)
    final pillarPaint = Paint()
      ..shader = LinearGradient(
        begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          const Color(0xFF18100B),
          const Color(0xFF382315),
          const Color(0xFF5A3922),
          const Color(0xFF352013),
          const Color(0xFF120B07),
        ],
        stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
      ).createShader(pillarRect);
    canvas.drawRect(pillarRect, pillarPaint);

    // Vertical carving flutes / ridges
    final ridgePaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double ridgeStep = width / 4.0;
    for (int i = 1; i <= 3; i++) {
      final rx = x + (i * ridgeStep);
      canvas.drawLine(Offset(rx, 0), Offset(rx, size.height * 0.85), ridgePaint);
    }

    // Pillar Capital / Capital Tier Arches at top
    final archPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.35),
          const Color(0xFFFF9900).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, 0, width, 180));
    canvas.drawRect(Rect.fromLTWH(x, 0, width, 180), archPaint);

    // Diya Wall Sconces with flickering warm golden lights
    final sconceYPositions = [
      size.height * 0.22,
      size.height * 0.40,
      size.height * 0.58,
      size.height * 0.74,
    ];

    for (int i = 0; i < sconceYPositions.length; i++) {
      final sy = sconceYPositions[i];
      final sx = isLeft ? (x + width - 12) : (x + 12);
      final flicker = math.sin(flameFlicker * math.pi * 2 + (i * 1.5));
      _drawWallDiya(canvas, Offset(sx, sy), flicker, isLeft: isLeft);
    }
  }

  void _drawWallDiya(Canvas canvas, Offset center, double flicker, {required bool isLeft}) {
    // Brass bracket
    final bracketPaint = Paint()
      ..color = const Color(0xFFC8A882)
      ..style = PaintingStyle.fill;
    final bracketRect = Rect.fromCenter(center: center, width: 14, height: 6);
    canvas.drawRRect(RRect.fromRectAndRadius(bracketRect, const Radius.circular(2)), bracketPaint);

    // Flame position
    final flameCenter = Offset(center.dx + (isLeft ? 4 : -4), center.dy - 7);
    final flameRadius = 14.0 + (flicker * 3.0);

    // Warm radial glow bloom
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.55 + (flicker * 0.15)),
          const Color(0xFFFF8F00).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: flameCenter, radius: flameRadius * 2.2));
    canvas.drawCircle(flameCenter, flameRadius * 2.2, glowPaint);

    // Flame Core
    final flamePath = Path()
      ..moveTo(flameCenter.dx, flameCenter.dy - 10)
      ..quadraticBezierTo(flameCenter.dx + 4, flameCenter.dy - 2, flameCenter.dx, flameCenter.dy + 3)
      ..quadraticBezierTo(flameCenter.dx - 4, flameCenter.dy - 2, flameCenter.dx, flameCenter.dy - 10);

    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF9C4), Color(0xFFFF9800)],
      ).createShader(Rect.fromCircle(center: flameCenter, radius: 8));
    canvas.drawPath(flamePath, corePaint);
  }

  void _drawAltarBase(Canvas canvas, Size size) {
    final altarTop = size.height * 0.86;
    final altarRect = Rect.fromLTWH(0, altarTop, size.width, size.height - altarTop);

    final altarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2E1C12),
          const Color(0xFF1A0F09),
          const Color(0xFF0E0704),
        ],
      ).createShader(altarRect);
    canvas.drawRect(altarRect, altarPaint);

    // Altar top golden rim line
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFFFFB300),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Colors.transparent,
        ],
        stops: [0.0, 0.25, 0.50, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, altarTop, size.width, 2))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, altarTop), Offset(size.width, altarTop), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _TempleSanctumPainter oldDelegate) {
    return oldDelegate.flameFlicker != flameFlicker;
  }
}
