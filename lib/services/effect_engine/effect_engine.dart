import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/jap_models.dart';
import '../../models/particles.dart';

// Shared RNG for effect engine — avoids constructing math.Random() in hot paths
final math.Random _engineRng = math.Random();

enum EffectEngineState { idle, active, completing, completed, disposed }

/// Core animation and particle simulation engine, driven exclusively by configuration.
class DivineEffectEngine extends ChangeNotifier {
  EffectPack _pack;
  EffectEngineState _state = EffectEngineState.idle;
  double _intensity = 1.0;
  double _timeSeconds = 0.0;

  // Particle pools
  final List<EmberParticle> _embers = [];
  final List<PetalParticle> _petals = [];
  final List<TapSparkParticle> _tapSparks = [];
  final List<SpiralSparkParticle> _spiralSparks = [];
  final List<SmokeParticle> _smokeParticles = [];
  final List<GlowRing> _glowRings = [];
  final List<FloatingOmText> _floatingOms = [];

  Offset? _activeIncensePosition;
  double _smokeEmitTimer = 0.0;
  DateTime _lastBurstTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _burstThrottle = Duration(milliseconds: 60);

  // Getters
  EffectPack get pack => _pack;
  EffectEngineState get state => _state;
  double get intensity => _intensity;
  double get timeSeconds => _timeSeconds;
  List<EmberParticle> get embers => _embers;
  List<PetalParticle> get petals => _petals;
  List<TapSparkParticle> get tapSparks => _tapSparks;
  List<SpiralSparkParticle> get spiralSparks => _spiralSparks;
  List<SmokeParticle> get smokeParticles => _smokeParticles;
  List<GlowRing> get glowRings => _glowRings;
  List<FloatingOmText> get floatingOms => _floatingOms;
  Offset? get activeIncensePosition => _activeIncensePosition;

  DivineEffectEngine({EffectPack? pack, double initialIntensity = 1.0})
    : _pack = pack ?? EffectPack.defaultGoldPreset,
      _intensity = initialIntensity.clamp(0.1, 2.0) {
    _initAmbientEmbers();
    _state = EffectEngineState.active;
  }

  /// Sets or updates the active EffectPack configuration dynamically at runtime
  void setEffectPack(EffectPack newPack) {
    if (_state == EffectEngineState.disposed) return;
    _pack = newPack;
    _petals.clear();
    notifyListeners();
  }

  /// Sets visual intensity scale (0.1 to 2.0)
  void setIntensity(double value) {
    if (_state == EffectEngineState.disposed) return;
    _intensity = value.clamp(0.1, 2.0);
    notifyListeners();
  }

  /// Sets the active tip position for rising incense smoke
  void setIncensePosition(Offset? pos) {
    _activeIncensePosition = pos;
  }

  void _initAmbientEmbers() {
    _embers.clear();
    final count = (25 * _intensity).round();
    for (int i = 0; i < count; i++) {
      _embers.add(
        EmberParticle(
          x: _engineRng.nextDouble() * 400,
          y: _engineRng.nextDouble() * 1000,
          vx: (_engineRng.nextDouble() * 0.5) - 0.25,
          vy: _engineRng.nextDouble() * 0.6 + 0.4,
          size: _engineRng.nextDouble() * 2.8 + 1.2,
          alpha: _engineRng.nextDouble() * 0.45 + 0.15,
          speedMultiplier: _engineRng.nextDouble() * 0.5 + 0.8,
        ),
      );
    }
  }

  void _initCelebrationPetals(double width, double height) {
    _petals.clear();
    final count = (30 * _intensity).round();
    for (int i = 0; i < count; i++) {
      final color = _pack.particleColors[i % _pack.particleColors.length];
      _petals.add(
        PetalParticle(
          x: _engineRng.nextDouble() * width,
          y: _engineRng.nextDouble() * height - height,
          vy: (_engineRng.nextDouble() * 1.2 + 0.9) * _pack.particleVelocity,
          angle: _engineRng.nextDouble() * 2 * math.pi,
          rotationSpeed: (_engineRng.nextDouble() * 0.035) - 0.0175,
          size: _engineRng.nextDouble() * 8.0 + 8.0,
          windFreq: _engineRng.nextDouble() * 1.3 + 0.7,
          windAmp: _engineRng.nextDouble() * 1.2 + 0.6,
          color: color,
          shape: _pack.shape,
        ),
      );
    }
  }

