import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../jap/custom_jap_darshan_video.dart';

/// Full-screen divine Darshan experience shown on 108 Jap completion in Dhup Chanting mode.
/// Features full Lord Shri Ram image, golden radiant aura, falling sacred rose petals,
/// and peaceful celebratory completion banner.
class DhupDarshanClimaxView extends StatefulWidget {
  final VoidCallback onNextMala;
  final VoidCallback onExit;
  final String title;
  final int target;
  final String videoUrl;
  final bool isSoundEnabled;

  const DhupDarshanClimaxView({
    super.key,
    required this.onNextMala,
    required this.onExit,
    this.title = '॥ जय श्री राम ॥',
    this.target = 108,
    this.videoUrl = '',
    this.isSoundEnabled = true,
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
        // 0. Generated Live Darshan Video (custom Japs)
        if (widget.videoUrl.isNotEmpty)
          CustomJapDarshanVideo(
            url: widget.videoUrl,
            isSoundEnabled: widget.isSoundEnabled,
          ),

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
