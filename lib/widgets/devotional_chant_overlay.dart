import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The 5 Photorealistic Devotional Animation Modes
enum DevotionalAnimationMode {
  dhoopSmoke,        // 1. Full-screen Billowing Dhoop Smoke & Real Brass Burner
  ramNaamVandana,    // 2. Pure Crisp Golden Ram Naam & Floating Sacred Mantras
  pushpanjaliPetals, // 3. Upright Blooming Lotus & Fresh 3D Tumbling Petal Shower
  radhaMorPankh108,  // 4. Gliding Mor Pankh Pointing to Sacred Name in Simple Words
  mahaAartiBells,    // 5. Perfectly Straight & Level Aarti Thali with Radiant Glow & Bells
}

extension DevotionalAnimationModeDetails on DevotionalAnimationMode {
  String get title {
    switch (this) {
      case DevotionalAnimationMode.dhoopSmoke:
        return 'ધૂપ & અગરબત્તી (Dhoop Smoke)';
      case DevotionalAnimationMode.ramNaamVandana:
        return 'રામ નામ વંદના (Ram Ram)';
      case DevotionalAnimationMode.pushpanjaliPetals:
        return 'દિવ્ય પુષ્પાંજલિ (Flower Petals)';
      case DevotionalAnimationMode.radhaMorPankh108:
        return 'મોરપિચ્છ & ૧૦૮ નામ (Mor Pankh)';
      case DevotionalAnimationMode.mahaAartiBells:
        return 'મંદિર મહા આરતી (Temple Aarti)';
    }
  }

  String get subtitle {
    switch (this) {
      case DevotionalAnimationMode.dhoopSmoke:
        return 'અસલ પિત્તળની ધૂપદાની અને આખી સ્ક્રીનમાં ફેલાતો સુગંધિત ધૂપનો ધુમાડો';
      case DevotionalAnimationMode.ramNaamVandana:
        return 'દિવ્ય સોનેરી શ્રી રામ અને આખી સ્ક્રીનમાં લહેરાતા પવિત્ર નામો';
      case DevotionalAnimationMode.pushpanjaliPetals:
        return 'સીધું ખીલતું પવિત્ર કમળ અને વાસ્તવિક પવન સાથે વરસતી તાજી પાંદડીઓ';
      case DevotionalAnimationMode.radhaMorPankh108:
        return 'મોરપિચ્છના સ્પર્શથી પ્રગટ થતાં રાધા રાણીના ૧૦૮ દિવ્ય નામો';
      case DevotionalAnimationMode.mahaAartiBells:
        return 'સોનેરી તેજ સાથે સીધી આરતીની થાળીની પરિક્રમા અને ઘંટનાદ';
    }
  }

  IconData get icon {
    switch (this) {
      case DevotionalAnimationMode.dhoopSmoke:
        return Icons.waves_rounded;
      case DevotionalAnimationMode.ramNaamVandana:
        return Icons.auto_stories_rounded;
      case DevotionalAnimationMode.pushpanjaliPetals:
        return Icons.spa_rounded;
      case DevotionalAnimationMode.radhaMorPankh108:
        return Icons.flutter_dash_rounded;
      case DevotionalAnimationMode.mahaAartiBells:
        return Icons.notifications_active_rounded;
    }
  }
}

