import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Represents a delicate curling incense smoke wisp.
class SmokeWispParticle {
  double x;
  double y;
  double vx;
  double vy;
  double width;
  double height;
  final double maxWidth;
  final double maxHeight;
  final double maxAlpha;
  final double duration;
  double age = 0.0;
  final Color color;

  SmokeWispParticle({
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = -35.0,
    required this.width,
    required this.height,
    required this.maxWidth,
    required this.maxHeight,
    required this.maxAlpha,
    required this.duration,
    required this.color,
  });

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;

    x += vx * dt;
    y += vy * dt;
    vy *= 0.985;
    vx += math.sin(age * 3.5) * 3.0 * dt;
    width += (maxWidth - width) * (dt / duration) * 1.8;
    height += (maxHeight - height) * (dt / duration) * 1.8;

    return true;
  }
}

/// Dynamic, living ribbon of sacred dhoop smoke that travels
/// from the brass Dhup Dani to the target reveal location.
/// ZERO CIRCLES — draws a smooth, fluid, serpentine ribbon of incense smoke.
class DirectionalSmokeStream {
  final int step;
  final Offset start;
  final Offset target;
  final VoidCallback onArrived;
  final double duration; // In seconds (~3.8s when voice on, 0.75s when muted)
  final String text; // Sacred Devanagari text, e.g. 'राम'
  double elapsed = 0.0;
  double progress = 0.0;
  bool hasArrived = false;
  bool isFinished = false;

  final List<SmokeWispParticle> dissipatingWisps = [];
  final Offset control1;
  final Offset control2;

  DirectionalSmokeStream({
    required this.step,
    required this.start,
    required this.target,
    required this.onArrived,
    this.duration = 3.8,
    this.text = 'राम',
  })  : control1 = _computeControlPoint1(start, target),
        control2 = _computeControlPoint2(start, target);

  static Offset _computeControlPoint1(Offset start, Offset target) {
    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    // Elegant S-curve initial billow outwards
    final sign = (dx >= 0) ? -1.0 : 1.0;
    return Offset(
      start.dx + (dx * 0.20) + (sign * 40.0),
      start.dy + (dy * 0.45),
    );
  }

  static Offset _computeControlPoint2(Offset start, Offset target) {
    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    final sign = (dx >= 0) ? 1.0 : -1.0;
    return Offset(
      start.dx + (dx * 0.70) + (sign * 30.0),
      start.dy + (dy * 0.85),
    );
  }

  /// Calculates exact point on cubic Bezier flight trajectory at fraction t
  Offset getHeadPosition(double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final u = 1.0 - clampedT;
    final double x = (u * u * u * start.dx) +
        (3 * u * u * clampedT * control1.dx) +
        (3 * u * clampedT * clampedT * control2.dx) +
        (clampedT * clampedT * clampedT * target.dx);
    final double y = (u * u * u * start.dy) +
        (3 * u * u * clampedT * control1.dy) +
        (3 * u * clampedT * clampedT * control2.dy) +
        (clampedT * clampedT * clampedT * target.dy);
    return Offset(x, y);
  }

  /// Updates simulation state. Can be driven directly by wall-clock progress.
  bool update(double dt, {double? forcedProgress}) {
    if (forcedProgress != null) {
      progress = forcedProgress.clamp(0.0, 1.0);
      elapsed = progress * duration;
    } else {
      elapsed += dt;
      progress = (elapsed / duration).clamp(0.0, 1.0);
    }

    // Update dissipating arrival wisps
    dissipatingWisps.removeWhere((w) => !w.update(dt));

    // When smoke head reaches the target node coordinate:
    if (progress >= 1.0 && !hasArrived) {
      hasArrived = true;
      onArrived();

      // Spawn a few delicate, organic upward curling smoke wisps (NO YELLOW EXPLOSION DISC!)
      final math.Random random = math.Random();
      for (int i = 0; i < 6; i++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final speed = 12.0 + (random.nextDouble() * 22.0);
        dissipatingWisps.add(
          SmokeWispParticle(
            x: target.dx + (math.cos(angle) * 6.0),
            y: target.dy + (math.sin(angle) * 6.0),
            vx: math.cos(angle) * speed * 0.4,
            vy: -25.0 - (random.nextDouble() * 25.0), // Gently rising
            width: 8.0,
            height: 16.0,
            maxWidth: 24.0 + (random.nextDouble() * 12.0),
            maxHeight: 40.0 + (random.nextDouble() * 16.0),
            maxAlpha: 0.45, // Soft, ethereal, non-blinding
            duration: 1.1 + (random.nextDouble() * 0.5),
            color: const Color(0xFFFFFDE7),
          ),
        );
      }
    }

    if (hasArrived && dissipatingWisps.isEmpty) {
      isFinished = true;
      return false;
    }

    return true;
  }
}

