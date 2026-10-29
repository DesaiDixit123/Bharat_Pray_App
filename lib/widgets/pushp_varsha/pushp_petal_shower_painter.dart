import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pushp_petal_physics.dart';

/// CustomPainter rendering falling flower petals, targeted flying petals,
/// golden impact sparks, and emerging sacred text in Pushp Varsha.
class PushpPetalShowerPainter extends CustomPainter {
  final List<FallingPetal> petals;
  final List<TargetedPetal> targetedPetals;
  final List<PetalImpactSpark> impactSparks;
  final List<FloatingRamText> floatingTexts;
  final bool isBackgroundLayer;
  final double ambientTime;

  PushpPetalShowerPainter({
    required this.petals,
    this.targetedPetals = const [],
    this.impactSparks = const [],
    this.floatingTexts = const [],
    required this.isBackgroundLayer,
    required this.ambientTime,
  });

  static final Paint _petalPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _veinPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 0.8;
  static final Paint _pollenPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ── 1. AMBIENT FALLING PETALS ─────────────────────────────────────────
    if (petals.isNotEmpty) {
      for (final petal in petals) {
        if (petal.isBackground != isBackgroundLayer) continue;
        if (petal.alpha <= 0.01) continue;

        canvas.save();
        canvas.translate(petal.x, petal.y);
        canvas.rotate(petal.rotation);

        // Realistic 3D flutter: scaling horizontal axis with tumble cosine
        final double tumbleScale = math.cos(petal.tumble);
        canvas.scale(tumbleScale.abs().clamp(0.12, 1.0), 1.0);

        switch (petal.type) {
          case PetalType.lotusPetal:
            _drawLotusPetal(canvas, petal.size, petal.alpha);
            break;
          case PetalType.marigoldPetal:
            _drawMarigoldPetal(canvas, petal.size, petal.alpha);
            break;
          case PetalType.jasminePetal:
            _drawJasminePetal(canvas, petal.size, petal.alpha);
            break;
          case PetalType.goldenPollen:
            _drawGoldenPollen(canvas, petal.size, petal.alpha);
            break;
        }

        canvas.restore();
      }
    }

    // ── 2. TARGETED OFFERING PETALS (Foreground Layer Only) ──────────────
    if (!isBackgroundLayer && targetedPetals.isNotEmpty) {
      for (final tp in targetedPetals) {
        if (tp.alpha <= 0.01) continue;

        canvas.save();
        canvas.translate(tp.currentPos.dx, tp.currentPos.dy);
        canvas.rotate(tp.rotation);

        final double tumbleScale = math.cos(tp.tumble);
        canvas.scale(tumbleScale.abs().clamp(0.12, 1.0), 1.0);

        switch (tp.type) {
          case PetalType.lotusPetal:
            _drawLotusPetal(canvas, tp.size, tp.alpha);
            break;
          case PetalType.marigoldPetal:
            _drawMarigoldPetal(canvas, tp.size, tp.alpha);
            break;
          case PetalType.jasminePetal:
            _drawJasminePetal(canvas, tp.size, tp.alpha);
            break;
          case PetalType.goldenPollen:
            _drawGoldenPollen(canvas, tp.size, tp.alpha);
            break;
        }

        canvas.restore();
      }
    }

