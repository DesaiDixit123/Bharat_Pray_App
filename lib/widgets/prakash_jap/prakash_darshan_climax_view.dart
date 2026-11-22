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

        // 2. Subtle Top-Left Back Button (Pure Live Darshan, matching Divine Reveal)
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onExit,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFFFFE082),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
