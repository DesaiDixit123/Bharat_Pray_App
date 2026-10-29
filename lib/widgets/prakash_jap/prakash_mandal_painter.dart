import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Single floating golden sparkle / energy particle in the Prakash Mandal
class GoldenParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double alpha;
  double maxAlpha;
  double pulseSpeed;
  double life;
  double maxLife;

  GoldenParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.maxAlpha,
    required this.pulseSpeed,
    required this.maxLife,
  })  : alpha = 0.0,
        life = 0.0;

  bool update(double dt) {
    life += dt;
    if (life >= maxLife) return false;

    x += vx * dt;
    y += vy * dt;

    // Fade in during first 20%, stay bright, fade out during last 30%
    final double norm = life / maxLife;
    if (norm < 0.20) {
      alpha = maxAlpha * (norm / 0.20);
    } else if (norm > 0.70) {
      alpha = maxAlpha * (1.0 - ((norm - 0.70) / 0.30));
    } else {
      alpha = maxAlpha;
    }
    return true;
  }
}

/// CustomPainter rendering the divine Prakash Mandal:
/// - Concentric sacred golden rings rotating smoothly
/// - Radial divine sunburst rays expanding with Jap progress
/// - Central halo aura bloom and starburst core
/// - Floating golden dust particles
class PrakashMandalPainter extends CustomPainter {
  final int count;
  final int targetCount;
  final double ambientTime; // 0.0 to 1.0 continuous loop
  final double pulseValue; // 0.0 to 1.0 tap pulse
  final double completionGlow; // 0.0 to 1.0 at 108
  final List<GoldenParticle> particles;

  PrakashMandalPainter({
    required this.count,
    this.targetCount = 108,
    required this.ambientTime,
    required this.pulseValue,
    required this.completionGlow,
    required this.particles,
  });

  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _rayPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double centerX = size.width * 0.50;
    // Position halo at Bhagwan's head/crown center (~28% of screen height)
    final double haloY = size.height * 0.285;
    final Offset haloCenter = Offset(centerX, haloY);

    final double t = (count / targetCount).clamp(0.0, 1.0);
    final double rotationAngle = ambientTime * 2 * math.pi;

    // ── STAGE 0: JAP 0 (Initial Glowing Starburst Point) ──────────────
    if (count == 0 && completionGlow <= 0.0) {
      _drawInitialGlow(canvas, haloCenter, size.width, rotationAngle);
      _drawParticles(canvas);
      return;
    }

    // ── STAGE 1..108: PROGRESSIVE EXPANDING PRAKASH MANDAL ────────────
    // Mandala Base Radius expands smoothly with Jap count
    // At count 1: small halo around head. At count 108: grand majestic mandala!
    final double baseRadius = size.width * (0.16 + (0.34 * math.pow(t, 0.85)));
    final double pulseExpansion = pulseValue * 14.0;
    final double currentRadius = baseRadius + pulseExpansion;

