import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/jap_models.dart';
import 'effect_engine.dart';

enum DivineEffectLayer { background, overlay, all }

/// Declarative Flutter player widget rendering divine effects driven by DivineEffectEngine.
class DivineEffectPlayer extends StatefulWidget {
  final EffectPack pack;
  final double intensity;
  final bool isCompleted;
  final DivineEffectLayer layer;
  final DivineEffectEngine? engine;
  final Widget? child;

  const DivineEffectPlayer({
    super.key,
    required this.pack,
    this.intensity = 1.0,
    this.isCompleted = false,
    this.layer = DivineEffectLayer.all,
    this.engine,
    this.child,
  });

  @override
  State<DivineEffectPlayer> createState() => _DivineEffectPlayerState();
}

class _DivineEffectPlayerState extends State<DivineEffectPlayer>
    with SingleTickerProviderStateMixin {
  late final DivineEffectEngine _engine;
  late final AnimationController _tickerController;
  bool _ownsEngine = false;

  @override
  void initState() {
    super.initState();
    if (widget.engine != null) {
      _engine = widget.engine!;
    } else {
      _engine = DivineEffectEngine(
        pack: widget.pack,
        initialIntensity: widget.intensity,
      );
      _ownsEngine = true;
    }

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onTick);
    _tickerController.repeat();
  }

  Duration _lastTickElapsed = Duration.zero;

  /// Calculates real delta time from AnimationController elapsed duration.
  /// This fixes animation speed on 90Hz / 120Hz devices (previously hardcoded 0.016 = 60fps only).
  void _onTick() {
    final elapsed = _tickerController.lastElapsedDuration ?? Duration.zero;
    final rawDt = (elapsed - _lastTickElapsed).inMicroseconds / 1000000.0;
    _lastTickElapsed = elapsed;
    // Clamp dt to a safe range: min 4ms (250fps cap), max 50ms (20fps floor)
    final dt = rawDt.clamp(0.004, 0.050);
    _engine.update(dt);
  }

  @override
  void didUpdateWidget(covariant DivineEffectPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pack != widget.pack) {
      _engine.setEffectPack(widget.pack);
    }
    if (oldWidget.intensity != widget.intensity) {
      _engine.setIntensity(widget.intensity);
    }
    if (!oldWidget.isCompleted && widget.isCompleted) {
      _engine.triggerCompletion();
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _engine,
      builder: (context, _) {
        final breathingScale =
            1.0 + (0.015 * math.sin(_engine.timeSeconds * 1.8));

        return CustomPaint(
          painter: _DivineEffectCanvasPainter(
            engine: _engine,
            layer: widget.layer,
            isCompleted: widget.isCompleted,
            // Pass a lightweight key so shouldRepaint can do fast comparison
            particleVersion:
                _engine.tapSparks.length +
                _engine.spiralSparks.length +
                _engine.floatingOms.length +
                _engine.glowRings.length,
          ),
          child: widget.child != null
              ? Transform.scale(scale: breathingScale, child: widget.child)
              : null,
        );
      },
    );
  }
}

class _DivineEffectCanvasPainter extends CustomPainter {
  final DivineEffectEngine engine;
  final DivineEffectLayer layer;
  final bool isCompleted;

  /// Lightweight version counter used by shouldRepaint to avoid unnecessary repaints
  final int particleVersion;

  _DivineEffectCanvasPainter({
    required this.engine,
    required this.layer,
    required this.isCompleted,
    this.particleVersion = 0,
  });

  // TextPainter cache — avoids alloc + layout per floating glyph per frame
  static final Map<String, TextPainter> _textPainterCache = {};

  static TextPainter _cachedTextPainter(String text, Color color) {
    final key = '$text:${color.toARGB32()}';
    if (_textPainterCache.containsKey(key)) {
      // Reuse cached painter — no alloc, no layout
      return _textPainterCache[key]!;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _textPainterCache[key] = tp;
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);

    // 1. Background Aura & Trishul-inspired radiance
    if (layer == DivineEffectLayer.background ||
        layer == DivineEffectLayer.all) {
      final pulse = 0.14 + (math.sin(engine.timeSeconds * 2.2) * 0.04);
      final auraPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                engine.pack.haloGlowColor.withValues(
                  alpha: pulse.clamp(0.0, 0.40),
                ),
                engine.pack.primaryColor.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.85),
            );
      canvas.drawCircle(center, size.width * 0.85, auraPaint);

