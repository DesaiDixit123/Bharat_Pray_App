import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../jap_mantra_helper.dart';

/// Full Sacred Mantra Descending & Transforming into Radiant Divine Light.
/// The complete mantra drops smoothly from above in brilliant golden light,
/// descends towards [revealPoint], and dissolves into celestial sunburst rays.
class MantraLightPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 3s)
  final String mantra;
  final Offset revealPoint;
  final double seed;

  MantraLightPainter({
    required this.progress,
    required this.mantra,
    required this.revealPoint,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final targetX = revealPoint.dx.clamp(40.0, size.width - 40.0);
    final targetY = revealPoint.dy.clamp(40.0, size.height - 40.0);
    final targetPos = Offset(targetX, targetY);

    final fullMantra = mantra.isNotEmpty ? mantra : 'ॐ नमः शिवाय';

    // Timeline:
    // 0.0 to 0.65: Full mantra drops down from above towards revealPoint
    // 0.65 to 1.0: Transforms into radiant sunburst rays and ascending sparks at revealPoint
    double textAlpha = 1.0;
    double dropT = 0.0;

    if (progress < 0.65) {
      dropT = Curves.easeOutCubic.transform((progress / 0.65).clamp(0.0, 1.0));
      textAlpha = (progress < 0.20)
          ? (progress / 0.20).clamp(0.0, 1.0)
          : 1.0;
    } else {
      dropT = 1.0;
      final outT = ((progress - 0.65) / 0.25).clamp(0.0, 1.0);
      textAlpha = (1.0 - Curves.easeInQuad.transform(outT)).clamp(0.0, 1.0);
    }

    // 1. Descending vertical divine light pillar
    if (progress < 0.75) {
      final beamAlpha = (textAlpha * 0.45).clamp(0.0, 0.45);
      final startY = 10.0;
      final curY = startY + (targetPos.dy - startY) * dropT;

      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: beamAlpha * 0.2),
            const Color(0xFFFFD700).withValues(alpha: beamAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTRB(targetPos.dx - 35, 0, targetPos.dx + 35, curY + 20))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      final beamRect = Rect.fromLTRB(targetPos.dx - 28, 0, targetPos.dx + 28, curY + 15);
      canvas.drawRect(beamRect, beamPaint);
    }

    // 2. Full Mantra dropping down smoothly
    if (textAlpha > 0.01) {
      final startY = 20.0;
      final curY = startY + (targetPos.dy - startY) * dropT;
      final curX = targetPos.dx + math.sin(progress * 5.0 + seed) * (1.0 - dropT) * 10.0;

      canvas.save();
      canvas.translate(curX, curY);

      // Radiant glow behind the full mantra
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: textAlpha * 0.45),
            const Color(0xFFFF8F00).withValues(alpha: textAlpha * 0.20),
            Colors.transparent,
          ],
          stops: const [0.0, 0.60, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 45.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(Offset.zero, 45.0, glowPaint);

      // Render the complete full mantra
      final textSpan = TextSpan(
        text: fullMantra,
        style: JapMantraHelper.getMantraTextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: textAlpha),
          shadows: [
            Shadow(
              color: const Color(0xFFFFD700).withValues(alpha: textAlpha * 0.95),
              blurRadius: 16.0,
            ),
            Shadow(
              color: const Color(0xFFFF8F00).withValues(alpha: textAlpha * 0.80),
              blurRadius: 10.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.88);

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // 3. Transformation into radiant sunburst rays at revealPoint (0.60 to 0.98)
    if (progress >= 0.60) {
      final burstT = ((progress - 0.60) / 0.38).clamp(0.0, 1.0);
      final burstCurve = Curves.easeOutCubic.transform(burstT);

      // Radiant sunburst orb
      final orbAlpha = (math.sin(burstT * math.pi) * 0.85).clamp(0.0, 0.85);
      if (orbAlpha > 0.01) {
        final orbRadius = 12.0 + (burstCurve * 32.0);
        final orbPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: orbAlpha),
              const Color(0xFFFFEB3B).withValues(alpha: orbAlpha * 0.85),
              const Color(0xFFFF9800).withValues(alpha: orbAlpha * 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.30, 0.65, 1.0],
          ).createShader(Rect.fromCircle(center: targetPos, radius: orbRadius))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(targetPos, orbRadius, orbPaint);
      }

      // 12 Radiating golden beams bursting from revealPoint
      const int rayCount = 12;
      final rayLength = 36.0 * burstCurve;
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2 * (1.0 - burstT * 0.5)
        ..color = const Color(0xFFFFD700).withValues(alpha: (1.0 - burstT) * 0.90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      for (int i = 0; i < rayCount; i++) {
        final angle = (i * 2 * math.pi / rayCount) + (burstT * 0.4);
        final p1 = Offset(
          targetPos.dx + math.cos(angle) * (8.0 * burstCurve),
          targetPos.dy + math.sin(angle) * (8.0 * burstCurve),
        );
        final p2 = Offset(
          targetPos.dx + math.cos(angle) * rayLength,
          targetPos.dy + math.sin(angle) * rayLength,
        );
        canvas.drawLine(p1, p2, rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MantraLightPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mantra != mantra || oldDelegate.revealPoint != revealPoint;
}
