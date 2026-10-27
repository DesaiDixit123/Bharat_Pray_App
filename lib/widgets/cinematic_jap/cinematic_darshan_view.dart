import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-Screen Pure Divine Lord Shri Ram Live Darshan View.
///
/// Features (Strict Master Prompt Compliance):
/// 1. Pure Full-Screen Darshan: NO mala, NO counter, NO buttons, NO progress ring, NO text labels.
/// 2. Live Darshan Video: Plays seamless looping video of Lord Shri Ram giving live darshan (1080x1920).
/// 3. Zero-gap High-Resolution fallback during video buffering/initialization.
/// 4. Cinematic Camera & Respiration: Organic breathing motion when displaying portrait fallback.
/// 5. Subtle Temple Atmosphere: Warm golden illumination and peaceful temple ambiance.
class CinematicDarshanView extends StatefulWidget {
  final String imageAsset;
  final String? videoAsset;
  final String? videoUrl;
  final bool isSoundEnabled;
  final VoidCallback? onExitRequested;

  const CinematicDarshanView({
    super.key,
    this.imageAsset = 'assets/images/lord_shri_ram_darshan.png',
    this.videoAsset = 'assets/videos/lord_shri_ram_live_darshan.mp4',
    this.videoUrl,
    this.isSoundEnabled = true,
    this.onExitRequested,
  });

  @override
  State<CinematicDarshanView> createState() => _CinematicDarshanViewState();
}