      // Divine light rays / spear motif (driven purely by particle shape configuration)
      if (engine.pack.shape == ParticleShapeType.leaf) {
        final trishulPulse = 0.09 + (math.sin(engine.timeSeconds * 2.0) * 0.04);
        final trishulPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  engine.pack.haloGlowColor.withValues(
                    alpha: (trishulPulse * 1.8).clamp(0.0, 0.5),
                  ),
                  engine.pack.accentColor.withValues(alpha: 0.0),
                ],
              ).createShader(
                Rect.fromLTWH(center.dx - 40, center.dy - 120, 80, 200),
              );

        final trishulPath = Path();
        // Central luminous spear
        trishulPath.moveTo(center.dx, center.dy - 115);
        trishulPath.lineTo(center.dx, center.dy + 65);
        // Left prong
        trishulPath.moveTo(center.dx, center.dy + 5);
        trishulPath.cubicTo(
          center.dx - 35,
          center.dy - 25,
          center.dx - 35,
          center.dy - 75,
          center.dx - 22,
          center.dy - 100,
        );
        // Right prong
        trishulPath.moveTo(center.dx, center.dy + 5);
        trishulPath.cubicTo(
          center.dx + 35,
          center.dy - 25,
          center.dx + 35,
          center.dy - 75,
          center.dx + 22,
          center.dy - 100,
        );

        canvas.drawPath(trishulPath, trishulPaint);
      }
    }

    // 2. Overlay Floating Embers, Om Particles & Falling Petals
    if (layer == DivineEffectLayer.overlay || layer == DivineEffectLayer.all) {
      // Floating Sacred Vibhuti Ash Embers
      final emberPaint = Paint()..style = PaintingStyle.fill;
      for (final ember in engine.embers) {
        emberPaint.color = engine.pack.secondaryColor.withValues(
          alpha: ember.alpha,
        );
        canvas.drawCircle(Offset(ember.x, ember.y), ember.size, emberPaint);
      }

      // Tap Burst Sparks
      for (final spark in engine.tapSparks) {
        final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);
        final sparkPaint = Paint()
          ..color = spark.color.withValues(alpha: alpha);
        canvas.drawCircle(spark.position, spark.size, sparkPaint);
      }

      // Spiral Helix Sparks
      for (final spark in engine.spiralSparks) {
        final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);
        final pos = spark.currentPosition;
        final spiralPaint = Paint()
          ..color = spark.color.withValues(alpha: alpha);
        canvas.drawCircle(pos, spark.size, spiralPaint);
      }

      // Floating Sacred Om Glyphs
      for (final om in engine.floatingOms) {
        final alpha = (om.life / om.maxLife).clamp(0.0, 1.0);
        final omColor = engine.pack.secondaryColor.withValues(alpha: alpha);
        // Reuse cached TextPainter — eliminates alloc+layout hot path
        final textPainter = _cachedTextPainter(om.text, omColor);
        textPainter.paint(
          canvas,
          om.position - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }

      // Falling Bilva Leaves / Petals Shower (when active or completed)
      if (isCompleted || engine.petals.isNotEmpty) {
        for (final petal in engine.petals) {
          canvas.save();
          canvas.translate(petal.x, petal.y);
          canvas.rotate(petal.angle);
          final paint = Paint()
            ..color = petal.color
            ..style = PaintingStyle.fill;

          final path = Path();
          switch (petal.shape) {
            case ParticleShapeType.leaf:
              path.moveTo(0, -petal.size);
              path.quadraticBezierTo(
                petal.size * 0.6,
                -petal.size * 0.3,
                0,
                petal.size * 0.5,
              );
              path.quadraticBezierTo(
                -petal.size * 0.6,
                -petal.size * 0.3,
                0,
                -petal.size,
              );
              canvas.drawPath(path, paint);
              break;

            case ParticleShapeType.feather:
              final rect = Rect.fromCenter(
                center: Offset.zero,
                width: petal.size * 0.8,
                height: petal.size * 1.5,
              );
              canvas.drawOval(rect, paint);
              canvas.drawCircle(
                Offset.zero,
                petal.size * 0.25,
                Paint()..color = const Color(0xFFFFD700),
              );
              break;

            case ParticleShapeType.spark:
            case ParticleShapeType.flame:
              // Two-circle fake glow: GPU-safe on all Android (no MaskFilter.blur / software fallback)
              // Visually equivalent at particle sizes 3–8px
              canvas.drawCircle(
                Offset.zero,
                petal.size * 0.6,
                Paint()..color = petal.color.withValues(alpha: 0.45),
              );
              canvas.drawCircle(Offset.zero, petal.size * 0.3, paint);
              break;

            case ParticleShapeType.petal:
            case ParticleShapeType.ash:
            case ParticleShapeType.custom:
              path.moveTo(0, -petal.size / 2);
              path.quadraticBezierTo(
                petal.size / 2.5,
                -petal.size / 4,
                0,
                petal.size / 2,
              );
              path.quadraticBezierTo(
                -petal.size / 2.5,
                -petal.size / 4,
                0,
                -petal.size / 2,
              );
              path.close();
              canvas.drawPath(path, paint);
              break;
          }
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DivineEffectCanvasPainter oldDelegate) {
    // Only repaint when visible state actually changes:
    // particle pool sizes, completion flag, or time has advanced
    return oldDelegate.isCompleted != isCompleted ||
        oldDelegate.particleVersion != particleVersion ||
        (oldDelegate.engine.timeSeconds - engine.timeSeconds).abs() > 0.008;
  }
}
