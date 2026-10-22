import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single particle definition representing assembly, ambient glow, and dispersion
class _TextParticle {
  final Offset startOffset;
  final Offset targetOffset;
  final Offset driftOffset;
  final double size;
  final Color color;
  final bool isStar;
  final double sparklePhase;

  const _TextParticle({
    required this.startOffset,
    required this.targetOffset,
    required this.driftOffset,
    required this.size,
    required this.color,
    required this.isStar,
    required this.sparklePhase,
  });
}

/// Generates a deterministic, lightweight set of 24 devotional particles per burst
List<_TextParticle> _generateParticles(int seed, Color primaryColor, Color glowColor) {
  final rng = math.Random(seed);
  final List<_TextParticle> list = [];

  const List<Color> palette = [
    Color(0xFFFFD700), // Pure Gold
    Color(0xFFFFE082), // Soft Amber Gold
    Color(0xFFFF9933), // Sacred Saffron
    Color(0xFFFFF8DC), // Divine Diamond White
    Color(0xFFFFB300), // Deep Radiant Amber
  ];

  // 16 Assembly Particles that converge to form the sacred mantra letters
  for (int i = 0; i < 16; i++) {
    final double angle = (i * (2 * math.pi / 16)) + (rng.nextDouble() * 0.35 - 0.17);
    final double dist = 50.0 + rng.nextDouble() * 40.0;
    final Offset start = Offset(dist * math.cos(angle), dist * math.sin(angle));

    // Target distributed along text horizontal bounds (-50 to +50 width, -12 to +12 height)
    final Offset target = Offset(
      (rng.nextDouble() * 100.0) - 50.0,
      (rng.nextDouble() * 24.0) - 12.0,
    );

    // Subtle drift vector upward and outward when dispersing
    final Offset drift = Offset(
      (rng.nextDouble() * 30.0) - 15.0,
      -15.0 - (rng.nextDouble() * 25.0),
    );

    final bool isStar = (i % 5 == 0);
    final double size = isStar ? (2.2 + rng.nextDouble() * 0.8) : (1.4 + rng.nextDouble() * 1.2);

    list.add(_TextParticle(
      startOffset: start,
      targetOffset: target,
      driftOffset: drift,
      size: size,
      color: palette[rng.nextInt(palette.length)],
      isStar: isStar,
      sparklePhase: rng.nextDouble() * math.pi * 2,
    ));
  }

  // 8 Ambient Floating & Glint Particles around the letters
  for (int i = 0; i < 8; i++) {
    final double angle = rng.nextDouble() * math.pi * 2;
    final double dist = 20.0 + rng.nextDouble() * 30.0;
    final Offset start = Offset(dist * math.cos(angle), dist * math.sin(angle));

    final Offset target = Offset(
      start.dx * 0.75 + (rng.nextDouble() * 10 - 5),
      start.dy * 0.75 + (rng.nextDouble() * 10 - 5),
    );

    final Offset drift = Offset(
      (rng.nextDouble() * 24.0) - 12.0,
      -10.0 - (rng.nextDouble() * 20.0),
    );

    list.add(_TextParticle(
      startOffset: start,
      targetOffset: target,
      driftOffset: drift,
      size: 1.2 + rng.nextDouble() * 1.0,
      color: palette[rng.nextInt(palette.length)],
      isStar: (i % 3 == 0),
      sparklePhase: rng.nextDouble() * math.pi * 2,
    ));
  }

  return list;
}

/// Represents a single expanding mantra instance with particle lifecycle
class _SingleMantraBurst {
  final int id;
  final String text;
  final Offset center;
  final double maxRadius;
  final AnimationController controller;
  final Animation<double> curveAnimation;
  final double angle; // In radians
  final Color primaryColor;
  final Color glowColor;
  final List<_TextParticle> particles;

  _SingleMantraBurst({
    required this.id,
    required this.text,
    required this.center,
    required this.maxRadius,
    required this.controller,
    required this.curveAnimation,
    required this.angle,
    required this.primaryColor,
    required this.glowColor,
    required this.particles,
  });

  void dispose() {
    controller.dispose();
  }
}

