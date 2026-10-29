import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/jap_models.dart';
import '../../models/jap_theme_config.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import '../../widgets/cinematic_jap/ram_path_calculator.dart';
import '../../widgets/cinematic_jap/single_ram_flight_widget.dart';
import '../../widgets/cinematic_jap/progressive_ram_reveal_painter.dart';
import '../../widgets/cinematic_jap/cinematic_chanting_controls.dart';
import '../../widgets/cinematic_jap/cinematic_darshan_view.dart';
import '../../models/jap_animation_effect.dart';
import '../../widgets/cinematic_jap/effects/multi_effect_ram_reveal_widget.dart';
import '../../widgets/cinematic_jap/effects/shared_vertical_ram_flight_painter.dart';
import '../../widgets/cinematic_jap/effects/jap_effect_selector_sheet.dart';
import 'dhup_jap_screen.dart';
import 'jal_jap_screen.dart';
import 'prakash_jap_screen.dart';
import 'pushp_varsha_jap_screen.dart';

/// Master Implementation — Bharat Pray Flutter App
/// Feature: Cinematic 108 Jap Chanting with Progressive Divine Image Reveal of Lord Shri Ram.
/// - Single "राम" emerges from the center of the circular Rudraksha mala
/// - Slow, divine, meditative trajectory (~3.5 seconds)
/// - Surrounding image and golden aura reveal first
/// - Lord Shri Ram's divine face is revealed LAST as the grand devotional climax
/// - Pure full-screen darshan on 108 Jap completion with zero remaining UI elements
class CinematicJapScreen extends StatefulWidget {
  final JapConfig entry;
  const CinematicJapScreen({super.key, required this.entry});

  @override
  State<CinematicJapScreen> createState() => _CinematicJapScreenState();
}

