import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping live darshan video generated for a custom Jap.
/// Stays empty until the video is ready, so the revealed image shows through.
class CustomJapDarshanVideo extends StatefulWidget {
  final String url;
  final bool isSoundEnabled;

  const CustomJapDarshanVideo({
    super.key,
    required this.url,
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
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.isSoundEnabled ? 1.0 : 0.0);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      debugPrint('[CustomJapDarshanVideo] Video error: $e');
      controller.dispose();
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
    if (controller == null) return const SizedBox.shrink();
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
