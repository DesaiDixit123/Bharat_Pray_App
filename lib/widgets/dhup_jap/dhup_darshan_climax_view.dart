import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen divine Darshan experience shown on 108 Jap completion in Dhup Chanting mode.
/// Features full Lord Shri Ram image, golden radiant aura, falling sacred rose petals,
/// and peaceful celebratory completion banner.
class DhupDarshanClimaxView extends StatefulWidget {
  final VoidCallback onNextMala;
  final VoidCallback onExit;

  const DhupDarshanClimaxView({
    super.key,
    required this.onNextMala,
    required this.onExit,
  });

  @override
  State<DhupDarshanClimaxView> createState() => _DhupDarshanClimaxViewState();
}

class _DhupDarshanClimaxViewState extends State<DhupDarshanClimaxView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _petalController;
  final math.Random _random = math.Random();
  final List<_FallingPetal> _petals = [];

  @override
  void initState() {
    super.initState();
    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Initialize 24 falling rose petals
    for (int i = 0; i < 24; i++) {
      _petals.add(_FallingPetal(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.12 + (_random.nextDouble() * 0.18),
        size: 16.0 + (_random.nextDouble() * 18.0),
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2.0,
        swayAmp: 0.04 + (_random.nextDouble() * 0.06),
        swayFreq: 1.0 + (_random.nextDouble() * 2.0),
      ));
    }
  }

  @override
  void dispose() {
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Falling Rose Petals Layer
        AnimatedBuilder(
          animation: _petalController,
          builder: (context, _) {
            final double dt = 0.016;
            for (final p in _petals) {
              p.y += p.speed * dt;
              if (p.y > 1.1) {
                p.y = -0.1;
                p.x = _random.nextDouble();
              }
              p.rotation += p.rotationSpeed * dt;
            }

            return CustomPaint(
              size: Size.infinite,
              painter: _PetalPainter(petals: _petals),
            );
          },
        ),

        // 2. Divine Completion Banner & Actions (Floating over the darshan)
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top celebratory title
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.70),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9900).withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '॥ जय श्री राम ॥',
                        style: GoogleFonts.notoSerifDevanagari(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFE082),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Actions: [Complete & Exit] and [Chant Next Mala]
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Row(
                  children: [
                    // Exit Darshan
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onExit,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFFC8A882).withValues(alpha: 0.60),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Done',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Next 108 Mala
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: widget.onNextMala,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9900), Color(0xFFFF5500)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7700).withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Next 108 Mala',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FallingPetal {
  double x;
  double y;
  final double speed;
  final double size;
  double rotation;
  final double rotationSpeed;
  final double swayAmp;
  final double swayFreq;

  _FallingPetal({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmp,
    required this.swayFreq,
  });
}

class _PetalPainter extends CustomPainter {
  final List<_FallingPetal> petals;
  final Paint _petalPaint = Paint()..style = PaintingStyle.fill;

  _PetalPainter({required this.petals});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final p in petals) {
      final currentX = (p.x + (math.sin(p.y * p.swayFreq * 2 * math.pi) * p.swayAmp)) * size.width;
      final currentY = p.y * size.height;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation);

      // Organic curved rose petal shape
      final path = Path()
        ..moveTo(0, -p.size * 0.5)
        ..cubicTo(p.size * 0.45, -p.size * 0.45, p.size * 0.45, p.size * 0.45, 0, p.size * 0.5)
        ..cubicTo(-p.size * 0.45, p.size * 0.45, -p.size * 0.45, -p.size * 0.45, 0, -p.size * 0.5);

      _petalPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE53935), Color(0xFFC62828), Color(0xFF880E4F)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size));

      canvas.drawPath(path, _petalPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) => true;
}
