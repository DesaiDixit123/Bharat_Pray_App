import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the cinematic temple sanctum with the sacred water pool.
/// Features:
/// - Traditional stone architecture with carved pillars and warm temple diya illumination.
/// - Sacred pool extending through the center with gentle water reflections and ambient light caustics.
/// - Floating pink lotus flowers and diya lamp reflections.
class JalTempleBackground extends StatelessWidget {
  final double flameFlicker; // 0.0 to 1.0 driving lamp warmth & reflection waves

  const JalTempleBackground({
    super.key,
    required this.flameFlicker,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Sacred Temple Sanctum Background Image ──────────────────
        Image.asset(
          'assets/images/jal_temple_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackSanctum(),
        ),

        // ── 2. Atmospheric Depth & Soft Vignette ───────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.15,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.25),
              ],
              stops: const [0.60, 0.85, 1.0],
            ),
          ),
        ),

        // ── 3. Warm Temple Diya Lamp Glow Layer ────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 240,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFF9900).withValues(
                    alpha: 0.12 + (0.06 * math.sin(flameFlicker * 2 * math.pi)),
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── 4. Ambient Sacred Water Pool Caustic Highlights (Bottom Half) ─
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 380,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WaterCausticPainter(flameFlicker: flameFlicker),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackSanctum() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F0B08),
            Color(0xFF1B140E),
            Color(0xFF0D151C), // Deep blue-black water pool tone
            Color(0xFF060B10),
          ],
          stops: [0.0, 0.45, 0.75, 1.0],
        ),
      ),
    );
  }
}

/// Paints subtle water caustics, wave light lines, and golden reflections.
class _WaterCausticPainter extends CustomPainter {
  final double flameFlicker;

  _WaterCausticPainter({required this.flameFlicker});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double t = flameFlicker * 2 * math.pi;

    // Draw horizontal gentle sinusoidal water wave ripples across pool
    for (int i = 0; i < 7; i++) {
      final double yRatio = 0.20 + (i * 0.12);
      final double y = size.height * yRatio;
      final double waveAlpha = (0.04 + (0.03 * math.sin(t + i))) * (1.0 - (yRatio * 0.4));

      wavePaint
        ..strokeWidth = 1.2 + (i * 0.3)
        ..color = (i % 2 == 0)
            ? const Color(0xFFFFD54F).withValues(alpha: waveAlpha * 1.5) // Golden reflection
            : const Color(0xFF80DEEA).withValues(alpha: waveAlpha); // Cyan water shimmer

      final Path path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 20) {
        final double offset = math.sin((x * 0.02) + t + (i * 0.8)) * (3.5 + (i * 0.8));
        path.lineTo(x, y + offset);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterCausticPainter oldDelegate) =>
      oldDelegate.flameFlicker != flameFlicker;
}
