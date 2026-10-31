import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cinematic_jap/ram_path_calculator.dart';

/// Progressive Image Reveal for Prakash Mandal (Divine Light Reveal).
/// Unveils Lord Shri Ram progressively on every Jap tap (1..108)
/// via expanding golden light and multi-node spiritual dispersion.
/// Leaves the background transparent so the temple sanctum shines through.
class PrakashProgressiveRevealWidget extends StatefulWidget {
  final int count;
  final int targetCount;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress; // 0.0 to 1.0 on tap
  final bool isCompleted;
  final double completionGlow;
  final String imageAsset;

  const PrakashProgressiveRevealWidget({
    super.key,
    required this.count,
    this.targetCount = 108,
    required this.revealedNodes,
    this.newestNode,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlow,
    this.imageAsset = 'assets/images/ram_deity_transparent.png',
  });

  @override
  State<PrakashProgressiveRevealWidget> createState() =>
      _PrakashProgressiveRevealWidgetState();
}

class _PrakashProgressiveRevealWidgetState
    extends State<PrakashProgressiveRevealWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant PrakashProgressiveRevealWidget oldWidget) {
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
      debugPrint('[PrakashProgressiveRevealWidget] Notice loading image: $e');
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
        painter: PrakashProgressiveRevealPainter(
          image: _loadedImage,
          count: widget.count,
          targetCount: widget.targetCount,
          revealedNodes: widget.revealedNodes,
          newestNode: widget.newestNode,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlow: widget.completionGlow,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class PrakashProgressiveRevealPainter extends CustomPainter {
  final ui.Image? image;
  final int count;
  final int targetCount;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlow;

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;
  static final Paint _glowEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  PrakashProgressiveRevealPainter({
    required this.image,
    required this.count,
    this.targetCount = 108,
    required this.revealedNodes,
    this.newestNode,
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

    // ── STAGE 0: JAP 0 (Calm, Hidden Deity with Very Subtle Golden Outline) ───
    if (count <= 0 && !isCompleted) {
      // Very faint ethereal presence (5% opacity) to invite chanting
      _imagePaint.color = Colors.white.withValues(alpha: 0.04);
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);
      _imagePaint.color = Colors.white;
      return;
    }

    // ── STAGE 4: JAP 108 (Full Darshan Completion) ────────────────────────
    if (isCompleted || count >= targetCount) {
      // 1. Draw Full Crisp Lord Shri Ram
      _imagePaint.color = Colors.white;
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // 2. Divine Radiance Halo Bloom
      final double auraRadius = dstRect.width * (0.85 + (0.10 * math.sin(completionGlow * math.pi)));
      final Paint auraPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          auraRadius,
          [
            const Color(0xFFFFF9C4).withValues(alpha: 0.45 * completionGlow),
            const Color(0xFFFFD54F).withValues(alpha: 0.25 * completionGlow),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(haloCenter, auraRadius, auraPaint);
      return;
    }

    // ── STAGES 1..107: PROGRESSIVE LIGHT-DRIVEN ORGANIC REVEAL ─────────────
    // Save a layer bounded to dstRect with alpha compositing
    canvas.saveLayer(dstRect, Paint());

    final double t = (count / targetCount).clamp(0.0, 1.0);

    // A. Expanding Prakash Light-Cone from Heaven & Crown Center
    // The central sacred light beam illuminates downward from halo
    final double lightBeamRadius = dstRect.width * (0.22 + (0.65 * math.pow(t, 0.82)));
    RamPathCalculator.drawOrganicRevealMask(canvas, haloCenter, lightBeamRadius * 0.62, 7);

    // B. Multi-Region Revealed Nodes from RamPathCalculator
    // Guarantees every single tap reveals a tangible, distinct portion
    final double expansion = 1.10 + (0.85 * math.pow(t, 1.5));
    for (final node in revealedNodes) {
      final Offset nodeCenter = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final double radius = node.radiusNorm * 1.30 * dstRect.width * expansion;

      RamPathCalculator.drawOrganicRevealMask(canvas, nodeCenter, radius * 0.60, node.step);
    }

    // Blend the image over the feathered mask using BlendMode.srcIn
    _imagePaint.blendMode = BlendMode.srcIn;
    canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);
    _imagePaint.blendMode = BlendMode.srcOver;

    canvas.restore(); // Restores composite layer to canvas

    // C. Golden Shimmer Highlight on the newly revealed node
    if (newestNode != null && shimmerProgress < 1.0) {
      final Offset newestCenter = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double sRadius =
          newestNode!.radiusNorm * dstRect.width * (1.0 + (0.5 * shimmerProgress));
      final double sAlpha = (1.0 - shimmerProgress).clamp(0.0, 1.0);

      _glowEdgePaint
        ..strokeWidth = 2.4 * (1.0 - (0.5 * shimmerProgress))
        ..color = const Color(0xFFFFD54F).withValues(alpha: sAlpha * 0.85);

      canvas.drawPath(RamPathCalculator.buildOrganicRevealPath(newestCenter, sRadius * 0.75, newestNode!.step), _glowEdgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PrakashProgressiveRevealPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlow != completionGlow ||
        oldDelegate.image != image;
  }
}