  /// Advances the physics simulation by delta time (e.g. 0.016s for 60fps)
  void update(
    double dt, {
    double screenWidth = 393,
    double screenHeight = 852,
  }) {
    if (_state == EffectEngineState.disposed ||
        _state == EffectEngineState.idle) {
      return;
    }

    _timeSeconds += dt;

    // 1. Embers update
    for (final ember in _embers) {
      ember.update(screenWidth, screenHeight);
    }

    // 2. Glow rings & sparks update
    _glowRings.removeWhere((ring) => !ring.update());
    _tapSparks.removeWhere((spark) => !spark.update());
    _spiralSparks.removeWhere((spark) => !spark.update());
    _floatingOms.removeWhere((om) => !om.update());

    // 3. Smoke update (capped at kMaxSmokeParticles to prevent memory growth)
    if (_activeIncensePosition != null &&
        _state != EffectEngineState.completing) {
      _smokeEmitTimer += dt;
      if (_smokeEmitTimer >= _pack.smokeEmissionIntervalSec &&
          _smokeParticles.length < kMaxSmokeParticles) {
        _smokeEmitTimer = 0.0;
        _smokeParticles.add(
          SmokeParticle(
            x: _activeIncensePosition!.dx,
            y: _activeIncensePosition!.dy,
            vx: (_engineRng.nextDouble() * 0.4) - 0.2,
            vy: _engineRng.nextDouble() * 0.6 + 0.6,
            size: _engineRng.nextDouble() * 2.0 + 2.0,
            alpha: _engineRng.nextDouble() * 0.10 + 0.08,
            maxLife: _engineRng.nextDouble() * 1.5 + 1.0,
            growthRate: _engineRng.nextDouble() * 0.4 + 0.2,
          ),
        );
      }
    }
    _smokeParticles.removeWhere((smoke) => !smoke.update());

    // 4. Petals update
    for (final petal in _petals) {
      petal.update(screenWidth, screenHeight);
    }

    // Guard: skip notifyListeners() if no visual state changed (all pools empty, no smoke)
    final bool hasActiveParticles =
        _embers.isNotEmpty ||
        _petals.isNotEmpty ||
        _tapSparks.isNotEmpty ||
        _spiralSparks.isNotEmpty ||
        _smokeParticles.isNotEmpty ||
        _glowRings.isNotEmpty ||
        _floatingOms.isNotEmpty;
    if (!hasActiveParticles && _state == EffectEngineState.active) return;
    notifyListeners();
  }

  /// Triggers a tap burst effect at a given coordinate with throttle protection and haptic feedback
  void triggerTapBurst(Offset position, {double scale = 1.0}) {
    if (_state == EffectEngineState.disposed) return;

    final now = DateTime.now();
    if (now.difference(_lastBurstTime) < _burstThrottle) {
      return; // Coalesce rapid triggers
    }
    _lastBurstTime = now;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    final effectiveScale = scale * _intensity;

    // 1. Radial sparks
    final sparkCount = (12 * effectiveScale).round().clamp(4, 24);
    for (int i = 0; i < sparkCount; i++) {
      final angle =
          (i / sparkCount.toDouble()) * 2 * math.pi +
          (_engineRng.nextDouble() * 0.4 - 0.2);
      final speed = (_engineRng.nextDouble() * 5.0 + 3.5) * effectiveScale;
      final sparkColors = [
        const Color(0xFFFFD700),
        const Color(0xFFFF9100),
        const Color(0xFFFFFFFF),
        _pack.primaryColor,
      ];
      _tapSparks.add(
        TapSparkParticle(
          position: position,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          maxLife: _engineRng.nextDouble() * 0.35 + 0.35,
          size: (_engineRng.nextDouble() * 4.0 + 3.0) * effectiveScale,
          color: sparkColors[i % sparkColors.length],
        ),
      );
    }

    // 2. Double-helix spiral swirl sparks
    final spiralCount = (8 * effectiveScale).round().clamp(2, 16);
    for (int i = 0; i < spiralCount; i++) {
      final startAngle = (i / spiralCount.toDouble()) * 2 * math.pi;
      _spiralSparks.add(
        SpiralSparkParticle(
          center: position,
          angle: startAngle,
          speed:
              (i % 2 == 0 ? 1.0 : -1.0) *
              (_engineRng.nextDouble() * 0.18 + 0.12),
          radialSpeed: (_engineRng.nextDouble() * 2.8 + 2.2) * effectiveScale,
          maxLife: _engineRng.nextDouble() * 0.35 + 0.40,
          size: (_engineRng.nextDouble() * 3.5 + 2.5) * effectiveScale,
          color: i % 2 == 0 ? const Color(0xFFFFD700) : _pack.primaryColor,
        ),
      );
    }

    // 3. Floating sacred glyph
    final omTexts = ['ॐ', 'राम', 'जय', 'ॐ', 'हरि', 'नमः'];
    _floatingOms.add(
      FloatingOmText(
        position: position,
        maxLife: 0.65,
        text: omTexts[_engineRng.nextInt(omTexts.length)],
      ),
    );

    // 4. Glow Ring
    _glowRings.add(
      GlowRing(
        position: position,
        maxRadius: 180.0 * effectiveScale,
        maxLife: 1.1,
        color: _pack.primaryColor,
      ),
    );

    notifyListeners();
  }

  /// Triggers full celebratory completion shower and dispatches completion callback
  void triggerCompletion({
    double screenWidth = 393,
    double screenHeight = 852,
    Duration duration = const Duration(milliseconds: 1200),
    VoidCallback? onComplete,
  }) {
    if (_state == EffectEngineState.disposed) return;

    _state = EffectEngineState.completing;
    _initCelebrationPetals(screenWidth, screenHeight);
    notifyListeners();

    _completionTimer?.cancel();
    _completionTimer = Timer(duration, () {
      if (_state != EffectEngineState.disposed) {
        _state = EffectEngineState.completed;
        notifyListeners();
        if (onComplete != null) {
          onComplete();
        }
      }
    });
  }

  Timer? _completionTimer;

  /// Cleans up all particle pools and sets engine state to disposed
  @override
  void dispose() {
    if (_state == EffectEngineState.disposed) return;
    _completionTimer?.cancel();
    _state = EffectEngineState.disposed;
    _embers.clear();
    _petals.clear();
    _tapSparks.clear();
    _spiralSparks.clear();
    _smokeParticles.clear();
    _glowRings.clear();
    _floatingOms.clear();
    super.dispose();
  }
}
