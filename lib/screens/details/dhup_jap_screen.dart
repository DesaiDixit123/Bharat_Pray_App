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

  static const int _target = 108;
  late int _count;
  int _completedMalas = 0;
  bool _isCompleted = false;
  bool _isChantingActive = false; // True during single chant flight (button shows ||)
  bool _isPaused = false;

  // Exact reveal nodes from RamPathCalculator
  List<RevealNode> _revealedNodes = [];
  RevealNode? _newestNode;

  // Directional & Ambient Smoke Simulation
  final List<DirectionalSmokeStream> _activeStreams = [];
  final List<AmbientSmokeWisp> _ambientWisps = [];
  Offset _burnerEmissionPoint = Offset.zero;
  double _smokeSpawnTimer = 0.0;
  final math.Random _random = math.Random();

  // Animation Controllers
  late final AnimationController _ambientController;
  late final AnimationController _shimmerController;
  late final AnimationController _completionController;
  late final AnimationController _tapButtonController;
  late final AnimationController _flightController;

  // Audio Player
  late final AudioPlayer _audioPlayer;
  bool _isSoundEnabled = true;

  Timer? _syncDebounceTimer;

  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();
    prepareJapVoice();

    // Devotional full-screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize Jap count & reveal state
    _count = widget.entry.progress % _target;
    _completedMalas = widget.entry.progress ~/ _target;
    _isCompleted = false;

    if (_count > 0) {
      _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
      _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
    } else {
      _revealedNodes = [];
      _newestNode = null;
    }

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
      if (_isChantingActive) {
        setState(() {
          _isChantingActive = false;
          _isPaused = false;
        });
      }
    });

    // Flight controller strictly synchronized with voice audio (5280ms duration)
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5280),
    );

    _flightController.addListener(() {
      if (!_isChantingActive || _isPaused) return;
      // When sound is enabled, arrival is at 0.72 (~3.8s, matching "जय जय राम")
      // When sound is disabled (muted), arrival is at 0.78 (~740ms)
      final double arrivalFraction = _isSoundEnabled ? 0.72 : 0.78;
      final double flightVal = _flightController.value;
      final double streamProgress = (flightVal / arrivalFraction).clamp(0.0, 1.0);

      for (final s in _activeStreams) {
        if (!s.hasArrived) {
          s.update(0.016, forcedProgress: streamProgress);
        }
      }
    });

    _flightController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _isChantingActive = false;
          _isPaused = false;
        });
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
    _shimmerController.dispose();
    _completionController.dispose();
    _tapButtonController.dispose();
    _flightController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Incense Smoke Simulation Ticker ──────────────────────────────────

  void _onAmbientTick() {
    const double dt = 0.016; // ~60fps step
    _smokeSpawnTimer += dt;

    // Prune finished directional streams and update active ones
    if (!_isPaused) {
      _activeStreams.removeWhere((stream) => stream.isFinished);
      for (final s in _activeStreams) {
        if (s.hasArrived) {
          s.update(dt);
        }
      }
    }

    // Prune expired ambient wisps and update active ones
    _ambientWisps.removeWhere((wisp) => !wisp.update(dt));

    // Spawn peaceful continuous ambient smoke wisps from burner (~3 per second)
    if (_smokeSpawnTimer >= 0.28) {
      _smokeSpawnTimer = 0.0;
      _spawnAmbientSmokeWisp();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnAmbientSmokeWisp() {
    final Size size = MediaQuery.of(context).size;
    final double originX = _burnerEmissionPoint.dx != 0 ? _burnerEmissionPoint.dx : (size.width * 0.50);
    final double originY = _burnerEmissionPoint.dy != 0 ? _burnerEmissionPoint.dy : (size.height * 0.76);

    // Subtle jitter from different incense sticks
    final double sx = originX + ((_random.nextDouble() - 0.5) * 22.0);
    final double sy = originY + ((_random.nextDouble() - 0.5) * 8.0);

    _ambientWisps.add(
      AmbientSmokeWisp(
        startX: sx,
        startY: sy,
        vy: -75.0 - (_random.nextDouble() * 50.0), // Calm upward drift
        waveFreq: 0.8 + (_random.nextDouble() * 0.6),
        waveAmp: 26.0 + (_random.nextDouble() * 26.0),
        wavePhase: _random.nextDouble() * 2 * math.pi,
        maxRadius: 40.0 + (_random.nextDouble() * 28.0),
        maxAlpha: 0.65, // Highly visible rich smoke
        duration: 3.5 + (_random.nextDouble() * 2.0),
        color: const Color(0xFFFFFDE7),
      ),
    );
  }

  // ── Core Chanting Actions (Play/Pause, Directional Smoke & Sacred Text 'राम') ──

  // ── Manual One-by-One Chanting (Single 'राम' text per Jap, Synchronized with Voice) ──

  void _onTapChant() {
    if (_isCompleted) return;

    if (_isChantingActive) {
      if (!_isPaused) {
        // Voice is playing -> Tap pauses playback!
        setState(() {
          _isPaused = true;
        });
        _flightController.stop();
        if (_isSoundEnabled) {
          _audioPlayer.pause().catchError((_) {});
        }
        HapticFeedback.selectionClick();
      } else {
        // Paused -> Tap resumes playback!
        setState(() {
          _isPaused = false;
        });
        _flightController.forward();
        if (_isSoundEnabled) {
          _audioPlayer.resume().catchError((_) {});
        }
        HapticFeedback.selectionClick();
      }
    } else {
      // Idle -> Tap starts single chant & keeps play button active as long as voice plays!
      _isPaused = false;
      _startFlightChant();
    }
  }

  void _startFlightChant() {
    if (_count >= _target) {
      _handle108Completion();
      return;
    }

    // 1. Finalize any lingering in-flight stream so strictly ONE 'राम' text is on screen
    if (_activeStreams.isNotEmpty) {
      for (final s in _activeStreams) {
        if (!s.hasArrived) {
          s.hasArrived = true;
          s.onArrived();
        }
      }
      _activeStreams.clear();
    }

    // 2. Set chanting state active (button turns to || "pause" during voice playback)
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

    final Size screenSize = MediaQuery.of(context).size;
    final int stepToReveal = _count; // Current Jap step to reveal
    final targetNode = RamPathCalculator.getNodeForStep(stepToReveal);

    // 5. Derive exact target coordinate on aspect-ratio fitted portrait
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    final targetPoint = Offset(
      dstRect.left + (targetNode.u * dstRect.width),
      dstRect.top + (targetNode.v * dstRect.height),
    );

    final defaultBurnerCenter = Offset(screenSize.width * 0.50, screenSize.height * 0.76);
    final startPoint = _burnerEmissionPoint.dx != 0 ? _burnerEmissionPoint : defaultBurnerCenter;

    // 6. Launch single dynamic stream with strictly ONE glowing 'राम' text
    // Synchronized with voice: when sound is enabled, travels for 3.8s (matching "जय जय राम" crescendo)
    // When sound is disabled (muted/test), travels 0.75s for fast responsive tapping
    final double streamDuration = _isSoundEnabled ? 3.8 : 0.75;

    final stream = DirectionalSmokeStream(
      step: stepToReveal,
      start: startPoint,
      target: targetPoint,
      duration: streamDuration,
      text: 'राम',
      onArrived: () {
        if (!mounted) return;

        setState(() {
          _count = math.min(_target, stepToReveal + 1);
          _newestNode = targetNode;
          _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
          // If sound is muted, chant finishes immediately upon arrival
          if (!_isSoundEnabled) {
            _isChantingActive = false;
            _isPaused = false;
          }
        });

        // Trigger golden shimmer on newly revealed node
        _shimmerController.forward(from: 0.0);
        HapticFeedback.selectionClick();

        // Check for 108 Jap Completion
        if (_count >= _target) {
          _handle108Completion();
        } else {
          _persistProgress();
        }
      },
    );

    setState(() {
      _activeStreams.add(stream);
    });

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
      _newestNode = null;
      _activeStreams.clear();
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
      _newestNode = null;
      _activeStreams.clear();
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
                    imageAsset: 'assets/images/lord_shri_ram_darshan.png',
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
                ),
              ),
            ),

            // ── LAYER 4: Brass Dhup Dani & Sacred Altar Base ──────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 155,
              child: DhupBurnerWidget(
                emberGlow: _ambientController.value,
                onBurnerMouthPositioned: (pos) {
                  if (_burnerEmissionPoint != pos) {
                    setState(() {
                      _burnerEmissionPoint = pos;
                    });
                  }
                },
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

          // Right action buttons: [Jal Darshan 🌊] & [♡ Favorite]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      _revealedNodes = _count > 0 ? RamPathCalculator.getRevealedNodesForCount(_count) : [];
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
                      _revealedNodes = _count > 0 ? RamPathCalculator.getRevealedNodesForCount(_count) : [];
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
                      _revealedNodes = _count > 0 ? RamPathCalculator.getRevealedNodesForCount(_count) : [];
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

          // Center: Glowing Orange/Gold Play Button (shows || "pause" while chanting)
          ScaleTransition(
            scale: _tapButtonController,
            child: GestureDetector(
              onTap: _onTapChant,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.3),
                    radius: 0.9,
                    colors: (_isChantingActive && !_isPaused)
                        ? const [
                            Color(0xFFFFB300),
                            Color(0xFFFF6D00),
                            Color(0xFFD84315),
                          ]
                        : const [
                            Color(0xFFFFD54F),
                            Color(0xFFFF9900),
                            Color(0xFFE65100),
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7700).withValues(alpha: (_isChantingActive && !_isPaused) ? 0.85 : 0.65),
                      blurRadius: (_isChantingActive && !_isPaused) ? 26.0 : 20.0,
                      spreadRadius: (_isChantingActive && !_isPaused) ? 4.0 : 2.0,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                      blurRadius: 12.0,
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
