import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Represents a single concentric water ripple wave traveling outwards.
class WaterRipple {
  final Offset center;
  double radius;
  final double maxRadius;
  final double duration;
  double age = 0.0;
  final Color baseColor;

  WaterRipple({
    required this.center,
    this.radius = 14.0,
    required this.maxRadius,
    this.duration = 1.6,
    this.baseColor = const Color(0xFF80DEEA),
  });

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;

    final progress = age / duration;
    // Cubic deceleration expansion
    radius = 14.0 + ((maxRadius - 14.0) * math.pow(progress, 0.65));
    return true;
  }
}

/// Represents an interactive sacred floating golden lotus with Devanagari text 'राम'
/// that drifts gracefully upon the sacred Tirth water pool whenever the user chants.
class FloatingRamLotus {
  final Offset origin;
  double x;
  double y;
  final String text; // 'राम' or 'श्री राम'
  final double scale;
  final double duration; // In seconds (~4.5s)
  double age = 0.0;
  final double driftVx;
  final double driftVy;
  final double wavePhase;

  FloatingRamLotus({
    required this.origin,
    this.text = 'राम',
    this.scale = 1.0,
    this.duration = 4.5,
    required this.driftVx,
    required this.driftVy,
    required this.wavePhase,
  })  : x = origin.dx,
        y = origin.dy;

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;

    // Gentle floating drift with wave oscillation
    x += driftVx * dt;
    y += driftVy * dt + (math.sin((age * 2.8) + wavePhase) * 6.0 * dt);
    return true;
  }
}

/// Represents a golden water droplet / splash particle on tap.
class WaterDrop {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  final double duration;
  double age = 0.0;
  final Color color;

  WaterDrop({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.duration,
    required this.color,
  });

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;

    x += vx * dt;
    y += vy * dt;
    vy += 95.0 * dt; // Gravity
    vx *= 0.98;
    return true;
  }
}

/// Floating lotus petal drifting gently on the sacred water pool.
class FloatingPetal {
  double x;
  double y;
  final double startX;
  final double startY;
  final double speed;
  final double waveAmp;
  final double waveFreq;
  final double phase;
  final double scale;
  final double rotation;
  double age = 0.0;
  final double duration;

  FloatingPetal({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.waveAmp,
    required this.waveFreq,
    required this.phase,
    required this.scale,
    required this.rotation,
    required this.duration,
  })  : x = startX,
        y = startY;

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;

    final progress = age / duration;
    y = startY - (speed * age);
    x = startX + (math.sin((progress * waveFreq * 2 * math.pi) + phase) * waveAmp);
    return true;
  }
}

/// Renders all active water ripples, floating 'राम' lotuses, droplets, and surface wave highlights.
class JalWaterRipplePainter extends CustomPainter {
  final List<WaterRipple> ripples;
  final List<FloatingRamLotus> floatingLotuses;
  final List<WaterDrop> droplets;
  final List<FloatingPetal> petals;
  final double ambientTime; // 0.0 to 1.0 continuous loop

  static final Paint _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _dropletPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _petalPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lotusPetalPaint = Paint()..style = PaintingStyle.fill;

