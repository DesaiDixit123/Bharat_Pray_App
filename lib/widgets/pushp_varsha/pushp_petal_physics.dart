import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PetalType {
  lotusPetal,
  marigoldPetal,
  goldenPollen,
  jasminePetal,
}

/// Represents a single ambient falling flower petal or pollen particle in Pushp Varsha.
class FallingPetal {
  double x;
  double y;
  double startX;
  double vy;
  double swayAmp;
  double swayFreq;
  double phase;
  double rotation;
  double rotSpeed;
  double tumble;
  double tumbleSpeed;
  double size;
  double alpha;
  double maxAlpha;
  double life;
  double maxLife;
  bool isBackground;
  PetalType type;

  FallingPetal({
    required this.x,
    required this.y,
    required this.vy,
    required this.swayAmp,
    required this.swayFreq,
    required this.phase,
    required this.rotation,
    required this.rotSpeed,
    required this.tumble,
    required this.tumbleSpeed,
    required this.size,
    required this.maxAlpha,
    required this.maxLife,
    required this.isBackground,
    required this.type,
  })  : startX = x,
        alpha = 0.0,
        life = 0.0;

  bool update(double dt, double screenHeight) {
    life += dt;
    if (life >= maxLife || y > screenHeight + 30) return false;

    // Advance vertical position with downward gravity
    y += vy * dt;

    // Horizontal sinusoidal sway
    final double swayTime = life * swayFreq * 2 * math.pi;
    x = startX + (math.sin(swayTime + phase) * swayAmp);

    // 2D Rotation and 3D Tumble Flutter
    rotation += rotSpeed * dt;
    tumble += tumbleSpeed * dt;

    // Fade in gracefully at top, maintain opacity, fade out at bottom
    final double norm = life / maxLife;
    if (norm < 0.15) {
      alpha = maxAlpha * (norm / 0.15);
    } else if (norm > 0.85) {
      alpha = maxAlpha * (1.0 - ((norm - 0.85) / 0.15));
    } else {
      alpha = maxAlpha;
    }
    return true;
  }
}

/// Represents a sacred flower petal flying gracefully towards a target location on Lord Shri Ram.
class TargetedPetal {
  final Offset start;
  final Offset control;
  final Offset target;
  final PetalType type;
  final double size;
  final double duration; // Calibrated slow duration (e.g. 1.4 .. 1.8s)
  final double delay; // Staggered launch delay
  final double rotSpeed;
  final double tumbleSpeed;
  final double swayAmp;
  final double swayFreq;
  final double maxAlpha;
  final double maxDriftTime;

  double elapsed = 0.0;
  double rotation = 0.0;
  double tumble = 0.0;
  Offset currentPos = Offset.zero;
  double alpha = 0.0;
  bool hasArrived = false;
  double driftElapsed = 0.0;
  Offset driftVelocity = Offset.zero;

  TargetedPetal({
    required this.start,
    required this.control,
    required this.target,
    required this.type,
    required this.size,
    required this.duration,
    this.delay = 0.0,
    required this.rotSpeed,
    required this.tumbleSpeed,
    required this.swayAmp,
    required this.swayFreq,
    this.maxAlpha = 0.95,
    this.maxDriftTime = 0.40,
  }) {
    currentPos = start;
  }

