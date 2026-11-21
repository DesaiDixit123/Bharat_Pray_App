import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft billowing smoke puff created at the destination node during the 1-2s dispersal animation.
class DispersalSmokePuff {
  double x;
  double y;
  final double vx;
  final double vy;
  final double maxRadius;
  final double maxAlpha;
  final double duration;
  double age = 0.0;
  final Color color;

  DispersalSmokePuff({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxRadius,
    required this.maxAlpha,
    required this.duration,
    required this.color,
  });

  bool update(double dt) {
    age += dt;
    if (age >= duration) return false;
    x += (vx * dt) + (math.sin(age * 3.5) * 4.0 * dt);
    y += vy * dt;
    return true;
  }
}

/// Dynamic, living ribbon of sacred dhoop smoke that travels
/// from the brass Dhup Dani wick all the way to the target reveal location.
/// - Full continuous smoke ribbon from wick to target ("akhu e avavu joie").
/// - Word 'राम' rides at the leading tip of the smoke all the way to the reveal spot.
/// - Upon arrival, enters a 1-2 second authentic smoke dispersal animation ("smoke type animation ma desapear thavu joei").
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

  // 1-2 second authentic smoke dispersal animation after arrival
  double dispersalElapsed = 0.0;
  final double dispersalDuration; // Typically 1.2 to 1.4 seconds smoke dispersal animation
  bool isFinished = false;

  final List<DispersalSmokePuff> dispersalPuffs = [];
  final Offset control1;
  final Offset control2;

  DirectionalSmokeStream({
    required this.step,
    required this.start,
    required this.target,
    required this.onArrived,
    this.duration = 1.0,
    this.dispersalDuration = 1.3,
    this.text = 'राम',
  })  : control1 = _computeControlPoint1(start, target, step),
        control2 = _computeControlPoint2(start, target, step);

  static Offset _computeControlPoint1(Offset start, Offset target, int step) {
    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    // Add step-based organic curve sway so multiple concurrent streams branch out gracefully
    final double sway = (((step * 3) % 7) - 3) * 12.0;
    final sign = (dx >= 0) ? -1.0 : 1.0;
    return Offset(
      start.dx + (dx * 0.20) + (sign * 35.0) + sway,
      start.dy + (dy * 0.45),
    );
  }

  static Offset _computeControlPoint2(Offset start, Offset target, int step) {
    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    final double sway = (((step * 5) % 7) - 3) * 10.0;
    final sign = (dx >= 0) ? 1.0 : -1.0;
    return Offset(
      start.dx + (dx * 0.70) + (sign * 28.0) + sway,
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
    if (!hasArrived) {
      if (forcedProgress != null) {
        progress = forcedProgress.clamp(0.0, 1.0);
        elapsed = progress * duration;
      } else {
        elapsed += dt;
        progress = (elapsed / duration).clamp(0.0, 1.0);
      }

      // When smoke head reaches the target node coordinate:
      if (progress >= 1.0) {
        progress = 1.0;
        hasArrived = true;
        onArrived();

        // Spawn realistic temple smoke dispersal billows at target
        _spawnDispersalPuffs();
      }
      return true;
    }

    // ── Dispersal Phase (1.2 - 1.4 seconds) ──
    dispersalElapsed += dt;

    // Update dispersal puffs
    dispersalPuffs.removeWhere((puff) => !puff.update(dt));

    // Guaranteed complete disappearance: clear puffs and finish immediately once dispersal duration reached
    if (dispersalElapsed >= dispersalDuration) {
      dispersalPuffs.clear();
      isFinished = true;
      return false;
    }

    return true;
  }

  void _spawnDispersalPuffs() {
    final rng = math.Random();
    const int puffCount = 7;
    for (int i = 0; i < puffCount; i++) {
      final double angle = (i * (2 * math.pi / puffCount)) + ((rng.nextDouble() - 0.5) * 0.40);
      final double speed = 10.0 + (rng.nextDouble() * 15.0);
      dispersalPuffs.add(
        DispersalSmokePuff(
          x: target.dx + (math.cos(angle) * 4.0),
          y: target.dy + (math.sin(angle) * 4.0),
          vx: math.cos(angle) * speed,
          vy: -14.0 - (rng.nextDouble() * 18.0), // Gracefully drifts upward
          maxRadius: 24.0 + (rng.nextDouble() * 16.0), // Softly expands
          maxAlpha: 0.38 + (rng.nextDouble() * 0.12),
          duration: 1.0 + (rng.nextDouble() * 0.25), // 1.0 to 1.25 seconds duration
          color: const Color(0xFFFFFDE7),
        ),
      );
    }
  }
}

/// Continuous ambient rising smoke wisp.
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
class DhupSmokePainter extends CustomPainter {
  final List<DirectionalSmokeStream> activeStreams;
  final List<AmbientSmokeWisp> ambientWisps;
  final Offset burnerMouthCenter;
  final double smokeTime;
  final double smokeIntensity;

  static final Paint _ribbonPaint = Paint()..style = PaintingStyle.fill;

