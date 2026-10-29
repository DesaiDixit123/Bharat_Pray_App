import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../ram_path_calculator.dart';

/// Painter for Effect 3: Dhoop Smoke Reveal (Client Priority).
///
/// Visual Style:
/// - Sacred temple incense smoke / dhoop wisps rising gently from the bottom base.
/// - Translucent curling smoke plumes unmasking the divine portrait as they rise.
/// - Soft translucent white, pearl, and warm golden-amber smoke wisps.
/// - STRICT FACE SHIELD: Sacred face remains protected (1..102) and unmasks last (103..108).
class DhoopSmokeRevealPainter extends CustomPainter {
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

  DhoopSmokeRevealPainter({
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
    final smokeBase = Offset(
      dstRect.left + (0.50 * dstRect.width),
      dstRect.bottom - (0.05 * dstRect.height),
    );

    // 2. Stage 4 Darshan / Full Unmasked Completion
    if (isCompleted) {
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      // Sacred divine aura bloom at completion
      final haloCenter = Offset(
        dstRect.left + (0.50 * dstRect.width),
        dstRect.top + (0.28 * dstRect.height),
      );
      final glowRadius = dstRect.width * (0.85 + (0.15 * math.sin(completionGlowProgress * math.pi)));
      final glowAlpha = (0.30 * completionGlowProgress).clamp(0.0, 1.0);

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

    // 3. Ambient Base Dhoop Ember Glow & Rising Wisps in Background
    final double progressRatio = (revealedNodes.length / 108.0).clamp(0.0, 1.0);
    _drawDhoopEmberGlow(canvas, smokeBase, dstRect.width * 0.40, progressRatio);

    // 4. SaveLayer for progressive feathered aperture masking
    canvas.saveLayer(screenRect, Paint());

    // Balanced progressive expansion:
    final double expansion = 1.0 + (2.00 * math.pow(progressRatio, 2.2));

    // ── A. Draw Non-Face Mask Blobs ─────────────────────────────────────
    // Sacred Dhoop Smoke Plume Mask Paths
    if (progressRatio > 0.03) {
      final smokePath = _buildCurlingSmokeMaskPath(smokeBase, dstRect.width, dstRect.height, progressRatio);
      final smokePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.88)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
      canvas.drawPath(smokePath, smokePaint);
    }

    // Overlapping organic feathered nodes ensuring full non-face image coverage
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

    // 5. Pale Golden Shimmer on boundary of newest revealed node
    if (newestNode != null && shimmerProgress < 1.0) {
      final shimmerAlpha = ((1.0 - shimmerProgress) * 0.90).clamp(0.0, 1.0);
      final center = Offset(
        dstRect.left + (newestNode!.u * dstRect.width),
        dstRect.top + (newestNode!.v * dstRect.height),
      );
      final double nodeExp = newestNode!.step < 102 ? expansion : 1.0;
      final radius = newestNode!.radiusNorm * 1.18 * dstRect.width * nodeExp * 0.88;

      _shimmerPaint.color = const Color(0xFFFFE082).withValues(alpha: shimmerAlpha);
      _shimmerPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
      canvas.drawCircle(center, radius, _shimmerPaint);
    }
  }

  Path _buildCurlingSmokeMaskPath(Offset base, double width, double height, double progress) {
    final path = Path();
    // 5 gentle curling incense smoke wisps rising upwards
    const int wispCount = 5;
    final double riseHeight = height * 0.85 * math.min(1.0, progress * 1.25);

    for (int i = 0; i < wispCount; i++) {
      final double frac = i / (wispCount - 1); // 0.0 to 1.0
      final double xOffset = (frac - 0.5) * (width * 0.35);
      final double wispBaseX = base.dx + xOffset;
      final double wispBaseY = base.dy;
      final double wispTopY = base.dy - riseHeight;

      final wispPath = Path()..moveTo(wispBaseX, wispBaseY);

      // Layered sinusoidal curling wave points
      const int segments = 6;
      final double segHeight = riseHeight / segments;
      final double waveAmp = (width * 0.08) * (1.0 + frac);
      final double phase = i * 1.15;

      for (int s = 1; s <= segments; s++) {
        final double currentY = wispBaseY - (s * segHeight);
        final double prevY = wispBaseY - ((s - 1) * segHeight);
        final double waveX = wispBaseX + (waveAmp * math.sin((s * 0.9) + phase));
        final double prevWaveX = wispBaseX + (waveAmp * math.sin(((s - 1) * 0.9) + phase));

        wispPath.cubicTo(
          prevWaveX + (waveAmp * 0.4),
          prevY - (segHeight * 0.5),
          waveX - (waveAmp * 0.4),
          currentY + (segHeight * 0.5),
          waveX,
          currentY,
        );
      }

      // Return down with expanding plume width
      final double plumeWidth = width * 0.16 * (0.8 + frac);
      wispPath.lineTo(base.dx + xOffset + plumeWidth, wispTopY);
      wispPath.quadraticBezierTo(
        base.dx + xOffset + (plumeWidth * 0.5),
        base.dy - (riseHeight * 0.5),
        wispBaseX + 10,
        wispBaseY,
      );
      wispPath.close();

      path.addPath(wispPath, Offset.zero);
    }
    return path;
  }

  void _drawDhoopEmberGlow(Canvas canvas, Offset base, double maxRadius, double progress) {
    // Warm dhoop incense ember glow at the bottom base
    final glowRadius = maxRadius * (0.45 + (0.35 * progress));
    final glowAlpha = (0.28 * math.min(1.0, progress * 1.5)).clamp(0.0, 0.30);

    final emberPaint = Paint()
      ..shader = ui.Gradient.radial(
        base,
        glowRadius,
        [
          const Color(0xFFFF9900).withValues(alpha: glowAlpha),
          const Color(0xFFFF5500).withValues(alpha: glowAlpha * 0.50),
          Colors.transparent,
        ],
        [0.0, 0.35, 1.0],
      );
    canvas.drawCircle(base, glowRadius, emberPaint);
  }

  @override
  bool shouldRepaint(covariant DhoopSmokeRevealPainter oldDelegate) {
    return oldDelegate.revealedNodes.length != revealedNodes.length ||
        oldDelegate.newestNode != newestNode ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlowProgress != completionGlowProgress ||
        oldDelegate.image != image;
  }
}
