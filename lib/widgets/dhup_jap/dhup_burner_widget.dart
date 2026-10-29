import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the traditional brass Dhup Dani (incense burner) with glowing embers,
/// burning incense sticks, flanking brass diyas, and scattered red rose petals on the altar.
class DhupBurnerWidget extends StatelessWidget {
  final double emberGlow;
  final ValueChanged<Offset>? onBurnerMouthPositioned;

  const DhupBurnerWidget({
    super.key,
    required this.emberGlow,
    this.onBurnerMouthPositioned,
  });

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double burnerSize = (screenW * 0.38).clamp(130.0, 180.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate smoke emission point in global or parent coordinates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize && onBurnerMouthPositioned != null) {
            final localCenter = Offset(
              renderBox.size.width * 0.50,
              renderBox.size.height * 0.32,
            );
            final globalCenter = renderBox.localToGlobal(localCenter);
            onBurnerMouthPositioned!(globalCenter);
          }
        });

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

              // 2. Left Altar Diya Lamp
              Positioned(
                bottom: 12,
                left: screenW * 0.15,
                child: _buildAltarDiya(emberGlow, isLeft: true),
              ),

              // 3. Right Altar Diya Lamp
              Positioned(
                bottom: 12,
                right: screenW * 0.15,
                child: _buildAltarDiya(emberGlow, isLeft: false),
              ),

              // 4. Warm Ember Glow behind/in Dhup Dani
              Positioned(
                bottom: 45,
                child: Container(
                  width: burnerSize * 0.65,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5500).withValues(
                          alpha: 0.45 + (0.25 * math.sin(emberGlow * math.pi)),
                        ),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(
                          alpha: 0.35 + (0.15 * math.cos(emberGlow * math.pi)),
                        ),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Burning Incense Sticks (Agarbatti) radiating from burner bowl
              Positioned(
                bottom: 55,
                child: CustomPaint(
                  size: Size(burnerSize * 0.60, 48),
                  painter: _IncenseSticksPainter(emberGlow: emberGlow),
                ),
              ),

              // 6. Brass Dhup Dani Image
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildAltarDiya(double emberGlow, {required bool isLeft}) {
    final double flicker = 0.85 + (0.15 * math.sin(emberGlow * math.pi * 2 + (isLeft ? 0.0 : 1.2)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flame
        Container(
          width: 12,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.60 * flicker),
                blurRadius: 14,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.40 * flicker),
                blurRadius: 22,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Brass Diya Lamp Image
        Image.asset(
          'assets/images/devotional/diya_lamp.png',
          width: 44,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFFB300),
            size: 28,
          ),
        ),
      ],
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

class _IncenseSticksPainter extends CustomPainter {
  final double emberGlow;

  _IncenseSticksPainter({required this.emberGlow});

  @override
  void paint(Canvas canvas, Size size) {
    final stickPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final emberPaint = Paint()..style = PaintingStyle.fill;

    final baseCenter = Offset(size.width / 2.0, size.height);

    // 5 Agarbatti incense sticks splayed out gently
    final angles = [-0.32, -0.16, 0.0, 0.16, 0.32];
    final stickLengths = [size.height * 0.95, size.height * 1.05, size.height * 1.10, size.height * 1.05, size.height * 0.95];

    for (int i = 0; i < angles.length; i++) {
      final angle = angles[i];
      final len = stickLengths[i];
      final tipX = baseCenter.dx + (len * math.sin(angle));
      final tipY = baseCenter.dy - (len * math.cos(angle));
      final tip = Offset(tipX, tipY);

      // Draw stick
      canvas.drawLine(baseCenter, tip, stickPaint);

      // Glowing ember tip
      final double flicker = 0.70 + (0.30 * math.sin(emberGlow * math.pi * 3 + (i * 1.2)));
      emberPaint.color = const Color(0xFFFF3D00).withValues(alpha: flicker);
      canvas.drawCircle(tip, 2.5, emberPaint);

      // Warm glow halo on tip
      final tipGlowPaint = Paint()
        ..color = const Color(0xFFFFAB00).withValues(alpha: flicker * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawCircle(tip, 4.0, tipGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IncenseSticksPainter oldDelegate) => true;
}
