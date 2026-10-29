import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/jap_models.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import '../../widgets/cinematic_jap/ram_path_calculator.dart';
import '../../widgets/jal_jap/jal_temple_background.dart';
import '../../widgets/jal_jap/jal_water_ripple_painter.dart';
import '../../widgets/jal_jap/jal_lotus_row_widget.dart';
import '../../widgets/jal_jap/jal_darshan_climax_view.dart';
import '../../widgets/jal_jap/jal_progressive_water_reveal_widget.dart';
import 'prakash_jap_screen.dart';
import 'pushp_varsha_jap_screen.dart';

/// Master Implementation — Divine Jal Darshan (Sacred Water Reveal) Screen.
/// Third independent Jap effect in BharatPray:
/// - Traditional Hindu temple interior with a sacred water pool.
/// - Progressive reveal of Lord Shri Ram through water ripples, reflections, and golden light.
/// - Every individual Jap tap spawns a natural water ripple and reveals an additional portion.
/// - At 108 Jap: full divine Darshan with live video darshan layer.
/// - Completely independent state, counter, and persistence.
class JalJapScreen extends StatefulWidget {
  final JapConfig entry;

  const JalJapScreen({super.key, required this.entry});

  @override
  State<JalJapScreen> createState() => _JalJapScreenState();
}

