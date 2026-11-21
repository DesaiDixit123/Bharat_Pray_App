import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../cinematic_jap/ram_path_calculator.dart';
import '../cinematic_jap/reveal_image_loader.dart';

/// Represents a bespoke, randomized organic incense smoke cloud reveal node on the deity portrait.
class DhupRevealNode {
  final int step; // 0..target-1
  final double u; // Normalized X (0.0 = left, 1.0 = right relative to portrait dstRect)
  final double v; // Normalized Y (0.0 = top, 1.0 = bottom relative to portrait dstRect)
  final double radiusNorm; // Base normalized radius
  final int seed; // Random seed driving the unique cloud shape
  final int numLobes; // 6 to 10 organic billowy lobes
  final double rotation; // Random rotation angle
  final double aspectX; // Horizontal spread factor
  final double aspectY; // Vertical drift factor
  final double radiusMultiplier; // Random size variation
  final String label;

  const DhupRevealNode({
    required this.step,
    required this.u,
    required this.v,
    required this.radiusNorm,
    required this.seed,
    this.numLobes = 7,
    this.rotation = 0.0,
    this.aspectX = 1.0,
    this.aspectY = 1.0,
    this.radiusMultiplier = 1.0,
    required this.label,
  });

  /// Factory constructor to convert a standard RevealNode with randomized organic cloud shape
  factory DhupRevealNode.fromRevealNode(RevealNode node, {int? seed}) {
    final s = seed ?? ((node.step * 1103515245 + 12345) & 0x7fffffff);
    final rng = math.Random(s);
    return DhupRevealNode(
      step: node.step,
      u: node.u,
      v: node.v,
      radiusNorm: node.radiusNorm,
      seed: s,
      numLobes: 6 + rng.nextInt(5), // 6 to 10 lobes
      rotation: rng.nextDouble() * 2 * math.pi,
      aspectX: 0.88 + (rng.nextDouble() * 0.28),
      aspectY: 0.95 + (rng.nextDouble() * 0.35),
      radiusMultiplier: 1.05 + (rng.nextDouble() * 0.30),
      label: node.label,
    );
  }

  /// Builds a completely random, organic, multi-lobed billowing dhoop smoke cloud path
  /// with silky smooth bezier curves and asymmetric natural smoke swirls.
  Path buildCloudPath(Offset center, double baseRadius) {
    final effectiveRadius = baseRadius * radiusMultiplier;
    const int totalPoints = 40;
    final List<Offset> points = [];

    final rng = math.Random(seed);
    final double phi1 = rng.nextDouble() * 2 * math.pi;
    final double phi2 = rng.nextDouble() * 2 * math.pi;
    final double tilt = (rng.nextDouble() - 0.5) * 0.45; // Drift angle

    for (int i = 0; i < totalPoints; i++) {
      final double angle = i * 2 * math.pi / totalPoints;

      // Primary billowy cloud puffs / lobes (6 to 10 lobes)
      final double lobeWave = math.sin((angle * numLobes) + rotation);
      // Secondary asymmetrical smoke curling wisp
      final double swirlWave = math.cos((angle * (numLobes - 2)) + phi1);
      // Delicate turbulence along smoke edge
      final double microNoise = math.sin(angle * 8 + phi2);

      final double billowFactor = 1.0 + (0.30 * lobeWave) + (0.15 * swirlWave) + (0.06 * microNoise);
      final double r = effectiveRadius * billowFactor;

      final double lx = r * aspectX * math.cos(angle);
      final double ly = r * aspectY * math.sin(angle);

      // Rotate by drift tilt
      final double rx = lx * math.cos(tilt) - ly * math.sin(tilt);
      final double ry = lx * math.sin(tilt) + ly * math.cos(tilt);

      points.add(Offset(center.dx + rx, center.dy + ry));
    }

    final path = Path();
    final firstMid = Offset(
      (points[0].dx + points[totalPoints - 1].dx) / 2,
      (points[0].dy + points[totalPoints - 1].dy) / 2,
    );
    path.moveTo(firstMid.dx, firstMid.dy);

    for (int i = 0; i < totalPoints; i++) {
      final next = (i + 1) % totalPoints;
      final mid = Offset((points[i].dx + points[next].dx) / 2, (points[i].dy + points[next].dy) / 2);
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }
}

/// Master Implementation — Dhup Incense Reveal Widget
/// Provides a bespoke, organic sacred incense smoke unveiling of the deity:
/// - ZERO circular holes or geometric circles
/// - Each revealed region is an organic, multi-lobed billowing dhoop smoke cloud path
/// - Deep Gaussian blur creates a silky, realistic sacred smoke mist unmasking
/// - Pure black sanctum baseline with warm divine golden shimmer along the smoke contours
class DhupIncenseRevealWidget extends StatefulWidget {
  final List<dynamic> revealedNodes;
  final dynamic newestNode;
  final double shimmerProgress; // 0.0 to 1.0
  final bool isCompleted;
  final double completionGlowProgress; // 0.0 to 1.0
  final String imageAsset;
  final double? revealProgress; // 0.0 to 1.0, for chant counts other than 108