  JalWaterRipplePainter({
    required this.ripples,
    this.floatingLotuses = const [],
    required this.droplets,
    required this.petals,
    required this.ambientTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ── 1. Draw Active Expanding Water Ripples ────────────────────────
    for (final ripple in ripples) {
      final double progress = (ripple.age / ripple.duration).clamp(0.0, 1.0);
      final double alphaCurve = math.pow(1.0 - progress, 1.4).toDouble();
      if (alphaCurve <= 0.01) continue;

      // Primary crest ring
      _ripplePaint
        ..strokeWidth = math.max(0.8, 3.2 * (1.0 - (progress * 0.75)))
        ..color = ripple.baseColor.withValues(alpha: alphaCurve * 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(ripple.center, ripple.radius, _ripplePaint);

      // Secondary inner golden caustic refraction ring
      if (ripple.radius > 20.0) {
        _ripplePaint
          ..strokeWidth = math.max(0.6, 2.0 * (1.0 - progress))
          ..color = const Color(0xFFFFE082).withValues(alpha: alphaCurve * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(ripple.center, ripple.radius * 0.82, _ripplePaint);
      }

      // Outer soft subtle shockwave ring
      if (ripple.radius > 40.0) {
        _ripplePaint
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: alphaCurve * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(ripple.center, ripple.radius * 1.15, _ripplePaint);
      }
    }

    // ── 2. Draw Floating 'राम' Lotuses with Glowing Sacred Text ───────
    for (final lotus in floatingLotuses) {
      final double progress = (lotus.age / lotus.duration).clamp(0.0, 1.0);
      final double alpha = (progress < 0.12)
          ? (progress / 0.12)
          : (progress > 0.80 ? ((1.0 - progress) / 0.20) : 1.0);
      if (alpha <= 0.01) continue;

      final double bloomScale = (progress < 0.18)
          ? (math.sin((progress / 0.18) * (math.pi / 2)) * lotus.scale)
          : lotus.scale;

      final bobY = math.sin((ambientTime * 2 * math.pi) + lotus.wavePhase) * 3.5;
      final lotusCenter = Offset(lotus.x, lotus.y + bobY);

      canvas.save();
      canvas.translate(lotusCenter.dx, lotusCenter.dy);
      canvas.scale(bloomScale);

      // A. Golden glowing aquatic reflection pool under the lotus
      final Paint poolGlow = Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 64.0, height: 28.0),
        poolGlow,
      );

      // B. Draw 8 delicate sacred golden-pink lotus petals
      const int numPetals = 8;
      for (int i = 0; i < numPetals; i++) {
        final double angle = (i * 2 * math.pi / numPetals);
        canvas.save();
        canvas.rotate(angle);

        final Path petalPath = Path();
        petalPath.moveTo(0, 0);
        petalPath.quadraticBezierTo(-7, -14, 0, -22);
        petalPath.quadraticBezierTo(7, -14, 0, 0);
        petalPath.close();

        // Soft gradient from pink to golden lotus tips
        _lotusPetalPaint.color = (i % 2 == 0)
            ? const Color(0xFFFF80AB).withValues(alpha: alpha * 0.75)
            : const Color(0xFFFFE082).withValues(alpha: alpha * 0.85);
        canvas.drawPath(petalPath, _lotusPetalPaint);

        canvas.restore();
      }

      // C. Center golden pericarp core
      final Paint corePaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset.zero, 11.0, corePaint);

      // D. Radiant Devanagari Sacred Text 'राम' (or 'श्री राम')
      final textSpan = TextSpan(
        text: lotus.text,
        style: GoogleFonts.notoSerifDevanagari(
          fontSize: (lotus.text.length > 3 ? 13.0 : 16.0),
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFFDE7).withValues(alpha: alpha.clamp(0.0, 1.0)),
          shadows: [
            Shadow(
              color: const Color(0xFFFF6D00).withValues(alpha: (alpha * 0.95).clamp(0.0, 1.0)),
              blurRadius: 10.0,
            ),
            Shadow(
              color: Colors.black.withValues(alpha: (alpha * 0.85).clamp(0.0, 1.0)),
              blurRadius: 4.0,
              offset: const Offset(0, 1.0),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = Offset(
        -textPainter.width / 2,
        -textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      canvas.restore();
    }

    // ── 3. Draw Golden Water Droplets / Tap Splash ─────────────────────
    for (final drop in droplets) {
      final double progress = (drop.age / drop.duration).clamp(0.0, 1.0);
      final double alpha = (1.0 - progress).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      _dropletPaint.color = drop.color.withValues(alpha: alpha * 0.85);
      canvas.drawCircle(Offset(drop.x, drop.y), drop.radius * (1.0 - (progress * 0.3)), _dropletPaint);

      // Specular highlight on water droplet
      _dropletPaint.color = Colors.white.withValues(alpha: alpha * 0.95);
      canvas.drawCircle(
        Offset(drop.x - (drop.radius * 0.3), drop.y - (drop.radius * 0.3)),
        drop.radius * 0.35,
        _dropletPaint,
      );
    }

    // ── 4. Draw Floating Rose & Lotus Petals ───────────────────────────
    for (final petal in petals) {
      final double progress = (petal.age / petal.duration).clamp(0.0, 1.0);
      final double alpha = (progress < 0.15)
          ? (progress / 0.15)
          : (progress > 0.85 ? ((1.0 - progress) / 0.15) : 1.0);
      if (alpha <= 0.01) continue;

      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.rotation + (math.sin(petal.age * 1.5) * 0.20));
      canvas.scale(petal.scale);

      // Draw graceful curved petal shape
      final Path path = Path();
      path.moveTo(0, -9);
      path.quadraticBezierTo(7, -5, 5, 5);
      path.quadraticBezierTo(0, 9, -5, 5);
      path.quadraticBezierTo(-7, -5, 0, -9);
      path.close();

      _petalPaint.color = const Color(0xFFFF80AB).withValues(alpha: alpha * 0.75);
      canvas.drawPath(path, _petalPaint);

      // Delicate inner pink highlight
      _petalPaint.color = const Color(0xFFFFF0F5).withValues(alpha: alpha * 0.50);
      canvas.drawCircle(const Offset(0, 0), 2.5, _petalPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant JalWaterRipplePainter oldDelegate) => true;
}
