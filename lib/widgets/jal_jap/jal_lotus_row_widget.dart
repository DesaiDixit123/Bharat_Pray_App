import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the sacred floating pink lotuses and burning brass diyas on the water surface.
/// Lotus flowers gently bob and sway with the water wave motion.
class JalLotusRowWidget extends StatelessWidget {
  final double waveTime; // 0.0 to 1.0 continuous animation

  const JalLotusRowWidget({
    super.key,
    required this.waveTime,
  });

  @override
  Widget build(BuildContext context) {
    final double t = waveTime * 2 * math.pi;
    final double leftBob = math.sin(t) * 4.5;
    final double rightBob = math.sin(t + 1.2) * 4.5;
    final double leftTilt = math.sin(t * 0.8) * 0.05;
    final double rightTilt = math.cos(t * 0.8) * 0.05;

    return IgnorePointer(
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            // ── Left Floating Lotus & Diya Cluster ─────────────────────
            Positioned(
              left: 14,
              bottom: 12 + leftBob,
              child: Transform.rotate(
                angle: leftTilt,
                child: _buildLotusCluster(isLeft: true),
              ),
            ),

            // ── Right Floating Lotus & Diya Cluster ────────────────────
            Positioned(
              right: 14,
              bottom: 16 + rightBob,
              child: Transform.rotate(
                angle: rightTilt,
                child: _buildLotusCluster(isLeft: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotusCluster({required bool isLeft}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isLeft) _buildFloatingDiya(),
        // Sacred Lotus
        Stack(
          alignment: Alignment.center,
          children: [
            // Golden watery reflection halo under lotus
            Container(
              width: 58,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF80AB).withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/devotional/sacred_lotus.png',
              width: 54,
              height: 54,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.spa_rounded,
                color: Color(0xFFFF80AB),
                size: 38,
              ),
            ),
          ],
        ),
        if (isLeft) _buildFloatingDiya(),
      ],
    );
  }

  Widget _buildFloatingDiya() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Golden reflection under water
          Container(
            width: 32,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9900).withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/devotional/diya_lamp.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF9900),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
