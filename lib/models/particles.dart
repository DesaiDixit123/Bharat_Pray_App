import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'jap_models.dart';

/// Maximum number of smoke particles allowed simultaneously.
/// Prevents unbounded memory growth during long sessions.
const int kMaxSmokeParticles = 20;

// ─────────────────────────────────────────────
// Shared Random instance — avoids per-frame allocations in update() hot paths
// ─────────────────────────────────────────────
final math.Random _sharedRng = math.Random();

class EmberParticle {
  double x, y, vx, vy, size, alpha, speedMultiplier;
  EmberParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.speedMultiplier,
  });

  void update(double width, double height) {
    x += vx * speedMultiplier;
    y -= vy * speedMultiplier;
    if (y < -20) {
      // Reuse shared RNG — avoids allocating a new math.Random() every frame
      y = height + 20;
      x = _sharedRng.nextDouble() * width;
    }
  }
}

class GlowRing {
  Offset position;
  double maxRadius;
  double life, maxLife;
  Color color;
  GlowRing({
    required this.position,
    required this.maxRadius,
    required this.maxLife,
    required this.color,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    return life > 0;
  }
}

class SmokeParticle {
  double x, y, vx, vy, size, alpha, life, maxLife, growthRate;
  SmokeParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.maxLife,
    required this.growthRate,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    x += vx;
    y -= vy;
    size += growthRate;
    return life > 0;
  }
}

class SpiralSparkParticle {
  Offset center;
  double angle, speed, radialSpeed, life, maxLife, size;
  Color color;
  SpiralSparkParticle({
    required this.center,
    required this.angle,
    required this.speed,
    required this.radialSpeed,
    required this.maxLife,
    required this.size,
    required this.color,
  }) : life = maxLife;

  Offset get currentPosition {
    final progress = (1.0 - (life / maxLife)).clamp(0.0, 1.0);
    final currentRadius = progress * 60.0;
    final curAngle = angle + (progress * speed * 4.0);
    return Offset(
      center.dx + math.cos(curAngle) * currentRadius,
      center.dy + math.sin(curAngle) * currentRadius,
    );
  }

  bool update() {
    life -= 0.016;
    return life > 0;
  }
}

class TapSparkParticle {
  Offset position;
  double vx, vy, life, maxLife, size;
  Color color;
  TapSparkParticle({
    required this.position,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.size,
    required this.color,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    position = position + Offset(vx, vy);
    return life > 0;
  }
}

class FloatingOmText {
  Offset position;
  double life, maxLife;
  String text;
  FloatingOmText({
    required this.position,
    required this.maxLife,
    required this.text,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    position = position - const Offset(0, 0.85);
    return life > 0;
  }
}

class PetalParticle {
  double x, y, vy, angle, rotationSpeed, size, windFreq, windAmp, time;
  Color color;
  ParticleShapeType shape;

  PetalParticle({
    required this.x,
    required this.y,
    required this.vy,
    required this.angle,
    required this.rotationSpeed,
    required this.size,
    required this.windFreq,
    required this.windAmp,
    required this.color,
    required this.shape,
  }) : time = _sharedRng.nextDouble() * 100;

  void update(double width, double height) {
    time += 0.016;
    y += vy;
    x += math.sin(time * windFreq) * windAmp;
    angle += rotationSpeed;

    if (y > height + 20) {
      y = -20;
      // Reuse shared RNG — avoids allocating a new math.Random() every frame
      x = _sharedRng.nextDouble() * width;
    }
  }
}