/// 108 Authentic Sacred Names of Shri Radha Rani
const List<String> kRadha108Names = [
  "श्री राधा", "रासेश्वरी", "वृन्दावनेश्वरी", "किशोरी जी", "लाडली जी", "सर्वेश्वरी",
  "कमलमुखी", "प्रेममयी", "करुणामयी", "गोपीका", "हरिप्रिया", "कृष्णप्रिया",
  "महालक्ष्मी", "दिव्यरूपा", "चन्द्रमुखी", "आनंददायिनी", "गोविन्दानन्दिनी", "नित्यकिशोरी",
  "रासप्रिया", "वृन्दावनविहारिणी", "सुन्दरी", "परमा", "ईश्वरी", "सुमुखी",
  "कालिन्दीतटचारिणी", "मदनमोहिनी", "गोपवधू", "कान्ता", "सत्यरूपा", "सुकोमला",
  "रसमयी", "मधुमती", "चम्पकवर्णा", "पद्मा", "विमला", "अनुराधा",
  "गान्धर्वा", "ललितासखी", "विशाखासखी", "आनन्दरूपा", "परमेश्वरी", "ब्रजरानी",
  "श्यामप्रिया", "मोहनमनोहारिणी", "मनोहरा", "कमला", "सर्वमंगला", "कात्यायनी",
  "त्रिलोकीजननी", "सौभाग्यवती", "सर्वसुखप्रदा", "गोलोकवासिनी", "मंगला", "जयप्रदा",
  "यमुनातीरविहारिणी", "रासविहारिणी", "प्रेमसरस्वती", "भक्तिप्रदा", "मुक्तिदा", "सर्वमयी",
  "अमृता", "शान्तिप्रदा", "कल्याणमयी", "सर्वमोहिनी", "सुहासिनी", "माधवी",
  "वृन्दारण्यरानी", "राधारानी", "श्यामा", "गोपीजनवल्लभा", "चित्तरंजनी", "मधुरा",
  "कृपामयी", "सर्वकामप्रदा", "नित्यसुन्दरी", "दिव्यभूषणा", "सर्ववन्दिता", "गोपिका",
  "कमलनयनी", "मधुरभाषिणी", "मृगनयनी", "रसराजप्रिया", "आनन्दकन्दा", "सर्वपूजिता",
  "वृन्दावनचन्द्रिका", "प्रेमदायिनी", "रासरंगिणी", "सर्वगुणोपेता", "जगन्मोहिनी",
  "नित्यरूपा", "आनन्ददायिका", "ब्रजेश्वरी", "श्यामसुन्दरप्रिया", "गोपिकावल्लभा", "रतिप्रदा",
  "सर्वसिद्धिदा", "परमानन्दरूपा", "भक्तिमयी", "मंजरी", "लीलामयी", "कोटिचन्द्रप्रभा",
  "श्रीजी", "लाडिली", "कृपानिधि", "वरदा", "सर्वेश्वरी", "राधा"
];

/// Floating Sacred Name Particle for Ram Naam Vandana
class _FloatingName {
  final String text;
  final Offset position;
  final double scale;
  final double opacity;
  final double vx;
  final double vy;

  _FloatingName({
    required this.text,
    required this.position,
    required this.scale,
    required this.opacity,
    required this.vx,
    required this.vy,
  });
}

/// Real-Life Fresh Flower Petal Particle with 3D Tumbling
class _FreshPetal {
  final double startX;
  final double fallSpeed;
  final double swaySpeed;
  final double swayWidth;
  final double rotSpeedZ;
  final double rotSpeedY;
  final double size;
  final double initialPhase;
  final Color primaryColor;
  final Color secondaryColor;

  _FreshPetal({
    required this.startX,
    required this.fallSpeed,
    required this.swaySpeed,
    required this.swayWidth,
    required this.rotSpeedZ,
    required this.rotSpeedY,
    required this.size,
    required this.initialPhase,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

/// Wide-spreading Volumetric Smoke Cloud Particle
class _SpreadingSmokeCloud {
  final double initialSpreadX;
  final double speedY;
  final double horizontalExpansion;
  final double swaySpeed;
  final double startRadius;
  final double endRadius;
  final double phase;
  final Color color;

  _SpreadingSmokeCloud({
    required this.initialSpreadX,
    required this.speedY,
    required this.horizontalExpansion,
    required this.swaySpeed,
    required this.startRadius,
    required this.endRadius,
    required this.phase,
    required this.color,
  });
}

/// The Main Interactive Devotional Chant Overlay
class DevotionalChantOverlay extends StatefulWidget {
  final DevotionalAnimationMode mode;
  final VoidCallback? onCompleted;
  final int tapCount;

  const DevotionalChantOverlay({
    super.key,
    required this.mode,
    required this.tapCount,
    this.onCompleted,
  });

  @override
  State<DevotionalChantOverlay> createState() => DevotionalChantOverlayState();
}

class DevotionalChantOverlayState extends State<DevotionalChantOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<_FloatingName> _floatingNames;
  late final List<_FreshPetal> _freshPetals;
  late final List<_SpreadingSmokeCloud> _spreadingClouds;

  // Mor Pankh flight path
  late Offset _featherStart;
  late Offset _featherTarget;
  late String _revealedRadhaName;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _initAnimationData();
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DevotionalChantOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tapCount != widget.tapCount || oldWidget.mode != widget.mode) {
      _initAnimationData();
      _animController.forward(from: 0.0).then((_) {
        if (mounted) {
          widget.onCompleted?.call();
        }
      });
    }
  }

