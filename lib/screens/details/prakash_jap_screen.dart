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
import '../../widgets/prakash_jap/prakash_temple_background.dart';
import '../../widgets/prakash_jap/prakash_mandal_painter.dart';
import '../../widgets/prakash_jap/prakash_progressive_reveal_widget.dart';
import '../../widgets/prakash_jap/prakash_darshan_climax_view.dart';
import 'jal_jap_screen.dart';

/// 4th Jap Chanting Effect: Prakash Mandal (Divine Light Reveal).
/// - Deep dark temple sanctum with hanging brass bells and celestial light column.
/// - Concentric sacred golden rings and sunburst rays expand on every Jap tap.
/// - Progressive light-driven reveal of Lord Shri Ram.
/// - Floating golden particles and divine light pulses.
/// - Completely independent state and progress tracking.
class PrakashJapScreen extends StatefulWidget {
  final JapConfig entry;

  const PrakashJapScreen({super.key, required this.entry});

  @override
  State<PrakashJapScreen> createState() => _PrakashJapScreenState();
}

class _PrakashJapScreenState extends State<PrakashJapScreen>
    with TickerProviderStateMixin {
  static const int _target = 108;
  late int _count;
  int _completedMalas = 0;
  bool _isCompleted = false;

  // Exact progressive reveal nodes from RamPathCalculator
  List<RevealNode> _revealedNodes = [];
  RevealNode? _newestNode;

  // Particle Simulation
  final List<GoldenParticle> _particles = [];
  final math.Random _random = math.Random();
  double _particleSpawnTimer = 0.0;

  // Animation Controllers
  late final AnimationController _ambientController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _completionController;
  late final AnimationController _tapButtonController;

  // Audio setup
  late final AudioPlayer _audioPlayer;
  static const int _voicePoolSize = 8;
  final List<AudioPlayer> _voicePlayers = [];
  int _voicePlayerIndex = 0;
  bool _isSoundEnabled = true;

  Timer? _syncDebounceTimer;

  String get _prakashJapId => '${widget.entry.id}_prakash';
  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _count = 0;
    _completedMalas = 0;
    _isCompleted = false;

    // Audio setup
    _audioPlayer = _createChantPlayer();
    for (int i = 0; i < _voicePoolSize; i++) {
      _voicePlayers.add(_createChantPlayer());
    }

    // Continuous ambient loop (4s rotation and breathing)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_onAmbientTick)
     ..repeat();

    // Tap pulse animation (expanding rings pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

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

      // Load independent progress for Prakash Mandal
      final cached = await JapOfflineRepository.getProgress(_prakashJapId,
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
        player.play(AssetSource('audio/ram_chant.mp3')).catchError((_) {});
      }).catchError((_) {
        player.play(AssetSource('audio/ram_chant.mp3')).catchError((_) {});
      });
    } catch (e) {
      debugPrint('[PrakashJap] Voice error: $e');
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
    _pulseController.dispose();
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

  // ── Particle Ticker ──────────────────────────────────────────────────

  void _onAmbientTick() {
    const double dt = 0.016;
    _particleSpawnTimer += dt;

    // Update particle lifetimes
    _particles.removeWhere((p) => !p.update(dt));

    // Spawn ambient floating golden sparkles
    final int maxParticles = 12 + (20 * (_count / _target)).round();
    if (_particleSpawnTimer >= 0.12 && _particles.length < maxParticles) {
      _particleSpawnTimer = 0.0;
      _spawnAmbientParticle();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnAmbientParticle([Offset? customOrigin]) {
    final Size size = MediaQuery.of(context).size;
    final double originX = customOrigin?.dx ??
        (size.width * (0.25 + (_random.nextDouble() * 0.50)));
    final double originY = customOrigin?.dy ??
        (size.height * (0.22 + (_random.nextDouble() * 0.45)));

    final double angle = _random.nextDouble() * 2 * math.pi;
    final double speed = 8.0 + (_random.nextDouble() * 16.0);

    _particles.add(
      GoldenParticle(
        x: originX,
        y: originY,
        vx: math.cos(angle) * speed,
        vy: -(math.sin(angle) * speed).abs() - 10.0, // Rising upward
        radius: 1.5 + (_random.nextDouble() * 2.2),
        maxAlpha: 0.45 + (_random.nextDouble() * 0.50),
        pulseSpeed: 2.0 + (_random.nextDouble() * 3.0),
        maxLife: 2.5 + (_random.nextDouble() * 2.0),
      ),
    );
  }

  // ── Core Chanting Action on Tap ──────────────────────────────────────

  void _onTapChant([Offset? tapPosition]) {
    if (_isCompleted || _count >= _target) return;

    // 1. Button spring bounce feedback
    _tapButtonController.reverse().then((_) {
      if (mounted) _tapButtonController.forward();
    });
    HapticFeedback.lightImpact();

    // 2. Play pure "राम" chant audio on EVERY tap without cut-off!
    _playVoiceChant();

    // 3. Trigger pulse through Prakash Mandal
    _pulseController.forward(from: 0.0);

    // 4. Spawn golden burst particles from halo center
    final Size screenSize = MediaQuery.of(context).size;
    final Offset burstCenter = tapPosition ??
        Offset(screenSize.width * 0.50, screenSize.height * 0.285);

    for (int i = 0; i < 6; i++) {
      _spawnAmbientParticle(burstCenter);
    }

    // 5. Progressively reveal the next node of Lord Shri Ram
    final int nextCount = _count + 1;
    setState(() {
      _count = nextCount;
      _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
      _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
    });

    _shimmerController.forward(from: 0.0);
    HapticFeedback.selectionClick();

    // Check for 108 Jap Completion
    if (_count >= _target) {
      _handle108Completion();
    } else {
      _persistProgress();
    }
  }

  void _handle108Completion() {
    setState(() {
      _isCompleted = true;
      _completedMalas++;
      _revealedNodes = RamPathCalculator.revealNodes; // 100% full reveal
    });

    _completionController.forward(from: 0.0);

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
      _particles.clear();
    });

    _pulseController.reset();
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
      _particles.clear();
    });
    _completionController.reset();
    _persistProgress();
  }

  void _persistProgress() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await JapOfflineRepository.saveProgress(
          japId: _prakashJapId,
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
        debugPrint('[PrakashJapScreen] Sync error: $e');
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
            // ── LAYER 1: Temple Sanctum & Heavenly Light Beam Background ───
            PrakashTempleBackground(
              ambientTime: _ambientController.value,
              lightBeamIntensity: 0.35 + (0.65 * (_count / _target)),
            ),

            // ── LAYER 2: Progressive Lord Shri Ram Light Reveal ───────────
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
                  return PrakashProgressiveRevealWidget(
                    count: _count,
                    targetCount: _target,
                    revealedNodes: _revealedNodes,
                    newestNode: _newestNode,
                    shimmerProgress: _shimmerController.value,
                    isCompleted: _isCompleted,
                    completionGlow: _completionController.value,
                    imageAsset: 'assets/images/ram_deity_transparent.png',
                  );
                },
              ),
            ),

            // ── LAYER 3: Concentric Prakash Mandal Rays & Sparkles ─────────
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _ambientController,
                  _pulseController,
                  _completionController,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: PrakashMandalPainter(
                      count: _count,
                      targetCount: _target,
                      ambientTime: _ambientController.value,
                      pulseValue: _pulseController.value,
                      completionGlow: _completionController.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),

            // ── LAYER 4: Controls & Devotional Counter ─────────────────────
            if (!_isCompleted)
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: [< Back] --- [શ્રી રામ જાપ] --- [Effects / Sound]
                    _buildTopBar(),

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

                          // Controls: [Reset] --- [Glowing Prakash Tap Button ✨] --- [Sound]
                          _buildChantingControls(),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── LAYER 5: Final 108 Climax View ────────────────────────────
            if (_isCompleted)
              PrakashDarshanClimaxView(
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
              color: const Color(0xFFFFD54F),
              shadows: const [
                Shadow(color: Color(0xFFFF9900), blurRadius: 14),
              ],
            ),
          ),

          // Right Switchers & Sound
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dedicated Jal Darshan Mode Switcher
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
                    });
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1C24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF80DEEA),
                      width: 1.0,
                    ),
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
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFFC8A882).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _isSoundEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                      color: _isSoundEnabled
                          ? const Color(0xFFFFD54F)
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
          'શ્રી રામ જય રામ જય જય રામ',
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

  // ── Chanting Controls: [Reset] --- [Tap Button ✨] --- [Sound] ────────

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

          // Center: Glowing Prakash Tap Button ✨
          GestureDetector(
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
                          Color(0xFFFFF9C4),
                          Color(0xFFFFD54F),
                          Color(0xFFFF8F00),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.75),
                          blurRadius: 22.0,
                          spreadRadius: 3.0,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF9900).withValues(alpha: 0.45),
                          blurRadius: 14.0,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFFDE7),
                        width: 2.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF3E2723),
                        size: 34,
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
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.70)
                    : const Color(0xFFC8A882).withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF9900).withValues(alpha: 0.25),
                        blurRadius: 8.0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFFFD54F) : Colors.white60,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E130B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
        ),
        title: Text(
          'Reset Chanting Counter?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will reset your current Prakash Mandal Mala ($_count / $_target) back to 0.',
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
              backgroundColor: const Color(0xFFFF9900),
              foregroundColor: Colors.black,
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
