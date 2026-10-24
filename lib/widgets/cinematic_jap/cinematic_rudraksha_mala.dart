import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the authentic sacred 108-cycle Rudraksha Mala encircling the orange play button.
///
/// Features:
/// - 27 distinct, beautifully shaded 3D Rudraksha beads (sacred Sumirani cycle: 4 rounds = 108 Jap).
/// - Authentic 5-mukhi wood-grain cleft textures and golden spacer knots (Kantha beads) between beads.
/// - Dynamic rotation: On each chant tap, the entire mala smoothly and visibly turns by 1 full bead (13.3° / ~11.6px).
/// - Rotating Guru (Meru) bead & sacred golden tassel: The Meru bead and tassel rotate with the mala around the button with realistic inertia sway!
/// - Active bead at the top apex is highlighted with a radiant golden halo from which the single "राम" text emerges.
/// - Ambient meditative micro-shimmer keeps the mala spiritually alive even between chants.
class CinematicRudrakshaMala extends StatefulWidget {
  final int count;
  final int target;
  final double pulseValue; // 0.0 to 1.0
  final bool isCompleted;
  final String subtitle;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onCenterCalculated;
  final int chantTrigger; // Incremented on each chant tap to trigger smooth bead advance
  final bool showCounter; // Whether to render the counter text above the mala
  final Widget? child; // Center widget (the orange play button)
  final int visibleBeads; // Default 27 (Sumirani 108 cycle: 27 x 4 = 108)

  const CinematicRudrakshaMala({
    super.key,
    required this.count,
    this.target = 108,
    required this.pulseValue,
    required this.isCompleted,
    this.subtitle = 'Shri Ram Jai Ram Jai Jai Ram',
    this.onTap,
    this.onCenterCalculated,
    this.chantTrigger = 0,
    this.showCounter = true,
    this.child,
    this.visibleBeads = 27,
  });

  @override
  State<CinematicRudrakshaMala> createState() => _CinematicRudrakshaMalaState();
}

class _CinematicRudrakshaMalaState extends State<CinematicRudrakshaMala>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  double _currentBeadStep = 0.0;
  double _targetBeadStep = 0.0;

  // Radius of the mala ring encircling the 64x64 play button
  static const double _malaRadius = 50.0;
  static const double _boxSize = 132.0;

  @override
  void initState() {
    super.initState();

    // Meditative, smooth 1-bead rotation duration (~1100ms) with gentle deceleration
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _currentBeadStep = widget.count.toDouble();
    _targetBeadStep = _currentBeadStep;
    _rotationAnimation = AlwaysStoppedAnimation(_currentBeadStep);

    _reportCenter();
  }

  @override
  void didUpdateWidget(CinematicRudrakshaMala oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count == 0 && oldWidget.count != 0) {
      // Session reset: return bead rotation instantly to 0.0
      _rotationController.stop();
      _currentBeadStep = 0.0;
      _targetBeadStep = 0.0;
      _rotationAnimation = const AlwaysStoppedAnimation(0.0);
      setState(() {});
      return;
    }

    // Advance exactly 1 bead forward when chantTrigger increments or count increases
    if (widget.chantTrigger != oldWidget.chantTrigger ||
        (widget.count > oldWidget.count && widget.count != 0)) {
      _advanceOneBeadForward();
    }
  }

  /// Smoothly advances exactly ONE highlighted bead around the play button
  void _advanceOneBeadForward() {
    _rotationController.stop();
    _currentBeadStep = _rotationAnimation.value;
    _targetBeadStep = _currentBeadStep + 1.0;

    _rotationAnimation = Tween<double>(
      begin: _currentBeadStep,
      end: _targetBeadStep,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic,
    ));

    _rotationController.forward(from: 0.0).then((_) {
      if (mounted) {
        _currentBeadStep = _targetBeadStep;
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _reportCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ro = context.findRenderObject() as RenderBox?;
      if (ro != null && ro.hasSize) {
        // The single "राम" text emerges from the highlighted active bead at the top apex of the ring
        final double topApexY = (ro.size.height / 2) - _malaRadius;
        final crestLocal = Offset(ro.size.width / 2, topApexY);
        final crestGlobal = ro.localToGlobal(crestLocal);
        widget.onCenterCalculated?.call(crestGlobal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _reportCenter();

    final malaRing = AnimatedBuilder(
      animation: _rotationController,
      builder: (context, _) {
        final double currentStep = _rotationAnimation.value;
        // Rotation velocity for dynamic tassel pendulum sway
        final double animVal = _rotationController.value;
        final double swayAngle = _rotationController.isAnimating
            ? (math.sin(animVal * math.pi) * 0.18) // ~10 degree physical sway
            : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            width: _boxSize,
            height: _boxSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. CustomPainter for authentic 3D Rudraksha beads encircling the center play button
                CustomPaint(
                  size: const Size(_boxSize, _boxSize),
                  painter: CircularMalaPainter(
                    count: widget.count,
                    target: widget.target,
                    pulseValue: widget.pulseValue,
                    isCompleted: widget.isCompleted,
                    beadStepProgress: currentStep,
                    radius: _malaRadius,
                    visibleBeads: widget.visibleBeads,
                    tasselSway: swayAngle,
                  ),
                ),

                // 2. Center Child (Orange Play Button) if provided
                if (widget.child != null)
                  Center(child: widget.child!),
              ],
            ),
          ),
        );
      },
    );

    if (!widget.showCounter) {
      return malaRing;
    }

    // Default standalone view with devotional counter (for widget tests & preview)
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Glassmorphic high-contrast devotional counter plaque
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.40),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 16.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sacred glowing "ॐ"
              Text(
                'ॐ',
                style: GoogleFonts.notoSerifDevanagari(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  shadows: const [
                    Shadow(color: Color(0xFFFF7700), blurRadius: 16.0),
                    Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
                  ],
                ),
              ),
              const SizedBox(height: 1),

              // Numerical count and target
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${widget.count}',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: const [
                        Shadow(color: Color(0xFFFF9900), blurRadius: 12.0),
                        Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${widget.target}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD54F),
                      letterSpacing: 0.5,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 4.0)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Devotional chant subtitle
              if (widget.subtitle.isNotEmpty)
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFFE082),
                    letterSpacing: 0.3,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4.0, offset: Offset(0, 1))],
                  ),
                ),
            ],
          ),
        ),

        // Mala Ring
        malaRing,
      ],
    );
  }
}

