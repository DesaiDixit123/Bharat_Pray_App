import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/jap_models.dart';
import '../../widgets/jap/jap_voice_selection.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import '../../widgets/cinematic_jap/ram_path_calculator.dart';
import '../../widgets/pushp_varsha/pushp_temple_background.dart';
import '../../widgets/pushp_varsha/pushp_petal_physics.dart';
import '../../widgets/pushp_varsha/pushp_petal_shower_painter.dart';
import '../../widgets/pushp_varsha/pushp_progressive_reveal_widget.dart';
import '../../widgets/pushp_varsha/pushp_darshan_climax_view.dart';
import 'prakash_jap_screen.dart';

/// 5th Jap Chanting Effect: Pushp Varsha (Divine Flower Shower).
/// - Ancient carved sandstone temple sanctum with circular skylight dome.
/// - Cascading shower of pink lotus petals, marigold petals, white jasmine, and golden pollen.
/// - Lord Shri Ram progressively emerges through flower petals offering:
///   On each tap, petals dynamically swarm and fly towards a distributed target node,
///   and minorly reveal that specific sacred spot upon arrival.
/// - Face is strictly protected in sacred mystery until Japs 103..108.
/// - Dynamic depth with petals falling both behind and in front of the deity.
/// - Completely independent state and progress tracking.
class PushpVarshaJapScreen extends StatefulWidget {
  final JapConfig entry;

  const PushpVarshaJapScreen({super.key, required this.entry});

  @override
  State<PushpVarshaJapScreen> createState() => _PushpVarshaJapScreenState();
}

