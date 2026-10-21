import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../services/darshan_animation_service.dart';

/// Full-Screen AI-Powered & Devotional Live Darshan Experience.
///
/// Features:
/// 1. Smooth 800ms cross-fade transition once 100% reveal is reached.
/// 2. Loops AI-generated video/GIF when available from backend or local cache.
/// 3. Zero-latency Local Devotional Darshan Animation Engine fallback:
///    - Living breathing & posture motion (6s sinusoidal cycle)
///    - Divine mukut/crown halo pulse (2.8s radiant aura)
///    - Rotating celestial sunbeams & light rays (24s cycle)
///    - Sacred tilak/eye blessing shimmer
///    - Drifting celestial petals & golden prana particles
///    - Sanctum sanctorum ghee diya ambient glow
class LiveDarshanView extends StatefulWidget {
  final ImageProvider imageProvider;
  final String deityId;
  final String deityName;
  final Color activeColor;
  final Color glowColor;
  final VoidCallback? onReplay;

  const LiveDarshanView({
    super.key,
    required this.imageProvider,
    required this.deityId,
    required this.deityName,
    this.activeColor = const Color(0xFFFF9933),
    this.glowColor = const Color(0xFFFFD700),
    this.onReplay,
  });

  @override
  State<LiveDarshanView> createState() => _LiveDarshanViewState();
}