/// Continuous ambient rising smoke wisp from the Dhup Dani burner.
class AmbientSmokeWisp {
  double x;
  double y;
  final double startX;
  final double startY;
  final double vy;
  final double waveFreq;
  final double waveAmp;
  final double wavePhase;
  final double maxRadius;
  final double maxAlpha;
  final double duration;
  double age = 0.0;
  final Color color;

  AmbientSmokeWisp({
    required this.startX,
    required this.startY,
    required this.vy,
    required this.waveFreq,
    required this.waveAmp,
    required this.wavePhase,
    required this.maxRadius,
    required this.maxAlpha,
    required this.duration,
    required this.color,
  })  : x = startX,
        y = startY;

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;

    final progress = age / duration;
    y = startY + (vy * age);
    x = startX + (math.sin((progress * waveFreq * 2 * math.pi) + wavePhase) * waveAmp * progress);
    return true;
  }
}

/// Master Incense Smoke Painter
/// ZERO CIRCLES:
/// 1. Directional smoke flight is rendered as an organic, curling, fluid ribbon of incense smoke.
/// 2. Sacred text 'राम' rises gracefully without any circular yellow disc or background halo.
/// 3. Ambient smoke wisps are rendered as vertically elongated, rising smoke plumes.
class DhupSmokePainter extends CustomPainter {
  final List<DirectionalSmokeStream> activeStreams;
  final List<AmbientSmokeWisp> ambientWisps;
  final Offset burnerMouthCenter;

  static final Paint _ribbonPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _ambientPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _wispPaint = Paint()..style = PaintingStyle.fill;

  DhupSmokePainter({
    required this.activeStreams,
    required this.ambientWisps,
    required this.burnerMouthCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ── 1. Draw Ambient Rising Smoke from Burner ───────────────────────
    // Renders elongated vertical plumes (height > width) — NO CIRCULAR BALLS!
    for (final wisp in ambientWisps) {
      final double progress = (wisp.age / wisp.duration).clamp(0.0, 1.0);
      final double alphaCurve = (progress < 0.15)
          ? (progress / 0.15)
          : math.pow(1.0 - progress, 1.2).toDouble();
      final double alpha = (alphaCurve * wisp.maxAlpha).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final double width = 8.0 + (wisp.maxRadius * 0.70 * math.pow(progress, 0.70));
      final double height = 14.0 + (wisp.maxRadius * 1.50 * math.pow(progress, 0.70));
      final center = Offset(wisp.x, wisp.y);

      // Outer soft smoke plume
      _ambientPaint.color = wisp.color.withValues(alpha: alpha * 0.40);
      _ambientPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.45);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: width * 1.4, height: height * 1.2),
        _ambientPaint,
      );

