import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/jap_animation_effect.dart';
import '../progressive_ram_reveal_painter.dart';
import '../ram_path_calculator.dart';
import 'golden_aura_reveal_painter.dart';
import 'lotus_bloom_reveal_painter.dart';
import 'dhoop_smoke_reveal_painter.dart';
import 'divine_particle_reveal_painter.dart';

/// Multi-Effect Reveal Widget managing image preloading and rendering of the
/// selected animation effect (including the 100% untouched approved default).
class MultiEffectRamRevealWidget extends StatefulWidget {
  final JapRevealEffectType effectType;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlowProgress;
  final String imageAsset;

  const MultiEffectRamRevealWidget({
    super.key,
    required this.effectType,
    required this.revealedNodes,
    this.newestNode,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlowProgress,
    this.imageAsset = 'assets/images/lord_shri_ram_darshan.png',
  });

  @override
  State<MultiEffectRamRevealWidget> createState() => _MultiEffectRamRevealWidgetState();
}

class _MultiEffectRamRevealWidgetState extends State<MultiEffectRamRevealWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant MultiEffectRamRevealWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset != widget.imageAsset) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load(widget.imageAsset);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _loadedImage = frameInfo.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MultiEffectRamRevealWidget] Error loading image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _loadedImage == null) {
      return const ColoredBox(color: Colors.black);
    }

    CustomPainter painter;

    switch (widget.effectType) {
      case JapRevealEffectType.goldenAuraReveal:
        painter = GoldenAuraRevealPainter(
          image: _loadedImage,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
        );
        break;

      case JapRevealEffectType.lotusBloomReveal:
        painter = LotusBloomRevealPainter(
          image: _loadedImage,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
        );
        break;

      case JapRevealEffectType.dhoopSmokeReveal:
        painter = DhoopSmokeRevealPainter(
          image: _loadedImage,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
        );
        break;

      case JapRevealEffectType.divineParticleReveal:
        painter = DivineParticleRevealPainter(
          image: _loadedImage,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
        );
        break;

      case JapRevealEffectType.divineVerticalReveal:
        // MANDATORY PRESERVATION: Delegates directly to the exact approved painter!
        painter = ProgressiveRamRevealPainter(
          image: _loadedImage,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
        );
        break;
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: painter,
        size: Size.infinite,
      ),
    );
  }
}