    // 1. Soft Divine Background Aura Bloom
    final double auraRadius = currentRadius * 1.55;
    final double auraAlpha = (0.25 + (0.50 * t) + (0.25 * completionGlow)).clamp(0.0, 1.0);
    _glowPaint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFF9C4).withValues(alpha: auraAlpha * 0.65),
        const Color(0xFFFFD54F).withValues(alpha: auraAlpha * 0.40),
        const Color(0xFFFF8F00).withValues(alpha: auraAlpha * 0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.70, 1.0],
    ).createShader(Rect.fromCircle(center: haloCenter, radius: auraRadius));
    canvas.drawCircle(haloCenter, auraRadius, _glowPaint);

    // 2. Radiant Sunburst Rays
    // Rays project outward from inner ring to beyond the outer ring
    final int numRays = 16 + (16 * t).round(); // 16 to 32 rays
    final double rayInnerR = currentRadius * 0.45;
    final double rayOuterR = currentRadius * (1.15 + (0.35 * t));

    for (int i = 0; i < numRays; i++) {
      final double angle = (i * (2 * math.pi / numRays)) + (rotationAngle * 0.15);
      final bool isMajor = (i % 2 == 0);
      final double rLength = isMajor ? rayOuterR : (rayOuterR * 0.75);
      final double rayAlpha = isMajor
          ? (0.35 + (0.45 * t) + (0.20 * pulseValue)).clamp(0.0, 1.0)
          : (0.20 + (0.30 * t)).clamp(0.0, 0.8);

      _rayPaint
        ..strokeWidth = isMajor ? (1.8 + (1.2 * t)) : 1.0
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: rayAlpha),
            const Color(0xFFFFB300).withValues(alpha: rayAlpha * 0.6),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromPoints(
            Offset(
              haloCenter.dx + (math.cos(angle) * rayInnerR),
              haloCenter.dy + (math.sin(angle) * rayInnerR),
            ),
            Offset(
              haloCenter.dx + (math.cos(angle) * rLength),
              haloCenter.dy + (math.sin(angle) * rLength),
            ),
          ),
        );

      canvas.drawLine(
        Offset(
          haloCenter.dx + (math.cos(angle) * rayInnerR),
          haloCenter.dy + (math.sin(angle) * rayInnerR),
        ),
        Offset(
          haloCenter.dx + (math.cos(angle) * rLength),
          haloCenter.dy + (math.sin(angle) * rLength),
        ),
        _rayPaint,
      );
    }

    // 3. Concentric Sacred Golden Rings
    // Ring 1: Innermost solid bright gold ring
    _ringPaint
      ..strokeWidth = 2.2
      ..color = const Color(0xFFFFF9C4).withValues(alpha: (0.75 + (0.25 * t)).clamp(0.0, 1.0));
    canvas.drawCircle(haloCenter, currentRadius * 0.52, _ringPaint);

    // Ring 2: Middle sacred dash/bead ring (rotates clockwise)
    final double r2 = currentRadius * 0.78;
    final int dashCount = 36;
    _ringPaint
      ..strokeWidth = 1.8
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.80);
    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (2 * math.pi / dashCount)) + (rotationAngle * 0.35);
      final double sweep = (2 * math.pi / dashCount) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: haloCenter, radius: r2),
        startAngle,
        sweep,
        false,
        _ringPaint,
      );
    }

    // Ring 3: Decorative petal/notch ring (rotates counter-clockwise)
    final double r3 = currentRadius;
    final int markerCount = 18;
    final Paint markerPaint = Paint()
      ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < markerCount; i++) {
      final double angle = (i * (2 * math.pi / markerCount)) - (rotationAngle * 0.25);
      final double mx = haloCenter.dx + (math.cos(angle) * r3);
      final double my = haloCenter.dy + (math.sin(angle) * r3);
      canvas.drawCircle(Offset(mx, my), 2.2 + (0.8 * t), markerPaint);
    }

    _ringPaint
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.65);
    canvas.drawCircle(haloCenter, r3, _ringPaint);

    // Ring 4: Outermost boundary halo with pulsing glow
    if (t > 0.40) {
      final double r4 = currentRadius * 1.18;
      _ringPaint
        ..strokeWidth = 1.0
        ..color = const Color(0xFFFFE082).withValues(
          alpha: (0.35 * ((t - 0.40) / 0.60) + (0.20 * math.sin(rotationAngle))).clamp(0.0, 0.75),
        );
      canvas.drawCircle(haloCenter, r4, _ringPaint);
    }

    // 4. Floating Golden Energy Particles
    _drawParticles(canvas);

    // 5. Completion Grand Climax Bloom (108 Jap)
    if (completionGlow > 0.0 || count >= targetCount) {
      final double climaxRadius = currentRadius * (1.65 + (0.20 * math.sin(rotationAngle * 2)));
      _glowPaint.shader = RadialGradient(
        colors: [
          const Color(0xFFFFFDE7).withValues(alpha: 0.70 * completionGlow),
          const Color(0xFFFFD54F).withValues(alpha: 0.45 * completionGlow),
          const Color(0xFFFF9900).withValues(alpha: 0.20 * completionGlow),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: haloCenter, radius: climaxRadius));
      canvas.drawCircle(haloCenter, climaxRadius, _glowPaint);
    }
  }

  void _drawInitialGlow(Canvas canvas, Offset center, double screenWidth, double angle) {
    final double r = screenWidth * 0.22;
    final double pulse = 0.85 + (0.15 * math.sin(angle));

    // Outer faint aura
    _glowPaint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFD54F).withValues(alpha: 0.35 * pulse),
        const Color(0xFFFF8F00).withValues(alpha: 0.15 * pulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.50, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, _glowPaint);

    // Faint subtle circular outline
    _ringPaint
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.30 * pulse);
    canvas.drawCircle(center, r * 0.70, _ringPaint);

    // Tiny radiant starburst core
    final Paint corePaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(center, 3.5 * pulse, corePaint);

    // Small starburst points
    final Paint starRay = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.75 * pulse)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 8; i++) {
      final double a = (i * math.pi / 4) + (angle * 0.2);
      final double len = (i % 2 == 0) ? 14.0 : 8.0;
      canvas.drawLine(
        center,
        Offset(center.dx + (math.cos(a) * len), center.dy + (math.sin(a) * len)),
        starRay,
      );
    }
  }

  void _drawParticles(Canvas canvas) {
    final Paint pPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      pPaint.color = const Color(0xFFFFD54F).withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, pPaint);

      // Core white speck
      pPaint.color = Colors.white.withValues(alpha: (p.alpha * 0.85).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.radius * 0.45, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PrakashMandalPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.ambientTime != ambientTime ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.completionGlow != completionGlow ||
        oldDelegate.particles.length != particles.length;
  }
}
