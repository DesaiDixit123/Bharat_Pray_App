import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/jap_video_preloader.dart';

/// Full-screen looping live darshan video generated for a custom Jap.
/// Stays empty until the video is ready, so the revealed image shows through.
class CustomJapDarshanVideo extends StatefulWidget {
  final String url;
  final String? fallbackAsset;
  final bool isSoundEnabled;

  const CustomJapDarshanVideo({
    super.key,
    required this.url,
    this.fallbackAsset,
    this.isSoundEnabled = true,
  });

  @override
  State<CustomJapDarshanVideo> createState() => _CustomJapDarshanVideoState();
}

class _CustomJapDarshanVideoState extends State<CustomJapDarshanVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = await JapVideoPreloader.createInitializedController(
      videoUrl: widget.url,
      fallbackAsset: widget.fallbackAsset,
      isSoundEnabled: widget.isSoundEnabled,
    );
    if (controller == null) return;
    if (!mounted) {
      await controller.dispose();
      return;
    }

    try {
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      debugPrint('[CustomJapDarshanVideo] Playback error: $e');
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return const SizedBox.shrink();
    final vSize = controller.value.size;
    final double vWidth = vSize.width > 0 ? vSize.width : 720.0;
    final double vHeight = vSize.height > 0 ? vSize.height : 1280.0;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: vWidth,
            height: vHeight,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
