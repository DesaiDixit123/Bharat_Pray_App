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
import '../../widgets/dhup_jap/dhup_incense_reveal_painter.dart';
import '../../widgets/dhup_jap/dhup_smoke_painter.dart';
import '../../widgets/dhup_jap/dhup_temple_background.dart';
import '../../widgets/dhup_jap/dhup_burner_widget.dart';
import '../../widgets/dhup_jap/dhup_darshan_climax_view.dart';
import 'jal_jap_screen.dart';
import 'prakash_jap_screen.dart';
import 'pushp_varsha_jap_screen.dart';

/// Master Implementation — Dhup Chanting Effect Screen
/// Inspired by the divine temple incense aesthetic (Section 2 & Mockup):
/// - Traditional brass Dhup Dani / incense burner resting on an altar with scattered rose petals and diyas
/// - Realistic incense smoke rising slowly and gracefully in front of and around the deity
/// - REUSES EXACT SAME image reveal mechanism, 108 reveal nodes, and timing from Ram Ram effect
/// - Top circular counter (0..108) with circular progress arc
/// - Circular glowing "Tap" button with diya icon at the bottom
/// - Independent counter, state management, and persistence
class DhupJapScreen extends StatefulWidget {
  final JapConfig entry;

  const DhupJapScreen({super.key, required this.entry});

  @override
  State<DhupJapScreen> createState() => _DhupJapScreenState();
}

