import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cinematic_rudraksha_mala.dart';

/// Minimal devotional controls near the bottom of the screen:
/// [Reset] (left), [Glowing Orange Play Button encircled by Circular Rudraksha Mala] (center), [Sound] (right).
class CinematicChantingControls extends StatelessWidget {
  final VoidCallback onChantTap;
  final VoidCallback onResetTap;
  final VoidCallback onSoundToggle;
  final VoidCallback onPauseToggle;
  final bool isSoundEnabled;
  final bool isPaused;
  final bool isChantingActive;
  final bool canChant;
  final int count;
  final int target;
  final double pulseValue;
  final int chantTrigger;
  final ValueChanged<Offset>? onMalaCenterCalculated;

  const CinematicChantingControls({
    super.key,
    required this.onChantTap,
    required this.onResetTap,
    required this.onSoundToggle,
    required this.onPauseToggle,
    required this.isSoundEnabled,
    this.isPaused = false,
    this.isChantingActive = false,
    this.canChant = true,
    this.count = 0,
    this.target = 108,
    this.pulseValue = 0.5,
    this.chantTrigger = 0,
    this.onMalaCenterCalculated,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── LEFT: Reset Button ─────────────────────────────────────────
          _buildActionButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onTap: () {
              HapticFeedback.mediumImpact();
              onResetTap();
            },
          ),

          // ── CENTER: Glowing Orange Play Button with Circular Mala encircling it ──
          CinematicRudrakshaMala(
            count: count,
            target: target,
            pulseValue: pulseValue,
            isCompleted: count >= target,
            chantTrigger: chantTrigger,
            showCounter: false,
            onTap: () {
              if (canChant) {
                HapticFeedback.lightImpact();
                onChantTap();
              }
            },
            onCenterCalculated: onMalaCenterCalculated,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.25, -0.3),
                  radius: 0.9,
                  colors: [
                    Color(0xFFFFB300),
                    Color(0xFFFF7700),
                    Color(0xFFE65100),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7700).withValues(alpha: isChantingActive ? 0.85 : 0.45),
                    blurRadius: isChantingActive ? 22.0 : 10.0,
                    spreadRadius: isChantingActive ? 3.5 : 1.0,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: isChantingActive ? 0.60 : 0.20),
                    blurRadius: isChantingActive ? 12.0 : 6.0,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFFFF3E0).withValues(alpha: 0.85),
                  width: 1.8,
                ),
              ),
              child: Center(
                child: isPaused
                    ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36)
                    : isChantingActive
                        ? const Icon(Icons.pause_rounded, color: Colors.white, size: 32)
                        : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            ),
          ),

          // ── RIGHT: Sound Toggle Button ────────────────────────────────
          _buildActionButton(
            icon: isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: isSoundEnabled ? 'Sound' : 'Mute',
            isActive: isSoundEnabled,
            onTap: () {
              HapticFeedback.selectionClick();
              onSoundToggle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.75),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFFFD54F).withValues(alpha: 0.50),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFFFD54F) : Colors.white,
                size: 21,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFFFFD54F) : Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
