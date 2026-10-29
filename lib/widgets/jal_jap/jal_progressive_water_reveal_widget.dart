import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cinematic_jap/ram_path_calculator.dart';

/// Progressive Sacred Water Emergence Widget for Lord Shri Ram Jal Darshan.
/// Key Devotional Architecture:
/// - Lord Shri Ram emerges upward FROM THE SACRED WATER POOL into the open temple archway.
/// - Unobstructed Devotional Composition: Bhagwan's crown, face, tilak, and blessing hand
///   tower in the center sanctum archway, COMPLETELY CLEAR of any bottom controls!
/// - At count 0: Hidden beneath the sacred water surface with an ethereal golden underwater aura.
/// - Count 1-18: Underwater approach; radiant crest of golden Mukut breaks through the water.
/// - Count 19-36: Towering golden Mukut and peacock feathers emerge above the waterline.
/// - Count 37-54: Divine forehead, sacred Tilak, and compassionate radiant eyes rise into the open archway.
/// - Count 55-72: Smiling divine face, jeweled kundals, and upper chest emerge above water.
/// - Count 73-90: Torso, blessing hand with sacred 'ॐ', and golden bow rise above water.
/// - Count 108: Full majestic waist-up Darshan with radiant celestial golden sunburst halo.
/// - Natural waterline meniscus, underwater refraction, and water ripples.
class JalProgressiveWaterRevealWidget extends StatefulWidget {
  final int count;
  final int targetCount;
  final List<RevealNode>? revealedNodes;
  final double ambientTime; // 0.0 to 1.0 continuous wave animation
  final bool isCompleted;
  final double completionGlow; // 0.0 to 1.0
  final String imageAsset;

  const JalProgressiveWaterRevealWidget({
    super.key,
    required this.count,
    this.targetCount = 108,
    this.revealedNodes,
    required this.ambientTime,
    required this.isCompleted,
    required this.completionGlow,
    this.imageAsset = 'assets/images/ram_deity_transparent.png',
  });

  @override
  State<JalProgressiveWaterRevealWidget> createState() => _JalProgressiveWaterRevealWidgetState();
}

