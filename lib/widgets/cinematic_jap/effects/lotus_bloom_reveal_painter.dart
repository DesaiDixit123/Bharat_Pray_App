import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../ram_path_calculator.dart';

/// Painter for Effect 2: Lotus Bloom Reveal.
///
/// Visual Style:
/// - Sacred pink-gold lotus petals unfolding upwards and outwards from the lower base.
/// - Expanding petal apertures unmasking the divine portrait.
/// - Soft pink-gold, rose-amber, and warm gold radial lighting.
/// - STRICT FACE SHIELD: Sacred face remains protected (1..102) and unmasks last (103..108).
class LotusBloomRevealPainter extends CustomPainter {
  final ui.Image? image;
  final List<RevealNode> revealedNodes;
  final RevealNode? newestNode;
  final double shimmerProgress;
  final bool isCompleted;
  final double completionGlowProgress;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;
  final Paint _shimmerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  LotusBloomRevealPainter({
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
    // 1. Guaranteed pure black baseline
    canvas.drawRect(screenRect, _backgroundPaint);

    if (image == null || (revealedNodes.isEmpty && !isCompleted)) {
      return;
    }

    final double imgW = image!.width.toDouble();
    final double imgH = image!.height.toDouble();
    final double imageRatio = imgW / imgH;

    // Aspect-ratio fitted destination rect
    final dstRect = RamPathCalculator.computeDstRect(size, imageAspect: imageRatio);
    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final lotusBase = Offset(
      dstRect.left + (0.50 * dstRect.width),
      dstRect.top + (0.85 * dstRect.height),
    );

    // 2. Stage 4 Darshan / Full Unmasked Completion
    if (isCompleted) {
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // Lotus divine aura bloom at completion
      final haloCenter = Offset(
        dstRect.left + (0.50 * dstRect.width),
        dstRect.top + (0.28 * dstRect.height),
      );
      final glowRadius = dstRect.width * (0.85 + (0.15 * math.sin(completionGlowProgress * math.pi)));
      final glowAlpha = (0.32 * completionGlowProgress).clamp(0.0, 1.0);

      final auraPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          glowRadius,
          [
            const Color(0xFFFF80AB).withValues(alpha: glowAlpha * 0.70),
            const Color(0xFFFFD54F).withValues(alpha: glowAlpha),
            Colors.transparent,
          ],
          [0.0, 0.40, 1.0],
        );
      canvas.drawCircle(haloCenter, glowRadius, auraPaint);
      return;
    }

    // Background Lotus Petal Outline Glow
    final double progressRatio = (revealedNodes.length / 108.0).clamp(0.0, 1.0);
    final double petalSpread = (math.pow(progressRatio, 1.0) * 1.0).clamp(0.0, 1.0);

    _drawLotusAmbientGlow(canvas, lotusBase, dstRect.width * 0.65, petalSpread);

    // 4. SaveLayer for progressive feathered aperture masking
    canvas.saveLayer(screenRect, Paint());

    // Balanced progressive expansion:
    final double expansion = 1.0 + (2.00 * math.pow(progressRatio, 2.2));

    // ── A. Draw Non-Face Mask Blobs ─────────────────────────────────────
    // Blooming Lotus Petals Mask Paths
    if (petalSpread > 0.04) {
      final lotusPath = _buildLotusPetalMaskPath(lotusBase, dstRect.width, dstRect.height, petalSpread);
      final petalPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.88)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.drawPath(lotusPath, petalPaint);
    }

    // Overlapping organic feathered nodes ensuring full regional detail
    for (final node in revealedNodes) {
      if (node.step >= 102) continue; // Face climax nodes in Step B

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * 1.18 * dstRect.width * expansion;

      RamPathCalculator.drawOrganicRevealMask(canvas, center, radius * 0.65, node.step);
    }

    // ── B. Draw Sacred Face Climax Nodes (Japs 103..108) ────────────────
    for (final node in revealedNodes) {
      if (node.step < 102) continue;

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * 1.18 * dstRect.width;

      RamPathCalculator.drawOrganicRevealMask(canvas, center, radius * 0.65, node.step);
    }

    // Composite portrait onto mask
    canvas.drawImageRect(
      image!,
      srcRect,
      dstRect,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..filterQuality = FilterQuality.high,
    );

    canvas.restore(); // End saveLayer

    // 5. Pink-Gold Shimmer on boundary of newest revealed node
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.90).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final radius = newestNode!.radiusNorm * 1.18 * dstRect.width * nodeExp * 0.88;

      _shimmerPaint.color = const Color(0xFFFF80AB).withValues(alpha: shimmerAlpha);
      _shimmerPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
      canvas.drawPath(RamPathCalculator.buildOrganicRevealPath(center, radius * 0.72, newestNode!.step), _shimmerPaint);
    }
  }

  Path _buildLotusPetalMaskPath(Offset base, double width, double height, double spread) {
    final path = Path();
    // 7 lotus petals fanning upwards and outwards
    const int petalCount = 7;
    final double maxPetalLength = height * 0.70 * spread;

    for (int i = 0; i < petalCount; i++) {
      // Angle: from -70 deg (-1.22 rad) to +70 deg (+1.22 rad), 0 is straight up (-pi/2)
      final double fraction = i / (petalCount - 1); // 0.0 to 1.0
      final double angleOffset = (fraction - 0.5) * 1.35; // radians spread
      final double petalAngle = -math.pi / 2 + angleOffset;

      final double currentLen = maxPetalLength * (0.75 + (0.25 * math.cos(angleOffset)));
      final double tipX = base.dx + (currentLen * math.cos(petalAngle));
      final double tipY = base.dy + (currentLen * math.sin(petalAngle));

      // Petal side control points
      final double sideOffset = width * 0.14 * spread;
      final double midLen = currentLen * 0.55;
      final double leftX = base.dx + (midLen * math.cos(petalAngle - 0.28)) - (sideOffset * math.sin(petalAngle));
      final double leftY = base.dy + (midLen * math.sin(petalAngle - 0.28)) + (sideOffset * math.cos(petalAngle));
      final double rightX = base.dx + (midLen * math.cos(petalAngle + 0.28)) + (sideOffset * math.sin(petalAngle));
      final double rightY = base.dy + (midLen * math.sin(petalAngle + 0.28)) - (sideOffset * math.cos(petalAngle));

      final petalPath = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(leftX, leftY, tipX, tipY)
        ..quadraticBezierTo(rightX, rightY, base.dx, base.dy)
        ..close();

      path.addPath(petalPath, Offset.zero);
    }
    return path;
  }

  void _drawLotusAmbientGlow(Canvas canvas, Offset base, double maxRadius, double spread) {
    if (spread <= 0.02) return;
    final glowRadius = maxRadius * spread;
    final glowAlpha = (0.25 * spread).clamp(0.0, 0.25);

    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        base,
        glowRadius,
        [
          const Color(0xFFFF80AB).withValues(alpha: glowAlpha),
          const Color(0xFFFFD54F).withValues(alpha: glowAlpha * 0.50),
          Colors.transparent,
        ],
        [0.0, 0.50, 1.0],
      );
    canvas.drawCircle(base, glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant LotusBloomRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.image != image;
  }
}
