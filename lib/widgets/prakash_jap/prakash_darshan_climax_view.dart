import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Climax View overlay displayed upon reaching 108 Jap in Prakash Mandal.
/// Displays celebratory banner "જય શ્રી રામ" with golden aura and options.
class PrakashDarshanClimaxView extends StatefulWidget {
  final VoidCallback onNextMala;
  final VoidCallback onExit;

  const PrakashDarshanClimaxView({
    super.key,
    required this.onNextMala,
    required this.onExit,
  });

  @override
  State<PrakashDarshanClimaxView> createState() =>
      _PrakashDarshanClimaxViewState();
}

class _PrakashDarshanClimaxViewState extends State<PrakashDarshanClimaxView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.20, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Soft Warm Vignette Overlay
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.35, 0.70, 1.0],
              ),
            ),
          ),
        ),

        // 2. Celebratory Content (Top Banner & Bottom Actions)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Radiant Completion Badge "જય શ્રી રામ"
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E130B).withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9900).withValues(alpha: 0.60),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFF9C4).withValues(alpha: 0.35),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'જય શ્રી રામ',
                            style: GoogleFonts.notoSerifDevanagari(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFF9C4),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFFF7700),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '૧૦૮ જાપ પૂર્ણ — દિવ્ય પ્રકાશ દર્શન',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFD54F),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 7),

                // Bottom Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Start Next Mala" Button
                      ElevatedButton.icon(
                        onPressed: widget.onNextMala,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9900),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFFFF9900),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: Text(
                          'Next Mala',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // "Complete / Exit" Button
                      OutlinedButton(
                        onPressed: widget.onExit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFFFD54F),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Complete',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