class _PushpVarshaJapScreenState extends State<PushpVarshaJapScreen>
    with JapVoiceSelection<PushpVarshaJapScreen>, TickerProviderStateMixin {
  @override
  JapConfig get japEntry => widget.entry;

  static const int _target = 108;
  late int _count;
  int _completedMalas = 0;
  bool _isCompleted = false;

  // Exact progressive reveal nodes from RamPathCalculator
  List<RevealNode> _revealedNodes = [];
  RevealNode? _newestNode;

  // Petal Shower Simulation
  final List<FallingPetal> _petals = [];
  final List<TargetedPetal> _targetedPetals = [];
  final List<PetalImpactSpark> _impactSparks = [];
  final List<FloatingRamText> _floatingTexts = [];
  final math.Random _random = math.Random();

  // Animation Controllers
  late final AnimationController _ambientController;
  late final AnimationController _shimmerController;
  late final AnimationController _completionController;
  late final AnimationController _tapButtonController;

  // Synchronized offering flight & arrival
  bool _isFlightActive = false;
  double _flightTimer = 0.0;
  final double _flightDuration = 1.38; // 1380ms calm, meditative flight from Play button to Lord Shri Ram
  bool _hasTriggeredArrival = false;
  Offset? _currentTargetOffset;

  // Global key to track Play button location on screen
  final GlobalKey _playButtonKey = GlobalKey();

  // Audio setup
  late final AudioPlayer _audioPlayer;
  static const int _voicePoolSize = 8;
  final List<AudioPlayer> _voicePlayers = [];
  int _voicePlayerIndex = 0;
  bool _isSoundEnabled = true;

  Timer? _syncDebounceTimer;

  String get _pushpJapId => '${widget.entry.id}_pushp';
  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();
    prepareJapVoice();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _count = 0;
    _completedMalas = 0;
    _isCompleted = false;

    // Audio setup
    _audioPlayer = _createChantPlayer();
    for (int i = 0; i < _voicePoolSize; i++) {
      _voicePlayers.add(_createChantPlayer());
    }

    // Continuous ambient water and flame loop
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_onAmbientTick)
     ..repeat();

    // Node outline shimmer and bloom
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 108 golden aura bloom
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Tap button spring bounce
    _tapButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.90,
      upperBound: 1.0,
    )..value = 1.0;

    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('jap_sound_enabled') ?? true;

      // Load independent progress for Pushp Varsha
      final cached = await JapOfflineRepository.getProgress(_pushpJapId,
          defaultTarget: _target);
      final count = cached['count'] ?? 0;
      final malas = cached['completedMalas'] ?? 0;

      if (mounted) {
        setState(() {
          _count = count % _target;
          _completedMalas = malas;
          _isCompleted = false;

          if (_count > 0) {
            _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
            _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
          } else {
            _revealedNodes = [];
            _newestNode = null;
          }
        });
      }
    } catch (_) {}
  }

  AudioPlayer _createChantPlayer() {
    final p = AudioPlayer();
    p.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
    return p;
  }

  void _playVoiceChant() {
    if (!_isSoundEnabled) return;
    try {
      final player = _voicePlayers[_voicePlayerIndex];
      _voicePlayerIndex = (_voicePlayerIndex + 1) % _voicePoolSize;
      player.stop().then((_) {
        player.play(japChantSource).catchError((_) {});
      }).catchError((_) {
        player.play(japChantSource).catchError((_) {});
      });
    } catch (e) {
      debugPrint('[PushpVarsha] Voice error: $e');
    }
  }

  void _stopAllAudio() {
    _audioPlayer.stop().catchError((_) {});
    for (final p in _voicePlayers) {
      p.stop().catchError((_) {});
    }
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _ambientController.removeListener(_onAmbientTick);
    _ambientController.dispose();
    _shimmerController.dispose();
    _completionController.dispose();
    _tapButtonController.dispose();
    _stopAllAudio();
    for (final p in _voicePlayers) {
      p.dispose();
    }
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Petal Shower Physics Ticker ──────────────────────────────────────

  void _onAmbientTick() {
    const double dt = 0.016;

    // 1. Detect petal arrival at target spot and trigger bloom
    if (_isFlightActive) {
      _flightTimer += dt;
      if (_flightTimer >= _flightDuration && !_hasTriggeredArrival) {
        _hasTriggeredArrival = true;
        _onPetalsArrived();
      }
    }

    // 2. Update targeted flying petals & detect arrivals
    _targetedPetals.removeWhere((tp) => !tp.update(dt));

    // 3. Update floating sacred text
    _floatingTexts.removeWhere((ft) => !ft.update(dt));

    // 4. Update impact sparks
    _impactSparks.removeWhere((s) => !s.update(dt));

    if (mounted) {
      setState(() {});
    }
  }

  void _onPetalsArrived() {
    if (_currentTargetOffset != null) {
      // Golden impact sparks bursting upon arrival at the sacred spot!
      for (int s = 0; s < 10; s++) {
        final double angle = _random.nextDouble() * 2 * math.pi;
        final double speed = 18.0 + (_random.nextDouble() * 32.0);
        final Color sparkColor = (s % 3 == 0)
            ? const Color(0xFFFF80AB) // Sacred Rose
            : (s % 3 == 1
                ? const Color(0xFFFFD54F) // Golden Pollen
                : const Color(0xFFFFF9C4)); // Ivory Jasmine
        _impactSparks.add(
          PetalImpactSpark(
            position: _currentTargetOffset!,
            velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
            size: 2.2 + (_random.nextDouble() * 2.8),
            maxLife: 0.65 + (_random.nextDouble() * 0.35),
            color: sparkColor,
          ),
        );
      }
    }

    // Soft tactile confirmation
    HapticFeedback.lightImpact();

    // Trigger smooth bloom & shimmer expansion of the newly revealed spot!
    _shimmerController.forward(from: 0.0).then((_) {
      if (mounted && _newestNode != null) {
        if (!_revealedNodes.contains(_newestNode)) {
          setState(() {
            _revealedNodes.add(_newestNode!);
          });
        }
      }
    });
  }

  void _spawnSinglePetal([double? customX, double? customY]) {
    final Size size = MediaQuery.of(context).size;
    final double spawnX = customX ??
        (size.width * (0.20 + (_random.nextDouble() * 0.60)));
    final double spawnY = customY ??
        (size.height * 0.04 - (_random.nextDouble() * 20.0));

    final double randType = _random.nextDouble();
    PetalType type;
    if (randType < 0.45) {
      type = PetalType.lotusPetal;
    } else if (randType < 0.75) {
      type = PetalType.marigoldPetal;
    } else if (randType < 0.88) {
      type = PetalType.jasminePetal;
    } else {
      type = PetalType.goldenPollen;
    }

    _petals.add(
      FallingPetal(
        x: spawnX,
        y: spawnY,
        vy: 45.0 + (_random.nextDouble() * 65.0),
        swayAmp: 14.0 + (_random.nextDouble() * 20.0),
        swayFreq: 0.80 + (_random.nextDouble() * 0.90),
        phase: _random.nextDouble() * 2 * math.pi,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotSpeed: (_random.nextDouble() - 0.5) * 2.5,
        tumble: _random.nextDouble() * 2 * math.pi,
        tumbleSpeed: 1.5 + (_random.nextDouble() * 3.0),
        size: type == PetalType.goldenPollen
            ? (2.5 + (_random.nextDouble() * 2.5))
            : (12.0 + (_random.nextDouble() * 10.0)),
        maxAlpha: 0.70 + (_random.nextDouble() * 0.28),
        maxLife: 6.0 + (_random.nextDouble() * 3.5),
        isBackground: _random.nextBool(),
        type: type,
      ),
    );
  }

  // ── Core Chanting Action on Tap (Targeted Petal Swarm & Spot Reveal) ──

  Offset _getPlayButtonPosition() {
    final RenderBox? renderBox =
        _playButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      return renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    }
    final Size size = MediaQuery.of(context).size;
    return Offset(size.width * 0.50, size.height - 110.0);
  }

  void _onTapChant([Offset? tapPosition]) {
    if (_isCompleted || _count >= _target) return;

    // If a flight was already active, finalize its node immediately so rapid taps don't lose nodes
    if (_isFlightActive && _newestNode != null) {
      if (!_revealedNodes.contains(_newestNode)) {
        _revealedNodes.add(_newestNode!);
      }
    }

    // 1. Button spring bounce feedback
    _tapButtonController.reverse().then((_) {
      if (mounted) _tapButtonController.forward();
    });
    HapticFeedback.lightImpact();

    // 2. Play pure "राम" chant audio on EVERY tap!
    _playVoiceChant();

    // 3. Compute target node and exact screen coordinate
    final int nextCount = _count + 1;
    final targetNode = RamPathCalculator.getNodeForStep(_count);

    final Size screenSize = MediaQuery.of(context).size;
    final Rect dstRect = RamPathCalculator.computeDstRect(
      screenSize,
      imageAspect: 768.0 / 1376.0,
    );
    final Offset targetOffset = Offset(
      dstRect.left + (targetNode.u * dstRect.width),
      dstRect.top + (targetNode.v * dstRect.height),
    );

    // 4. Launch dynamic flurry of flower petals emerging directly from the Tap/Play button!
    final Offset origin = _getPlayButtonPosition();
    _spawnTargetedPetals(origin, targetOffset);

    // 5. Launch sacred Devanagari "राम" text floating gracefully along with petals!
    const String mantraText = 'राम';
    final double textArchSide = ((nextCount % 2 == 0) ? 1.0 : -1.0) * (30.0 + _random.nextDouble() * 25.0);
    final Offset textControl = Offset(
      (origin.dx + targetOffset.dx) / 2.0 + textArchSide,
      math.min(origin.dy, targetOffset.dy) - (50.0 + _random.nextDouble() * 30.0),
    );
    _floatingTexts.add(
      FloatingRamText(
        text: mantraText,
        start: Offset(origin.dx, origin.dy - 16.0),
        control: textControl,
        target: targetOffset,
        duration: _flightDuration,
        fontSize: 22.0,
      ),
    );

    // 6. Update state: count advances, but newestNode starts completely hidden (bloom = 0.0) until petals arrive!
    _currentTargetOffset = targetOffset;
    _isFlightActive = true;
    _flightTimer = 0.0;
    _hasTriggeredArrival = false;
    _shimmerController.reset();

    setState(() {
      _count = nextCount;
      _newestNode = targetNode;
    });

    // Check for 108 Jap Completion
    if (_count >= _target) {
      _handle108Completion();
    } else {
      _persistProgress();
    }
  }

  void _spawnTargetedPetals(Offset origin, Offset target) {
    final int count = 15 + _random.nextInt(6); // 15-20 petals in the streaming floral fountain

    for (int i = 0; i < count; i++) {
      // Petals blossom directly out of the Play button at the bottom center
      final Offset start = Offset(
        origin.dx + ((_random.nextDouble() - 0.5) * 28.0),
        origin.dy - (8.0 + _random.nextDouble() * 22.0),
      );

      // Slightly scattered landing around target node on Lord Shri Ram
      final Offset end = Offset(
        target.dx + ((_random.nextDouble() - 0.5) * 24.0),
        target.dy + ((_random.nextDouble() - 0.5) * 24.0),
      );

      // Arched trajectory swooping upwards from Play button to target spot
      final double midX = (start.dx + end.dx) / 2.0;
      final double sideArch = ((i % 2 == 0) ? 1.0 : -1.0) * (45.0 + _random.nextDouble() * 75.0);
      final Offset control = Offset(
        midX + sideArch,
        math.min(start.dy, end.dy) - (40.0 + _random.nextDouble() * 55.0),
      );

      final double randType = _random.nextDouble();
      PetalType type;
      if (randType < 0.45) {
        type = PetalType.lotusPetal;
      } else if (randType < 0.75) {
        type = PetalType.marigoldPetal;
      } else if (randType < 0.88) {
        type = PetalType.jasminePetal;
      } else {
        type = PetalType.goldenPollen;
      }

      final double duration = 1.35 + (_random.nextDouble() * 0.20); // 1.35s - 1.55s (slow, calm, graceful meditative flight)
      final double delay = i * 0.026; // smooth staggered fountain trail

      _targetedPetals.add(
        TargetedPetal(
          start: start,
          control: control,
          target: end,
          type: type,
          size: type == PetalType.goldenPollen
              ? (3.0 + _random.nextDouble() * 2.5)
              : (13.0 + _random.nextDouble() * 9.0),
          duration: duration,
          delay: delay,
          rotSpeed: (_random.nextDouble() - 0.5) * 5.0,
          tumbleSpeed: 2.5 + (_random.nextDouble() * 3.0),
          swayAmp: 12.0 + (_random.nextDouble() * 14.0),
          swayFreq: 1.0 + (_random.nextDouble() * 0.60),
          maxAlpha: 0.85 + (_random.nextDouble() * 0.15),
          maxDriftTime: 0.90,
        ),
      );
    }
  }

  void _handle108Completion() {
    setState(() {
      _isCompleted = true;
      _completedMalas++;
      _revealedNodes = RamPathCalculator.revealNodes; // 100% full reveal
    });

    _completionController.forward(from: 0.0);

    // Grand celebratory shower
    final Size screenSize = MediaQuery.of(context).size;
    for (int i = 0; i < 28; i++) {
      final double bx = screenSize.width * (0.10 + (_random.nextDouble() * 0.80));
      final double by = screenSize.height * 0.02 + (_random.nextDouble() * 60.0);
      _spawnSinglePetal(bx, by);
    }

    _stopAllAudio();
    if (_isSoundEnabled) {
      _audioPlayer.play(AssetSource('audio/temple_bell.wav')).catchError((_) {});
    }

    HapticFeedback.heavyImpact();
    _persistProgress();
  }

  void _performReset() {
    _stopAllAudio();
    setState(() {
      _count = 0;
      _completedMalas = 0;
      _isCompleted = false;
      _revealedNodes = [];
      _newestNode = null;
      _isFlightActive = false;
      _hasTriggeredArrival = false;
      _petals.clear();
      _targetedPetals.clear();
      _floatingTexts.clear();
      _impactSparks.clear();
    });

    _shimmerController.reset();
    _completionController.reset();

    HapticFeedback.mediumImpact();
    _persistProgress();
  }

  void _startNextMala() {
    setState(() {
      _count = 0;
      _isCompleted = false;
      _revealedNodes = [];
      _newestNode = null;
      _isFlightActive = false;
      _hasTriggeredArrival = false;
      _petals.clear();
      _targetedPetals.clear();
      _floatingTexts.clear();
      _impactSparks.clear();
    });
    _completionController.reset();
    _persistProgress();
  }

  void _persistProgress() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await JapOfflineRepository.saveProgress(
          japId: _pushpJapId,
          count: _count,
          completedMalas: _completedMalas,
          targetCount: _target,
        );

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
        if (token.isNotEmpty && widget.entry.id.length == 24) {
          await ApiService.syncJapProgress(
            token,
            widget.entry.id,
            _totalProgress,
            completedMalas: _completedMalas,
          );
        }
      } catch (e) {
        debugPrint('[PushpVarshaJapScreen] Sync error: $e');
      }
    });
  }

  // ── Build UI Hierarchy ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _persistProgress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── LAYER 1: Pure Black Devotional Sanctum ─────────────────
            const PushpTempleBackground(),

            // ── LAYER 2: Background Falling Petals (Behind Deity) ─────────
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: PushpPetalShowerPainter(
                  petals: _petals,
                  targetedPetals: const [],
                  impactSparks: const [],
                  isBackgroundLayer: true,
                  ambientTime: _ambientController.value,
                ),
              ),
            ),

            // ── LAYER 3: Progressive Lord Shri Ram Flower Reveal ──────────
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                if (!_isCompleted && _count < _target) {
                  _onTapChant(details.localPosition);
                }
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _ambientController,
                  _shimmerController,
                  _completionController,
                ]),
                builder: (context, _) {
                  double newestBloom = 1.0;
                  if (_isFlightActive) {
                    if (!_hasTriggeredArrival) {
                      newestBloom = 0.0; // Completely dark while petals are flying!
                    } else {
                      newestBloom = Curves.easeOutCubic.transform(
                          _shimmerController.value.clamp(0.0, 1.0));
                    }
                  }
                  return PushpProgressiveRevealWidget(
                    count: _count,
                    targetCount: _target,
                    revealedNodes: _revealedNodes,
                    newestNode: _newestNode,
                    newestNodeBloom: newestBloom,
                    shimmerProgress: _shimmerController.value,
                    isCompleted: _isCompleted,
                    completionGlow: _completionController.value,
                    imageAsset: 'assets/images/ram_deity_transparent.png',
                  );
                },
              ),
            ),

            // ── LAYER 4: Foreground Falling Petals, Swarm & Sparks ────────
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: PushpPetalShowerPainter(
                  petals: _petals,
                  targetedPetals: _targetedPetals,
                  impactSparks: _impactSparks,
                  floatingTexts: _floatingTexts,
                  isBackgroundLayer: false,
                  ambientTime: _ambientController.value,
                ),
              ),
            ),

            // ── LAYER 5: Controls & Devotional Counter ─────────────────────
            if (!_isCompleted)
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: [< Back] --- [શ્રી રામ જાપ] --- [Effects / Sound]
                    _buildTopBar(),

                    buildJapVoiceButton(),

                    const Spacer(),

                    // Subtle bottom gradient protecting counter and controls
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Devotional Counter directly above Tap Button (0 / 108...)
                          _buildDevotionalCounter(),

                          const SizedBox(height: 8),

                          // Controls: [Reset] --- [Glowing Flower Tap Button 🌸] --- [Sound]
                          _buildChantingControls(),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── LAYER 6: Final 108 Climax View ────────────────────────────
            if (_isCompleted)
              PushpDarshanClimaxView(
                onNextMala: _startNextMala,
                onExit: () {
                  _persistProgress();
                  Navigator.pop(context, _totalProgress);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar (< Back, Title, Mode Switcher, Favorite) ─────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              _persistProgress();
              Navigator.pop(context, _totalProgress);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC8A882).withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFC8A882),
                  size: 16,
                ),
              ),
            ),
          ),

          // Title: "શ્રી રામ જાપ"
          Text(
            'શ્રી રામ જાપ',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF80AB),
              shadows: const [
                Shadow(color: Color(0xFFE91E63), blurRadius: 14),
              ],
            ),
          ),

          // Right Switchers & Sound
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dedicated Prakash Mandal Mode Switcher
              GestureDetector(
                onTap: () async {
                  _persistProgress();
                  final updated = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrakashJapScreen(entry: widget.entry),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _count = updated % _target;
                      _completedMalas = updated ~/ _target;
                      _isCompleted = _count >= _target;
                    });
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E130B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFD54F),
                      size: 17,
                    ),
                  ),
                ),
              ),

              // Sound Toggle Button
              GestureDetector(
                onTap: () {
                  setState(() => _isSoundEnabled = !_isSoundEnabled);
                  if (!_isSoundEnabled) _stopAllAudio();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isSoundEnabled
                          ? const Color(0xFFFF80AB)
                          : const Color(0xFFC8A882).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _isSoundEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                      color: _isSoundEnabled
                          ? const Color(0xFFFF80AB)
                          : const Color(0xFFC8A882).withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Devotional Counter: 0 / 108... ───────────────────────────────────

  Widget _buildDevotionalCounter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$_count',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: const [
                  Shadow(color: Color(0xFFE91E63), blurRadius: 16.0),
                  Shadow(color: Colors.black, blurRadius: 8.0, offset: Offset(0, 2)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '/ $_target',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF80AB),
                letterSpacing: 0.5,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'શ્રી રામ જય રામ જય જય રામ',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSerifDevanagari(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFF0F5),
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Chanting Controls: [Reset] --- [Tap Button 🌸] --- [Sound] ────────

  Widget _buildChantingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Reset Button
          _buildActionButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onTap: () {
              if (_count == 0) return;
              _showResetDialog();
            },
          ),

          // Center: Glowing Play Button 🌸 ▶
          GestureDetector(
            key: _playButtonKey,
            onTap: () => _onTapChant(),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _tapButtonController,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.25, -0.3),
                        radius: 0.9,
                        colors: [
                          Color(0xFFFFF0F5),
                          Color(0xFFFF80AB),
                          Color(0xFFE91E63),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.70),
                          blurRadius: 22.0,
                          spreadRadius: 3.0,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.40),
                          blurRadius: 14.0,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFF0F5),
                        width: 2.2,
                      ),
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: 3.5), // Optical centering for play triangle
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF80AB),
                  ),
                ),
              ],
            ),
          ),

          // Right: Sound Button
          _buildActionButton(
            icon: _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: _isSoundEnabled ? 'Sound' : 'Mute',
            isActive: _isSoundEnabled,
            onTap: () {
              setState(() => _isSoundEnabled = !_isSoundEnabled);
              if (!_isSoundEnabled) _stopAllAudio();
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
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFF80AB).withValues(alpha: 0.70)
                    : const Color(0xFFC8A882).withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.25),
                        blurRadius: 8.0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFFF80AB) : Colors.white60,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFFFF80AB) : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF261217),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF80AB), width: 1.5),
        ),
        title: Text(
          'Reset Chanting Counter?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will reset your current Pushp Varsha Mala ($_count / $_target) back to 0.',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performReset();
            },
            child: Text(
              'Reset',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