class _JalProgressiveWaterRevealWidgetState extends State<JalProgressiveWaterRevealWidget> {
  ui.Image? _loadedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant JalProgressiveWaterRevealWidget oldWidget) {
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
      debugPrint('[JalProgressiveWaterRevealWidget] Notice loading image: $e');
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
        painter: JalProgressiveWaterRevealPainter(
          image: _loadedImage,
          count: widget.count,
          targetCount: widget.targetCount,
          revealedNodes: widget.revealedNodes,
          ambientTime: widget.ambientTime,
          isCompleted: widget.isCompleted,
          completionGlow: widget.completionGlow,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// CustomPainter rendering Lord Shri Ram rising vertically into the temple archway
/// from the sacred Tirth water pool.
class JalProgressiveWaterRevealPainter extends CustomPainter {
  final ui.Image? image;
  final int count;
  final int targetCount;
  final List<RevealNode>? revealedNodes;
  final double ambientTime;
  final bool isCompleted;
  final double completionGlow;

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;
  static final Paint _waterlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _underwaterGlowPaint = Paint()..style = PaintingStyle.fill;

  JalProgressiveWaterRevealPainter({
    required this.image,
    required this.count,
    this.targetCount = 108,
    this.revealedNodes,
    required this.ambientTime,
    required this.isCompleted,
    required this.completionGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || image == null) return;

    final double imgW = image!.width.toDouble();
    final double imgH = image!.height.toDouble();
    final double imageAspect = imgW / imgH;

    // ── Water Pool Geometry & Sanctum Archway Alignment ────────────────
    // The sacred water pool back steps in jal_temple_bg.png meet the archway at ~54% height
    final double waterlineY = size.height * 0.54;
    final double centerX = size.width * 0.50;

    // Deity rendered dimensions: aspect-fit horizontally centered in the archway
    final double deityW = size.width * 0.84;
    final double deityH = deityW / imageAspect;
    final double deityLeft = (size.width - deityW) * 0.50;

    // ── Upward Emergence Motion Calculation ───────────────────────────
    final double t = isCompleted ? 1.0 : (count / targetCount).clamp(0.0, 1.0);

    // At t = 0.0: The crown apex is submerged just below the waterline
    final double startTopY = waterlineY + 20.0;

    // At t = 1.0: Full Darshan position — waist (at ~68% of image height) meets the waterline
    // This places the crown top right below the top bar (~9% height) and the face (~22% height)
    // completely clear of all bottom controls!
    final double finalTopY = waterlineY - (deityH * 0.68);

    // Smooth upward ascension curve
    final double currentTopY = startTopY - ((startTopY - finalTopY) * math.pow(t, 0.88));
    final Rect dstRect = Rect.fromLTWH(deityLeft, currentTopY, deityW, deityH);
    final Rect srcRect = Rect.fromLTWH(0, 0, imgW, imgH);

    // Dynamic wave modulation at the waterline
    final double waveT = ambientTime * 2 * math.pi;
    final double waveOscillation = math.sin(waveT) * 3.0;
    final double effectiveWaterline = waterlineY + waveOscillation;

    // ── STAGE 0: JAP 0 (Calm Water, Deity Submerged) ───────────────────
    if (count <= 0 && !isCompleted) {
      final double subtleGlow = 0.06 + (0.03 * math.sin(waveT));
      _underwaterGlowPaint.shader = ui.Gradient.radial(
        Offset(centerX, waterlineY + 45),
        size.width * 0.40,
        [
          const Color(0xFFFFD54F).withValues(alpha: subtleGlow),
          Colors.transparent,
        ],
        [0.0, 1.0],
      );
      canvas.drawCircle(Offset(centerX, waterlineY + 45), size.width * 0.40, _underwaterGlowPaint);
      return;
    }

    // ── STAGE 1: SUBMERGED ZONE (Below Waterline) ──────────────────────
    if (dstRect.bottom > effectiveWaterline) {
      canvas.save();
      // Clip to water area only
      canvas.clipRect(Rect.fromLTRB(0, effectiveWaterline, size.width, size.height));

      // 1. Underwater Golden Light Emanating from the Deity
      final double underwaterAlpha = (0.24 + (0.28 * t)).clamp(0.15, 0.52);
      _underwaterGlowPaint.shader = ui.Gradient.radial(
        Offset(centerX, effectiveWaterline + 45),
        deityW * 0.65,
        [
          const Color(0xFFFFE082).withValues(alpha: underwaterAlpha * 0.60),
          const Color(0xFF004D40).withValues(alpha: underwaterAlpha * 0.35),
          Colors.transparent,
        ],
        [0.0, 0.55, 1.0],
      );
      canvas.drawCircle(Offset(centerX, effectiveWaterline + 45), deityW * 0.65, _underwaterGlowPaint);

      // 2. Submerged Deity Form with sacred water tint & refraction
      final double refractionAlpha = (0.30 + (0.15 * (1.0 - t))).clamp(0.18, 0.45);
      _imagePaint.color = Colors.white.withValues(alpha: refractionAlpha);

      canvas.save();
      final double swayX = math.sin(waveT + 1.2) * 3.5;
      canvas.translate(swayX, 0);
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);
      canvas.restore();

      // 3. Sacred water ripples over the submerged figure
      _waterlinePaint
        ..strokeWidth = 1.4
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.22 + (0.10 * math.sin(waveT)));
      for (int i = 1; i <= 4; i++) {
        final double rippleY = effectiveWaterline + (i * 24.0);
        if (rippleY < dstRect.bottom) {
          final Path p = Path()..moveTo(deityLeft + 20, rippleY);
          for (double x = deityLeft + 20; x <= deityLeft + deityW - 20; x += 16) {
            final double yOff = math.sin((x * 0.03) + waveT + i) * 3.0;
            p.lineTo(x, rippleY + yOff);
          }
          canvas.drawPath(p, _waterlinePaint);
        }
      }

      canvas.restore();
    }

    // ── STAGE 2: EMERGED ZONE (Above Waterline in the Archway) ─────────
    if (dstRect.top < effectiveWaterline) {
      canvas.save();
      // Clip strictly above the waterline
      canvas.clipRect(Rect.fromLTRB(0, 0, size.width, effectiveWaterline));

      // Radiant golden aura bloom behind Bhagwan's crown and halo
      final haloCenter = Offset(
        dstRect.left + (0.50 * deityW),
        dstRect.top + (0.28 * deityH),
      );
      final double auraRadius = deityW * 0.68;
      final double auraAlpha = (0.22 + (0.60 * t) + (0.20 * completionGlow)).clamp(0.0, 1.0);

      final auraPaint = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          auraRadius,
          [
            const Color(0xFFFFE082).withValues(alpha: auraAlpha * 0.70),
            const Color(0xFFFF9900).withValues(alpha: auraAlpha * 0.35),
            Colors.transparent,
          ],
          [0.0, 0.50, 1.0],
        );
      canvas.drawCircle(haloCenter, auraRadius, auraPaint);

      // Draw the emerged deity with full clarity and vibrant devotional colors
      _imagePaint.color = Colors.white;
      canvas.drawImageRect(image!, srcRect, dstRect, _imagePaint);

      canvas.restore();
    }

    // ── STAGE 3: WATERLINE INTERSECTION & CREST RIPPLES ───────────────
    if (dstRect.top <= effectiveWaterline && dstRect.bottom >= effectiveWaterline) {
      final double bodyWidthAtWaterline = deityW * (0.35 + (0.45 * t));
      final Rect ringRect = Rect.fromCenter(
        center: Offset(centerX, effectiveWaterline),
        width: bodyWidthAtWaterline,
        height: 18.0 + (math.sin(waveT) * 3.0),
      );

      // 1. Golden water crest meniscus ring
      _waterlinePaint
        ..strokeWidth = 2.4
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.75 + (0.20 * math.sin(waveT)));
      canvas.drawOval(ringRect, _waterlinePaint);

      // 2. Outer cyan refractive water shockwave
      _waterlinePaint
        ..strokeWidth = 1.2
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, effectiveWaterline),
          width: bodyWidthAtWaterline * 1.35,
          height: 26.0,
        ),
        _waterlinePaint,
      );

      // 3. Sparkling water droplet highlights at the emergence edge
      final Paint splashPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final double splashSpread = bodyWidthAtWaterline * 0.45;
      for (int i = 0; i < 4; i++) {
        final double sx = centerX + ((i - 1.5) * (splashSpread * 0.6));
        final double sy = effectiveWaterline - 4.0 + (math.sin(waveT + i) * 3.0);
        canvas.drawCircle(Offset(sx, sy), 1.8, splashPaint);
      }
    }

    // ── STAGE 4: FULL DARSHAN AT 108 ──────────────────────────────────
    if (isCompleted || count >= targetCount) {
      final haloCenter = Offset(
        dstRect.left + (0.50 * deityW),
        dstRect.top + (0.28 * deityH),
      );
      final double glowRadius = deityW * (0.85 + (0.15 * math.sin(ambientTime * 2 * math.pi)));
      final Paint completionAura = Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          glowRadius,
          [
            const Color(0xFFFFF176).withValues(alpha: 0.50),
            const Color(0xFFFF9900).withValues(alpha: 0.25),
            Colors.transparent,
          ],
          [0.0, 0.40, 1.0],
        );
      canvas.drawCircle(haloCenter, glowRadius, completionAura);
    }
  }

  @override
  bool shouldRepaint(covariant JalProgressiveWaterRevealPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.ambientTime != ambientTime ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.completionGlow != completionGlow ||
        oldDelegate.image != image;
  }
}
