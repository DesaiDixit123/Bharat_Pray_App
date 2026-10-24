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
  final Paint _maskBlobPaint = Paint()..style = PaintingStyle.fill;
  final Paint _shimmerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

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

    // Compute exact screen coordinate rect and organic rounded oval for Lord Ram's sacred face
    final faceRect = Rect.fromLTRB(
      dstRect.left + (RamPathCalculator.faceBox.left * dstRect.width),
      dstRect.top + (RamPathCalculator.faceBox.top * dstRect.height),
      dstRect.left + (RamPathCalculator.faceBox.right * dstRect.width),
      dstRect.top + (RamPathCalculator.faceBox.bottom * dstRect.height),
    );
    final faceRRect = RRect.fromRectAndRadius(faceRect, Radius.circular(faceRect.width * 0.38));

    // Smooth progressive expansion:
    // Count 1..30: subtle focused points (~12-35%)
    // Count 50: gentle (~50-58% revealed, well-dispersed)
    // Count 90: rich & continuous (~87% revealed, all non-face gaps on shoulders, chest, crown, and pitambar smoothly filled!)
    final double totalRatio = (revealedNodes.length / 102.0).clamp(0.0, 1.0);
    final double expansion = 1.0 + (1.25 * math.pow(totalRatio, 2.2));

    // ── A. Draw Non-Face Nodes with Strict Face Exclusion ────────────────
    // PathFillType.evenOdd GUARANTEES the sacred face stays 100% pure black!
    final faceClipPath = Path()
      ..addRect(screenRect)
      ..addRRect(faceRRect);
    faceClipPath.fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipPath(faceClipPath);

    for (final node in revealedNodes) {
      if (node.step >= 102) continue; // Face climax nodes drawn in Step B!

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * 1.05 * dstRect.width * expansion;

      _maskBlobPaint.shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.white,
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        [0.0, 0.48, 0.78, 1.0],
      );
      canvas.drawCircle(center, radius, _maskBlobPaint);
    }
    canvas.restore(); // Restores clip so face climax nodes can be painted!

    // ── B. Draw Sacred Face Climax Nodes (Japs 103..108) ──────────────────
    // Unmasks Tilak, Left Eye, Right Eye, Nose, Lips, and Full Climax!
    for (final node in revealedNodes) {
      if (node.step < 102) continue;

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * dstRect.width;

      _maskBlobPaint.shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.white,
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.40),
          Colors.transparent,
        ],
        [0.0, 0.50, 0.80, 1.0],
      );
      canvas.drawCircle(center, radius, _maskBlobPaint);
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

    // 5. Draw subtle golden outline shimmer on the boundary of the newest revealed node
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.85).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final radius = newestNode!.radiusNorm * 1.05 * dstRect.width * nodeExp * 0.88;

      _shimmerPaint.color = const Color(0xFFFFD700).withValues(alpha: shimmerAlpha);
      _shimmerPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(center, radius, _shimmerPaint);
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
