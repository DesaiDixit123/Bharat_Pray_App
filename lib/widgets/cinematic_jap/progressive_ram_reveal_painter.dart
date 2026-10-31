import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ram_path_calculator.dart';

/// Preloads and manages the high-resolution Lord Shri Ram portrait with
/// a seamless, soft-feathered organic reveal mask (ZERO rectangular blocks).
class ProgressiveRamRevealWidget extends StatefulWidget {
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress; // 0.0 to 1.0
  final bool isCompleted;
  final double completionGlowProgress; // 0.0 to 1.0
  final String imageAsset;

  const ProgressiveRamRevealWidget({
    super.key,
    required this.revealedNodes,
    this.newestNode,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlowProgress,
    this.imageAsset = 'assets/images/lord_shri_ram_darshan.png',
  });

  @override
  State<ProgressiveRamRevealWidget> createState() => _ProgressiveRamRevealWidgetState();
}

class _ProgressiveRamRevealWidgetState extends State<ProgressiveRamRevealWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ProgressiveRamRevealWidget oldWidget) {
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
      debugPrint('[ProgressiveRamRevealWidget] Error loading image: $e');
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

    return RepaintBoundary(
      child: CustomPaint(
        painter: ProgressiveRamRevealPainter(
          image: _loadedImage,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// CustomPainter rendering a pure black background and progressively revealing the high-res
/// portrait of Lord Shri Ram with overlapping feathered radial masks.
class ProgressiveRamRevealPainter extends CustomPainter {
  final ui.Image? image;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlowProgress;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;
  final Paint _shimmerGlowPaint = Paint()..style = PaintingStyle.fill;

  ProgressiveRamRevealPainter({
    required this.image,
    required this.revealedNodes,
    this.newestNode,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Guaranteed pure black baseline across the entire screen
    canvas.drawRect(screenRect, _backgroundPaint);

    if (image == null || (revealedNodes.isEmpty && !isCompleted)) {
      return; // 100% black initial state
    }

    final double imgW = image!.width.toDouble();
    final double imgH = image!.height.toDouble();
    final double imageRatio = imgW / imgH;

    // 2. Aspect-ratio fitted destination rect for the portrait
    final dstRect = RamPathCalculator.computeDstRect(size, imageAspect: imageRatio);
    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);

    // 3. Stage 4 Darshan / Full Unmasked Completion
    if (isCompleted) {
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // Warm divine radiance/aura bloom centered on Bhagwan's halo
      if (completionGlowProgress > 0.01) {
        final haloCenter = Offset(
          dstRect.left + (0.50 * dstRect.width),
          dstRect.top + (0.28 * dstRect.height),
        );
        final glowRadius = dstRect.width * (0.85 + (0.15 * math.sin(completionGlowProgress * math.pi)));
        final glowAlpha = (0.28 * completionGlowProgress).clamp(0.0, 1.0);

        final auraPaint = Paint()
          ..shader = ui.Gradient.radial(
            haloCenter,
            glowRadius,
            [
              const Color(0xFFFFD54F).withValues(alpha: glowAlpha),
              const Color(0xFFFF9900).withValues(alpha: glowAlpha * 0.45),
              Colors.transparent,
            ],
            [0.0, 0.45, 1.0],
          );
        canvas.drawCircle(haloCenter, glowRadius, auraPaint);
      }
      return;
    }

    // 4. In-progress reveal: Single saveLayer with BlendMode.srcIn for 100% robust cross-platform rendering
    canvas.saveLayer(screenRect, Paint());

    // Balanced progressive expansion:
    // Count 1..25: Compact, refined reveal circles (~80px radius)
    // Count 56: Exactly ~50% of the portrait gracefully revealed, face stays pure & protected!
    // Count 85..107: Smoothly merges neighboring ornaments as count approaches completion
    // Count 108: Full 100% complete darshan!
    final double totalRatio = (revealedNodes.length / 108.0).clamp(0.0, 1.0);
    final double expansion = 1.0 + (2.00 * math.pow(totalRatio, 2.2));

    // ── A. Draw Non-Face Nodes with Organic Feathered Radial Gradients ──
    for (final node in revealedNodes) {
      if (node.step >= 102) continue; // Face climax nodes drawn in Step B!

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * dstRect.width * expansion;

      // Soft feathered smoke-like gradient falloff with vibrant luminous core (ZERO hard black cutout hole)
      RamPathCalculator.drawOrganicRevealMask(canvas, center, radius * 0.76, node.step);
    }

    // ── B. Draw Sacred Face Climax Nodes (Japs 103..108) ──────────────────
    // Unmasks Tilak, Left Eye, Right Eye, Nose, Lips, and Full Climax!
    for (final node in revealedNodes) {
      if (node.step < 102) continue;

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * dstRect.width * (node.step == 107 ? (1.30 * expansion) : 1.15);

      RamPathCalculator.drawOrganicRevealMask(canvas, center, radius * 0.70, node.step);
    }

    // C. Draw portrait using BlendMode.srcIn: paints portrait pixels ONLY where mask blobs exist
    canvas.drawImageRect(
      image!,
      srcRect,
      dstRect,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..filterQuality = FilterQuality.high,
    );

    // D. Composite masked portrait onto the black background
    canvas.restore();

    // 5. Draw subtle golden ambient shimmer on newest revealed node (NO harsh stroke circle outline!)
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.75).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final radius = newestNode!.radiusNorm * 0.72 * dstRect.width * nodeExp;

      // Soft divine warm glow that follows the same smoke-shaped contour
      _shimmerGlowPaint
        ..color = const Color(0xFFFFD54F).withValues(alpha: shimmerAlpha * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.50);
      canvas.drawPath(
        RamPathCalculator.buildOrganicRevealPath(center, radius * 1.05, newestNode!.step),
        _shimmerGlowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressiveRamRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.image != image;
  }
}
