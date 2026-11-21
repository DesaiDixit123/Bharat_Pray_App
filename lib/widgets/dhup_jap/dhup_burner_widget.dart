import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders the traditional brass Dhup Dani (incense burner) with glowing embers,
/// scattered red rose petals on the altar, and a realistic sacred diya flame.
/// - The baked flame has been removed from the brass burner image so it is unlit by default.
/// - When chanting is clicked, an authentic, realistic living flame ignites on the wick spout.
class DhupBurnerWidget extends StatelessWidget {
  final double emberGlow;
  final double diyaIntensity; // 0.0 (dormant/unlit) to 1.0+ (bright flaming)
  final bool isChantingActive;
  final ValueChanged<Offset>? onBurnerMouthPositioned;

  const DhupBurnerWidget({
    super.key,
    required this.emberGlow,
    this.diyaIntensity = 0.0,
    this.isChantingActive = false,
    this.onBurnerMouthPositioned,
  });

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double burnerSize = (screenW * 0.38).clamp(130.0, 180.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate smoke emission point in global coordinates (at the tip of the flame)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize && onBurnerMouthPositioned != null) {
            final localCenter = Offset(
              (renderBox.size.width * 0.50) + (burnerSize * 0.198),
              renderBox.size.height - (burnerSize * 0.678) - 16,
            );
            final globalCenter = renderBox.localToGlobal(localCenter);
            onBurnerMouthPositioned!(globalCenter);
          }
        });

        final double clampedIntensity = diyaIntensity.clamp(0.0, 1.3);

        return SizedBox(
          width: double.infinity,
          height: 145,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // 1. Scattered Rose Petals on the altar floor
              Positioned(
                bottom: 8,
                left: screenW * 0.18,
                child: Transform.rotate(
                  angle: 0.35,
                  child: Image.asset(
                    'assets/images/devotional/rose_petal.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: screenW * 0.28,
                child: Transform.rotate(
                  angle: -0.45,
                  child: Image.asset(
                    'assets/images/devotional/rose_petal.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: screenW * 0.28,
                child: Transform.rotate(
                  angle: 0.55,
                  child: Image.asset(
                    'assets/images/devotional/rose_petal.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                right: screenW * 0.18,
                child: Transform.rotate(
                  angle: -0.25,
                  child: Image.asset(
                    'assets/images/devotional/rose_petal.png',
                    width: 25,
                    height: 25,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 2. Unlit Brass Dhup Dani Image
              Positioned(
                bottom: 0,
                child: Image.asset(
                  'assets/images/devotional/dhoop_burner.png',
                  width: burnerSize,
                  height: burnerSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackDhupDani(burnerSize),
                ),
              ),

              // 3. Realistic Sacred Central Diya Flame positioned strictly ON the wick spout
              if (clampedIntensity > 0.01)
                Positioned(
                  bottom: (burnerSize * 0.678) - 5,
                  left: (screenW / 2) + (burnerSize * 0.198) - 13,
                  child: RealisticDiyaFlame(
                    emberGlow: emberGlow,
                    intensity: clampedIntensity,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackDhupDani(double size) {
    return Container(
      width: size,
      height: size * 0.85,
      alignment: Alignment.center,
      child: const Icon(
        Icons.waves_rounded,
        size: 72,
        color: Color(0xFFFFB300),
      ),
    );
  }
}

/// Authentic, realistic temple oil lamp flame (દીવાની જ્યોત)
/// - Teardrop organic flame envelope with golden amber and saffron tones
/// - Radiant golden aura (પ્રભા) casting warm divine glow on the brass lamp
/// - Vivid golden-yellow core and white-hot spark center (શુદ્ધ શ્વેત જ્યોત)
/// - Delicate cyan-blue combustion base at the charred cotton wick (વાટ)
/// - Living organic micro-flicker and tip sway
class RealisticDiyaFlame extends StatelessWidget {
  final double emberGlow;
  final double intensity;

  const RealisticDiyaFlame({
    super.key,
    required this.emberGlow,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0.01) return const SizedBox.shrink();

    // Natural multi-frequency living flicker
    final double flicker = 0.94 +
        (0.06 * math.sin(emberGlow * math.pi * 7.0)) +
        (0.03 * math.sin(emberGlow * math.pi * 15.0));
    final double tipSway = 1.6 * math.sin(emberGlow * math.pi * 5.0);
    final double scale = (intensity * flicker).clamp(0.0, 1.4);

    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: CustomPaint(
        size: const Size(26, 40),
        painter: _RealisticFlamePainter(
          flicker: flicker,
          tipSway: tipSway,
          intensity: intensity.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _RealisticFlamePainter extends CustomPainter {
  final double flicker;
  final double tipSway;
  final double intensity;

  _RealisticFlamePainter({
    required this.flicker,
    required this.tipSway,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    final w = size.width;
    final h = size.height;
    final centerX = w * 0.50;
    final baseY = h - 2.0;

    // 1. Broad Ambient Golden/Saffron Aura (Soft Warm Glow)
    final auraPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, h * 0.55),
        w * 1.5,
        [
          const Color(0xFFFFD54F).withValues(alpha: 0.65 * intensity),
          const Color(0xFFFF8F00).withValues(alpha: 0.35 * intensity),
          const Color(0xFFE65100).withValues(alpha: 0.15 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.40, 0.75, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(Offset(centerX, h * 0.55), w * 1.4, auraPaint);

    // 2. Charred Cotton Wick Base (વાટ)
    final wickPaint = Paint()
      ..color = const Color(0xFF261C14).withValues(alpha: intensity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX - 0.5, baseY), Offset(centerX, baseY - 5.0), wickPaint);

    // 3. Outer Flame Body (Organic Teardrop Bezier)
    final outerPath = Path();
    final tipX = centerX + tipSway;
    final tipY = 1.0;

    outerPath.moveTo(centerX, baseY - 2.0);
    // Left belly
    outerPath.cubicTo(
      centerX - (w * 0.46), baseY - (h * 0.28),
      centerX - (w * 0.38), h * 0.38,
      tipX, tipY,
    );
    // Right belly
    outerPath.cubicTo(
      centerX + (w * 0.38), h * 0.38,
      centerX + (w * 0.46), baseY - (h * 0.28),
      centerX, baseY - 2.0,
    );
    outerPath.close();

    final outerFlamePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX, baseY),
        Offset(tipX, tipY),
        [
          const Color(0xFFFF5722).withValues(alpha: 0.90 * intensity),
          const Color(0xFFFF9800).withValues(alpha: 0.95 * intensity),
          const Color(0xFFFFD600).withValues(alpha: 0.98 * intensity),
          const Color(0xFFFFEB3B).withValues(alpha: 0.90 * intensity),
          const Color(0xFFFF9100).withValues(alpha: 0.85 * intensity),
        ],
        [0.0, 0.25, 0.60, 0.85, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    canvas.drawPath(outerPath, outerFlamePaint);

    // 4. Inner Radiant Core (Golden-Yellow Teardrop)
    final innerPath = Path();
    final innerTipY = h * 0.18;
    innerPath.moveTo(centerX, baseY - 4.0);
    innerPath.cubicTo(
      centerX - (w * 0.26), baseY - (h * 0.32),
      centerX - (w * 0.20), h * 0.45,
      centerX + (tipSway * 0.5), innerTipY,
    );
    innerPath.cubicTo(
      centerX + (w * 0.20), h * 0.45,
      centerX + (w * 0.26), baseY - (h * 0.32),
      centerX, baseY - 4.0,
    );
    innerPath.close();

    final innerFlamePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX, baseY),
        Offset(centerX, innerTipY),
        [
          const Color(0xFFFFD54F).withValues(alpha: 0.95 * intensity),
          const Color(0xFFFFF59D).withValues(alpha: 0.98 * intensity),
          const Color(0xFFFFFFFF).withValues(alpha: 0.95 * intensity),
        ],
        [0.0, 0.50, 1.0],
      );
    canvas.drawPath(innerPath, innerFlamePaint);

    // 5. White-Hot Spark Center (શુદ્ધ શ્વેત જ્યોત)
    final corePath = Path();
    final coreTipY = h * 0.34;
    corePath.moveTo(centerX, baseY - 5.0);
    corePath.cubicTo(
      centerX - (w * 0.12), baseY - (h * 0.30),
      centerX - (w * 0.08), h * 0.52,
      centerX + (tipSway * 0.2), coreTipY,
    );
    corePath.cubicTo(
      centerX + (w * 0.08), h * 0.52,
      centerX + (w * 0.12), baseY - (h * 0.30),
      centerX, baseY - 5.0,
    );
    corePath.close();

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.98 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    canvas.drawPath(corePath, corePaint);

    // 6. Base Cyan-Blue Crescent (Authentic Combustion Zone)
    final blueBasePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, baseY - 1.0),
        w * 0.28,
        [
          const Color(0xFF2979FF).withValues(alpha: 0.60 * intensity),
          const Color(0xFF1565C0).withValues(alpha: 0.35 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.65, 1.0],
      );
    canvas.drawCircle(Offset(centerX, baseY - 1.5), w * 0.25, blueBasePaint);
  }

  @override
  bool shouldRepaint(covariant _RealisticFlamePainter oldDelegate) => true;
}
