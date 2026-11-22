import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

/// Full-screen 108 Jap completion Climax view for Divine Jal Darshan.
/// Features:
/// - Seamless looping playback of the live darshan video (`ram_jal_live_darshan.mp4`).
/// - Zero-gap fallback to high-resolution portrait (`ram_jal_darshan.png`).
/// - Floating lotus petals and divine golden water sparkles.
/// - Completion message: "🙏 जय श्री राम — दिव्य जल दर्शन 🙏".
class JalDarshanClimaxView extends StatefulWidget {
  final VoidCallback onNextMala;
  final VoidCallback onExit;
  final String videoAsset;
  final String imageAsset;

  const JalDarshanClimaxView({
    super.key,
    required this.onNextMala,
    required this.onExit,
    this.videoAsset = 'assets/videos/ram_jal_live_darshan.mp4',
    this.imageAsset = 'assets/images/ram_jal_darshan.png',
  });

  @override
  State<JalDarshanClimaxView> createState() => _JalDarshanClimaxViewState();
}

class _JalDarshanClimaxViewState extends State<JalDarshanClimaxView>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset(widget.videoAsset);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0); // Devotional bell plays independently
      await controller.play();

      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoReady = true;
        });
      }
    } catch (e) {
      debugPrint('[JalDarshanClimaxView] Video playback notice: $e');
      if (mounted) {
        setState(() => _isVideoReady = false);
      }
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Live Darshan Video or High-Res Fallback ──────────────
          if (_isVideoReady && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width > 0
                      ? _videoController!.value.size.width
                      : 1080,
                  height: _videoController!.value.size.height > 0
                      ? _videoController!.value.size.height
                      : 1920,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            Image.asset(
              widget.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Colors.black),
            ),

          // ── 2. Radiant Golden Aura & Temple Water Vignette ───────────
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              final double t = _ambientController.value * 2 * math.pi;
              final double glow = 0.20 + (0.08 * math.sin(t));
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [
                      const Color(0xFFFFD54F).withValues(alpha: glow),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              );
            },
          ),

          // ── 3. Subtle Top-Left Back Button (Pure Live Darshan, matching Divine Reveal) ──
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onExit,
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
      );
  }
}
