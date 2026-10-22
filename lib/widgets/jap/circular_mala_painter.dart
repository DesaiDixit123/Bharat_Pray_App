import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/jap_customization_models.dart';

/// Renders the 108-bead circular sacred mala with dynamic golden progression,
/// animated active bead halo, dedicated uncounted Guru (Meru) crown bead with tassel,
/// and authentic 3D bead shaders.
class CircularMalaPainter extends CustomPainter {
  final int count;
  final int target;
  final double pulseValue; // 0.0 to 1.0 for active bead pulse
  final MalaBeadStyle style;
  final Color themeAccentColor;
  final bool isCompleted;

  // Reusable paint objects to avoid allocations during 60/120fps animation
  final Paint _threadPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  final Paint _beadFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _beadBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  final Paint _activeGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _tasselPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.8;

  CircularMalaPainter({
    required this.count,
    this.target = 108,
    required this.pulseValue,
    required this.style,
    required this.themeAccentColor,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Leave safe padding for bead size, meru bead, and active bead halos
    final radius = (math.min(size.width, size.height) / 2) - 22.0;
    if (radius <= 10) return;

    // 1. Draw sacred connecting thread (Sutra)
    _threadPaint.color = isCompleted
        ? const Color(0xFFFFD700).withValues(alpha: 0.7)
        : const Color(0xFFC8A882).withValues(alpha: 0.35);
    canvas.drawCircle(center, radius, _threadPaint);

    final int totalBeads = target > 0 ? target : 108;
    final double baseBeadRadius = math.max(2.8, math.min(4.8, radius * 0.032));

    // Calculate angle step (clockwise from top -pi/2 + small offset to center around Meru)
    const double startAngle = -math.pi / 2;
    final double angleStep = (2 * math.pi) / totalBeads;

    // 2. Draw 108 Individual Countable Beads
    for (int i = 0; i < totalBeads; i++) {
      // Offset slightly clockwise so bead 0 starts just past the top Meru bead
      final double angle = startAngle + ((i + 0.5) * angleStep);
      final double bx = center.dx + (radius * math.cos(angle));
      final double by = center.dy + (radius * math.sin(angle));
      final Offset beadCenter = Offset(bx, by);

      final bool isCurrent = (i == count && !isCompleted);
      final bool isDone = (i < count || isCompleted);

      double beadRadius = baseBeadRadius;

      if (isCurrent) {
        // Active bead pulse scale
        final double scale = 1.0 + (0.45 * math.sin(pulseValue * math.pi));
        beadRadius *= scale;

        // Draw radial halo glow behind active bead
        _activeGlowPaint.shader = RadialGradient(
          colors: [
            style.activeColor.withValues(alpha: 0.90),
            style.highlightColor.withValues(alpha: 0.40),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: beadCenter, radius: beadRadius * 3.4));

        canvas.drawCircle(beadCenter, beadRadius * 3.4, _activeGlowPaint);
      }

      // Draw bead body
      if (isDone) {
        // 3D Polished Bead Shader (Radial specular light on top-left)
        _beadFillPaint.shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.85,
          colors: [
            Colors.white,
            style.highlightColor,
            style.activeColor,
            _darkenColor(style.activeColor, 0.3),
          ],
          stops: const [0.0, 0.25, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: beadCenter, radius: beadRadius));

        canvas.drawCircle(beadCenter, beadRadius, _beadFillPaint);

        // Subtle specular rim
        _beadBorderPaint.color = Colors.white.withValues(alpha: 0.6);
        canvas.drawCircle(beadCenter, beadRadius, _beadBorderPaint);
      } else {
        // Incomplete / Upcoming bead (Muted organic texture)
        _beadFillPaint.shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            const Color(0xFF5A4A3D).withValues(alpha: 0.8),
            const Color(0xFF2C221A).withValues(alpha: 0.85),
            const Color(0xFF16100B).withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: beadCenter, radius: beadRadius));

        canvas.drawCircle(beadCenter, beadRadius, _beadFillPaint);

        _beadBorderPaint.color = const Color(0xFF8C7355).withValues(alpha: 0.4);
        canvas.drawCircle(beadCenter, beadRadius, _beadBorderPaint);
      }
    }

    // 3. Draw Uncounted Apex Guru / Meru Bead & Devotional Saffron Tassel at top
    final double meruRadius = baseBeadRadius * 1.5;
    final Offset meruCenter = Offset(center.dx, center.dy - radius);

    // Meru bead halo
    final meruGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: isCompleted ? 0.9 : 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: meruCenter, radius: meruRadius * 2.2));
    canvas.drawCircle(meruCenter, meruRadius * 2.2, meruGlow);

    // Meru bead sphere
    final meruPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: const [
          Colors.white,
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFE65100),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: meruCenter, radius: meruRadius));
    canvas.drawCircle(meruCenter, meruRadius, meruPaint);

    // Golden Bindu Cap on top of Meru
    final Paint binduCapPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(meruCenter.dx, meruCenter.dy - meruRadius - 1.5), meruRadius * 0.4, binduCapPaint);

    // Traditional Saffron / Red Tassel extending upward from Guru Bead
    _tasselPaint.color = const Color(0xFFFF7700).withValues(alpha: 0.85);
    final double tasselTopY = meruCenter.dy - meruRadius - 9.0;
    canvas.drawLine(
      Offset(meruCenter.dx, meruCenter.dy - meruRadius - 2.5),
      Offset(meruCenter.dx, tasselTopY),
      _tasselPaint,
    );
    // Tassel strands
    _tasselPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.7);
    canvas.drawLine(
      Offset(meruCenter.dx, tasselTopY),
      Offset(meruCenter.dx - 3.5, tasselTopY - 4.0),
      _tasselPaint,
    );
    canvas.drawLine(
      Offset(meruCenter.dx, tasselTopY),
      Offset(meruCenter.dx + 3.5, tasselTopY - 4.0),
      _tasselPaint,
    );
  }

  Color _darkenColor(Color c, double factor) {
    return Color.fromARGB(
      (c.a * 255.0).round().clamp(0, 255),
      ((c.r * 255.0) * (1.0 - factor)).round().clamp(0, 255),
      ((c.g * 255.0) * (1.0 - factor)).round().clamp(0, 255),
      ((c.b * 255.0) * (1.0 - factor)).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(covariant CircularMalaPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.style != style ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.themeAccentColor != themeAccentColor;
  }
}