    // ── 3. PETAL IMPACT SPARKS & POLLEN PUFFS (Foreground Layer) ─────────
    if (!isBackgroundLayer && impactSparks.isNotEmpty) {
      for (final spark in impactSparks) {
        if (spark.alpha <= 0.02) continue;

        final Paint spPaint = Paint()
          ..color = spark.color.withValues(alpha: spark.alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(spark.position, spark.size * spark.alpha, spPaint);

        final Paint glowPaint = Paint()
          ..color = spark.color.withValues(alpha: spark.alpha * 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(spark.position, spark.size * 2.2 * spark.alpha, glowPaint);
      }
    }

    // ── 4. FLOATING SACRED DEVANAGARI TEXT (Foreground Layer Only) ───────
    if (!isBackgroundLayer && floatingTexts.isNotEmpty) {
      for (final ft in floatingTexts) {
        if (ft.alpha <= 0.01) continue;

        final List<Shadow> shadows = [
          Shadow(
            color: const Color(0xFFFFD54F).withValues(alpha: ft.alpha * 0.95),
            blurRadius: 14.0,
          ),
          Shadow(
            color: const Color(0xFFFF80AB).withValues(alpha: ft.alpha * 0.75),
            blurRadius: 22.0,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: ft.alpha * 0.90),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ];

        final bool isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
        final TextStyle style = isTest
            ? TextStyle(
                fontSize: ft.fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFFFFF9C4).withValues(alpha: ft.alpha),
                shadows: shadows,
              )
            : GoogleFonts.notoSerifDevanagari(
                fontSize: ft.fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFFFFF9C4).withValues(alpha: ft.alpha),
                shadows: shadows,
              );

        final textSpan = TextSpan(
          text: ft.text,
          style: style,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(ft.currentPos.dx, ft.currentPos.dy);
        canvas.scale(ft.scale, ft.scale);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2.0, -textPainter.height / 2.0),
        );
        canvas.restore();
      }
    }
  }

  void _drawLotusPetal(Canvas canvas, double size, double alpha) {
    final double w = size;
    final double h = size * 1.55;

    final Path path = Path()
      ..moveTo(0, -h * 0.50) // Tip
      ..cubicTo(w * 0.52, -h * 0.22, w * 0.48, h * 0.32, 0, h * 0.50) // Right curve to base
      ..cubicTo(-w * 0.48, h * 0.32, -w * 0.52, -h * 0.22, 0, -h * 0.50) // Left curve to tip
      ..close();

    final Rect rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);

    // Sacred lotus petal gradient: soft pink base to vibrant magenta tip
    _petalPaint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFFFF0F5).withValues(alpha: alpha * 0.95), // White-pink base
        const Color(0xFFFF80AB).withValues(alpha: alpha * 0.90), // Soft rose
        const Color(0xFFE91E63).withValues(alpha: alpha * 0.85), // Magenta tip
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);

    canvas.drawPath(path, _petalPaint);

    // Translucent central vein
    _veinPaint.color = Colors.white.withValues(alpha: alpha * 0.40);
    canvas.drawLine(const Offset(0, 0.35 * 10), const Offset(0, -0.40 * 10), _veinPaint);
  }

  void _drawMarigoldPetal(Canvas canvas, double size, double alpha) {
    final double w = size * 0.85;
    final double h = size * 1.30;

    final Path path = Path()
      ..moveTo(0, -h * 0.50)
      ..cubicTo(w * 0.55, -h * 0.15, w * 0.45, h * 0.35, 0, h * 0.50)
      ..cubicTo(-w * 0.45, h * 0.35, -w * 0.55, -h * 0.15, 0, -h * 0.50)
      ..close();

    final Rect rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);

    _petalPaint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFFFF9C4).withValues(alpha: alpha * 0.95),
        const Color(0xFFFFD54F).withValues(alpha: alpha * 0.90),
        const Color(0xFFFF8F00).withValues(alpha: alpha * 0.85),
      ],
      stops: const [0.0, 0.50, 1.0],
    ).createShader(rect);

    canvas.drawPath(path, _petalPaint);
  }

  void _drawJasminePetal(Canvas canvas, double size, double alpha) {
    final double w = size * 0.70;
    final double h = size * 1.25;

    final Path path = Path()
      ..moveTo(0, -h * 0.50)
      ..cubicTo(w * 0.50, -h * 0.18, w * 0.40, h * 0.30, 0, h * 0.50)
      ..cubicTo(-w * 0.40, h * 0.30, -w * 0.50, -h * 0.18, 0, -h * 0.50)
      ..close();

    final Rect rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);

    _petalPaint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFFFF9C4).withValues(alpha: alpha * 0.95), // Delicate pale ivory base
        const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.92), // Crisp white
        const Color(0xFFF3E5F5).withValues(alpha: alpha * 0.85), // Soft sacred lilac tint
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);

    canvas.drawPath(path, _petalPaint);
  }

  void _drawGoldenPollen(Canvas canvas, double size, double alpha) {
    final double r = size * 0.35;
    _pollenPaint.shader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: alpha),
        const Color(0xFFFFD54F).withValues(alpha: alpha * 0.85),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.8));

    canvas.drawCircle(Offset.zero, r * 1.8, _pollenPaint);
  }

  @override
  bool shouldRepaint(covariant PushpPetalShowerPainter oldDelegate) {
    return oldDelegate.petals.length != petals.length ||
        oldDelegate.targetedPetals.length != targetedPetals.length ||
        oldDelegate.impactSparks.length != impactSparks.length ||
        oldDelegate.floatingTexts.length != floatingTexts.length ||
        oldDelegate.ambientTime != ambientTime ||
        oldDelegate.isBackgroundLayer != isBackgroundLayer;
  }
}