  const DhupIncenseRevealWidget({
    super.key,
    required this.revealedNodes,
    this.newestNode,
    required this.shimmerProgress,
    required this.isCompleted,
    required this.completionGlowProgress,
    this.imageAsset = 'assets/images/lord_shri_ram_darshan.png',
    this.revealProgress,
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
      final bytes = await loadRevealImageBytes(widget.imageAsset);
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
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

    final convertedNodes = widget.revealedNodes.map<DhupRevealNode>((node) {
      if (node is DhupRevealNode) return node;
      if (node is RevealNode) return DhupRevealNode.fromRevealNode(node);
      return DhupRevealNode.fromRevealNode(node as RevealNode);
    }).toList();

    DhupRevealNode? convertedNewest;
    if (widget.newestNode != null) {
      if (widget.newestNode is DhupRevealNode) {
        convertedNewest = widget.newestNode as DhupRevealNode;
      } else if (widget.newestNode is RevealNode) {
        convertedNewest = DhupRevealNode.fromRevealNode(widget.newestNode as RevealNode);
      }
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: DhupIncenseRevealPainter(
          image: _loadedImage,
          revealedNodes: convertedNodes,
          newestNode: convertedNewest,
          shimmerProgress: widget.shimmerProgress,
          isCompleted: widget.isCompleted,
          completionGlowProgress: widget.completionGlowProgress,
          revealProgress: widget.revealProgress,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// CustomPainter that renders deity emerging from sacred incense smoke:
/// ZERO geometric circles — every revealed node is rendered as a bespoke, organic,
/// billowing incense smoke cloud path with soft Gaussian blur feathering.
class DhupIncenseRevealPainter extends CustomPainter {
  final ui.Image? image;
  final List<DhupRevealNode> revealedNodes;
  final DhupRevealNode? newestNode;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlowProgress;
  final double? revealProgress;

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
    this.revealProgress,
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

    // 3. Full Darshan / Unmasked Completion
    if (isCompleted) {
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // Warm divine radiance/aura bloom centered on halo
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

    // Balanced progressive expansion so smoke billows merge harmoniously to reveal 100% of image
    final double totalRatio = (revealProgress ?? (revealedNodes.length / 108.0)).clamp(0.0, 1.0);
    final double expansion = 1.0 + (1.60 * math.pow(totalRatio, 1.8));

    // Draw all revealed organic dhoop smoke cloud paths into mask layer
    for (final node in revealedNodes) {
      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final baseRadius = node.radiusNorm * dstRect.width * expansion;

      // Generate bespoke random organic smoke cloud path
      final cloudPath = node.buildCloudPath(center, baseRadius);

      // Deep Gaussian blur feathering for realistic smoke unmasking
      _maskPlumePaint.color = Colors.white;
      _maskPlumePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.35);

      canvas.drawPath(cloudPath, _maskPlumePaint);
    }

    // BlendMode.srcIn: paints portrait pixels ONLY where organic smoke clouds exist
    canvas.drawImageRect(
      image!,
      srcRect,
      dstRect,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..filterQuality = FilterQuality.high,
    );

    // Composite masked portrait onto pure black sanctum
    canvas.restore();

    // 5. Draw subtle golden incense mist shimmer on newest revealed plume
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.70).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double baseRadius = newestNode!.radiusNorm * dstRect.width * expansion;
      final cloudPath = newestNode!.buildCloudPath(center, baseRadius);

      _shimmerMistPaint.color = const Color(0xFFFFD54F).withValues(alpha: shimmerAlpha * 0.40);
      _shimmerMistPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.45);

      canvas.drawPath(cloudPath, _shimmerMistPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DhupIncenseRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.image != image;
  }
}