class _LiveDarshanViewState extends State<LiveDarshanView>
    with TickerProviderStateMixin {
  // Animation controllers for living darshan engine
  late final AnimationController _entryController;
  late final AnimationController _breathingController;
  late final AnimationController _auraController;
  late final AnimationController _raysController;
  late final AnimationController _shimmerController;
  late final AnimationController _particleController;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  DarshanAnimationMode _activeMode = DarshanAnimationMode.localDarshanEngine;

  @override
  void initState() {
    super.initState();

    // 1. Smooth 800ms transition into darshan
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // 2. Living breathing motion (6s serene cycle)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    // 3. Divine crown / aura pulse (2.8s cycle)
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // 4. Rotating celestial sunbeams (24s continuous loop)
    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // 5. Sacred tilak / divine gaze shimmer (4s cycle)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // 6. Floating celestial petals & prana particles (8s loop)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 7. Check for AI video or cached assets
    _loadDarshanAsset();
  }

  Future<void> _loadDarshanAsset() async {
    try {
      final result = await DarshanAnimationService.getDarshanAnimation(
        deityId: widget.deityId,
        deityName: widget.deityName,
      );

      if (!mounted) return;

      if (result.hasVideo) {
        VideoPlayerController? ctrl;
        if (result.localFilePath != null && File(result.localFilePath!).existsSync()) {
          ctrl = VideoPlayerController.file(File(result.localFilePath!));
        } else if (result.videoUrl != null && result.videoUrl!.isNotEmpty) {
          ctrl = VideoPlayerController.networkUrl(Uri.parse(result.videoUrl!));
        }

        if (ctrl != null) {
          await ctrl.initialize();
          await ctrl.setLooping(true);
          await ctrl.setVolume(0.0);
          await ctrl.play();

          if (mounted) {
            setState(() {
              _videoController = ctrl;
              _isVideoInitialized = true;
              _activeMode = DarshanAnimationMode.aiVideo;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[LiveDarshanView] Asset load error: $e');
    }

    if (mounted) {
      setState(() {
        _activeMode = DarshanAnimationMode.localDarshanEngine;
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathingController.dispose();
    _auraController.dispose();
    _raysController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Base Background Atmosphere ─────────────────────
          Container(color: Colors.black),

          // ── Layer 2: Rotating Celestial Divine Light Rays ───────────
          AnimatedBuilder(
            animation: _raysController,
            builder: (ctx, _) {
              return Transform.rotate(
                angle: _raysController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CelestialRaysPainter(
                    color: widget.glowColor.withValues(alpha: 0.18),
                  ),
                ),
              );
            },
          ),

          // ── Layer 3: Divine Mukut / Crown Pulsing Halo ──────────────
          AnimatedBuilder(
            animation: _auraController,
            builder: (ctx, _) {
              final double auraPulse = 0.85 + (0.25 * _auraController.value);
              return Center(
                child: Container(
                  width: 320 * auraPulse,
                  height: 320 * auraPulse,
                  margin: const EdgeInsets.only(bottom: 90),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.glowColor.withValues(alpha: 0.40 * _auraController.value),
                        widget.activeColor.withValues(alpha: 0.20 * _auraController.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Layer 4: Living Deity Artwork or AI Video Playback ───────
          if (_isVideoInitialized && _videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            // High-Fidelity Living Devotional Darshan Engine
            AnimatedBuilder(
              animation: _breathingController,
              builder: (ctx, _) {
                // Lifelike breathing motion: 1.0 -> 1.025 scale with gentle vertical drift
                final double breathScale = 1.0 + (0.022 * _breathingController.value);
                final double breathY = -4.0 * _breathingController.value;

                return Transform.translate(
                  offset: Offset(0, breathY),
                  child: Transform.scale(
                    scale: breathScale,
                    child: Image(
                      image: widget.imageProvider,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                );
              },
            ),

          // ── Layer 5: Sacred Tilak / Divine Blessing Shimmer ──────────
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (ctx, _) {
              final double shimmerProgress = _shimmerController.value;
              // Shimmer fires gently between 0.35 and 0.65 of the cycle
              if (shimmerProgress < 0.35 || shimmerProgress > 0.65) {
                return const SizedBox.shrink();
              }
              final double shimmerOpacity = math.sin((shimmerProgress - 0.35) / 0.30 * math.pi);

              return Center(
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 120),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFF8E1).withValues(alpha: 0.55 * shimmerOpacity),
                        widget.glowColor.withValues(alpha: 0.25 * shimmerOpacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Layer 6: Drifting Celestial Jasmine & Rose Petals ────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (ctx, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _DevotionalPetalsPainter(
                  progress: _particleController.value,
                  accentColor: widget.activeColor,
                  glowColor: widget.glowColor,
                ),
              );
            },
          ),

          // ── Layer 7: Sanctum Sanctorum Ghee Diya Ambient Glow ────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 180,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _auraController,
                builder: (ctx, _) {
                  final double flicker = 0.85 + (0.15 * math.sin(_auraController.value * math.pi * 3));
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFFFF6F00).withValues(alpha: 0.32 * flicker),
                          const Color(0xFFFFB300).withValues(alpha: 0.12 * flicker),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Layer 8: Respectful Live Darshan Status Badge ────────────
          Positioned(
            top: 52,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.glowColor.withValues(alpha: 0.55),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.glowColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.glowColor,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _activeMode == DarshanAnimationMode.aiVideo
                        ? '✨ Live Darshan (AI)'
                        : '✨ Live Darshan (Living Engine)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering rotating celestial volumetric light rays
class _CelestialRaysPainter extends CustomPainter {
  final Color color;

  _CelestialRaysPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.40);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int rayCount = 12;
    final double rayLength = size.longestSide * 1.2;
    const double angleStep = (2 * math.pi) / rayCount;

    for (int i = 0; i < rayCount; i++) {
      final double startAngle = i * angleStep;
      final double sweepAngle = angleStep * 0.35;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + rayLength * math.cos(startAngle),
          center.dy + rayLength * math.sin(startAngle),
        )
        ..lineTo(
          center.dx + rayLength * math.cos(startAngle + sweepAngle),
          center.dy + rayLength * math.sin(startAngle + sweepAngle),
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialRaysPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom painter rendering softly falling jasmine/rose petals and rising golden prana embers
class _DevotionalPetalsPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color glowColor;

  static final List<_PetalParticle> _particles = List.generate(24, (i) {
    final rand = math.Random(i * 37 + 11);
    return _PetalParticle(
      startX: rand.nextDouble(),
      speed: 0.6 + (rand.nextDouble() * 0.8),
      size: 4.0 + (rand.nextDouble() * 6.0),
      swayFrequency: 2.0 + (rand.nextDouble() * 3.0),
      swayAmplitude: 15.0 + (rand.nextDouble() * 25.0),
      isPetal: i % 2 == 0,
    );
  });

  _DevotionalPetalsPainter({
    required this.progress,
    required this.accentColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final double yRatio = (p.startX * 0.5 + progress * p.speed) % 1.0;
      final double y = yRatio * size.height;
      final double sway = math.sin((yRatio * p.swayFrequency * 2 * math.pi)) * p.swayAmplitude;
      final double x = (p.startX * size.width + sway) % size.width;

      final double fade = math.sin(yRatio * math.pi).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = (p.isPetal ? const Color(0xFFFF80AB) : glowColor).withValues(alpha: 0.65 * fade)
        ..style = PaintingStyle.fill;

      if (p.isPetal) {
        // Draw petal as an oval
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(sway * 0.05);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size * 0.9),
          paint,
        );
        canvas.restore();
      } else {
        // Draw glowing golden prana ember
        canvas.drawCircle(Offset(x, y), p.size * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DevotionalPetalsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PetalParticle {
  final double startX;
  final double speed;
  final double size;
  final double swayFrequency;
  final double swayAmplitude;
  final bool isPetal;

  const _PetalParticle({
    required this.startX,
    required this.speed,
    required this.size,
    required this.swayFrequency,
    required this.swayAmplitude,
    required this.isPetal,
  });
}