/// Controller interface to trigger single radial mantra expansion from anywhere
class RadialMantraBurstController {
  _RadialMantraBurstOverlayState? _state;

  void _attach(_RadialMantraBurstOverlayState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Triggers a single particle-based outward expansion of the divine mantra along the next cycling direction
  void trigger({
    Offset? center,
    String text = 'શ્રી રાધા',
    double? maxRadius,
    Color? primaryColor,
    Color? glowColor,
    int? directionIndex,
  }) {
    _state?.triggerBurst(
      center: center,
      text: text,
      maxRadius: maxRadius,
      primaryColor: primaryColor,
      glowColor: glowColor,
      directionIndex: directionIndex,
    );
  }
}

/// Overlay that animates the sacred mantra text outward with a premium particle reveal,
/// subtle diamond sparkles, golden shimmer sweep, and gentle dispersion.
///
/// Features:
/// - Particles gather together to gradually reveal the sacred text (0–1.8s)
/// - Sparkling starlets glint as the letters become visible
/// - Gentle golden shimmer sweep across the letters (1.8–3.6s)
/// - A few tiny particles gently drift away and disappear (3.6–5.0s)
/// - Sharp, readable glyphs rendered with proper Unicode fonts
/// - 100% transparent background (no box, no dark rectangles, no blurry overlays)
class RadialMantraBurstOverlay extends StatefulWidget {
  final RadialMantraBurstController? controller;
  final Offset defaultCenter;
  final double defaultMaxRadius;
  final Widget? child;

  const RadialMantraBurstOverlay({
    super.key,
    this.controller,
    this.defaultCenter = Offset.zero,
    this.defaultMaxRadius = 240.0,
    this.child,
  });

  @override
  State<RadialMantraBurstOverlay> createState() => _RadialMantraBurstOverlayState();
}

class _RadialMantraBurstOverlayState extends State<RadialMantraBurstOverlay>
    with TickerProviderStateMixin {
  final List<_SingleMantraBurst> _activeBursts = [];
  int _idCounter = 0;
  int _directionCounter = 0;

  // Maximum concurrent animations
  static const int _maxSimultaneousBursts = 14;

  // 8 sequential radial directions (Up, Right, Down, Left, diagonals)
  static const List<double> _directionSequence = [
    -math.pi / 2,     // Tap 1: Up
    0.0,              // Tap 2: Right
    math.pi / 2,      // Tap 3: Down
    math.pi,          // Tap 4: Left
    -math.pi / 4,     // Tap 5: Top-Right
    math.pi / 4,      // Tap 6: Bottom-Right
    3 * math.pi / 4,  // Tap 7: Bottom-Left
    -3 * math.pi / 4, // Tap 8: Top-Left
  ];

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant RadialMantraBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    for (final burst in _activeBursts) {
      burst.dispose();
    }
    _activeBursts.clear();
    super.dispose();
  }

  void triggerBurst({
    Offset? center,
    String text = 'શ્રી રાધા',
    double? maxRadius,
    Color? primaryColor,
    Color? glowColor,
    int? directionIndex,
  }) {
    if (!mounted) return;

    // Prune oldest if max reached
    if (_activeBursts.length >= _maxSimultaneousBursts) {
      final oldest = _activeBursts.removeAt(0);
      oldest.dispose();
    }

    final int burstId = ++_idCounter;

    // Determine direction angle
    final double chosenAngle = (directionIndex != null)
        ? _directionSequence[directionIndex % _directionSequence.length]
        : _directionSequence[_directionCounter % _directionSequence.length];
    _directionCounter++;

    // 5.0 seconds slow, peaceful, meditative duration
    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    final curveAnim = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOutSine,
    );

    final Color prim = primaryColor ?? const Color(0xFFFFD700);
    final Color glow = glowColor ?? const Color(0xFFFF9933);

