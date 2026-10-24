import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../ram_path_calculator.dart';

/// Painter for Effect 1: Golden Aura Reveal.
///
/// Visual Style:
/// - Radiant concentric sunburst rings and expanding golden halo.
/// - Unmasks the deity from the radiant aura and crown outwards.
/// - Volumetric golden light rays and warm amber bloom.
/// - STRICT FACE SHIELD: Sacred face remains protected (1..102) and unmasks last (103..108).
class GoldenAuraRevealPainter extends CustomPainter {
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

  GoldenAuraRevealPainter({
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
    final haloCenter = Offset(
      dstRect.left + (0.50 * dstRect.width),
      dstRect.top + (0.28 * dstRect.height),
    );

    // 2. Stage 4 Darshan / Full Unmasked Completion
    if (isCompleted) {
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // Radiant golden sunburst rays & halo bloom
      final glowRadius = dstRect.width * (0.90 + (0.15 * math.sin(completionGlowProgress * math.pi)));
      final glowAlpha = (0.35 * completionGlowProgress).clamp(0.0, 1.0);

      _drawGoldenAuraRays(canvas, haloCenter, glowRadius * 1.2, glowAlpha);

      final auraPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          glowRadius,
          [
            const Color(0xFFFFD54F).withValues(alpha: glowAlpha),
            const Color(0xFFFF9900).withValues(alpha: glowAlpha * 0.50),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(haloCenter, glowRadius, auraPaint);
      return;
    }

    // 3. In-Progress Reveal: Golden Volumetric Ray Background Glow
    final double progressRatio = (revealedNodes.length / 108.0).clamp(0.0, 1.0);
    final double bgAuraAlpha = (0.22 * progressRatio).clamp(0.0, 0.25);
    if (bgAuraAlpha > 0.02) {
      _drawGoldenAuraRays(canvas, haloCenter, dstRect.width * 0.9, bgAuraAlpha);
    }

    // 4. SaveLayer for progressive feathered aperture masking
    canvas.saveLayer(screenRect, Paint());

    // Exact screen coordinate rect for Lord Ram's sacred face
    final faceRect = Rect.fromLTRB(
      dstRect.left + (RamPathCalculator.faceBox.left * dstRect.width),
      dstRect.top + (RamPathCalculator.faceBox.top * dstRect.height),
      dstRect.left + (RamPathCalculator.faceBox.right * dstRect.width),
      dstRect.top + (RamPathCalculator.faceBox.bottom * dstRect.height),
    );
    final faceRRect = RRect.fromRectAndRadius(faceRect, Radius.circular(faceRect.width * 0.38));

    // Smooth progressive expansion
    final double expansion = 1.0 + (1.20 * math.pow(progressRatio, 2.0));

    // Concentric expanding golden halo aperture centered on crown/halo
    final double haloApertureRadius = dstRect.width * 0.55 * math.pow(progressRatio, 1.3);

    // ── A. Draw Non-Face Mask Blobs with Strict Face Shield ─────────────
    final faceClipPath = Path()
      ..addRect(screenRect)
      ..addRRect(faceRRect);
    faceClipPath.fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipPath(faceClipPath);

    // Halo radial unmasking ring (centered on halo)
    if (haloApertureRadius > 10.0) {
      _maskBlobPaint.shader = ui.Gradient.radial(
        haloCenter,
        haloApertureRadius,
        [
          Colors.white,
          Colors.white.withValues(alpha: 0.85),
          Colors.transparent,
        ],
        [0.0, 0.65, 1.0],
      );
      canvas.drawCircle(haloCenter, haloApertureRadius, _maskBlobPaint);
    }

    // Revealed node mask blobs
    for (final node in revealedNodes) {
      if (node.step >= 102) continue; // Face climax nodes in Step B

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * 1.10 * dstRect.width * expansion;

      _maskBlobPaint.shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.white,
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        [0.0, 0.45, 0.75, 1.0],
      );
      canvas.drawCircle(center, radius, _maskBlobPaint);
    }
    canvas.restore(); // Restores clip so face climax can be unmasked

    // ── B. Draw Sacred Face Climax Nodes (Japs 103..108) ────────────────
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
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.40),
          Colors.transparent,
        ],
        [0.0, 0.50, 0.80, 1.0],
      );
      canvas.drawCircle(center, radius, _maskBlobPaint);
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

    // 5. Golden Outline Shimmer on boundary of newest revealed node
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.90).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final radius = newestNode!.radiusNorm * 1.10 * dstRect.width * nodeExp * 0.90;

      _shimmerPaint.color = const Color(0xFFFFD700).withValues(alpha: shimmerAlpha);
      _shimmerPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
      canvas.drawCircle(center, radius, _shimmerPaint);
    }
  }

  void _drawGoldenAuraRays(Canvas canvas, Offset center, double maxRadius, double alpha) {
    const int rayCount = 12;
    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    for (int i = 0; i < rayCount; i++) {
      final double angle = (i * 2 * math.pi) / rayCount;
      final double widthHalf = 0.09; // radians

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + maxRadius * math.cos(angle - widthHalf),
          center.dy + maxRadius * math.sin(angle - widthHalf),
        )
        ..lineTo(
          center.dx + maxRadius * math.cos(angle + widthHalf),
          center.dy + maxRadius * math.sin(angle + widthHalf),
        )
        ..close();

      rayPaint.shader = ui.Gradient.radial(
        center,
        maxRadius,
        [
          const Color(0xFFFFD54F).withValues(alpha: alpha),
          const Color(0xFFFF9900).withValues(alpha: alpha * 0.40),
          Colors.transparent,
        ],
        [0.0, 0.60, 1.0],
      );
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GoldenAuraRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.image != image;
  }
}