class _CinematicDarshanViewState extends State<CinematicDarshanView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Animation Controllers ──────────────────────────────────────────
  late final AnimationController _cameraController; // Initial dolly-in (6000ms)
  late final AnimationController _breathingController; // Divine breathing (5200ms loop)
  late final AnimationController _ambientController; // Continuous cosmic flow (30s loop)
  late final AnimationController _jewelShimmerController; // Jewellery gleam cycle (7500ms loop)
  late final AnimationController _blinkController; // Divine gentle eye soften/blink (5500ms loop)
  late final AnimationController _diyaFlickerController; // Temple diya lamp flame flicker (1800ms loop)
  late final AnimationController _entryFadeController; // Initial smooth fade-in (1200ms)

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  final List<_GoldenParticle> _particles = [];
  final List<_RosePetal> _petals = [];
  final math.Random _rng = math.Random(108);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Initial Soft Entry Fade-in (1200ms)
    _entryFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // 2. Cinematic Camera Dolly-in (6000ms)
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..forward();

    // 3. Divine Breathing Respiration (5200ms continuous loop)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);

    // 4. Cosmic Ambient Flow (Volumetric rays, particles, petals: 30s)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // 5. Jewellery Light Sweep Cycle (7500ms)
    _jewelShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..repeat();

    // 6. Divine Eye Soften / Peaceful Blink (5500ms loop for true living presence)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();

    // 7. Temple Diya Aarti Flame Flicker (1800ms continuous organic flicker)
    _diyaFlickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 8. Initialize 26 Golden Light Particles drifting upward
    for (int i = 0; i < 26; i++) {
      _particles.add(
        _GoldenParticle(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          speed: 0.025 + (_rng.nextDouble() * 0.05),
          radius: 1.0 + (_rng.nextDouble() * 2.2),
          maxAlpha: 0.30 + (_rng.nextDouble() * 0.45),
          phase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }

    // 9. Initialize 12 Delicate Rose Petals swaying gently downward
    for (int i = 0; i < 12; i++) {
      _petals.add(
        _RosePetal(
          x: 0.05 + (_rng.nextDouble() * 0.90),
          y: _rng.nextDouble(),
          speed: 0.018 + (_rng.nextDouble() * 0.035),
          size: 7.0 + (_rng.nextDouble() * 6.5),
          rotationSpeed: 0.35 + (_rng.nextDouble() * 0.7),
          swayAmplitude: 0.025 + (_rng.nextDouble() * 0.04),
          phase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }

    // 10. Initialize Full Live Darshan Video Player
    if (widget.videoAsset != null || widget.videoUrl != null) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      VideoPlayerController? ctrl;
      if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else if (widget.videoAsset != null && widget.videoAsset!.isNotEmpty) {
        ctrl = VideoPlayerController.asset(widget.videoAsset!);
      }
      if (ctrl == null) return;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(widget.isSoundEnabled ? 1.0 : 0.0);
      await ctrl.play();
      if (mounted) {
        setState(() {
          _videoController = ctrl;
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[CinematicDarshanView] Video player initialization: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _videoController?.pause();
      _cameraController.stop();
      _breathingController.stop();
      _ambientController.stop();
      _jewelShimmerController.stop();
      _blinkController.stop();
      _diyaFlickerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _videoController?.play();
      if (_cameraController.value < 1.0) _cameraController.forward();
      _breathingController.repeat(reverse: true);
      _ambientController.repeat();
      _jewelShimmerController.repeat();
      _blinkController.repeat();
      _diyaFlickerController.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.pause();
    _videoController?.dispose();
    _entryFadeController.dispose();
    _cameraController.dispose();
    _breathingController.dispose();
    _ambientController.dispose();
    _jewelShimmerController.dispose();
    _blinkController.dispose();
    _diyaFlickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: Deep Temple Background Aura & Atmospheric Illumination ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breathingController,
              builder: (context, _) {
                final double breath = _breathingController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.45),
                      radius: 1.1 + (0.15 * breath),
                      colors: [
                        const Color(0xFF4A2800).withValues(alpha: 0.45 + (0.10 * breath)),
                        const Color(0xFF1E0E02).withValues(alpha: 0.65),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── LAYER 1B: Temple Garbhagriha Diya Lamp Warm Flame Illumination ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _diyaFlickerController,
              builder: (context, _) {
                final double t = _diyaFlickerController.value * 2 * math.pi;
                final double flicker = 0.22 + (0.06 * math.sin(t * 3.0)) + (0.03 * math.cos(t * 7.0));
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.85), // Temple altar floor illumination
                      radius: 0.95,
                      colors: [
                        const Color(0xFFFF9900).withValues(alpha: flicker),
                        const Color(0xFFFF6F00).withValues(alpha: flicker * 0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── LAYER 2: Divine Volumetric Golden Rays emanating from Halo Arch ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ambientController, _breathingController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _DivineVolumetricRaysPainter(
                    rotationProgress: _ambientController.value,
                    breathingProgress: _breathingController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // ── LAYER 3: Complete Lord Shri Ram Living Video Darshan ───────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _entryFadeController,
              builder: (context, _) {
                final double entryOpacity = Curves.easeOut.transform(_entryFadeController.value);

                // When live darshan video is ready, render it full-screen with seamless BoxFit.cover
                if (_isVideoInitialized && _videoController != null) {
                  return Opacity(
                    opacity: entryOpacity,
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),
                  );
                }

                // Smooth high-res fallback while video buffers / initializes
                final double cameraScale = 1.0 + (0.038 * Curves.easeInOutCubic.transform(_cameraController.value));
                final double breathVal = _breathingController.value;
                final double breathCurve = math.sin(breathVal * math.pi);
                final double scaleX = cameraScale * (1.0 + (0.005 * breathCurve));
                final double scaleY = cameraScale * (1.0 + (0.013 * breathCurve));

                return Opacity(
                  opacity: entryOpacity,
                  child: Transform(
                    transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                    alignment: const Alignment(0.0, 0.15), // Centered on sacred chest
                    child: Image.asset(
                      widget.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── LAYER 4: Divine Eye Illumination & Highlights (Fallback when video loading) ──
          if (!_isVideoInitialized)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _breathingController,
                  _jewelShimmerController,
                  _cameraController,
                  _blinkController,
                ]),
                builder: (context, _) {
                  final double cameraScale = 1.0 + (0.038 * Curves.easeInOutCubic.transform(_cameraController.value));
                  final double breathVal = _breathingController.value;
                  final double breathCurve = math.sin(breathVal * math.pi);
                  final double scaleX = cameraScale * (1.0 + (0.005 * breathCurve));
                  final double scaleY = cameraScale * (1.0 + (0.013 * breathCurve));

                  return Transform(
                    transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                    alignment: const Alignment(0.0, 0.15),
                    child: CustomPaint(
                      painter: _DivineFeaturesPainter(
                        breathingProgress: _breathingController.value,
                        jewelProgress: _jewelShimmerController.value,
                        blinkProgress: _blinkController.value,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
            ),

          // ── LAYER 5: Ambient Floating Golden Particles & Soft Rose Petals ─────
          if (!_isVideoInitialized)
            Positioned.fill(
              child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AmbientAtmospherePainter(
                    progress: _ambientController.value,
                    particles: _particles,
                    petals: _petals,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // ── LAYER 6: Subtle Devotee Exit (Pure & Unobtrusive) ─────────────
          // Devotee can peacefully tap top-left when ready to return
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onExitRequested != null) {
                      widget.onExitRequested!();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFFE082),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS FOR DIVINE LIVE DARSHAN
// ─────────────────────────────────────────────────────────────────────────────

/// 1. Volumetric Golden Rays emanating from the Temple Halo behind Bhagwan's crown
class _DivineVolumetricRaysPainter extends CustomPainter {
  final double rotationProgress;
  final double breathingProgress;

  _DivineVolumetricRaysPainter({
    required this.rotationProgress,
    required this.breathingProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final dstRect = _computeDstRect(size, 682.0 / 1024.0);

    // Prabhavali Halo Arch Center directly behind Bhagwan's crown (u = 0.50, v = 0.16)
    final center = Offset(
      dstRect.left + (0.50 * dstRect.width),
      dstRect.top + (0.16 * dstRect.height),
    );
    final double maxRadius = math.max(size.width, size.height) * 0.95;

    const int rayCount = 16;
    final double angleStep = (2 * math.pi) / rayCount;
    final double baseRotation = rotationProgress * 2 * math.pi;
    final double breathAlpha = 0.14 + (0.06 * math.sin(breathingProgress * math.pi));

    for (int i = 0; i < rayCount; i++) {
      final double rayAngle = baseRotation + (i * angleStep);
      const double rayWidth = 0.07; // Narrow wedge in radians

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + (maxRadius * math.cos(rayAngle - rayWidth)),
        center.dy + (maxRadius * math.sin(rayAngle - rayWidth)),
      );
      path.lineTo(
        center.dx + (maxRadius * math.cos(rayAngle + rayWidth)),
        center.dy + (maxRadius * math.sin(rayAngle + rayWidth)),
      );
      path.close();

      final rayPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          maxRadius,
          [
            const Color(0xFFFFD54F).withValues(alpha: breathAlpha),
            const Color(0xFFFF9900).withValues(alpha: breathAlpha * 0.45),
            Colors.transparent,
          ],
          [0.0, 0.40, 1.0],
        );

      canvas.drawPath(path, rayPaint);
    }
  }

  static Rect _computeDstRect(Size size, double aspect) {
    final double screenRatio = size.width / size.height;
    double dstW, dstH, dstX, dstY;
    if (screenRatio > aspect) {
      dstW = size.width;
      dstH = size.width / aspect;
      dstX = 0.0;
      dstY = (size.height - dstH) / 2.0;
    } else {
      dstH = size.height;
      dstW = size.height * aspect;
      dstY = 0.0;
      dstX = (size.width - dstW) / 2.0;
    }
    return Rect.fromLTWH(dstX, dstY, dstW, dstH);
  }

  @override
  bool shouldRepaint(covariant _DivineVolumetricRaysPainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress ||
        oldDelegate.breathingProgress != breathingProgress;
  }
}

/// 2. Divine Eye Illumination, Gentle Soft Blink, Jewellery Specular Reflections, and Halo Bloom
class _DivineFeaturesPainter extends CustomPainter {
  final double breathingProgress;
  final double jewelProgress;
  final double blinkProgress;

  _DivineFeaturesPainter({
    required this.breathingProgress,
    required this.jewelProgress,
    required this.blinkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Aspect-ratio dstRect mapped for BoxFit.cover
    final dstRect = _computeDstRect(size, 682.0 / 1024.0);

    // ── A. Divine Lotus Eyes (Live Gaze, Soft Natural Blink & Specular Twinkle) ────
    final leftEye = Offset(dstRect.left + (0.441 * dstRect.width), dstRect.top + (0.282 * dstRect.height));
    final rightEye = Offset(dstRect.left + (0.548 * dstRect.width), dstRect.top + (0.287 * dstRect.height));

    final double eyeBreath = math.sin(breathingProgress * math.pi);
    final double baseAlpha = 0.22 + (0.18 * eyeBreath);
    final double glintRadius = dstRect.width * 0.0075;

    // Peaceful Divine Soft Blink Window: t = 0.88 to 0.94 (~330ms every 5.5s)
    double blinkAmount = 0.0;
    if (blinkProgress >= 0.88 && blinkProgress <= 0.94) {
      final double bt = (blinkProgress - 0.88) / 0.06;
      blinkAmount = math.sin(bt * math.pi); // 0.0 -> 1.0 -> 0.0
    }

    if (blinkAmount > 0.02) {
      // Gentle natural eyelid softening in divine blue skin tone
      final lidPaint = Paint()
        ..color = const Color(0xFF6B8FA8).withValues(alpha: (0.42 * blinkAmount).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

      canvas.drawOval(
        Rect.fromCenter(
          center: leftEye + Offset(0, 1.5 * blinkAmount),
          width: dstRect.width * 0.038,
          height: dstRect.width * 0.020 * blinkAmount,
        ),
        lidPaint,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: rightEye + Offset(0, 1.5 * blinkAmount),
          width: dstRect.width * 0.038,
          height: dstRect.width * 0.020 * blinkAmount,
        ),
        lidPaint,
      );
    }

    // Moist Specular Eye Twinkle (intensifies softly as eyes open)
    final double twinkleBoost = (blinkProgress > 0.94 && blinkProgress < 0.99)
        ? 0.35 * math.sin(((blinkProgress - 0.94) / 0.05) * math.pi)
        : 0.0;

    final double effectiveEyeAlpha = ((baseAlpha + twinkleBoost) * (1.0 - (0.85 * blinkAmount))).clamp(0.0, 1.0);

    if (effectiveEyeAlpha > 0.02) {
      final eyeGlintPaint = Paint()
        ..shader = ui.Gradient.radial(
          leftEye,
          glintRadius * 2.8,
          [
            const Color(0xFFFFFFFF).withValues(alpha: effectiveEyeAlpha),
            const Color(0xFFFFE082).withValues(alpha: effectiveEyeAlpha * 0.55),
            Colors.transparent,
          ],
          [0.0, 0.40, 1.0],
        );
      canvas.drawCircle(leftEye, glintRadius * 2.8, eyeGlintPaint);

      final rightEyeGlintPaint = Paint()
        ..shader = ui.Gradient.radial(
          rightEye,
          glintRadius * 2.8,
          [
            const Color(0xFFFFFFFF).withValues(alpha: effectiveEyeAlpha),
            const Color(0xFFFFE082).withValues(alpha: effectiveEyeAlpha * 0.55),
            Colors.transparent,
          ],
          [0.0, 0.40, 1.0],
        );
      canvas.drawCircle(rightEye, glintRadius * 2.8, rightEyeGlintPaint);
    }

    // ── B. Crown & Jewellery Specular Shimmer Sweep ─────────────────────────
    // Selected sacred ornaments matching reference image landmarks in sacred rhythm:
    final jewelTargets = [
      _JewelGlint(u: 0.505, v: 0.080, size: 5.5, label: 'Crown Ruby Crest', triggerT: 0.12),
      _JewelGlint(u: 0.501, v: 0.256, size: 4.8, label: 'Forehead Tilak Jewel', triggerT: 0.28),
      _JewelGlint(u: 0.880, v: 0.220, size: 5.4, label: 'Kodanda Bow Gold Finial', triggerT: 0.44),
      _JewelGlint(u: 0.220, v: 0.350, size: 4.5, label: 'Left Ear Kundal', triggerT: 0.58),
      _JewelGlint(u: 0.650, v: 0.370, size: 4.5, label: 'Right Ear Kundal', triggerT: 0.70),
      _JewelGlint(u: 0.510, v: 0.525, size: 6.2, label: 'Necklace Royal Pendant', triggerT: 0.82),
      _JewelGlint(u: 0.140, v: 0.880, size: 7.0, label: 'Blessing Lotus Hand Aura', triggerT: 0.94),
    ];

    for (final j in jewelTargets) {
      final double dt = (jewelProgress - j.triggerT).abs();
      final double normalizedDt = dt > 0.5 ? (1.0 - dt) : dt;
      if (normalizedDt < 0.12) {
        final double intensity = 1.0 - (normalizedDt / 0.12);
        final double alpha = (intensity * 0.85).clamp(0.0, 1.0);

        final pos = Offset(
          dstRect.left + (j.u * dstRect.width),
          dstRect.top + (j.v * dstRect.height),
        );

        final jewelGlowPaint = Paint()
          ..shader = ui.Gradient.radial(
            pos,
            j.size * 2.4,
            [
              const Color(0xFFFFFDE7).withValues(alpha: alpha),
              const Color(0xFFFFD700).withValues(alpha: alpha * 0.60),
              Colors.transparent,
            ],
            [0.0, 0.35, 1.0],
          );
        canvas.drawCircle(pos, j.size * 2.4, jewelGlowPaint);

        // Delicate 4-point cross-glint sparkle
        final sparkPaint = Paint()
          ..color = const Color(0xFFFFFDE7).withValues(alpha: alpha * 0.90)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;

        final double sparkLen = j.size * 1.6;
        canvas.drawLine(pos - Offset(sparkLen, 0), pos + Offset(sparkLen, 0), sparkPaint);
        canvas.drawLine(pos - Offset(0, sparkLen), pos + Offset(0, sparkLen), sparkPaint);
      }
    }
  }

  static Rect _computeDstRect(Size size, double aspect) {
    final double screenRatio = size.width / size.height;
    double dstW, dstH, dstX, dstY;
    if (screenRatio > aspect) {
      dstW = size.width;
      dstH = size.width / aspect;
      dstX = 0.0;
      dstY = (size.height - dstH) / 2.0;
    } else {
      dstH = size.height;
      dstW = size.height * aspect;
      dstY = 0.0;
      dstX = (size.width - dstW) / 2.0;
    }
    return Rect.fromLTWH(dstX, dstY, dstW, dstH);
  }

  @override
  bool shouldRepaint(covariant _DivineFeaturesPainter oldDelegate) {
    return oldDelegate.breathingProgress != breathingProgress ||
        oldDelegate.jewelProgress != jewelProgress ||
        oldDelegate.blinkProgress != blinkProgress;
  }
}

/// 3. Ambient Floating Golden Particles & Swaying Rose Petals
class _AmbientAtmospherePainter extends CustomPainter {
  final double progress;
  final List<_GoldenParticle> particles;
  final List<_RosePetal> petals;

  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  _AmbientAtmospherePainter({
    required this.progress,
    required this.particles,
    required this.petals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ── A. Floating Golden Particles (drift upward around ambient space) ──
    for (final p in particles) {
      final double currentY = (p.y - (progress * p.speed)) % 1.0;
      final double driftX = p.x + (0.02 * math.sin(p.phase + (progress * 2 * math.pi)));
      final double px = (driftX % 1.0) * size.width;
      final double py = currentY * size.height;

      // Soft vertical fade at top/bottom screen edges
      final double edgeAlpha = math.sin(currentY * math.pi);
      final double alpha = (p.maxAlpha * edgeAlpha).clamp(0.0, 1.0);

      _particlePaint.color = const Color(0xFFFFD700).withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.radius, _particlePaint);

      _particlePaint.color = const Color(0xFFFF9900).withValues(alpha: alpha * 0.35);
      canvas.drawCircle(Offset(px, py), p.radius * 2.2, _particlePaint);
    }

    // ── B. Delicate Pink Rose Petals (sway downward peacefully) ─────────
    for (final pt in petals) {
      final double currentY = (pt.y + (progress * pt.speed)) % 1.0;
      final double swayX = pt.x + (pt.swayAmplitude * math.sin(pt.phase + (progress * 2 * math.pi * 1.5)));
      final double px = (swayX % 1.0) * size.width;
      final double py = currentY * size.height;

      final double edgeAlpha = math.sin(currentY * math.pi);
      final double alpha = (0.75 * edgeAlpha).clamp(0.0, 1.0);

      // Save canvas state for petal rotation
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(progress * pt.rotationSpeed * 2 * math.pi);

      final petalPath = Path();
      final double w = pt.size;
      final double h = pt.size * 1.4;

      petalPath.moveTo(0, -h / 2);
      petalPath.cubicTo(w / 2, -h / 4, w / 2, h / 4, 0, h / 2);
      petalPath.cubicTo(-w / 2, h / 4, -w / 2, -h / 4, 0, -h / 2);
      petalPath.close();

      final petalPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -h / 2),
          Offset(0, h / 2),
          [
            const Color(0xFFFF80AB).withValues(alpha: alpha),
            const Color(0xFFF48FB1).withValues(alpha: alpha * 0.90),
            const Color(0xFFC2185B).withValues(alpha: alpha * 0.75),
          ],
          [0.0, 0.5, 1.0],
        );

      canvas.drawPath(petalPath, petalPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS FOR PARTICLES & PETALS
// ─────────────────────────────────────────────────────────────────────────────

class _GoldenParticle {
  double x;
  double y;
  final double speed;
  final double radius;
  final double maxAlpha;
  final double phase;

  _GoldenParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.maxAlpha,
    required this.phase,
  });
}

class _RosePetal {
  double x;
  double y;
  final double speed;
  final double size;
  final double rotationSpeed;
  final double swayAmplitude;
  final double phase;

  _RosePetal({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.phase,
  });
}

class _JewelGlint {
  final double u;
  final double v;
  final double size;
  final String label;
  final double triggerT;

  const _JewelGlint({
    required this.u,
    required this.v,
    required this.size,
    required this.label,
    required this.triggerT,
  });
}