  void _initAnimationData() {
    final rng = math.Random(widget.tapCount * 9137 + DateTime.now().millisecond);

    // 1. Setup Ram Naam floating particles (PERIPHERAL ONLY - Center is kept 100% CLEAR!)
    final ramWords = [
      "श्री राम", "जय श्री राम", "सिया राम", "राघव", "रघुपति",
      "रामचंद्र", "जानकीनाथ", "अयोध्यापति", "राम राम", "मर्यादा पुरुषोत्तम",
    ];
    _floatingNames = [];
    // Carefully positioned away from the center title!
    final peripheralPositions = [
      const Offset(0.12, 0.16),
      const Offset(0.78, 0.16),
      const Offset(0.10, 0.34),
      const Offset(0.82, 0.34),
      const Offset(0.12, 0.62),
      const Offset(0.80, 0.62),
      const Offset(0.20, 0.78),
      const Offset(0.74, 0.78),
      const Offset(0.46, 0.12),
      const Offset(0.48, 0.84),
    ];
    for (int i = 0; i < peripheralPositions.length; i++) {
      _floatingNames.add(
        _FloatingName(
          text: ramWords[i % ramWords.length],
          position: peripheralPositions[i],
          scale: 0.85 + rng.nextDouble() * 0.20,
          opacity: 0.80 + rng.nextDouble() * 0.20,
          vx: (rng.nextDouble() - 0.5) * 10.0,
          vy: -18.0 - rng.nextDouble() * 18.0,
        ),
      );
    }

    // 2. Setup Real-Life Fresh Flower Petals Shower (32 fresh silky petals)
    final petalPalettes = [
      [const Color(0xFFFF1744), const Color(0xFFFF5252)],
      [const Color(0xFFFF4081), const Color(0xFFFF80AB)],
      [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
      [const Color(0xFFFF6F00), const Color(0xFFFFB300)],
    ];
    _freshPetals = List.generate(32, (i) {
      final pair = petalPalettes[i % petalPalettes.length];
      return _FreshPetal(
        startX: (i / 32.0) + (rng.nextDouble() - 0.5) * 0.05,
        fallSpeed: 1.20 + rng.nextDouble() * 0.60,
        swaySpeed: 3.0 + rng.nextDouble() * 3.5,
        swayWidth: 26.0 + rng.nextDouble() * 30.0,
        rotSpeedZ: (rng.nextDouble() - 0.5) * 5.0,
        rotSpeedY: 2.2 + rng.nextDouble() * 4.0,
        size: 18.0 + rng.nextDouble() * 16.0,
        initialPhase: rng.nextDouble() * math.pi * 2,
        primaryColor: pair[0],
        secondaryColor: pair[1],
      );
    });

    // 3. Setup Wide-spreading Incense Smoke Clouds (Full-width billowing clouds)
    _spreadingClouds = List.generate(28, (i) {
      final spreadSign = (i % 2 == 0) ? 1.0 : -1.0;
      return _SpreadingSmokeCloud(
        initialSpreadX: 0.50 + (rng.nextDouble() - 0.5) * 0.10,
        speedY: 0.75 + rng.nextDouble() * 0.45,
        horizontalExpansion: spreadSign * (80.0 + rng.nextDouble() * 160.0),
        swaySpeed: 1.8 + rng.nextDouble() * 2.5,
        startRadius: 22.0 + rng.nextDouble() * 18.0,
        endRadius: 110.0 + rng.nextDouble() * 95.0,
        phase: rng.nextDouble() * math.pi * 2,
        color: (i % 4 == 0)
            ? const Color(0xFFFFF8E1)
            : ((i % 4 == 1)
                ? const Color(0xFFE0F7FA)
                : ((i % 4 == 2) ? const Color(0xFFECEFF1) : const Color(0xFFFFF3E0))),
      );
    });

    // 4. Setup Radha Rani 108 Sacred Name & Mor Pankh Pointing Flight
    final nameIdx = (widget.tapCount) % kRadha108Names.length;
    _revealedRadhaName = kRadha108Names[nameIdx];

    // Feather glides towards a random spot and points its tip directly at it
    final double targetX = 0.28 + (rng.nextDouble() * 0.44);
    final double targetY = 0.32 + (rng.nextDouble() * 0.34);

    final bool startFromLeft = (rng.nextBool());
    final double startX = startFromLeft ? -0.15 : 1.15;
    final double startY = 0.65 + rng.nextDouble() * 0.25;

    _featherStart = Offset(startX, startY);
    _featherTarget = Offset(targetX, targetY);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final progress = _animController.value;
        // Global master fade: in over first 10%, holds, fades out in last 15%
        double masterAlpha = 1.0;
        if (progress < 0.10) {
          masterAlpha = progress / 0.10;
        } else if (progress > 0.85) {
          masterAlpha = (1.0 - progress) / 0.15;
        }
        masterAlpha = masterAlpha.clamp(0.0, 1.0);

        if (masterAlpha <= 0.001) return const SizedBox.shrink();

        return Opacity(
          opacity: masterAlpha,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              switch (widget.mode) {
                case DevotionalAnimationMode.dhoopSmoke:
                  return _buildDhoopSmokeAnimation(w, h, progress);
                case DevotionalAnimationMode.ramNaamVandana:
                  return _buildRamNaamAnimation(w, h, progress);
                case DevotionalAnimationMode.pushpanjaliPetals:
                  return _buildPushpanjaliAnimation(w, h, progress);
                case DevotionalAnimationMode.radhaMorPankh108:
                  return _buildRadhaMorPankhAnimation(w, h, progress);
                case DevotionalAnimationMode.mahaAartiBells:
                  return _buildMahaAartiAnimation(w, h, progress);
              }
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. DHOOP & INCENSE SMOKE (REAL BRASS BURNER & FULL-IMAGE SPREADING SMOKE)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDhoopSmokeAnimation(double w, double h, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ambient Fragrant Atmospheric Haze spreading across the background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 0.4),
                radius: 1.1,
                colors: [
                  const Color(0xFFFFF8E1).withValues(alpha: (t * 0.18).clamp(0.0, 0.20)),
                  const Color(0xFFE0F7FA).withValues(alpha: (t * 0.12).clamp(0.0, 0.15)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Full-width Spreading Volumetric Incense Smoke Clouds
        CustomPaint(
          size: Size(w, h),
          painter: _FullSpreadSmokePainter(clouds: _spreadingClouds, progress: t),
        ),

        // Glowing Floating Ember Sparks spreading across screen
        CustomPaint(
          size: Size(w, h),
          painter: _WideEmberSparksPainter(
            originX: w * 0.50,
            originY: h - 85,
            progress: t,
          ),
        ),

        // Real Photorealistic Brass Dhoop Burner with Glowing Charcoal Heart
        Positioned(
          bottom: 18,
          left: (w - 110) / 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Red-Orange Burning Ember Pulse
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.85 + math.sin(t * 12.0) * 0.15),
                      blurRadius: 16,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF176),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Image.asset(
                'assets/images/devotional/dhoop_burner.png',
                width: 110,
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // Sacred Sanskrit Mantra Calligraphy
        Positioned(
          top: h * 0.16,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Text(
                'ॐ धूपं समर्पयामि',
                textAlign: TextAlign.center,
                style: GoogleFonts.rozhaOne(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFF9C4),
                  shadows: const [
                    Shadow(
                      color: Color(0xFFFF9100),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'દિવ્ય સુગંધ & વાતાવરણ શુદ્ધિ',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. RAM NAAM VANDANA (PURE CRISP GOLDEN TYPOGRAPHY, ZERO COLLISION/OVER-SHADOW)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRamNaamAnimation(double w, double h, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Center Divine Rays Halo (Soft & Pure)
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.28 + math.sin(t * 8.0) * 0.10),
                  blurRadius: 45,
                  spreadRadius: 16,
                ),
              ],
            ),
          ),
        ),

        // 10 Floating Sacred Ram Names positioned PERIPHERALLY (Zero center overlap!)
        for (final fn in _floatingNames)
          Positioned(
            left: (fn.position.dx * w) + (fn.vx * t),
            top: (fn.position.dy * h) + (fn.vy * t),
            child: Opacity(
              opacity: (fn.opacity * (0.50 + math.sin(t * math.pi) * 0.50)).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: fn.scale + (math.sin(t * 5.0) * 0.05),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9933).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFCC80).withValues(alpha: 0.45),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    fn.text,
                    style: GoogleFonts.rozhaOne(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFFDE7),
                      shadows: const [
                        Shadow(
                          color: Color(0xFFFF8F00),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Crisp, Clean Luminous "॥ श्री राम ॥" (Centered & uncluttered)
        Center(
          child: Transform.scale(
            scale: 0.88 + Curves.easeOutBack.transform(t.clamp(0.0, 0.40) / 0.40) * 0.24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '॥ श्री राम ॥',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rozhaOne(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFDE7),
                    shadows: const [
                      Shadow(
                        color: Color(0xFFFF9933),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'रघुपति राघव राजा राम',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 1.4,
                    shadows: const [
                      Shadow(
                        color: Color(0xFFFF8F00),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. PUSHPANJALI (UPRIGHT LOTUS BLOOM & SILKY 3D TUMBLING FRESH PETALS SHOWER)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPushpanjaliAnimation(double w, double h, double t) {
    // Lotus Blooming Physics: rises and blooms open in the center
    final double bloomT = (t / 0.45).clamp(0.0, 1.0);
    final double bloomCurve = Curves.easeOutBack.transform(bloomT);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Center Sacred Blooming Lotus (Straight, Upright, Pure Flower Head!)
        Center(
          child: Transform.scale(
            scale: 0.70 + (bloomCurve * 0.35),
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4081).withValues(alpha: 0.45 * bloomT),
                    blurRadius: 40,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/devotional/sacred_lotus.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Real-Life Fresh 3D Tumbling Petals Shower (Custom botanical painter)
        CustomPaint(
          size: Size(w, h),
          painter: _FreshPetalShowerPainter(petals: _freshPetals, progress: t),
        ),

        // Bottom Blessing Banner
        Positioned(
          bottom: 26,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E0A12).withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF80AB).withValues(alpha: 0.60),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4081).withValues(alpha: 0.30),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Text(
                '॥ दिव्य पुष्पांजलिम् समर्पितम् ॥',
                style: GoogleFonts.rozhaOne(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD1DC),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. RADHA MOR PANKH & 108 NAMES (GLIDES, POINTS WITH TIP, PURE WORDS REVEAL)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRadhaMorPankhAnimation(double w, double h, double t) {
    // Flight Path: Feather glides from start to target
    final double flightT = (t / 0.55).clamp(0.0, 1.0);
    final double smoothFlight = Curves.easeInOutCubic.transform(flightT);

    final double curX = _featherStart.dx + (_featherTarget.dx - _featherStart.dx) * smoothFlight;
    final double curY = _featherStart.dy + (_featherTarget.dy - _featherStart.dy) * smoothFlight - (math.sin(smoothFlight * math.pi) * 0.16);

    final bool isArrived = (t >= 0.40);
    final double nameRevealT = ((t - 0.40) / 0.45).clamp(0.0, 1.0);

    final double featherPixelX = (curX * w).clamp(15.0, w - 90.0);
    final double featherPixelY = (curY * h).clamp(30.0, h - 130.0);

    // Feather quill/tip points forward along motion, then tips down towards the name!
    final double flightAngle = isArrived ? -0.38 : -0.20 + math.sin(t * 8.0) * 0.12;

    // Spot coordinates where the tip points
    final double touchPointX = featherPixelX + 20;
    final double touchPointY = featherPixelY - 10;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Celestial Sparkle Trail behind flight
        CustomPaint(
          size: Size(w, h),
          painter: _SparkleTrailPainter(
            headX: featherPixelX + 35,
            headY: featherPixelY + 35,
            progress: t,
          ),
        ),

        // Gliding Mor Pankh with pointed tip
        Positioned(
          left: featherPixelX,
          top: featherPixelY,
          child: Transform.rotate(
            angle: flightAngle,
            alignment: Alignment.bottomRight,
            child: Image.asset(
              'assets/images/devotional/peacock_feather.png',
              width: 95,
              height: 95,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Simple Divine Name Reveal directly where tip points (NO heavy box!)
        if (isArrived)
          Positioned(
            left: (touchPointX - 100).clamp(16.0, w - 216.0),
            top: (touchPointY - 45).clamp(40.0, h - 160.0),
            child: Transform.scale(
              scale: 0.80 + Curves.easeOutBack.transform(nameRevealT) * 0.28,
              child: Opacity(
                opacity: nameRevealT,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Spark of divine celestial light at touch point
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF9C4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Pure Simple Sacred Name in Divine Glowing Gold (NO box!)
                    Text(
                      '॥ $_revealedRadhaName ॥',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rozhaOne(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFDE7),
                        shadows: const [
                          Shadow(
                            color: Color(0xFFFF9100),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: Color(0xFF7C4DFF),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'जय श्री राधे',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD54F),
                        shadows: const [
                          Shadow(
                            color: Color(0xFFFF8F00),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. MAHA AARTI (HORIZONTALLY LEVEL THALI, RADIANT GOLDEN GLOW & BELLS)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMahaAartiAnimation(double w, double h, double t) {
    // Symmetrical Pendulum Bell Motion
    final double bellAngle = math.sin(t * 14.0) * math.exp(-t * 0.7) * 0.18;

    // Smooth Clockwise Devotional Aarti Circulation Orbit
    final double aartiAngle = t * math.pi * 3.6;
    final double thaliOffsetX = math.cos(aartiAngle) * 50.0;
    final double thaliOffsetY = math.sin(aartiAngle) * 30.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Symmetrical Golden Bell Sound Wave Ripple Rings
        CustomPaint(
          size: Size(w, h),
          painter: _BellSoundWavesPainter(
            leftBellPos: const Offset(55, 60),
            rightBellPos: Offset(w - 55, 60),
            progress: t,
          ),
        ),

        // Left Temple Bell (Transparent PNG)
        Positioned(
          top: -8,
          left: 12,
          child: Transform.rotate(
            angle: bellAngle,
            alignment: Alignment.topCenter,
            child: Image.asset(
              'assets/images/devotional/temple_bells.png',
              width: 100,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Right Temple Bell (Transparent PNG)
        Positioned(
          top: -8,
          right: 12,
          child: Transform.rotate(
            angle: -bellAngle,
            alignment: Alignment.topCenter,
            child: Image.asset(
              'assets/images/devotional/temple_bells.png',
              width: 100,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Golden Aarti Flame Sparks swirling with Thali
        CustomPaint(
          size: Size(w, h),
          painter: _AartiSparksPainter(
            centerX: (w / 2) + thaliOffsetX,
            centerY: (h * 0.38) + thaliOffsetY,
            progress: t,
          ),
        ),

        // Horizontally Level, Non-tilted Aarti Thali with Magnificent Glowing Halo!
        Positioned(
          top: (h * 0.38 - 110) + thaliOffsetY,
          left: ((w - 220) / 2) + thaliOffsetX,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.50 + math.sin(t * 10.0) * 0.15),
                  blurRadius: 50,
                  spreadRadius: 18,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/devotional/aarti_thali.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Sacred Aarti Shlok Banner
        Positioned(
          bottom: 26,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF261203).withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.75),
                  width: 1.2,
                ),
              ),
              child: Text(
                '॥ ॐ कर्पूरगौरं करुणावतारं संसारसारम् ॥',
                style: GoogleFonts.rozhaOne(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFECB3),
                  shadows: const [
                    Shadow(
                      color: Color(0xFFFF6F00),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS FOR FLUID DEVOTIONAL RENDERING
// ─────────────────────────────────────────────────────────────────────────────

/// Full-Spread Volumetric Incense Smoke Clouds
class _FullSpreadSmokePainter extends CustomPainter {
  final List<_SpreadingSmokeCloud> clouds;
  final double progress;

  _FullSpreadSmokePainter({required this.clouds, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final burnerY = size.height - 75;
    final burnerX = size.width * 0.50;

    for (final c in clouds) {
      final double y = burnerY - (progress * c.speedY * size.height * 0.88);
      final double expansion = progress * c.horizontalExpansion;
      final double sway = math.sin((progress * c.swaySpeed * 6.0) + c.phase) * (35.0 * (progress + 0.15));
      final double x = burnerX + expansion + sway;

      final double radius = c.startRadius + (c.endRadius - c.startRadius) * progress;
      final double alpha = (1.0 - progress).clamp(0.0, 1.0) * 0.22;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            c.color.withValues(alpha: alpha),
            c.color.withValues(alpha: alpha * 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FullSpreadSmokePainter oldDelegate) => true;
}

/// Real-Life Fresh Flower Petal Shower Painter (Smooth 3D tumbling silky petals)
class _FreshPetalShowerPainter extends CustomPainter {
  final List<_FreshPetal> petals;
  final double progress;

  _FreshPetalShowerPainter({required this.petals, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final double curY = -40 + (progress * p.fallSpeed * (size.height + 90)) + ((p.startX * 45.0) % (size.height + 90));
      final double curX = (p.startX * size.width) + math.sin(progress * p.swaySpeed + p.initialPhase) * p.swayWidth;

      final double rotZ = p.initialPhase + (progress * p.rotSpeedZ);
      final double flipY = math.sin((progress * p.rotSpeedY) + p.initialPhase);

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(rotZ);
      canvas.scale(1.0, flipY.abs().clamp(0.15, 1.0));

      final petalPath = Path()
        ..moveTo(0, -p.size * 0.8)
        ..cubicTo(p.size * 0.65, -p.size * 0.4, p.size * 0.55, p.size * 0.5, 0, p.size * 0.8)
        ..cubicTo(-p.size * 0.55, p.size * 0.5, -p.size * 0.65, -p.size * 0.4, 0, -p.size * 0.8)
        ..close();

      final petalPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.secondaryColor.withValues(alpha: 0.90),
            p.primaryColor.withValues(alpha: 0.95),
          ],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6));

      canvas.drawPath(petalPath, petalPaint);

      // Specular shine on petal edge
      final shinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.35);
      canvas.drawPath(petalPath, shinePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FreshPetalShowerPainter oldDelegate) => true;
}

/// Wide-spreading Ember Sparks
class _WideEmberSparksPainter extends CustomPainter {
  final double originX;
  final double originY;
  final double progress;

  _WideEmberSparksPainter({required this.originX, required this.originY, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 22; i++) {
      final speed = 0.5 + rng.nextDouble() * 0.9;
      final spreadX = (rng.nextDouble() - 0.5) * (size.width * 0.85);
      final driftX = math.sin((progress * 5.0) + i) * 20.0;

      final px = originX + spreadX + driftX;
      final py = originY - (progress * speed * size.height * 0.55) - (i * 7.0);
      final alpha = (1.0 - progress).clamp(0.0, 1.0) * (0.85 - rng.nextDouble() * 0.2);

      paint.color = (i % 2 == 0 ? const Color(0xFFFFAB00) : const Color(0xFFFF3D00))
          .withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(px, py), 1.6 + rng.nextDouble() * 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WideEmberSparksPainter oldDelegate) => true;
}

/// Shimmering Stardust Trail for Mor Pankh Flight
class _SparkleTrailPainter extends CustomPainter {
  final double headX;
  final double headY;
  final double progress;

  _SparkleTrailPainter({
    required this.headX,
    required this.headY,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final lag = (i / 30.0) * 0.25;
      final t = (progress - lag).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final spreadX = (rng.nextDouble() - 0.5) * 45.0;
      final spreadY = (rng.nextDouble() - 0.5) * 45.0;
      final px = headX - (progress * 45.0) + spreadX;
      final py = headY + spreadY;
      final alpha = (1.0 - (i / 30.0)) * 0.85;

      paint.color = (i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFF00E5FF))
          .withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(px, py), 2.2 + rng.nextDouble() * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleTrailPainter oldDelegate) => true;
}

/// Golden Bell Sound Wave Ripple Rings
class _BellSoundWavesPainter extends CustomPainter {
  final Offset leftBellPos;
  final Offset rightBellPos;
  final double progress;

  _BellSoundWavesPainter({
    required this.leftBellPos,
    required this.rightBellPos,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress * 3.5 - i * 0.35) % 1.0;
      if (waveProgress < 0.0) continue;

      final radius = 25.0 + waveProgress * 45.0;
      final alpha = (1.0 - waveProgress) * 0.45;

      paint.color = const Color(0xFFFFD54F).withValues(alpha: alpha);

      canvas.drawCircle(leftBellPos, radius, paint);
      canvas.drawCircle(rightBellPos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BellSoundWavesPainter oldDelegate) => true;
}

/// Aarti Flame Sparks swirling with Thali
class _AartiSparksPainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double progress;

  _AartiSparksPainter({required this.centerX, required this.centerY, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(88);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final angle = (i * 0.314) + (progress * math.pi * 4.0);
      final dist = 45.0 + rng.nextDouble() * 55.0;
      final px = centerX + math.cos(angle) * dist;
      final py = centerY + math.sin(angle) * (dist * 0.6);

      final alpha = (0.3 + math.sin(progress * math.pi) * 0.7) * (0.85 - rng.nextDouble() * 0.2);
      paint.color = (i % 2 == 0 ? const Color(0xFFFFD54F) : const Color(0xFFFF6D00))
          .withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(px, py), 2.0 + rng.nextDouble() * 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AartiSparksPainter oldDelegate) => true;
}