/// CustomPainter rendering 27 authentic 3D Rudraksha beads (4 rounds = 108 Jap)
/// in a circular ring encircling the play button, complete with rotating Meru bead and swaying tassel.
class CircularMalaPainter extends CustomPainter {
  final int count;
  final int target;
  final double pulseValue;
  final bool isCompleted;
  final double beadStepProgress;
  final double radius; // e.g. 50.0 px
  final int visibleBeads; // 27 beads
  final double tasselSway; // Pendulum sway angle in radians

  final Paint _threadPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  final Paint _beadFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _activeGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _cleftPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7
    ..strokeCap = StrokeCap.round;

  CircularMalaPainter({
    required this.count,
    required this.target,
    required this.pulseValue,
    required this.isCompleted,
    required this.beadStepProgress,
    required this.radius,
    this.visibleBeads = 27,
    this.tasselSway = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final int totalBeads = visibleBeads > 0 ? visibleBeads : 27;
    const double baseBeadRadius = 3.8;

    // 0. Dark Contrast Halo Backing Plate (Ensures 3D beads & golden thread pop vividly over bright revealed imagery)
    final backingPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 1.34,
        [
          const Color(0xFF0C0806).withValues(alpha: 0.88),
          const Color(0xFF140E0A).withValues(alpha: 0.70),
          Colors.transparent,
        ],
        [0.0, 0.72, 1.0],
      );
    canvas.drawCircle(center, radius * 1.34, backingPaint);

    // Subtle golden outer rim ring defining the sacred mala perimeter
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.32);
    canvas.drawCircle(center, radius + baseBeadRadius + 2.5, rimPaint);

    // 1. Sacred Connecting Sutra Thread circling around the play button
    _threadPaint.color = isCompleted
        ? const Color(0xFFFFD700).withValues(alpha: 0.85)
        : const Color(0xFF8D4004).withValues(alpha: 0.65);
    canvas.drawCircle(center, radius, _threadPaint);

    const double startAngle = -math.pi / 2; // Top apex, directly above play button
    final double angleStep = (2 * math.pi) / totalBeads;

