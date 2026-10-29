import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../ram_path_calculator.dart';

/// Painter for Effect 4: Divine Particle Reveal.
///
/// Visual Style:
/// - Celestial golden stardust & prana particles spiraling upwards in dynamic arcs.
/// - Unmasks the portrait through expanding golden stardust constellations.
/// - Shimmering golden sparks, soft glowing orbs, and radiant starlight blooms.
/// - STRICT FACE SHIELD: Sacred face remains protected (1..102) and unmasks last (103..108).
class DivineParticleRevealPainter extends CustomPainter {
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

  DivineParticleRevealPainter({
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

      // Celestial golden stardust bloom at completion
      final glowRadius = dstRect.width * (0.85 + (0.15 * math.sin(completionGlowProgress * math.pi)));
      final glowAlpha = (0.32 * completionGlowProgress).clamp(0.0, 1.0);

      _drawCelestialStardustField(canvas, dstRect, 35, completionGlowProgress);

      final auraPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          glowRadius,
          [
            const Color(0xFFFFE082).withValues(alpha: glowAlpha),
            const Color(0xFFFF9900).withValues(alpha: glowAlpha * 0.45),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        );
      canvas.drawCircle(haloCenter, glowRadius, auraPaint);
      return;
    }

    // 3. Ambient Drifting Golden Stardust in Background
    final double progressRatio = (revealedNodes.length / 108.0).clamp(0.0, 1.0);
    _drawCelestialStardustField(canvas, dstRect, 22, progressRatio);

    // 4. SaveLayer for progressive feathered aperture masking
    canvas.saveLayer(screenRect, Paint());

    // Balanced progressive expansion:
    final double expansion = 1.0 + (2.00 * math.pow(progressRatio, 2.2));

    // ── A. Draw Non-Face Mask Blobs ─────────────────────────────────────
    // Overlapping organic feathered nodes with stardust particle clusters
    for (final node in revealedNodes) {
      if (node.step >= 102) continue; // Face climax nodes in Step B

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * 1.18 * dstRect.width * expansion;

      _maskBlobPaint.shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.white,
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        [0.0, 0.50, 0.78, 1.0],
      );
      canvas.drawCircle(center, radius, _maskBlobPaint);
    }

    // ── B. Draw Sacred Face Climax Nodes (Japs 103..108) ────────────────
    for (final node in revealedNodes) {
      if (node.step < 102) continue;

      final center = Offset(
        dstRect.left + (node.u * dstRect.width),
        dstRect.top + (node.v * dstRect.height),
      );
      final radius = node.radiusNorm * 1.18 * dstRect.width;

      _maskBlobPaint.shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.white,
          Colors.white.withValues(alpha: 0.94),
          Colors.white.withValues(alpha: 0.42),
          Colors.transparent,
        ],
        [0.0, 0.58, 0.82, 1.0],
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

    // 5. Golden Stardust Sparkle & Shimmer on boundary of newest revealed node
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.90).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final radius = newestNode!.radiusNorm * 1.18 * dstRect.width * nodeExp * 0.88;

      _shimmerPaint.color = const Color(0xFFFFD700).withValues(alpha: shimmerAlpha);
      _shimmerPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
      canvas.drawCircle(center, radius, _shimmerPaint);

      // Stardust particle burst sparks around newest node
      _drawNodeSparkBurst(canvas, center, radius, shimmerProgress);
    }
  }

  void _drawNodeSparkBurst(Canvas canvas, Offset center, double radius, double progress) {
    const int sparkCount = 8;
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    final double burstDist = radius * (1.0 + (0.35 * progress));
    final double sparkAlpha = ((1.0 - progress) * 0.85).clamp(0.0, 1.0);

    for (int i = 0; i < sparkCount; i++) {
      final double angle = (i * 2 * math.pi) / sparkCount + (progress * 0.5);
      final sparkPos = Offset(
        center.dx + (burstDist * math.cos(angle)),
        center.dy + (burstDist * math.sin(angle)),
      );
      sparkPaint.color = const Color(0xFFFFE082).withValues(alpha: sparkAlpha);
      canvas.drawCircle(sparkPos, 2.5 * (1.0 - progress), sparkPaint);
    }
  }

  void _drawCelestialStardustField(Canvas canvas, Rect dstRect, int count, double progress) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      // Deterministic pseudo-random distribution
      final double seedU = ((i * 37) % 100) / 100.0;
      final double seedV = ((i * 53) % 100) / 100.0;
      final double pSize = 1.2 + (((i * 17) % 25) / 10.0);

      final double px = dstRect.left + (seedU * dstRect.width);
      // Gentle upward drift based on progress
      final double driftY = (progress * 40.0 * (1.0 + (i % 3))) % dstRect.height;
      double py = dstRect.top + (seedV * dstRect.height) - driftY;
      if (py < dstRect.top) py += dstRect.height;

      final double alpha = (0.35 + (0.45 * math.sin((i + progress * 4) * 0.8))).clamp(0.15, 0.80);
      final Color pColor = (i % 2 == 0)
          ? const Color(0xFFFFD700)
          : const Color(0xFFFFF8E7);

      particlePaint.color = pColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), pSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DivineParticleRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.image != image;
  }
}