    final burst = _SingleMantraBurst(
      id: burstId,
      text: text.isNotEmpty ? text : 'શ્રી રાધા',
      center: center ?? widget.defaultCenter,
      maxRadius: maxRadius ?? widget.defaultMaxRadius,
      controller: animController,
      curveAnimation: curveAnim,
      angle: chosenAngle,
      primaryColor: prim,
      glowColor: glow,
      particles: _generateParticles(burstId, prim, glow),
    );

    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _activeBursts.removeWhere((b) => b.id == burstId);
          });
        }
        burst.dispose();
      }
    });

    setState(() {
      _activeBursts.add(burst);
    });

    animController.forward(from: 0.0);
  }

  TextStyle _resolveDevotionalStyle(String text, Color primaryColor, Color glowColor, double opacity) {
    final bool isGujarati = RegExp(r'[\u0A80-\u0AFF]').hasMatch(text);

    final List<Shadow> shadows = [
      // Deep dark outline for high contrast on black and deity images
      Shadow(
        color: Colors.black.withValues(alpha: (opacity * 0.95).clamp(0.0, 1.0)),
        blurRadius: 4,
        offset: const Offset(0, 1.5),
      ),
      // Soft divine golden halo directly surrounding the glyphs
      Shadow(
        color: glowColor.withValues(alpha: (opacity * 0.75).clamp(0.0, 1.0)),
        blurRadius: 10,
        offset: Offset.zero,
      ),
    ];

    if (isGujarati) {
      return GoogleFonts.notoSansGujarati(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: 1.2,
        shadows: shadows,
      );
    } else {
      return GoogleFonts.notoSerifDevanagari(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 1.2,
        shadows: shadows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        if (widget.child != null) widget.child!,

        // Active bursts overlay — renders particle-based reveal and elegant text
        for (final burst in _activeBursts)
          AnimatedBuilder(
            key: ValueKey<int>(burst.id),
            animation: burst.controller,
            builder: (ctx, _) {
              final double t = burst.curveAnimation.value;
              if (t <= 0.0 || t >= 1.0) return const SizedBox.shrink();

              // ── Phase Timing & Opacity Curves ──────────────────────────
              // Stage 1 (0.0 to 0.36, 0–1.8s): Particles gather inwards. Text fades in (0.12 to 0.36)
              // Stage 2 (0.36 to 0.72, 1.8–3.6s): Text fully radiant (opacity 1.0) with subtle shimmer
              // Stage 3 (0.72 to 1.0, 3.6–5.0s): Particles drift away. Text softly fades to 0.0
              double textOpacity;
              if (t < 0.12) {
                textOpacity = 0.0;
              } else if (t < 0.36) {
                textOpacity = ((t - 0.12) / 0.24).clamp(0.0, 1.0);
              } else if (t < 0.72) {
                textOpacity = 1.0;
              } else {
                textOpacity = ((1.0 - t) / 0.28).clamp(0.0, 1.0);
              }

              // Distance: travels peacefully from center (10px) outward
              final double distance = 10.0 + (burst.maxRadius * t);

              // Scale: gentle, continuous expansion from 0.92 to 1.12
              final double scale = 0.92 + (0.20 * t);

              // Coordinates for this instance
              final double x = burst.center.dx + (distance * math.cos(burst.angle));
              final double y = burst.center.dy + (distance * math.sin(burst.angle));

              // Shimmer sweep across the letters during hold phase (t: 0.36 -> 0.72)
              final double shimmerPos = (t >= 0.30 && t <= 0.75)
                  ? ((t - 0.30) / 0.45).clamp(0.0, 1.0)
                  : -1.0;

              final textStyle = _resolveDevotionalStyle(
                burst.text,
                burst.primaryColor,
                burst.glowColor,
                textOpacity,
              );

              return Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: x,
                        top: y,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, -0.5),
                          child: SizedBox(
                            width: 190,
                            height: 90,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // 1. Dynamic Particle Canvas (Gathering, Star Sparkles, Drifting Embers)
                                CustomPaint(
                                  size: const Size(190, 90),
                                  painter: _TextParticlePainter(
                                    particles: burst.particles,
                                    progress: t,
                                    primaryColor: burst.primaryColor,
                                    glowColor: burst.glowColor,
                                  ),
                                ),

                                // 2. Sacred Mantra Text with Smooth Golden Shimmer
                                Opacity(
                                  opacity: textOpacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: (shimmerPos >= 0.0)
                                        ? ShaderMask(
                                            blendMode: BlendMode.srcIn,
                                            shaderCallback: (bounds) {
                                              return LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  burst.primaryColor,
                                                  const Color(0xFFFFFBE6), // Brilliant diamond gold glint
                                                  const Color(0xFFFFE082),
                                                  burst.primaryColor,
                                                ],
                                                stops: [
                                                  (shimmerPos - 0.25).clamp(0.0, 1.0),
                                                  shimmerPos,
                                                  (shimmerPos + 0.12).clamp(0.0, 1.0),
                                                  (shimmerPos + 0.35).clamp(0.0, 1.0),
                                                ],
                                              ).createShader(bounds);
                                            },
                                            child: Text(
                                              burst.text,
                                              textAlign: TextAlign.center,
                                              style: textStyle,
                                            ),
                                          )
                                        : Text(
                                            burst.text,
                                            textAlign: TextAlign.center,
                                            style: textStyle,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Lightweight, high-performance CustomPainter rendering converging particles,
/// sparkling starlets, and fading drift embers.
class _TextParticlePainter extends CustomPainter {
  final List<_TextParticle> particles;
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color glowColor;

  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _starPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.0;

  _TextParticlePainter({
    required this.particles,
    required this.progress,
    required this.primaryColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      Offset pos;
      double particleAlpha;

      if (progress < 0.36) {
        // ── Phase 1: Particles gather softly inward to form the text (0.0 -> 0.36)
        final double gatherFactor = (progress / 0.36).clamp(0.0, 1.0);
        // Smooth easing curve for gathering
        final double eased = Curves.easeInOutCubic.transform(gatherFactor);

        pos = origin + Offset(
          p.startOffset.dx + (p.targetOffset.dx - p.startOffset.dx) * eased,
          p.startOffset.dy + (p.targetOffset.dy - p.startOffset.dy) * eased,
        );

        // Fade in quickly then maintain radiance as they converge
        particleAlpha = (gatherFactor * 1.5).clamp(0.0, 1.0);
      } else if (progress < 0.72) {
        // ── Phase 2: Gentle ambient hovering & twinkling around the assembled letters
        final double holdFactor = (progress - 0.36) / 0.36;
        final double hoverX = math.sin((holdFactor * math.pi * 2) + p.sparklePhase) * 2.5;
        final double hoverY = math.cos((holdFactor * math.pi * 2) + p.sparklePhase) * 1.5;

        pos = origin + p.targetOffset + Offset(hoverX, hoverY);

        // Soft sinusoidal twinkle
        final double twinkle = 0.55 + 0.45 * math.sin((progress * 14.0) + p.sparklePhase);
        particleAlpha = twinkle.clamp(0.0, 1.0);
      } else {
        // ── Phase 3: Tiny particles gently drift away and disappear (0.72 -> 1.0)
        final double driftFactor = (progress - 0.72) / 0.28;
        final double eased = Curves.easeOutQuad.transform(driftFactor);

        pos = origin + p.targetOffset + Offset(
          p.driftOffset.dx * eased,
          p.driftOffset.dy * eased,
        );

        // Gradually fade away to 0.0
        particleAlpha = ((1.0 - driftFactor) * 0.9).clamp(0.0, 1.0);
      }

      if (particleAlpha <= 0.01) continue;

      _particlePaint.color = p.color.withValues(alpha: particleAlpha);

      // Draw particle dot
      canvas.drawCircle(pos, p.size, _particlePaint);

      // Draw 4-point sparkle starlet on star particles
      if (p.isStar && particleAlpha > 0.35) {
        final double starAlpha = (particleAlpha * 0.9).clamp(0.0, 1.0);
        _starPaint.color = Colors.white.withValues(alpha: starAlpha);
        final double arm = p.size * 2.2;

        // Horizontal star ray
        canvas.drawLine(
          Offset(pos.dx - arm, pos.dy),
          Offset(pos.dx + arm, pos.dy),
          _starPaint,
        );
        // Vertical star ray
        canvas.drawLine(
          Offset(pos.dx, pos.dy - arm),
          Offset(pos.dx, pos.dy + arm),
          _starPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TextParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.glowColor != glowColor;
  }
}