    // Current position in the 27-bead cycle (0..26)
    final int currentBeadInCycle = totalBeads > 0 ? (count % totalBeads) : 0;

    // 2. Draw 27 Sacred 3D Rudraksha Beads with Golden Spacer Knots
    for (int i = 0; i < totalBeads; i++) {
      // Rotation: active bead advances clockwise from top apex downwards as beadStepProgress increments
      final double angle = startAngle + ((beadStepProgress - i) * angleStep);
      final double bx = center.dx + (radius * math.cos(angle));
      final double by = center.dy + (radius * math.sin(angle));
      final beadPos = Offset(bx, by);

      // ── A. Golden Spacer Bead (Kantha knot) between beads ──
      final double spacerAngle = angle - (angleStep / 2.0);
      final spacerPos = Offset(
        center.dx + (radius * math.cos(spacerAngle)),
        center.dy + (radius * math.sin(spacerAngle)),
      );
      final spacerPaint = Paint()
        ..color = isCompleted
            ? const Color(0xFFFFD700).withValues(alpha: 0.90)
            : const Color(0xFFFFB300).withValues(alpha: 0.70)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(spacerPos, 1.1, spacerPaint);

      // ── B. Determine bead status ──
      // Check if this bead is at or near the top apex (-pi/2)
      final double normalizedAngle = (angle - startAngle) % (2 * math.pi);
      final double distToApex = normalizedAngle > math.pi
          ? (2 * math.pi - normalizedAngle).abs()
          : normalizedAngle.abs();
      final bool isCurrentApex = (distToApex < (angleStep * 0.40)) && !isCompleted;
      final bool isDone = (i < currentBeadInCycle || count >= target || isCompleted);

      double beadRadius = baseBeadRadius;

      // ── C. Active Top Bead Radiant Golden Aura ──
      if (isCurrentApex) {
        final double scale = 1.0 + (0.35 * math.sin(pulseValue * math.pi));
        beadRadius *= scale;

        // Multi-tier golden halo radiating outward
        _activeGlowPaint.shader = ui.Gradient.radial(
          beadPos,
          beadRadius * 3.8,
          [
            const Color(0xFFFFD700).withValues(alpha: 0.95),
            const Color(0xFFFF9900).withValues(alpha: 0.50),
            Colors.transparent,
          ],
          [0.0, 0.40, 1.0],
        );
        canvas.drawCircle(beadPos, beadRadius * 3.8, _activeGlowPaint);
      }

      // ── D. Authentic 3D Rudraksha Bead Shading ──
      if (isCurrentApex) {
        // Glowing active bead shader with golden core
        _beadFillPaint.shader = ui.Gradient.radial(
          beadPos + Offset(-beadRadius * 0.35, -beadRadius * 0.35),
          beadRadius * 1.4,
          [
            const Color(0xFFFFFDE7),
            const Color(0xFFFFB300),
            const Color(0xFFE65100),
          ],
          [0.0, 0.45, 1.0],
        );
      } else if (isDone) {
        // Completed bead: warm polished Rudraksha with golden highlight
        _beadFillPaint.shader = ui.Gradient.radial(
          beadPos + Offset(-beadRadius * 0.30, -beadRadius * 0.30),
          beadRadius * 1.3,
          [
            const Color(0xFFFFD54F),
            const Color(0xFFC67D24),
            const Color(0xFF5D2800),
          ],
          [0.0, 0.38, 1.0],
        );
      } else {
        // Uncounted Rudraksha: authentic organic 5-mukhi wood texture
        _beadFillPaint.shader = ui.Gradient.radial(
          beadPos + Offset(-beadRadius * 0.30, -beadRadius * 0.30),
          beadRadius * 1.3,
          [
            const Color(0xFFD7995A),
            const Color(0xFF8D4004),
            const Color(0xFF381200),
          ],
          [0.0, 0.35, 1.0],
        );
      }

      // Draw 3D bead body
      canvas.drawCircle(beadPos, beadRadius, _beadFillPaint);

      // ── E. Delicate 5-Mukhi Cleft Grooves ──
      _cleftPaint.color = isCurrentApex
          ? const Color(0xFFBF360C).withValues(alpha: 0.80)
          : const Color(0xFF260D00).withValues(alpha: 0.55);
      // Subtle vertical organic groove curves
      canvas.drawLine(
        beadPos + Offset(0, -beadRadius * 0.70),
        beadPos + Offset(0, beadRadius * 0.70),
        _cleftPaint,
      );
      canvas.drawLine(
        beadPos + Offset(-beadRadius * 0.45, -beadRadius * 0.45),
        beadPos + Offset(-beadRadius * 0.25, beadRadius * 0.55),
        _cleftPaint,
      );
      canvas.drawLine(
        beadPos + Offset(beadRadius * 0.45, -beadRadius * 0.45),
        beadPos + Offset(beadRadius * 0.25, beadRadius * 0.55),
        _cleftPaint,
      );

      // Subtle warm specular highlight dot
      if (isDone || isCurrentApex) {
        final dotPaint = Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.75);
        canvas.drawCircle(
          beadPos + Offset(-beadRadius * 0.30, -beadRadius * 0.30),
          beadRadius * 0.25,
          dotPaint,
        );
      }
    }

    // ── 3. Dedicated Rotating Guru (Meru) Crown Bead & Swaying Golden Tassel ──
    // Meru bead starts at the bottom apex (pi/2) and visibly rotates WITH the mala around the button!
    const double meruStartAngle = math.pi / 2; // Bottom apex
    final double meruAngle = meruStartAngle + (beadStepProgress * angleStep);
    final meruPos = Offset(
      center.dx + (radius * math.cos(meruAngle)),
      center.dy + (radius * math.sin(meruAngle)),
    );
    const double meruRadius = baseBeadRadius * 1.55; // Larger sacred crown bead

    // Meru bead radiant aura
    final meruHaloPaint = Paint()
      ..shader = ui.Gradient.radial(
        meruPos,
        meruRadius * 2.4,
        [
          const Color(0xFFFFD700).withValues(alpha: 0.75),
          const Color(0xFFFF9900).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(meruPos, meruRadius * 2.4, meruHaloPaint);

    // Meru bead 3D sacred sandalwood body
    final meruPaint = Paint()
      ..shader = ui.Gradient.radial(
        meruPos + Offset(-meruRadius * 0.3, -meruRadius * 0.3),
        meruRadius * 1.3,
        [
          const Color(0xFFFFECB3),
          const Color(0xFFFFA000),
          const Color(0xFF5D4037),
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(meruPos, meruRadius, meruPaint);

    // Golden Kalas / Crown band on top of Meru bead
    final capDir = Offset(math.cos(meruAngle), math.sin(meruAngle));
    final capPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(meruPos - (capDir * (meruRadius * 0.7)), meruRadius * 0.45, capPaint);

    // ── Sacred Golden Tassel hanging outward with rotational inertia sway ──
    // Tassel endpoint naturally influenced by gravity (downwards) and rotational sway
    final double effectiveSway = tasselSway;
    final double tasselAngle = meruAngle + math.pi + effectiveSway;
    final tasselBase = meruPos + (capDir * meruRadius);

    final tasselPaint = Paint()
      ..color = const Color(0xFFFF9900)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final tasselGoldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Tassel band ring
    canvas.drawCircle(tasselBase, 1.8, tasselGoldPaint);

    // 3 fine shimmering golden silk threads fanning out slightly
    const double tasselLength = 10.0;
    final tOffsetCenter = Offset(math.cos(tasselAngle), math.sin(tasselAngle)) * tasselLength;
    final tOffsetLeft = Offset(math.cos(tasselAngle - 0.25), math.sin(tasselAngle - 0.25)) * (tasselLength - 1.0);
    final tOffsetRight = Offset(math.cos(tasselAngle + 0.25), math.sin(tasselAngle + 0.25)) * (tasselLength - 1.0);

    canvas.drawLine(tasselBase, tasselBase + tOffsetCenter, tasselGoldPaint);
    canvas.drawLine(tasselBase, tasselBase + tOffsetLeft, tasselPaint);
    canvas.drawLine(tasselBase, tasselBase + tOffsetRight, tasselPaint);
  }

  @override
  bool shouldRepaint(covariant CircularMalaPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.target != target ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.beadStepProgress != beadStepProgress ||
        oldDelegate.radius != radius ||
        oldDelegate.visibleBeads != visibleBeads ||
        oldDelegate.tasselSway != tasselSway;
  }
}
