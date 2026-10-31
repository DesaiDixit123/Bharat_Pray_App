import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cinematic_jap/ram_path_calculator.dart';

/// Progressive Image Reveal for Pushp Varsha (Divine Flower Shower).
/// Unveils Lord Shri Ram progressively on every Jap tap (1..108)
/// exclusively at the target locations where flower petals land.
/// Strict sacred face-last protection is maintained until Japs 103..108.
class PushpProgressiveRevealWidget extends StatefulWidget {
  final int count;
  final int targetCount;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double newestNodeBloom; // 0.0 to 1.0 (blooms as petals arrive)
  final double shimmerProgress; // 0.0 to 1.0 on tap
  final bool isCompleted;
  final double completionGlow;
  final String imageAsset;

  const PushpProgressiveRevealWidget({
    super.key,
    required this.count,
    this.targetCount = 108,
    required this.revealedNodes,
    this.newestNode,
    this.newestNodeBloom = 1.0,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlow,
    this.imageAsset = 'assets/images/ram_deity_transparent.png',
  });

  @override
  State<PushpProgressiveRevealWidget> createState() =>
      _PushpProgressiveRevealWidgetState();
}

class _PushpProgressiveRevealWidgetState
    extends State<PushpProgressiveRevealWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant PushpProgressiveRevealWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset != widget.imageAsset) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load(widget.imageAsset);
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _loadedImage = frameInfo.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PushpProgressiveRevealWidget] Notice loading image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _loadedImage == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: PushpProgressiveRevealPainter(
          image: _loadedImage,
          count: widget.count,
          targetCount: widget.targetCount,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          newestNodeBloom: widget.newestNodeBloom,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlow: widget.completionGlow,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class PushpProgressiveRevealPainter extends CustomPainter {
  final ui.Image? image;
  final int count;
  final int targetCount;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double newestNodeBloom;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlow;

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;
  static final Paint _shimmerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  PushpProgressiveRevealPainter({
    required this.image,
    required this.count,
    this.targetCount = 108,
    required this.revealedNodes,
    this.newestNode,
    this.newestNodeBloom = 1.0,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || image == null) return;

    final double imgW = image!.width.toDouble();
    final double imgH = image!.height.toDouble();
    final double imageAspect = imgW / imgH;

    // Aspect-ratio fitted bounds for Lord Shri Ram
    final Rect dstRect =
        RamPathCalculator.computeDstRect(size, imageAspect: imageAspect);
    final Rect srcRect = Rect.fromLTWH(0, 0, imgW, imgH);

    final Offset haloCenter = Offset(
      dstRect.left + (0.50 * dstRect.width),
      dstRect.top + (0.285 * dstRect.height),
    );

    // ── STAGE 0: JAP 0 (Serene Hidden State with Faint Sacred Silhouette) ──
    if (count <= 0 && !isCompleted) {
      _imagePaint.color = Colors.white.withValues(alpha: 0.04);
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);
      _imagePaint.color = Colors.white;
      return;
    }

    // ── STAGE 4: JAP 108 (Full Darshan Completion & Divine Aura) ──────────
    if (isCompleted || count >= targetCount) {
      // 1. Draw Full Lord Shri Ram in complete, vibrant clarity
      _imagePaint.color = Colors.white;
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // 2. Divine Radiance Halo & Warm Rose-Gold Aura Bloom
      final double auraRadius =
          dstRect.width * (0.82 + (0.12 * math.sin(completionGlow * math.pi)));
      final Paint auraPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          auraRadius,
          [
            const Color(0xFFFFD54F).withValues(alpha: 0.42 * completionGlow),
            const Color(0xFFFF80AB).withValues(alpha: 0.28 * completionGlow),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(haloCenter, auraRadius, auraPaint);
      return;
    }

    // ── STAGES 1..107: SYNCHRONIZED FLOWER PETAL ARRIVAL REVEAL ───────────
    // 1. Faint sanctum silhouette in the background
    _imagePaint.color = Colors.white.withValues(alpha: 0.04);
    canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);
    _imagePaint.color = Colors.white;

    // 2. Composite Layer: Unmask locations where flower petals have arrived
    canvas.saveLayer(dstRect, Paint());

    // Merge expansion factor near the end (Japs 75..108)
    final double mergeExpansion = 1.0 + (0.50 * math.max(0.0, (count - 75) / 33.0));

    // Draw all previously completed nodes
    for (final node in revealedNodes) {
      // If this is the newestNode currently in mid-bloom, draw it separately below
      if (node == newestNode && newestNodeBloom < 1.0) continue;

      final Offset nodeCenter = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );

      final double radius = node.radiusNorm * 1.15 * dstRect.width * mergeExpansion;

      RamPathCalculator.drawOrganicRevealMask(canvas, nodeCenter, radius * 0.65, node.step);
    }

    // Draw the newest node ONLY when blooming has begun upon petal arrival!
    if (newestNode != null && newestNodeBloom > 0.0) {
      final Offset newestCenter = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double radius = newestNode!.radiusNorm *
          1.15 *
          dstRect.width *
          mergeExpansion *
          newestNodeBloom;

      RamPathCalculator.drawOrganicRevealMask(canvas, newestCenter, radius * 0.65, newestNode!.step);
    }

    // Blend Lord Shri Ram image over the feathered petal mask using BlendMode.srcIn
    _imagePaint.blendMode = BlendMode.srcIn;
    canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);
    _imagePaint.blendMode = BlendMode.srcOver;

    canvas.restore(); // Restores composite layer

    // 3. Soft Rose & Gold Shimmer on the newest node ONLY when blooming has begun
    if (newestNode != null && newestNodeBloom > 0.0 && shimmerProgress < 1.0) {
      final Offset newestCenter = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double easeShimmer =
          Curves.easeOutCubic.transform(shimmerProgress.clamp(0.0, 1.0));
      final double baseRadius = newestNode!.radiusNorm * 1.15 * dstRect.width;
      final double sRadius = baseRadius * (0.65 + (0.50 * easeShimmer));
      final double sAlpha = (1.0 - easeShimmer).clamp(0.0, 1.0);

      _shimmerPaint
        ..strokeWidth = 2.4 * (1.0 - (0.5 * easeShimmer))
        ..color = const Color(0xFFFF80AB).withValues(alpha: sAlpha * 0.85);
      canvas.drawPath(RamPathCalculator.buildOrganicRevealPath(newestCenter, sRadius * 0.65, newestNode!.step), _shimmerPaint);

      final Paint goldRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0xFFFFD54F).withValues(alpha: sAlpha * 0.90);
      canvas.drawPath(RamPathCalculator.buildOrganicRevealPath(newestCenter, sRadius * 0.52, newestNode!.step), goldRing);
    }
  }

  @override
  bool shouldRepaint(covariant PushpProgressiveRevealPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.newestNodeBloom != newestNodeBloom ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlow != completionGlow ||
        oldDelegate.image != image;
  }
}
