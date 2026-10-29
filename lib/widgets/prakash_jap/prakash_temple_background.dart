import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Background widget for Prakash Mandal (Divine Light Reveal).
/// Renders the dark cosmic temple sanctum at night with hanging brass bells,
/// celestial vertical light shaft, and bottom reflective lotus pool.
class PrakashTempleBackground extends StatelessWidget {
  final double ambientTime; // 0.0 to 1.0 continuous animation
  final double lightBeamIntensity; // 0.0 to 1.0 based on tap / Jap count

  const PrakashTempleBackground({
    super.key,
    required this.ambientTime,
    this.lightBeamIntensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final double flicker = math.sin(ambientTime * 2 * math.pi) * 0.08;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Deep Sanctum Base Color
        Container(color: const Color(0xFF0A0705)),

        // 2. High-Resolution Temple Sanctum Background
        Image.asset(
          'assets/images/prakash_mandal_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Devotional procedural fallback if asset not ready
            return Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF2A1B0E),
                    Color(0xFF140D07),
                    Color(0xFF050302),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            );
          },
        ),

        // 3. Central Heavenly Light Beam Column Shimmer
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _LightShaftOverlayPainter(
              ambientTime: ambientTime,
              beamIntensity: (lightBeamIntensity + flicker).clamp(0.1, 1.0),
            ),
          ),
        ),

        // 4. Subtle Vignette around edges to frame the divine light
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.45, 0.78, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LightShaftOverlayPainter extends CustomPainter {
  final double ambientTime;
  final double beamIntensity;

  _LightShaftOverlayPainter({
    required this.ambientTime,
    required this.beamIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double centerX = size.width * 0.50;
    final double topWidth = size.width * 0.32;
    final double bottomWidth = size.width * 0.75;
    final double midY = size.height * 0.60;

    // Heavenly light shaft polygon from top ceiling downward
    final Path shaftPath = Path()
      ..moveTo(centerX - (topWidth / 2), 0)
      ..lineTo(centerX + (topWidth / 2), 0)
      ..lineTo(centerX + (bottomWidth / 2), midY)
      ..lineTo(centerX - (bottomWidth / 2), midY)
      ..close();

    final double pulse = 0.85 + (0.15 * math.sin(ambientTime * 2 * math.pi));
    final double alpha = (0.12 * beamIntensity * pulse).clamp(0.02, 0.30);

    final Paint shaftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFF9C4).withValues(alpha: alpha * 1.5),
          const Color(0xFFFFD54F).withValues(alpha: alpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, midY));

    canvas.drawPath(shaftPath, shaftPaint);
  }

  @override
  bool shouldRepaint(covariant _LightShaftOverlayPainter oldDelegate) {
    return oldDelegate.ambientTime != ambientTime ||
        oldDelegate.beamIntensity != beamIntensity;
  }
}
