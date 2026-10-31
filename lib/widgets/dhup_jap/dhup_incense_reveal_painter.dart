import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cinematic_jap/ram_path_calculator.dart';

/// Master Implementation — Dhup Incense Reveal Widget
/// Provides a bespoke, organic sacred incense smoke unveiling of Lord Shri Ram:
/// - ZERO circular holes or geometric circles
/// - Each revealed region is an organic, multi-lobed vertical smoke plume path
/// - Deep Gaussian blur creates a silky, realistic sacred smoke mist unmasking
/// - Strict face protection keeping the sacred face veiled until Japs 103..108
/// - Pure black sanctum baseline with warm divine golden shimmer along the smoke contours
class DhupIncenseRevealWidget extends StatefulWidget {
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress; // 0.0 to 1.0
  final bool isCompleted;
  final double completionGlowProgress; // 0.0 to 1.0
  final String imageAsset;

  const DhupIncenseRevealWidget({
    super.key,
    required this.revealedNodes,
    this.newestNode,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlowProgress,
    this.imageAsset = 'assets/images/lord_shri_ram_darshan.png',
  });

  @override
  State<DhupIncenseRevealWidget> createState() => _DhupIncenseRevealWidgetState();
}

class _DhupIncenseRevealWidgetState extends State<DhupIncenseRevealWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant DhupIncenseRevealWidget oldWidget) {
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
      debugPrint('[DhupIncenseRevealWidget] Error loading image: $e');
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
        painter: DhupIncenseRevealPainter(
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

/// CustomPainter that renders Lord Shri Ram emerging from sacred incense smoke:
/// ZERO geometric circles — every revealed node is rendered as an organic, flowing,
/// vertically elongated incense smoke billow path with soft Gaussian blur feathering.
class DhupIncenseRevealPainter extends CustomPainter {
  final ui.Image? image;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlowProgress;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;
  final Paint _maskPlumePaint = Paint()..style = PaintingStyle.fill;
  final Paint _shimmerMistPaint = Paint()..style = PaintingStyle.fill;

  DhupIncenseRevealPainter({
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

    // 1. Guaranteed pure black sanctum baseline across the entire screen
    canvas.drawRect(screenRect, _backgroundPaint);

    if (image == null || (revealedNodes.isEmpty && !isCompleted)) {
      return; // 100% black sanctum initial state
    }

    final double imgW = image!.width.toDouble();
    final double imgH = image!.height.toDouble();
    final double imageRatio = imgW / imgH;

    // 2. Aspect-ratio fitted destination rect for the divine portrait
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

    // 4. In-progress reveal: Single saveLayer with BlendMode.srcIn
    canvas.saveLayer(screenRect, Paint());

    // Balanced progressive expansion:
    final double totalRatio = (revealedNodes.length / 108.0).clamp(0.0, 1.0);
    final double expansion = 1.0 + (2.00 * math.pow(totalRatio, 2.2));

    // ── A. Draw Non-Face Smoke Plumes ────────────────────────────────────
    for (final node in revealedNodes) {
      if (node.step >= 102) continue; // Face climax nodes drawn in Step B!

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final baseRadius = node.radiusNorm * 0.76 * dstRect.width * expansion;

      // Generate organic, billowing, vertically elongated incense smoke plume path
      final plumePath = RamPathCalculator.buildOrganicRevealPath(center, baseRadius, node.step);

      // Deep Gaussian blur feathering: completely eliminates any circular, hard, or geometric edges
      _maskPlumePaint.color = Colors.white;
      _maskPlumePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.40);

      canvas.drawPath(plumePath, _maskPlumePaint);
    }

    // ── B. Draw Sacred Face Climax Nodes (Japs 103..108) ──────────────────
    for (final node in revealedNodes) {
      if (node.step < 102) continue;

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final baseRadius = node.radiusNorm * 0.80 * dstRect.width;

      final plumePath = RamPathCalculator.buildOrganicRevealPath(center, baseRadius, node.step);
      _maskPlumePaint.color = Colors.white;
      _maskPlumePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.35);

      canvas.drawPath(plumePath, _maskPlumePaint);
    }

    // C. Draw portrait using BlendMode.srcIn: paints portrait pixels ONLY where organic smoke plumes exist
    canvas.drawImageRect(
      image!,
      srcRect,
      dstRect,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..filterQuality = FilterQuality.high,
    );

    // D. Composite masked portrait onto the pure black sanctum background
    canvas.restore();

    // 5. Draw subtle golden incense mist shimmer on newest revealed plume (NO CIRCULAR OUTLINES!)
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.65).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final double baseRadius = newestNode!.radiusNorm * 0.76 * dstRect.width * nodeExp;

      // Follows the EXACT same organic smoke plume geometry with a warm amber-golden glow
      final plumePath = RamPathCalculator.buildOrganicRevealPath(center, baseRadius, newestNode!.step);

      _shimmerMistPaint.color = const Color(0xFFFFD54F).withValues(alpha: shimmerAlpha * 0.35);
      _shimmerMistPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.48);

      canvas.drawPath(plumePath, _shimmerMistPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DhupIncenseRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.image != image;
  }
}