      // Dense visible smoke core
      _ambientPaint.color = Colors.white.withValues(alpha: alpha * 0.65);
      _ambientPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.25);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: width * 0.75, height: height * 0.85),
        _ambientPaint,
      );
    }

    // ── 2. Draw Active Directional Smoke Streams ───────────────────────
    for (final stream in activeStreams) {
      final progress = stream.progress;

      // A. Draw the continuous, flowing incense smoke ribbon while in flight
      if (progress > 0.01 && progress < 1.0) {
        _drawIncenseSmokeRibbon(canvas, stream, progress);
      }

      // B. Draw dissipating organic wisps after arrival (NO YELLOW EXPLOSION!)
      for (final wisp in stream.dissipatingWisps) {
        final double p = (wisp.age / wisp.duration).clamp(0.0, 1.0);
        final double alpha = (math.pow(1.0 - p, 1.3) * wisp.maxAlpha).clamp(0.0, 1.0);
        if (alpha <= 0.01) continue;

        _wispPaint.color = wisp.color.withValues(alpha: alpha);
        _wispPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, wisp.width * 0.35);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(wisp.x, wisp.y),
            width: wisp.width,
            height: wisp.height,
          ),
          _wispPaint,
        );
      }

      // C. Draw traveling sacred text 'राम' at the head of the smoke ribbon
      // ZERO CIRCULAR BACKGROUND AURA!
      if (!stream.hasArrived &&
          stream == activeStreams.lastWhere((s) => !s.hasArrived, orElse: () => stream)) {
        final headPos = stream.getHeadPosition(progress);

        if (stream.text.isNotEmpty) {
          final double textAlpha = (progress < 0.12)
              ? (progress / 0.12)
              : (progress > 0.85 ? ((1.0 - progress) / 0.15) : 1.0);
          final double textScale = 0.90 + (0.25 * math.sin(progress * math.pi));

          final textSpan = TextSpan(
            text: stream.text,
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 22.0 * textScale,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFFDE7).withValues(alpha: textAlpha.clamp(0.0, 1.0)),
              shadows: [
                Shadow(
                  color: const Color(0xFFFF9900).withValues(alpha: (textAlpha * 0.85).clamp(0.0, 1.0)),
                  blurRadius: 10.0,
                ),
                Shadow(
                  color: Colors.black87.withValues(alpha: (textAlpha * 0.70).clamp(0.0, 1.0)),
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

          // Center traveling text precisely at headPos
          final textOffset = Offset(
            headPos.dx - (textPainter.width / 2),
            headPos.dy - (textPainter.height / 2),
          );
          textPainter.paint(canvas, textOffset);
        }
      }
    }
  }

  /// Constructs and renders a continuous, silky ribbon of sacred incense smoke
  /// along the cubic Bezier path from burner mouth to head position.
  /// ZERO CIRCLES — purely fluid ribbon geometry!
  void _drawIncenseSmokeRibbon(
    Canvas canvas,
    DirectionalSmokeStream stream,
    double progress,
  ) {
    const int segments = 24;
    final List<Offset> points = [];
    final List<Offset> normals = [];
    final List<double> widths = [];

    for (int i = 0; i <= segments; i++) {
      final double t = (i / segments) * progress;
      final pt = stream.getHeadPosition(t);
      points.add(pt);

      // Approximate tangent vector
      final double deltaT = 0.01;
      final ptNext = stream.getHeadPosition((t + deltaT).clamp(0.0, 1.0));
      final double dx = ptNext.dx - pt.dx;
      final double dy = ptNext.dy - pt.dy;
      final double len = math.sqrt((dx * dx) + (dy * dy));

      if (len > 0.001) {
        // Normal perpendicular to tangent (-dy, dx)
        normals.add(Offset(-dy / len, dx / len));
      } else {
        normals.add(const Offset(1, 0));
      }

      // Ribbon width expands naturally as smoke wafts upward: ~4px at burner to ~16px near head
      final double normT = i / segments;
      final double w = 4.0 + (12.0 * math.pow(normT, 0.75)) + (math.sin(normT * 10.0) * 2.0);
      widths.add(w);
    }

    if (points.length < 2) return;

    // Construct left boundary (forward) and right boundary (backward)
    final leftPath = Path();
    leftPath.moveTo(
      points[0].dx + (normals[0].dx * widths[0]),
      points[0].dy + (normals[0].dy * widths[0]),
    );

    for (int i = 1; i <= segments; i++) {
      final lx = points[i].dx + (normals[i].dx * widths[i]);
      final ly = points[i].dy + (normals[i].dy * widths[i]);
      leftPath.lineTo(lx, ly);
    }

    // Right boundary backwards
    for (int i = segments; i >= 0; i--) {
      final rx = points[i].dx - (normals[i].dx * widths[i]);
      final ry = points[i].dy - (normals[i].dy * widths[i]);
      leftPath.lineTo(rx, ry);
    }
    leftPath.close();

    // 1. Soft outer incense smoke mist
    _ribbonPaint.color = const Color(0xFFFFFDE7).withValues(alpha: 0.35);
    _ribbonPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawPath(leftPath, _ribbonPaint);

    // 2. Bright dense central smoke thread
    _ribbonPaint.color = Colors.white.withValues(alpha: 0.60);
    _ribbonPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawPath(leftPath, _ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant DhupSmokePainter oldDelegate) => true;
}