class _JalJapScreenState extends State<JalJapScreen>
    with TickerProviderStateMixin {
  static const int _target = 108;
  late int _count;
  int _completedMalas = 0;
  bool _isCompleted = false;
  bool _isChantingActive = false;
  bool _isPaused = false;

  // Exact progressive reveal nodes from RamPathCalculator
  List<RevealNode> _revealedNodes = [];

  // Water Ripple and Particle Simulation
  final List<WaterRipple> _ripples = [];
  final List<FloatingRamLotus> _floatingLotuses = [];
  final List<WaterDrop> _droplets = [];
  final List<FloatingPetal> _petals = [];
  final math.Random _random = math.Random();
  double _petalSpawnTimer = 0.0;

  // Animation Controllers
  late final AnimationController _ambientController;
  late final AnimationController _shimmerController;
  late final AnimationController _completionController;
  late final AnimationController _tapButtonController;
  late final AnimationController _flightController;

  // Audio setup
  late final AudioPlayer _audioPlayer;
  bool _isSoundEnabled = true;

  Timer? _syncDebounceTimer;

  String get _jalJapId => '${widget.entry.id}_jal';
  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initial counter & reveal state (loaded independently)
    _count = 0;
    _completedMalas = 0;
    _isCompleted = false;

    // Audio setup
    _audioPlayer = AudioPlayer();
    _audioPlayer.setAudioContext(
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

    // Flight controller strictly synchronized with voice audio (5280ms duration)
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5280),
    );

    _flightController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _isChantingActive = false;
          _isPaused = false;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      if (_isChantingActive) {
        setState(() {
          _isChantingActive = false;
          _isPaused = false;
        });
      }
    });

    // Continuous ambient water and flame loop
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_onAmbientTick)
     ..repeat();

    // Node outline shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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

      // Load independent progress for Jal Darshan
      final cached = await JapOfflineRepository.getProgress(_jalJapId, defaultTarget: _target);
      final count = cached['count'] ?? 0;
      final malas = cached['completedMalas'] ?? 0;

      if (mounted) {
        setState(() {
          _count = count % _target;
          _completedMalas = malas;
          _isCompleted = false;

          if (_count > 0) {
            _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
          } else {
            _revealedNodes = [];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSoundPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('jap_sound_enabled', value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _ambientController.removeListener(_onAmbientTick);
    _ambientController.dispose();
    _shimmerController.dispose();
    _completionController.dispose();
    _tapButtonController.dispose();
    _flightController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Water Physics Ticker ─────────────────────────────────────────────

  void _onAmbientTick() {
    const double dt = 0.016;
    _petalSpawnTimer += dt;

    // Update ripples, floating lotuses, and droplets
    _ripples.removeWhere((r) => !r.update(dt));
    _floatingLotuses.removeWhere((l) => !l.update(dt));
    _droplets.removeWhere((d) => !d.update(dt));
    _petals.removeWhere((p) => !p.update(dt));

    // Spawn gentle drifting lotus petals (~1 every 2 seconds)
    if (_petalSpawnTimer >= 2.2 && _petals.length < 8) {
      _petalSpawnTimer = 0.0;
      _spawnFloatingPetal();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnFloatingPetal() {
    final Size size = MediaQuery.of(context).size;
    final double startX = size.width * (0.15 + (_random.nextDouble() * 0.70));
    final double startY = size.height * (0.68 + (_random.nextDouble() * 0.18));

    _petals.add(
      FloatingPetal(
        startX: startX,
        startY: startY,
        speed: 10.0 + (_random.nextDouble() * 12.0),
        waveAmp: 12.0 + (_random.nextDouble() * 14.0),
        waveFreq: 1.0 + (_random.nextDouble() * 0.8),
        phase: _random.nextDouble() * 2 * math.pi,
        scale: 0.85 + (_random.nextDouble() * 0.35),
        rotation: _random.nextDouble() * 2 * math.pi,
        duration: 4.5 + (_random.nextDouble() * 2.0),
      ),
    );
  }

  // ── Core Chanting Action on Tap (Ripple, Floating 'राम' Lotus & Water Emergence) ──

  void _onTapChant([Offset? tapPosition]) {
    if (_isCompleted) return;

    // If user taps the main button while chanting is active: toggle pause/resume
    if (_isChantingActive && tapPosition == null) {
      if (!_isPaused) {
        setState(() => _isPaused = true);
        _flightController.stop();
        if (_isSoundEnabled) _audioPlayer.pause().catchError((_) {});
        HapticFeedback.selectionClick();
        return;
      } else {
        setState(() => _isPaused = false);
        _flightController.forward();
        if (_isSoundEnabled) _audioPlayer.resume().catchError((_) {});
        HapticFeedback.selectionClick();
        return;
      }
    }

    _isPaused = false;
    _startFlightChant(tapPosition);
  }

  void _startFlightChant([Offset? tapPosition]) {
    if (_count >= _target) {
      _handle108Completion();
      return;
    }

    setState(() {
      _isChantingActive = true;
      _isPaused = false;
    });

    // 1. Button spring bounce feedback
    _tapButtonController.reverse().then((_) {
      if (mounted) _tapButtonController.forward();
    });
    HapticFeedback.lightImpact();

    // 2. Play chant audio
    _playChantAudio();

    final Size screenSize = MediaQuery.of(context).size;
    final double poolMinY = screenSize.height * 0.54;
    final double poolMaxY = screenSize.height * 0.82;

    // Determine spawn coordinate: if user tapped on water, use that location;
    // if user tapped button, spawn in the golden center of the water pool
    Offset lotusPos;
    if (tapPosition != null && tapPosition.dy >= poolMinY * 0.90) {
      lotusPos = Offset(
        tapPosition.dx.clamp(screenSize.width * 0.12, screenSize.width * 0.88),
        tapPosition.dy.clamp(poolMinY + 15, poolMaxY),
      );
    } else {
      final double jitterX = (_random.nextDouble() - 0.5) * (screenSize.width * 0.50);
      final double jitterY = (_random.nextDouble() - 0.5) * 50.0;
      lotusPos = Offset(
        (screenSize.width * 0.50) + jitterX,
        (screenSize.height * 0.68) + jitterY,
      );
    }

    // 3. Spawn floating sacred 'राम' lotus (or 'श्री राम' on special milestones)
    final String chantText = (_count % 9 == 0 && _count > 0) ? 'श्री राम' : 'राम';
    final double driftAngle = _random.nextDouble() * 2 * math.pi;
    final double driftSpeed = 3.5 + (_random.nextDouble() * 5.0);

    _floatingLotuses.add(
      FloatingRamLotus(
        origin: lotusPos,
        text: chantText,
        scale: 0.95 + (_random.nextDouble() * 0.25),
        duration: 4.8,
        driftVx: math.cos(driftAngle) * driftSpeed,
        driftVy: (math.sin(driftAngle) * driftSpeed * 0.5) - 2.0,
        wavePhase: _random.nextDouble() * 2 * math.pi,
      ),
    );

    // Limit active floating lotuses to 8 for silky smooth 60/120fps performance
    if (_floatingLotuses.length > 8) {
      _floatingLotuses.removeAt(0);
    }

    // 4. Trigger expanding concentric water ripples
    _ripples.add(
      WaterRipple(
        center: lotusPos,
        maxRadius: 180.0 + (_random.nextDouble() * 70.0),
        duration: 1.6,
        baseColor: const Color(0xFF80DEEA),
      ),
    );

    // 5. Trigger golden water splash droplets
    for (int i = 0; i < 9; i++) {
      final double angle = _random.nextDouble() * 2 * math.pi;
      final double speed = 32.0 + (_random.nextDouble() * 50.0);
      _droplets.add(
        WaterDrop(
          x: lotusPos.dx,
          y: lotusPos.dy,
          vx: math.cos(angle) * speed,
          vy: (math.sin(angle) * speed) - 45.0, // Rising
          radius: 2.2 + (_random.nextDouble() * 1.8),
          duration: 0.9 + (_random.nextDouble() * 0.4),
          color: (i % 2 == 0) ? const Color(0xFFFFD54F) : const Color(0xFFE0F7FA),
        ),
      );
    }

    // 6. Progressively reveal the next step of Lord Shri Ram emergence
    final int nextCount = _count + 1;

    setState(() {
      _count = nextCount;
      _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
    });

    _shimmerController.forward(from: 0.0);
    HapticFeedback.selectionClick();

    // Check for 108 Jap Completion
    if (_count >= _target) {
      _handle108Completion();
    } else {
      _persistProgress();
    }

    // Drive flight controller duration: 5280ms when sound on, 950ms when sound muted
    _flightController.duration = _isSoundEnabled
        ? const Duration(milliseconds: 5280)
        : const Duration(milliseconds: 950);
    _flightController.forward(from: 0.0);
  }

  Future<void> _playChantAudio() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      final String? audioUrl = widget.entry.shlokAudioUrl;
      final String rawAudio = (audioUrl != null && audioUrl.isNotEmpty)
          ? audioUrl
          : 'audio/ram_chant.mp3';

      if (rawAudio.startsWith('http://') || rawAudio.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(rawAudio));
      } else if (rawAudio.startsWith('assets/')) {
        await _audioPlayer.play(AssetSource(rawAudio.replaceFirst('assets/', '')));
      } else if (rawAudio.startsWith('/')) {
        await _audioPlayer.play(DeviceFileSource(rawAudio));
      } else {
        await _audioPlayer.play(AssetSource(rawAudio));
      }
    } catch (e) {
      debugPrint('[JalAudio] Notice: $e');
    }
  }

  void _handle108Completion() {
    _flightController.stop();
    setState(() {
      _isChantingActive = false;
      _isPaused = false;
      _isCompleted = true;
      _completedMalas++;
      _revealedNodes = RamPathCalculator.revealNodes; // 100% full reveal
    });

    _completionController.forward(from: 0.0);

    if (_isSoundEnabled) {
      _audioPlayer.stop().catchError((_) {});
      _audioPlayer.play(AssetSource('audio/temple_bell.wav')).catchError((_) {});
    }

    HapticFeedback.heavyImpact();
    _persistProgress();
  }

  void _performReset() {
    _audioPlayer.stop().catchError((_) {});
    _flightController.reset();
    setState(() {
      _count = 0;
      _completedMalas = 0;
      _isCompleted = false;
      _isChantingActive = false;
      _isPaused = false;
      _revealedNodes = [];
      _ripples.clear();
      _floatingLotuses.clear();
      _droplets.clear();
    });

    _shimmerController.reset();
    _completionController.reset();

    HapticFeedback.mediumImpact();
    _persistProgress();
  }

  void _startNextMala() {
    _audioPlayer.stop().catchError((_) {});
    _flightController.reset();
    setState(() {
      _count = 0;
      _isCompleted = false;
      _isChantingActive = false;
      _isPaused = false;
      _revealedNodes = [];
      _ripples.clear();
      _floatingLotuses.clear();
      _droplets.clear();
    });
    _completionController.reset();
    _persistProgress();
  }

  void _persistProgress() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await JapOfflineRepository.saveProgress(
          japId: _jalJapId,
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
        debugPrint('[JalJapScreen] Sync error: $e');
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
            // ── LAYER 1: Temple Sanctum & Sacred Water Pool Background ─────
            JalTempleBackground(
              flameFlicker: _ambientController.value,
            ),

            // ── LAYER 2: Progressive Lord Shri Ram Sacred Water Reveal ─────
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                if (!_isCompleted && _count < _target) {
                  _onTapChant(details.localPosition);
                }
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_ambientController, _completionController]),
                builder: (context, _) {
                  return JalProgressiveWaterRevealWidget(
                    count: _count,
                    targetCount: _target,
                    revealedNodes: _revealedNodes,
                    ambientTime: _ambientController.value,
                    isCompleted: _isCompleted,
                    completionGlow: _completionController.value,
                    imageAsset: 'assets/images/ram_deity_transparent.png',
                  );
                },
              ),
            ),

            // ── LAYER 3: Expanding Water Ripples, Floating Ram Lotuses & Droplets
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: JalWaterRipplePainter(
                  ripples: _ripples,
                  floatingLotuses: _floatingLotuses,
                  droplets: _droplets,
                  petals: _petals,
                  ambientTime: _ambientController.value,
                ),
              ),
            ),

            // ── LAYER 4: Floating Sacred Pink Lotuses & Burning Brass Diyas ─
            Positioned(
              left: 0,
              right: 0,
              bottom: 125,
              child: JalLotusRowWidget(
                waveTime: _ambientController.value,
              ),
            ),

            // ── LAYER 5: Controls & Devotional Counter ────────────────────────
            if (!_isCompleted)
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: [< Back] --- [राम] --- [♡ Favorite]
                    _buildTopBar(),

                    const Spacer(),

                    // Subtle bottom gradient protecting counter and controls over sacred water
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.50),
                            Colors.black.withValues(alpha: 0.80),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Devotional Counter directly above Tap Button (0 / 108, 1 / 108...)
                          _buildDevotionalCounter(),

                          const SizedBox(height: 8),

                          // Controls: [Reset] --- [Glowing Jal Tap Button 🌊] --- [Sound]
                          _buildChantingControls(),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── LAYER 6: Final 108 Live Darshan Climax ────────────────────────
            if (_isCompleted)
              JalDarshanClimaxView(
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

  // ── Top Bar (< Back, राम Title, Favorite) ───────────────────────────

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

          // Glowing Devanagari Title "राम"
          Text(
            'राम',
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFB300),
              shadows: const [
                Shadow(color: Color(0xFFFF7700), blurRadius: 12),
              ],
            ),
          ),

          // Right Actions (Prakash & Pushp Switchers & Favorite)
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
                  margin: const EdgeInsets.only(right: 6),
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
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Dedicated Pushp Varsha Mode Switcher
              GestureDetector(
                onTap: () async {
                  _persistProgress();
                  final updated = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PushpVarshaJapScreen(entry: widget.entry),
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
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261217),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF80AB),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.spa_rounded,
                      color: Color(0xFFFF80AB),
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Favorite Heart Button
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC8A882).withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFFC8A882),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Devotional Counter: 0 / 108, 1 / 108... ─────────────────────────

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
                  Shadow(color: Color(0xFFFF9900), blurRadius: 16.0),
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
                color: const Color(0xFFFFD54F),
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
          'श्री राम जय राम जय जय राम',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSerifDevanagari(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFE082),
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Chanting Controls: [Reset] --- [Tap Button 🌊] --- [Sound] ─────

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

          // Center: Glowing Jal Tap Button 🌊
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _tapButtonController,
                child: GestureDetector(
                  onTap: () => _onTapChant(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.25, -0.3),
                        radius: 0.9,
                        colors: [
                          Color(0xFFFFE082),
                          Color(0xFFFF9900),
                          Color(0xFFE65100),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.70),
                          blurRadius: 22.0,
                          spreadRadius: 3.0,
                        ),
                        BoxShadow(
                          color: const Color(0xFF80DEEA).withValues(alpha: 0.40),
                          blurRadius: 14.0,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFF3E0),
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          (_isChantingActive && !_isPaused) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey<bool>(_isChantingActive && !_isPaused),
                          color: Colors.white,
                          size: 40,
                        ),
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
                  color: const Color(0xFFFFD54F),
                ),
              ),
            ],
          ),

          // Right: Sound Toggle Button
          _buildActionButton(
            icon: _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: _isSoundEnabled ? 'Sound' : 'Mute',
            isActive: _isSoundEnabled,
            onTap: () {
              setState(() => _isSoundEnabled = !_isSoundEnabled);
              if (!_isSoundEnabled) _audioPlayer.stop().catchError((_) {});
              _saveSoundPreference(_isSoundEnabled);
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFC8A882).withValues(alpha: 0.40),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFFFB300) : Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFFFD54F) : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14191F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFC8A882), width: 1.2),
        ),
        title: Text(
          'Reset Divine Jal Darshan?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will return your chant count to 0 and re-veil the divine darshan beneath the sacred water pool.',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
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
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performReset();
            },
            child: Text(
              'Reset',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