  /// Updates petal trajectory along smooth ease-out Bezier curve to target.
  /// Returns false when the petal has completely finished its graceful drift.
  bool update(double dt) {
    elapsed += dt;
    if (elapsed < delay) {
      currentPos = start;
      alpha = 0.0;
      return true;
    }

    final double activeTime = elapsed - delay;
    final double rawT = (activeTime / duration).clamp(0.0, 1.0);
    // Graceful ease-out cubic deceleration: floats gently as it nears the deity
    final double t = Curves.easeOutCubic.transform(rawT);

    rotation += rotSpeed * dt;
    tumble += tumbleSpeed * dt;

    if (rawT < 1.0) {
      // Bezier curve: (1-t)^2 * P0 + 2*(1-t)*t * P1 + t^2 * P2
      final double invT = 1.0 - t;
      final double bx = (invT * invT * start.dx) + (2 * invT * t * control.dx) + (t * t * target.dx);
      final double by = (invT * invT * start.dy) + (2 * invT * t * control.dy) + (t * t * target.dy);

      // Natural fluttering breeze sway
      final double flutter = math.sin(activeTime * swayFreq * 2 * math.pi) * swayAmp * (1.0 - (0.4 * rawT));
      currentPos = Offset(bx + flutter, by);

      // Fade in smoothly at launch
      alpha = (rawT < 0.12) ? (maxAlpha * (rawT / 0.12)) : maxAlpha;
      return true;
    } else {
      // Petal has arrived at the target point!
      if (!hasArrived) {
        hasArrived = true;
        final rand = math.Random();
        driftVelocity = Offset(
          (rand.nextDouble() - 0.5) * 20.0,
          10.0 + (rand.nextDouble() * 20.0),
        );
      }

      driftElapsed += dt;
      if (driftElapsed >= maxDriftTime) return false;

      // Gentle drift and soft dissolve
      currentPos += driftVelocity * dt;
      final double driftT = driftElapsed / maxDriftTime;
      alpha = maxAlpha * (1.0 - driftT);
      return true;
    }
  }
}

/// A radiant golden spark or pollen particle bursting outward when flower petals hit their target.
class PetalImpactSpark {
  Offset position;
  final Offset velocity;
  final double size;
  final double maxLife;
  final Color color;
  double life = 0.0;
  double alpha = 1.0;

  PetalImpactSpark({
    required this.position,
    required this.velocity,
    required this.size,
    required this.maxLife,
    required this.color,
  });

  bool update(double dt) {
    life += dt;
    if (life >= maxLife) return false;

    position += velocity * dt;
    final double t = life / maxLife;
    alpha = (1.0 - t).clamp(0.0, 1.0);
    return true;
  }
}

/// Represents a sacred mantra text ('राम', 'श्री राम', 'जय श्री राम') emerging on tap
/// and floating gracefully along with flower petals towards the deity.
class FloatingRamText {
  final String text;
  final Offset start;
  final Offset control;
  final Offset target;
  final double duration;
  final double fontSize;

  double elapsed = 0.0;
  Offset currentPos = Offset.zero;
  double alpha = 0.0;
  double scale = 0.75;
  bool hasArrived = false;
  double driftElapsed = 0.0;
  static const double maxDrift = 0.45;

  FloatingRamText({
    required this.text,
    required this.start,
    required this.control,
    required this.target,
    this.duration = 1.38,
    this.fontSize = 20.0,
  }) {
    currentPos = start;
  }

  /// Updates text position along ease-out Bezier arc and dissolves upon arrival.
  bool update(double dt) {
    elapsed += dt;
    final double rawT = (elapsed / duration).clamp(0.0, 1.0);
    final double t = Curves.easeOutCubic.transform(rawT);

    if (rawT < 1.0) {
      final double invT = 1.0 - t;
      final double bx = (invT * invT * start.dx) +
          (2 * invT * t * control.dx) +
          (t * t * target.dx);
      final double by = (invT * invT * start.dy) +
          (2 * invT * t * control.dy) +
          (t * t * target.dy);

      // Gentle horizontal swaying float
      final double sway = math.sin(elapsed * 2.8) * 8.0;
      currentPos = Offset(bx + sway, by);

      // Smooth fade-in and scale-up from launch button
      if (rawT < 0.15) {
        alpha = (rawT / 0.15).clamp(0.0, 1.0);
        scale = 0.75 + (0.35 * (rawT / 0.15));
      } else {
        alpha = 1.0;
        scale = 1.10 + (0.10 * rawT);
      }
      return true;
    } else {
      if (!hasArrived) {
        hasArrived = true;
        driftElapsed = 0.0;
        currentPos = target;
        alpha = 1.0;
        scale = 1.20;
        return true;
      }
      driftElapsed += dt;
      if (driftElapsed >= maxDrift) return false;

      // Soft rise and golden glow dissolution at destination
      final double driftT = driftElapsed / maxDrift;
      currentPos = Offset(target.dx, target.dy - (driftT * 20.0));
      scale = 1.20 + (0.15 * driftT);
      alpha = (1.0 - driftT).clamp(0.0, 1.0);
      return true;
    }
  }
}

