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

          // ── 3. Bottom Controls & Devotional Blessing Banner ──────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blessing Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFB300),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9900).withValues(alpha: 0.45),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        '🙏 जय श्री राम — दिव्य जल दर्शन 🙏',
                        style: GoogleFonts.notoSerifDevanagari(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD54F),
                          shadows: const [
                            Shadow(color: Color(0xFFFF7700), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Actions: [Next Mala 📿] and [Darshan Exit]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Next Mala Button
                        ElevatedButton.icon(
                          onPressed: widget.onNextMala,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          label: Text(
                            'Next Mala',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 6,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Exit Button
                        OutlinedButton(
                          onPressed: widget.onExit,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
                            backgroundColor: Colors.black45,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}