  DhupSmokePainter({
    required this.activeStreams,
    this.ambientWisps = const [],
    required this.burnerMouthCenter,
    this.smokeTime = 0.0,
    this.smokeIntensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final stream in activeStreams) {
      if (stream.isFinished) continue;

      // ── A. Dynamic, full incense smoke ribbon from wick to target ──
      _drawIncenseSmokeRibbon(canvas, stream);

      // ── B. Soft billowing smoke dispersal puffs at the target node ──
      for (final puff in stream.dispersalPuffs) {
        final double p = (puff.age / puff.duration).clamp(0.0, 1.0);
        final double alpha = math.pow(1.0 - p, 1.4) * puff.maxAlpha;
        if (alpha <= 0.01) continue;

        // Smoke puff softly billows outward from ~10px to maxRadius
        final double radius = 10.0 + ((puff.maxRadius - 10.0) * math.sin(p * math.pi * 0.5));

        final puffPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = puff.color.withValues(alpha: (alpha * 0.40).clamp(0.0, 1.0))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);

        canvas.drawCircle(Offset(puff.x, puff.y), radius, puffPaint);
      }

      // ── C. Sacred text 'राम' riding the smoke to the reveal spot ──
      // In flight: 100% visible, arrives right ON the target point!
      // After arrival: softly pulses and dissolves over ~0.8s into the revealed darshan
      if (stream.text.isNotEmpty) {
        double textAlpha = 1.0;
        double textScale = 1.0;
        Offset textCenter = Offset.zero;

        if (!stream.hasArrived) {
          // In flight: text flies at the leading tip of the smoke
          textCenter = stream.getHeadPosition(stream.progress);
          textAlpha = (stream.progress < 0.10) ? (stream.progress / 0.10) : 1.0;
          textScale = 0.95 + (0.20 * math.sin(stream.progress * math.pi));
        } else {
          // At target: smoothly dissolves over 0.5 seconds into the image
          textCenter = stream.target;
          final double p = (stream.dispersalElapsed / 0.50).clamp(0.0, 1.0);
          textAlpha = (1.0 - p);
          textScale = 1.0 + (0.18 * math.sin(p * math.pi));
        }

        if (textAlpha > 0.01) {
          final textSpan = TextSpan(
            text: stream.text,
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 24 * textScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD54F).withValues(alpha: textAlpha.clamp(0.0, 1.0)),
              shadows: [
                Shadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.85 * textAlpha),
                  blurRadius: 14.0,
                ),
                Shadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.50 * textAlpha),
                  blurRadius: 22.0,
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
            textCenter.dx - (textPainter.width / 2),
            textCenter.dy - (textPainter.height / 2),
          );
          textPainter.paint(canvas, textOffset);
        }
      }
    }
  }

  /// Constructs and renders a continuous, silky ribbon of sacred incense smoke
  /// along the cubic Bezier path from the diya wick all the way to the target node.
  /// Full smoke from wick to target while in flight; evaporates from bottom to top on dispersal.
  void _drawIncenseSmokeRibbon(
    Canvas canvas,
    DirectionalSmokeStream stream,
  ) {
    final double progress = stream.progress;
    if (progress <= 0.01) return;

    double tailT = 0.0;
    double headT = progress;
    double ribbonAlpha = 1.0;

    if (!stream.hasArrived) {
      // Full smoke from the burner wick all the way to current head position
      tailT = 0.0;
      headT = progress;
      ribbonAlpha = (progress < 0.10) ? (progress / 0.10) : 1.0;
    } else {
      // Dispersal phase: ribbon trail evaporates from burner upward over dispersalDuration
      final double p = (stream.dispersalElapsed / stream.dispersalDuration).clamp(0.0, 1.0);
      if (p >= 1.0) return; // fully evaporated
      tailT = p;
      headT = 1.0;
      ribbonAlpha = math.pow(1.0 - p, 1.4).toDouble();
    }

    if (headT <= tailT || ribbonAlpha <= 0.01) return;

    const int segments = 24;
    final List<Offset> points = [];
    final List<Offset> normals = [];
    final List<double> widths = [];

    for (int i = 0; i <= segments; i++) {
      final double normI = i / segments;
      final double t = tailT + (normI * (headT - tailT));
      final pt = stream.getHeadPosition(t);
      points.add(pt);

      final double deltaT = 0.01;
      final ptNext = stream.getHeadPosition((t + deltaT).clamp(0.0, 1.0));
      final double dx = ptNext.dx - pt.dx;
      final double dy = ptNext.dy - pt.dy;
      final double len = math.sqrt((dx * dx) + (dy * dy));

      if (len > 0.001) {
        normals.add(Offset(-dy / len, dx / len));
      } else {
        normals.add(const Offset(1, 0));
      }

      // Beautiful fluid smoke ribbon width (broader near target, slender at burner)
      final double w = 3.5 + (12.0 * math.pow(t, 0.70)) + (math.sin(normI * 9.0) * 1.8);
      widths.add(w);
    }

    if (points.length < 2) return;

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

    for (int i = segments; i >= 0; i--) {
      final rx = points[i].dx - (normals[i].dx * widths[i]);
      final ry = points[i].dy - (normals[i].dy * widths[i]);
      leftPath.lineTo(rx, ry);
    }
    leftPath.close();

    // Soft outer incense mist
    _ribbonPaint.color = const Color(0xFFFFFDE7).withValues(alpha: (0.32 * ribbonAlpha).clamp(0.0, 1.0));
    _ribbonPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    canvas.drawPath(leftPath, _ribbonPaint);

    // Visible core smoke thread
    _ribbonPaint.color = Colors.white.withValues(alpha: (0.55 * ribbonAlpha).clamp(0.0, 1.0));
    _ribbonPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(leftPath, _ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant DhupSmokePainter oldDelegate) => true;
}