class _CinematicJapScreenState extends State<CinematicJapScreen>
    with TickerProviderStateMixin {
  static const int _target = 108;
  late int _count;
  int _completedMalas = 0;

  // Selected animation effect (Default: existing approved Live Darshan Effect)
  JapRevealEffectType _selectedEffect = JapRevealEffectType.divineVerticalReveal;

  // Reveal state: feathered organic nodes
  List<RevealNode> _revealedNodes = [];
  RevealNode? _newestNode;

  // Animation Controllers
  late final AnimationController _flightTicker;
  late final AnimationController _shimmerController;
  late final AnimationController _pulseController;
  late final AnimationController _completionController;
  late final AnimationController _uiFadeController;

  // Active flying "राम" text offerings
  final List<CinematicRamFlight> _activeFlights = [];

  // Audio Players: Polyphonic voice pool guarantees EVERY tap plays "राम" voice chant without drops or cutoff
  late final AudioPlayer _audioPlayer;
  static const int _voicePoolSize = 8;
  final List<AudioPlayer> _voicePlayers = [];
  int _voicePlayerIndex = 0;
  bool _isSoundEnabled = true;

  late final JapThemeConfig _theme = JapThemeConfig.resolveFromEntry(
    name: widget.entry.name,
    shlokText: widget.entry.shlokText,
  );

  String get _effectiveImageAsset {
    if (widget.entry.darshanImageUrl.isNotEmpty &&
        widget.entry.darshanImageUrl.startsWith('assets/')) {
      return widget.entry.darshanImageUrl;
    }
    return _theme.imageAsset;
  }

  String get _audioAssetPath {
    final a = _theme.audioAsset;
    return a.startsWith('assets/') ? a.replaceFirst('assets/', '') : a;
  }

  // Flight State
  bool _isFlightAnimating = false;
  Offset? _malaCenterOffset;
  int _chantTrigger = 0;
  bool _isPaused = false;
  bool _isCompleted = false;

  Timer? _syncDebounceTimer;

  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();

    // 1. Full-screen immersive devotional mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 2. Initialize Count & Progress
    _count = widget.entry.progress % _target;
    _completedMalas = widget.entry.progress ~/ _target;
    _isCompleted = false; // Fresh chanting session always active on screen entry

    // Load previously revealed nodes if resuming existing session
    if (_count > 0) {
      _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
      _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
    } else {
      _revealedNodes = [];
      _newestNode = null;
    }

    // 3. Audio Setup (Polyphonic multi-voice pool ensures rapid taps never miss a chant)
    _audioPlayer = _createChantPlayer();
    for (int i = 0; i < _voicePoolSize; i++) {
      _voicePlayers.add(_createChantPlayer());
    }

    // 4. Animation Controllers
    // A. "राम" flight physics ticker: Smooth 60fps trajectory simulation
    _flightTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onFlightTick)
     ..repeat();

    // B. Newly revealed node golden outline shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // C. Active Rudraksha bead pulsing glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // D. Final 108th Jap Completion Golden Bloom
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // E. Mala & Controls UI Fade Controller (Smoothly removes controls at Jap 108)
    _uiFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEffect = await JapEffectSelectorSheet.loadSelectedEffect();
      if (mounted) {
        setState(() {
          _isSoundEnabled = prefs.getBool('jap_sound_enabled') ?? true;
          _selectedEffect = savedEffect;
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

  void _playRamVoiceChant() {
    if (!_isSoundEnabled) return;
    try {
      final player = _voicePlayers[_voicePlayerIndex];
      _voicePlayerIndex = (_voicePlayerIndex + 1) % _voicePoolSize;
      player.stop().then((_) {
        player.play(AssetSource(_audioAssetPath)).catchError((_) {});
      }).catchError((_) {
        player.play(AssetSource(_audioAssetPath)).catchError((_) {});
      });
    } catch (e) {
      debugPrint('[CinematicJapScreen] Voice error: $e');
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
    _flightTicker.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _completionController.dispose();
    _uiFadeController.dispose();
    _stopAllAudio();
    for (final p in _voicePlayers) {
      p.dispose();
    }
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Flight Simulation Ticker ─────────────────────────────────────────

  void _onFlightTick() {
    if (_activeFlights.isEmpty) {
      if (_isFlightAnimating) {
        setState(() {
          _isFlightAnimating = false;
        });
      }
      return;
    }
    const double dt = 0.016;
    _activeFlights.removeWhere((flight) => !flight.update(dt));
    if (mounted) {
      setState(() {});
    }
  }

  // ── Core Jap Chanting Action on Tap ──────────────────────────────────

  void _onCenterButtonTapped() {
    if (_isCompleted || _count >= _target) return;

    // 1. Advance Jap Count immediately on each tap!
    final nextCount = math.min(_target, _count + 1);
    final newlyNode = RamPathCalculator.getNodeForStep(_count);

    // 2. Compute exact target coordinate on the aspect-ratio fitted portrait
    final Size screenSize = MediaQuery.of(context).size;
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    final normTarget = RamPathCalculator.getTargetNormalizedPoint(_count);
    final targetPoint = (_selectedEffect == JapRevealEffectType.divineVerticalReveal)
        ? Offset(
            dstRect.left + (normTarget.dx * dstRect.width),
            dstRect.top + (normTarget.dy * dstRect.height),
          )
        : Offset(
            dstRect.left + (0.50 * dstRect.width),
            dstRect.top + (normTarget.dy * dstRect.height),
          );

    final startPoint = _malaCenterOffset ??
        Offset(screenSize.width * 0.50, screenSize.height * 0.70);

    // 3. Launch flying "राम" text emerging from mala center!
    // The image node reveals ONLY when "राम" arrives at its destination!
    _activeFlights.add(
      CinematicRamFlight(
        step: _count,
        node: newlyNode,
        startPoint: startPoint,
        targetPoint: targetPoint,
        duration: 1.80, // Calibrated meditative flight; reveals image upon arrival
        onArrived: () {
          if (!mounted) return;
          if (!_revealedNodes.any((n) => n.step == newlyNode.step)) {
            _revealedNodes.add(newlyNode);
            _revealedNodes.sort((a, b) => a.step.compareTo(b.step));
          }
          _newestNode = newlyNode;
          _shimmerController.forward(from: 0.0);
          _persistProgress();
        },
      ),
    );

    // 4. Update state: count increments immediately, mala pulses, flight starts
    // (Image reveal is synchronized to "राम" arriving at its target spot)
    setState(() {
      _count = nextCount;
      _chantTrigger++;
      _isFlightAnimating = true;
      _isPaused = false;
    });

    HapticFeedback.lightImpact();

    // 5. Play pure "राम" chant audio on EVERY tap without cut-off!
    _playRamVoiceChant();

    // 6. Check for 108 Jap Completion Sequence
    if (_count >= _target) {
      _handle108CompletionSequence();
    } else {
      _persistProgress();
    }
  }

  /// Exact 108th Jap Completion Sequence (Mandatory Section 7 of Prompt)
  void _handle108CompletionSequence() {
    setState(() {
      _isCompleted = true;
      _completedMalas++;
      _revealedNodes = RamPathCalculator.revealNodes; // 100% full reveal including face
    });

    // Stage 1 & 2: Divine golden light bloom & sacred temple bell
    _completionController.forward(from: 0.0);
    _stopAllAudio();
    if (_isSoundEnabled) {
      _audioPlayer.play(AssetSource('audio/temple_bell.wav')).catchError((_) {});
    }

    // Stage 3: Smoothly remove mala, counter, and controls (950ms fade)
    _uiFadeController.forward(from: 0.0);

    HapticFeedback.heavyImpact();
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
        debugPrint('[CinematicJapScreen] Sync error: $e');
      }
    });
  }

  // ── Chanting Controls Actions ────────────────────────────────────────

  void _onResetTapped() {
    if (_count == 0) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1412),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFC8A882), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Color(0xFFFF9900), size: 24),
            const SizedBox(width: 10),
            Text(
              'Reset Jap Session?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This will return your chant count to 0 and reset the divine image reveal to pure black.',
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
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performReset() {
    _stopAllAudio();
    setState(() {
      _count = 0;
      _completedMalas = 0;
      _chantTrigger = 0;
      _isCompleted = false;
      _revealedNodes = [];
      _newestNode = null;
      _isFlightAnimating = false;
      _isPaused = false;
    });

    _activeFlights.clear();
    _shimmerController.reset();
    _completionController.reset();
    _uiFadeController.reset();

    HapticFeedback.mediumImpact();
    _persistProgress();
  }

  void _onSoundToggled() {
    setState(() {
      _isSoundEnabled = !_isSoundEnabled;
    });
    if (!_isSoundEnabled) {
      _stopAllAudio();
    }
    _saveSoundPreference(_isSoundEnabled);
  }

  void _onPauseToggled() {
    _onCenterButtonTapped();
  }

  // ── Build Method ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _persistProgress();
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Guaranteed deep black baseline
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── LAYER A: Full-Screen Progressive Feathered Divine Reveal ────
            AnimatedBuilder(
              animation: Listenable.merge([_shimmerController, _completionController, _uiFadeController]),
              builder: (context, _) {
                final bool isFullCompleted = _isCompleted || _count >= _target;
                if (_selectedEffect == JapRevealEffectType.divineVerticalReveal) {
                  // MANDATORY PRESERVATION: Exact existing approved widget
                  return ProgressiveRamRevealWidget(
                    revealedNodes: _revealedNodes,
                    newestNode: _newestNode,
                    shimmerProgress: _shimmerController.value,
                    isCompleted: isFullCompleted,
                    completionGlowProgress: _completionController.value,
                    imageAsset: _effectiveImageAsset,
                  );
                } else {
                  // 4 New Selectable Animation Effects
                  return MultiEffectRamRevealWidget(
                    effectType: _selectedEffect,
                    revealedNodes: _revealedNodes,
                    newestNode: _newestNode,
                    shimmerProgress: _shimmerController.value,
                    isCompleted: isFullCompleted,
                    completionGlowProgress: _completionController.value,
                    imageAsset: _effectiveImageAsset,
                  );
                }
              },
            ),

            // ── LAYER B: Chanting Interface (Mala, Counter, Controls) ─────
            // Fades out smoothly on Jap 108 completion
            AnimatedBuilder(
              animation: _uiFadeController,
              builder: (context, child) {
                final double fadeVal = _uiFadeController.value;
                if (fadeVal >= 1.0 && _isCompleted) {
                  // Stage 4: Completely removed. Only Lord Ram darshan remains.
                  return const SizedBox.shrink();
                }
                final double opacity = (1.0 - Curves.easeInOut.transform(fadeVal)).clamp(0.0, 1.0);
                final double scale = 1.0 - (0.12 * fadeVal);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: IgnorePointer(
                      ignoring: _isCompleted,
                      child: child,
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Smooth dark bottom vignette ensuring mala, play button, and counter pop with pristine contrast over any bright revealed image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: screenSize.height * 0.46,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.40),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            stops: const [0.0, 0.42, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      children: [
                        // 1. Top Bar (< Back, ♡ Favorite)
                        _buildTopBar(),

                        // Vast open view keeping the entire middle and upper view clear for Lord Shri Ram's divine reveal
                        const Spacer(),

                        // 2. High-legibility Devotional Counter directly above the mala ring
                        _buildDevotionalCounter(),

                        const SizedBox(height: 10),

                        // 3. Devotional Controls: [Reset] (left) --- [Play Button encircled by Circular Mala] (center) --- [Sound] (right)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return CinematicChantingControls(
                              onChantTap: _onCenterButtonTapped,
                              onResetTap: _onResetTapped,
                              onSoundToggle: _onSoundToggled,
                              onPauseToggle: _onPauseToggled,
                              isSoundEnabled: _isSoundEnabled,
                              isPaused: _isPaused,
                              isChantingActive: _isFlightAnimating && !_isPaused,
                              canChant: !_isCompleted,
                              count: _count,
                              target: _target,
                              pulseValue: _pulseController.value,
                              chantTrigger: _chantTrigger,
                              onMalaCenterCalculated: (center) {
                                if (_malaCenterOffset != center) {
                                  setState(() {
                                    _malaCenterOffset = center;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── LAYER C: Single/Multiple Glowing Devanagari Text Flight ───────
            // Visual-only flying flight. Never intercepts user touches.
            if (_activeFlights.isNotEmpty)
              IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MultiRamFlightPainter(
                      flights: _activeFlights,
                      effectType: _selectedEffect,
                      screenSize: screenSize,
                      chantText: _theme.mantraText,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),

            // ── LAYER D: Stage 4 Full-Screen Divine Darshan ────────────────
            // Shown when 108 Jap completed and UI faded away into living darshan video
            if (_isCompleted)
              AnimatedBuilder(
                animation: _uiFadeController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _uiFadeController.value.clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: _uiFadeController.value < 0.85,
                      child: CinematicDarshanView(
                        imageAsset: _effectiveImageAsset,
                        videoAsset: widget.entry.name.toLowerCase().contains('ram')
                            ? 'assets/videos/lord_shri_ram_live_darshan.mp4'
                            : null,
                        isSoundEnabled: _isSoundEnabled,
                        onExitRequested: () {
                          Navigator.maybePop(context, _totalProgress);
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevotionalCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 18.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                '$_count',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: const [
                    Shadow(color: Color(0xFFFF9900), blurRadius: 14.0),
                    Shadow(color: Colors.black, blurRadius: 8.0, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '/ $_target',
                style: GoogleFonts.outfit(
                  fontSize: 14,
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
          const SizedBox(height: 3),

          // Devotional chant subtitle
          Text(
            _theme.mantraText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFE082),
              letterSpacing: 1.2,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC8A882).withValues(alpha: 0.35),
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

          // Glowing Devanagari Title
          Text(
            _theme.mantraText,
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFB300),
              shadows: const [
                Shadow(color: Color(0xFFFF7700), blurRadius: 12),
              ],
            ),
          ),

          // Right Actions: [Dhup Mode] & [Effect Selector] & [Favorite Heart]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dedicated Dhup Chanting Mode Switcher
              GestureDetector(
                onTap: () async {
                  if (_isFlightAnimating) return;
                  _persistProgress();
                  final updated = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DhupJapScreen(entry: widget.entry),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _count = updated % _target;
                      _completedMalas = updated ~/ _target;
                      _isCompleted = _count >= _target;
                      if (_count > 0 && !_isCompleted) {
                        _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
                        _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
                      } else if (_count == 0) {
                        _revealedNodes = [];
                        _newestNode = null;
                      }
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E140F),
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
                      Icons.waves_rounded,
                      color: Color(0xFFFFD54F),
                      size: 19,
                    ),
                  ),
                ),
              ),

              // Dedicated Jal Darshan Mode Switcher
              GestureDetector(
                onTap: () async {
                  if (_isFlightAnimating) return;
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
                      if (_count > 0 && !_isCompleted) {
                        _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
                        _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
                      } else if (_count == 0) {
                        _revealedNodes = [];
                        _newestNode = null;
                      }
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
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
                      size: 19,
                    ),
                  ),
                ),
              ),

              // Dedicated Prakash Mandal Mode Switcher
              GestureDetector(
                onTap: () async {
                  if (_isFlightAnimating) return;
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
                      if (_count > 0 && !_isCompleted) {
                        _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
                        _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
                      } else if (_count == 0) {
                        _revealedNodes = [];
                        _newestNode = null;
                      }
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
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
                      Icons.light_mode_rounded,
                      color: Color(0xFFFFD54F),
                      size: 19,
                    ),
                  ),
                ),
              ),

              // Dedicated Pushp Varsha Mode Switcher
              GestureDetector(
                onTap: () async {
                  if (_isFlightAnimating) return;
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
                      if (_count > 0 && !_isCompleted) {
                        _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count);
                        _newestNode = _revealedNodes.isNotEmpty ? _revealedNodes.last : null;
                      } else if (_count == 0) {
                        _revealedNodes = [];
                        _newestNode = null;
                      }
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
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
                      size: 19,
                    ),
                  ),
                ),
              ),

              // Animation Effect Selector Button
              GestureDetector(
                onTap: () {
                  if (_isFlightAnimating) return;
                  JapEffectSelectorSheet.show(
                    context,
                    currentEffect: _selectedEffect,
                    onEffectSelected: (newEffect) {
                      setState(() {
                        _selectedEffect = newEffect;
                      });
                    },
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.50),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFB300),
                      size: 19,
                    ),
                  ),
                ),
              ),

              // Favorite Heart Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
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
}

/// CustomPainter that renders multiple concurrent flying "राम" offerings,
/// ensuring every single tap produces an advancing text without blocking.
class MultiRamFlightPainter extends CustomPainter {
  final List<CinematicRamFlight> flights;
  final JapRevealEffectType effectType;
  final Size screenSize;
  final String chantText;

  MultiRamFlightPainter({
    required this.flights,
    required this.effectType,
    required this.screenSize,
    this.chantText = 'राम',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (flights.isEmpty) return;
    for (final flight in flights) {
      if (flight.progress <= 0.0 || flight.progress >= 1.0) continue;
      if (effectType == JapRevealEffectType.divineVerticalReveal) {
        final painter = SingleRamFlightPainter(
          progress: flight.progress,
          malaCenter: flight.startPoint,
          targetPoint: flight.targetPoint,
          screenSize: screenSize,
          chantText: chantText,
        );
        painter.paint(canvas, size);
      } else {
        final painter = SharedVerticalRamFlightPainter(
          progress: flight.progress,
          startPoint: flight.startPoint,
          targetPoint: flight.targetPoint,
          screenSize: screenSize,
          chantText: chantText,
        );
        painter.paint(canvas, size);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MultiRamFlightPainter oldDelegate) => true;
}

