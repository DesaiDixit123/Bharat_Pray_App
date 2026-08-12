import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/jap_models.dart';
import '../../models/darshan_model.dart';
import '../../services/jap_session_controller.dart';
import '../../services/effect_engine/effect_engine.dart';
import '../../services/effect_engine/effect_player.dart';

enum DarshanStreamState {
  loading,
  liveStreaming,
  fallbackVideo,
  fallbackImage,
  error,
}

/// Devotional Darshan runtime experience opened only after a valid Jap completion.
class DarshanRuntimeScreen extends StatefulWidget {
  final JapConfig config;
  final DarshanConfig? darshanConfig;
  final JapSessionController? sessionController;

  const DarshanRuntimeScreen({
    super.key,
    required this.config,
    this.darshanConfig,
    this.sessionController,
  });

  @override
  State<DarshanRuntimeScreen> createState() => _DarshanRuntimeScreenState();
}

class _DarshanRuntimeScreenState extends State<DarshanRuntimeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  VideoPlayerController? _videoPlayerController;
  late final DivineEffectEngine _effectEngine;
  late final AnimationController _pulseController;

  DarshanStreamState _streamState = DarshanStreamState.loading;
  String _activeMediaUrl = '';
  String _statusBannerMessage = '';
  final bool _isPlaying = true;
  bool _isDiyaActive = false;

  late final DarshanConfig _effectiveDarshan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _effectEngine = DivineEffectEngine(pack: widget.config.effectPack);

    // Construct effective Darshan configuration
    _effectiveDarshan =
        widget.darshanConfig ??
        DarshanConfig(
          id: widget.config.id,
          godCategoryId: 'god_category',
          name: widget.config.name,
          type: DarshanType.image,
          imageUrl: widget.config.darshanImageUrl.isNotEmpty
              ? widget.config.darshanImageUrl
              : widget.config.thumbnailUrl,
        );

    _initializeDarshanMedia();
  }

  Future<void> _initializeDarshanMedia() async {
    setState(() {
      _streamState = DarshanStreamState.loading;
    });

    if (_effectiveDarshan.type == DarshanType.image) {
      _activeMediaUrl = _effectiveDarshan.imageUrl;
      setState(() {
        _streamState = DarshanStreamState.fallbackImage;
      });
      return;
    }

    if (_effectiveDarshan.type == DarshanType.video) {
      await _setupVideoPlayer(
        url: _effectiveDarshan.videoUrl,
        onFailToImage: () {
          setState(() {
            _activeMediaUrl = _effectiveDarshan.fallbackImageUrl.isNotEmpty
                ? _effectiveDarshan.fallbackImageUrl
                : _effectiveDarshan.imageUrl;
            _streamState = DarshanStreamState.fallbackImage;
            _statusBannerMessage = 'Archival Darshan Photo';
          });
        },
      );
      return;
    }

    if (_effectiveDarshan.type == DarshanType.live) {
      // 1. Attempt Live Stream
      final liveUrl = _effectiveDarshan.liveStreamUrl;
      if (liveUrl.isNotEmpty) {
        final liveSuccess = await _attemptStreamLoad(liveUrl);
        if (liveSuccess) {
          setState(() {
            _streamState = DarshanStreamState.liveStreaming;
            _statusBannerMessage = '🔴 24x7 LIVE DARSHAN';
          });
          return;
        }
      }

      // 2. Cascade Fallback: Video
      if (_effectiveDarshan.fallbackType == DarshanFallbackType.video &&
          _effectiveDarshan.fallbackVideoUrl.isNotEmpty) {
        final fallbackVideoSuccess = await _attemptStreamLoad(
          _effectiveDarshan.fallbackVideoUrl,
        );
        if (fallbackVideoSuccess) {
          setState(() {
            _streamState = DarshanStreamState.fallbackVideo;
            _statusBannerMessage = '📹 Recorded Sacred Aarti';
          });
          return;
        }
      }

      // 3. Cascade Fallback: Image
      setState(() {
        _activeMediaUrl = _effectiveDarshan.fallbackImageUrl.isNotEmpty
            ? _effectiveDarshan.fallbackImageUrl
            : _effectiveDarshan.imageUrl;
        _streamState = DarshanStreamState.fallbackImage;
        _statusBannerMessage =
            'Live stream offline. Showing Sacred Deity Photo.';
      });
    }
  }

  Future<bool> _attemptStreamLoad(String streamUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await controller.initialize().timeout(const Duration(seconds: 8));
      await controller.setLooping(true);
      await controller.play();

      _videoPlayerController?.dispose();
      _videoPlayerController = controller;
      _activeMediaUrl = streamUrl;
      return true;
    } catch (e) {
      debugPrint('[DarshanRuntime] Stream URL "$streamUrl" failed: $e');
      return false;
    }
  }

  Future<void> _setupVideoPlayer({
    required String url,
    required VoidCallback onFailToImage,
  }) async {
    if (url.isEmpty) {
      onFailToImage();
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize().timeout(const Duration(seconds: 8));
      await controller.setLooping(true);
      await controller.play();

      _videoPlayerController?.dispose();
      _videoPlayerController = controller;
      _activeMediaUrl = url;
      setState(() {
        _streamState = DarshanStreamState.fallbackVideo;
      });
    } catch (e) {
      debugPrint('[DarshanRuntime] Video load failed: $e');
      onFailToImage();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoPlayerController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_isPlaying) {
        _videoPlayerController?.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayerController?.dispose();
    _pulseController.dispose();
    _effectEngine.dispose();
    super.dispose();
  }

  void _offerFlowers() {
    _effectEngine.triggerTapBurst(const Offset(200, 300), scale: 1.5);
    _effectEngine.triggerCompletion();
  }

  void _toggleDiya() {
    setState(() {
      _isDiyaActive = !_isDiyaActive;
    });
    _offerFlowers();
  }

  void _shareBlessing() {
    // ignore: deprecated_member_use
    Share.share(
      '🙏 Received Divine Darshan of ${widget.config.name} after completing 108 Sacred Japs on BharatPray! Har Har Mahadev! 🙏',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Security Gate: Verify Darshan is actually unlocked
    if (widget.sessionController != null &&
        !widget.sessionController!.isDarshanUnlocked &&
        !widget.sessionController!.isCompleted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_clock,
                  size: 72,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                Text(
                  'Darshan Is Locked',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please complete your sacred 108 Jap Mala to unlock Divine Darshan and blessings.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Media Presentation Layer
          Positioned.fill(child: _buildMediaPresentation()),

          // 2. Divine Atmospheric Aura & Pulse
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.8 + (_pulseController.value * 0.2),
                      colors: [
                        Colors.transparent,
                        _isDiyaActive
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Particle Effect Engine Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DivineEffectPlayer(
                pack: widget.config.effectPack,
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // 4. Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                if (_statusBannerMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _streamState == DarshanStreamState.liveStreaming
                          ? Colors.redAccent.withValues(alpha: 0.9)
                          : const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _statusBannerMessage,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareBlessing,
                ),
              ],
            ),
          ),

          // 5. Devotional Footer Overlay
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _buildDevotionalFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPresentation() {
    if (_streamState == DarshanStreamState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }

    if ((_streamState == DarshanStreamState.liveStreaming ||
            _streamState == DarshanStreamState.fallbackVideo) &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: VideoPlayer(_videoPlayerController!),
        ),
      );
    }

    // Default: Image Presentation
    return Image.network(
      _activeMediaUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF0F172A),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.temple_hindu,
                  size: 80,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.config.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevotionalFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.config.shlokText,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansDevanagari(
            color: const Color(0xFFFDE68A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Colors.black,
                blurRadius: 8,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.config.effectPack.blessingTitle,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDevotionalButton(
              icon: Icons.local_florist,
              label: 'Offer Flowers',
              color: const Color(0xFFF59E0B),
              onTap: _offerFlowers,
            ),
            _buildDevotionalButton(
              icon: Icons.wb_sunny,
              label: _isDiyaActive ? 'Aarti Active' : 'Light Diya',
              color: _isDiyaActive ? Colors.orangeAccent : Colors.white70,
              onTap: _toggleDiya,
            ),
            if (widget.sessionController != null)
              _buildDevotionalButton(
                icon: Icons.replay,
                label: 'Next Mala',
                color: const Color(0xFF38BDF8),
                onTap: () {
                  widget.sessionController!.advanceMala();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDevotionalButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