class _DhupJapScreenState extends State<DhupJapScreen>
    with JapVoiceSelection<DhupJapScreen>, TickerProviderStateMixin {
  @override
  JapConfig get japEntry => widget.entry;

  late final int _target = widget.entry.targetCount > 0 ? widget.entry.targetCount : 108;
  late int _count;
  int _completedMalas = 0;
  bool _isCompleted = false;
  bool _isChantingActive = false; // True during single chant flight (button shows ||)
  bool _isPaused = false;

  // Exact reveal nodes for dhoop smoke reveal
  List<DhupRevealNode> _allTargetNodes = [];
  List<DhupRevealNode> _revealedNodes = [];
  DhupRevealNode? _newestNode;
  int _launchedCount = 0; // Tracks launched streams for simultaneous/concurrent Jap taps

  // Directional & Ambient Smoke Simulation
  final List<DirectionalSmokeStream> _activeStreams = [];
  final List<AmbientSmokeWisp> _ambientWisps = [];
  Offset _burnerEmissionPoint = Offset.zero;

  // Animation Controllers
  late final AnimationController _ambientController;
  late final AnimationController _diyaController;
  late final AnimationController _shimmerController;
  late final AnimationController _completionController;
  late final AnimationController _tapButtonController;
  late final AnimationController _flightController;

  // Audio Player
  late final AudioPlayer _audioPlayer;
  bool _isSoundEnabled = true;

  Timer? _syncDebounceTimer;

  String _getLocalDhupDarshanVideoAsset() {
    if (widget.entry.isCustom) return '';
    final name = (widget.entry.displayName.isNotEmpty
            ? widget.entry.displayName
            : widget.entry.name)
        .toLowerCase();
    if (name.contains('ram')) return 'assets/videos/lord_shri_ram_live_darshan.mp4';
    if (name.contains('radha')) return 'assets/videos/radha_live_darshan.mp4';
    if (name.contains('krishna')) return 'assets/videos/krishna_live_darshan.mp4';
    if (name.contains('shiva') || name.contains('shiv')) return 'assets/videos/shiva_live_darshan.mp4';
    if (name.contains('ganesh') || name.contains('ganpati') || name.contains('ganesha')) {
      return 'assets/videos/ganesh_live_darshan.mp4';
    }
    if (name.contains('durga')) return 'assets/videos/durga_live_darshan.mp4';
    if (name.contains('lakshmi') || name.contains('laxmi')) {
      return 'assets/videos/lakshmi_live_darshan.mp4';
    }
    if (name.contains('vishnu')) return 'assets/videos/vishnu_live_darshan.mp4';
    if (name.contains('swaminarayan')) {
      return 'assets/videos/swaminarayan_live_darshan.mp4';
    }
    if (name.contains('ambe') || name.contains('amba')) {
      return 'assets/videos/ambe_live_darshan.mp4';
    }
    if (name.contains('khatu') || name.contains('shyam')) {
      return 'assets/videos/khatu_live_darshan.mp4';
    }
    if (name.contains('hanuman') || name.contains('bajrang')) {
      return 'assets/videos/hanuman_live_darshan.mp4';
    }
    return '';
  }

  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();
    prepareJapVoice();
    refreshJapDarshanVideo();

    // Devotional full-screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize Jap count & reveal state
    _count = widget.entry.progress % _target;
    _completedMalas = widget.entry.progress ~/ _target;
    _isCompleted = false;

    // Initialize randomized target nodes across the portrait
    _initTargetNodes();

    // Diya ignition controller ("divo sarje") on chant tap
    _diyaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      reverseDuration: const Duration(milliseconds: 700),
    );

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

    // Audio completion listener: smoothly returns button to Play ▶ when chant audio finishes
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      final anyInFlight = _activeStreams.any((s) => !s.hasArrived);
      if (!anyInFlight && _isChantingActive) {
        setState(() {
          _isChantingActive = false;
          _isPaused = false;
        });
        _diyaController.reverse();
      }
    });

    // Flight controller synchronized with chant duration
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _flightController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _isChantingActive = false;
          _isPaused = false;
        });
        _diyaController.reverse();
      }
    });

    // Ambient loop controller: drives continuous smoke physics, flame flickers, ember pulsations
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_onAmbientTick)
     ..repeat();

    // Node outline shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Final 108 golden aura bloom
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (_isCompleted) {
      _completionController.value = 1.0;
    }

    // Tap button spring bounce
    _tapButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.90,
      upperBound: 1.0,
    )..value = 1.0;

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isSoundEnabled = prefs.getBool('jap_sound_enabled') ?? true;
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
    _diyaController.dispose();
    _shimmerController.dispose();
    _completionController.dispose();
    _tapButtonController.dispose();
    _flightController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Randomized Target & Organic Shape Generation ──────────────────────

  void _initTargetNodes() {
    final int seed = (widget.entry.id.hashCode ^ (_completedMalas * 7919) ^ 0x5A5A5A5A);
    final math.Random rng = math.Random(seed);

    // 108 master anchor nodes from RamPathCalculator:
    // 0..95: Non-face anchors (halo, lotus, robes, jewels, arms, background)
    // 96..107: Climax face anchors (revealed gracefully at the conclusion)
    final nonFaceIndices = List.generate(96, (i) => i)..shuffle(rng);
    final faceIndices = List.generate(12, (i) => 96 + i)..shuffle(rng);
    final allShuffled = [...nonFaceIndices, ...faceIndices];

    final double baseScale = (_target < 108)
        ? math.pow(108.0 / _target, 0.68).clamp(1.0, 9.0).toDouble()
        : 1.0;

    _allTargetNodes = List.generate(_target, (step) {
      final int anchorIdx = (_target == 108)
          ? allShuffled[step]
          : allShuffled[(step * 108 ~/ _target).clamp(0, 107)];
      final anchor = RamPathCalculator.revealNodes[anchorIdx];

      // Subtle random spatial jitter across the entire sacred deity portrait
      final double uJitter = (rng.nextDouble() - 0.5) * 0.035;
      final double vJitter = (rng.nextDouble() - 0.5) * 0.035;
      // Naturally distribute across the full portrait from halo/crown peak (0.04) down to lotus feet (0.94)
      final double u = (anchor.u + uJitter).clamp(0.04, 0.96);
      final double v = (anchor.v + vJitter).clamp(0.04, 0.94);

      // Bespoke random cloud shape parameters (random lobes, aspect, rotation, scale)
      final int nodeSeed = rng.nextInt(1000000000);
      final int numLobes = 6 + rng.nextInt(5); // 6 to 10 lobes
      final double rotation = rng.nextDouble() * 2 * math.pi;
      final double aspectX = 0.88 + (rng.nextDouble() * 0.28);
      final double aspectY = 0.95 + (rng.nextDouble() * 0.35);
      final double radiusMultiplier = 1.05 + (rng.nextDouble() * 0.30);

      return DhupRevealNode(
        step: step,
        u: u,
        v: v,
        radiusNorm: anchor.radiusNorm * baseScale,
        seed: nodeSeed,
        numLobes: numLobes,
        rotation: rotation,
        aspectX: aspectX,
        aspectY: aspectY,
        radiusMultiplier: radiusMultiplier,
        label: anchor.label,
      );
    });

    if (_count > 0 && _count <= _allTargetNodes.length) {
      _revealedNodes = _allTargetNodes.sublist(0, _count);
      _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
    } else {
      _revealedNodes = [];
      _newestNode = null;
    }
    _launchedCount = _count;
  }

  // ── Incense Smoke Simulation Ticker ──────────────────────────────────

  void _onAmbientTick() {
    const double dt = 0.016; // ~60fps step

    // Advance and prune all active directional incense streams
    if (!_isPaused && _activeStreams.isNotEmpty) {
      for (final s in _activeStreams) {
        s.update(dt);
      }
      _activeStreams.removeWhere((stream) => stream.isFinished);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnBurstSmokePuffs() {
    // Realistic fluid smoke tendrils are dynamically rendered by DhupSmokePainter
  }

  // ── Core Chanting Actions (Play/Pause, Directional Smoke & Sacred Text 'राम') ──

  // ── Manual One-by-One Chanting (Single 'राम' text per Jap, Synchronized with Voice) ──

  void _onTapChant() {
    if (_isCompleted) return;
    // Every click on Play triggers a Jap chant ("jetlli var karu etli var thavu joie")
    _startFlightChant();
  }

  void _startFlightChant() {
    if (_count >= _target) {
      _handle108Completion();
      return;
    }

    // Support simultaneous/concurrent Jap taps so multiple streams fly and reveal together
    if (_launchedCount < _count) {
      _launchedCount = _count;
    }
    if (_launchedCount >= _target) {
      return;
    }

    final int stepToReveal = _launchedCount;
    _launchedCount++;

    final targetNode = (stepToReveal < _allTargetNodes.length)
        ? _allTargetNodes[stepToReveal]
        : _allTargetNodes.last;

    // 2. Set chanting state active
    setState(() {
      _isChantingActive = true;
      _isPaused = false;
    });

    // 3. Spring bounce button feedback
    _tapButtonController.reverse().then((_) {
      if (mounted) _tapButtonController.forward();
    });
    HapticFeedback.lightImpact();

    // 4. Play chant audio (if sound enabled)
    _playChantAudio();

    // 4b. Ignite diya flame immediately on chant click ("divo sarje")
    _diyaController.forward();

    // 4c. Spawn immediate rich burst of incense smoke puffs ("dhuoop aave")
    _spawnBurstSmokePuffs();

    final Size screenSize = MediaQuery.of(context).size;

    // 5. Derive exact random target coordinate on aspect-ratio fitted portrait ("random jagya ae jaay")
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    final targetPoint = Offset(
      dstRect.left + (targetNode.u * dstRect.width),
      dstRect.top + (targetNode.v * dstRect.height),
    );

    final defaultBurnerCenter = Offset(screenSize.width * 0.50, screenSize.height * 0.76);
    final startPoint = _burnerEmissionPoint.dx != 0 ? _burnerEmissionPoint : defaultBurnerCenter;

    // Fast responsive and synchronized flight duration: ~1.0s (sound on) or ~0.65s (muted)
    final double streamDuration = _isSoundEnabled ? 1.0 : 0.65;

    final stream = DirectionalSmokeStream(
      step: stepToReveal,
      start: startPoint,
      target: targetPoint,
      duration: streamDuration,
      dispersalDuration: 1.3,
      text: japMantraText,
      onArrived: () {
        if (!mounted) return;

        setState(() {
          _count = math.min(_target, _count + 1);
          _newestNode = targetNode;
          _revealedNodes = _allTargetNodes.sublist(0, _count);

          // If sound is muted and all active streams have arrived, reset chanting state
          if (!_isSoundEnabled) {
            final anyInFlight = _activeStreams.any((s) => !s.hasArrived);
            if (!anyInFlight) {
              _isChantingActive = false;
              _isPaused = false;
              _diyaController.reverse();
            }
          }
        });

        // Trigger golden shimmer on newly revealed node
        _shimmerController.forward(from: 0.0);
        HapticFeedback.selectionClick();

        // Check for 108 Jap Completion
        if (_count >= _target) {
          _persistProgress();
          // Delay transition by 1.2s so the devotee clearly sees "108 / 108",
          // full unmasking of the deity portrait, and glorious golden shimmer bloom!
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && _count >= _target && !_isCompleted) {
              _handle108Completion();
            }
          });
        } else {
          _persistProgress();
        }
      },
    );

    setState(() {
      _activeStreams.add(stream);
    });

    // Drive flight controller duration: 1800ms when sound on, 1100ms when sound muted
    _flightController.duration = _isSoundEnabled
        ? const Duration(milliseconds: 1800)
        : const Duration(milliseconds: 1100);
    _flightController.forward(from: 0.0);
  }

  Future<void> _playChantAudio() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      if (japChantClipPath != null) {
        await _audioPlayer.play(japChantSource);
        return;
      }
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
      debugPrint('[DhupAudio] Playback exception: $e');
    }
  }

  void _handle108Completion() {
    _flightController.stop();
    setState(() {
      _isChantingActive = false;
      _isPaused = false;
      _isCompleted = true;
      _completedMalas++;
      _revealedNodes = _allTargetNodes; // 100% full reveal
    });
    refreshJapDarshanVideo(notifyIfPending: true);

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
    _diyaController.reset();
    setState(() {
      _count = 0;
      _completedMalas = 0;
      _isCompleted = false;
      _isChantingActive = false;
      _isPaused = false;
      _revealedNodes = [];
      _newestNode = null;
      _activeStreams.clear();
      _ambientWisps.clear();
      _initTargetNodes();
    });

    _shimmerController.reset();
    _completionController.reset();

    HapticFeedback.mediumImpact();
    _persistProgress();
  }

  void _startNextMala() {
    _audioPlayer.stop().catchError((_) {});
    _flightController.reset();
    _diyaController.reset();
    setState(() {
      _count = 0;
      _completedMalas += 1;
      _isCompleted = false;
      _isChantingActive = false;
      _isPaused = false;
      _revealedNodes = [];
      _newestNode = null;
      _activeStreams.clear();
      _ambientWisps.clear();
      _initTargetNodes();
    });
    _completionController.reset();
    _persistProgress();
  }

  void _persistProgress() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await JapOfflineRepository.saveProgress(
          japId: widget.entry.id,
          count: _count,
          completedMalas: _completedMalas,
          targetCount: _target,
        );

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
        if (token.isNotEmpty) {
          await ApiService.syncJapProgress(
            token,
            widget.entry.id,
            _totalProgress,
            completedMalas: _completedMalas,
          );
          await JapOfflineRepository.markSynced(widget.entry.id);
        }
      } catch (e) {
        debugPrint('[DhupJapScreen] Sync error: $e');
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
            // ── LAYER 1: Dark Cinematic Temple Sanctum with Pillars & Lights ──
            DhupTempleBackground(
              flameFlicker: _ambientController.value,
            ),

            // ── LAYER 2: Progressive Lord Shri Ram Reveal ────────────────────
            // Bespoke organic incense smoke plume reveal (ZERO geometric circles!)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (!_isCompleted && _count < _target) {
                  _onTapChant();
                }
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_shimmerController, _completionController]),
                builder: (context, _) {
                  return DhupIncenseRevealWidget(
                    revealedNodes: _revealedNodes,
                    newestNode: _newestNode,
                    shimmerProgress: _shimmerController.value,
                    isCompleted: _isCompleted,
                    completionGlowProgress: _completionController.value,
                    imageAsset: widget.entry.isCustom && widget.entry.darshanImageUrl.isNotEmpty
                        ? widget.entry.darshanImageUrl
                        : 'assets/images/lord_shri_ram_darshan.png',
                    revealProgress: _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0,
                  );
                },
              ),
            ),

            // ── LAYER 3: Volumetric Directional & Ambient Incense Smoke ─────
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: DhupSmokePainter(
                  activeStreams: _activeStreams,
                  ambientWisps: _ambientWisps,
                  burnerMouthCenter: _burnerEmissionPoint,
                  smokeTime: _ambientController.value * 2 * math.pi,
                  smokeIntensity: (_isChantingActive && !_isPaused) ? _diyaController.value : 0.0,
                ),
              ),
            ),

            // ── LAYER 4: Brass Dhup Dani & Sacred Altar Base ──────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 155,
              child: AnimatedBuilder(
                animation: _diyaController,
                builder: (context, _) => DhupBurnerWidget(
                  emberGlow: _ambientController.value,
                  diyaIntensity: _diyaController.value,
                  isChantingActive: _isChantingActive && !_isPaused,
                  onBurnerMouthPositioned: (pos) {
                    if (_burnerEmissionPoint != pos) {
                      setState(() {
                        _burnerEmissionPoint = pos;
                      });
                    }
                  },
                ),
              ),
            ),

            // ── LAYER 5: Controls & Devotional Counter ────────────────────────
            if (!_isCompleted)
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: [< Back] --- [राम] --- [♡ Favorite]
                    _buildTopBar(),

                    buildJapVoiceButton(),

                    const Spacer(),

                    // Devotional Counter directly above Play Button (1 / 108, 2 / 108...)
                    _buildDevotionalCounter(),

                    const SizedBox(height: 8),

                    // Controls: [Reset] --- [Glowing Play Button ▶] --- [Sound]
                    _buildChantingControls(),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // ── LAYER 6: Final 108 Darshan Climax ─────────────────────────────
            if (_isCompleted)
              DhupDarshanClimaxView(
                title: '॥ $japMantraText ॥',
                target: _target,
                videoUrl: japDarshanVideoUrl.isNotEmpty
                    ? japDarshanVideoUrl
                    : _getLocalDhupDarshanVideoAsset(),
                isSoundEnabled: _isSoundEnabled,
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

          // Glowing Devanagari / Display Title
          Text(
            widget.entry.displayName.isNotEmpty
                ? widget.entry.displayName
                : (widget.entry.isCustom ? japMantraText : 'राम'),
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFB300),
              shadows: const [
                Shadow(color: Color(0xFFFF7700), blurRadius: 12),
              ],
            ),
          ),

          // Right action buttons: [Jal Darshan 🌊] & [♡ Favorite]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.entry.isCustom) ...[
              // Jal Darshan Mode Switcher
              GestureDetector(
                onTap: () async {
                  _persistProgress();
                  final updated = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JalJapScreen(entry: widget.entry),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _count = updated % _target;
                      _completedMalas = updated ~/ _target;
                      _isCompleted = _count >= _target;
                      _initTargetNodes();
                    });
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1C24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF80DEEA),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ACC1).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF80DEEA),
                      size: 17,
                    ),
                  ),
                ),
              ),

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
                      _initTargetNodes();
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
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9900).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
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
                      _initTargetNodes();
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
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.spa_rounded,
                      color: Color(0xFFFF80AB),
                      size: 17,
                    ),
                  ),
                ),
              ),

              ],

              // Favorite Heart Button
              Container(
                width: 40,
                height: 40,
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
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Devotional Counter: 1 / 108, 2 / 108, 3 / 108... ─────────────────

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
        if (widget.entry.shlokText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            widget.entry.shlokText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFE082),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Chanting Controls: [Reset] --- [Glowing Play Button ▶] --- [Sound]

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

          // Center: Glowing Orange/Gold Play Button (chants on every tap, "jetlli var karu etli var thavu joie")
          ScaleTransition(
            scale: _tapButtonController,
            child: GestureDetector(
              onTap: _onTapChant,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.25, -0.3),
                    radius: 0.9,
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFF9900),
                      Color(0xFFE65100),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7700).withValues(alpha: _isChantingActive ? 0.90 : 0.65),
                      blurRadius: _isChantingActive ? 28.0 : 20.0,
                      spreadRadius: _isChantingActive ? 4.0 : 2.0,
                    ),
                    const BoxShadow(
                      color: Color(0xFFFFD54F),
                      blurRadius: 12.0,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFFFF3E0),
                    width: 2.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),

          // Right: Sound Toggle Button
          _buildActionButton(
            icon: _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: _isSoundEnabled ? 'Sound' : 'Mute',
            isActive: _isSoundEnabled,
            onTap: () {
              setState(() => _isSoundEnabled = !_isSoundEnabled);
              if (!_isSoundEnabled) {
                _audioPlayer.pause().catchError((_) {});
              } else if (_isChantingActive && !_isPaused) {
                _playChantAudio();
              }
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
        backgroundColor: const Color(0xFF1A1412),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFC8A882), width: 1.2),
        ),
        title: Text(
          'Reset Dhup Jap?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will return your chant count to 0 and re-veil the divine image behind sacred smoke.',
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
