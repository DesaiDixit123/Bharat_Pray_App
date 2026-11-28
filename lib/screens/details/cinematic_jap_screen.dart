import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/jap_models.dart';
import '../../widgets/jap/jap_voice_selection.dart';
import '../../models/jap_theme_config.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import '../../services/jap_background_dhun_service.dart';
import '../../services/jap_video_preloader.dart';
import '../../services/saved_items_service.dart';
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
    with JapVoiceSelection<CinematicJapScreen>, TickerProviderStateMixin {
  @override
  JapConfig get japEntry => widget.entry;

  int _target = 108;
  int _count = 0;
  int _completedMalas = 0;

  // Dedicated background instrumental music service
  final JapBackgroundDhunService _dhunService = JapBackgroundDhunService();
  bool _isVoiceEnabled = true;
  double _voiceVolume = 1.0;
  bool _isMusicEnabled = true;
  double _musicVolume = 0.22;
  bool _isInstrumentalOnly = false;
  bool _isAutoChanting = false;
  Timer? _autoChantTimer;
  bool _isMantraHighlighted = false;

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

  // Active flying mantra text offerings
  final List<CinematicRamFlight> _activeFlights = [];

  // Audio Players: Polyphonic voice pool guarantees EVERY chant plays voice without drops or cutoff
  late final AudioPlayer _audioPlayer;
  static const int _voicePoolSize = 8;
  final List<AudioPlayer> _voicePlayers = [];
  int _voicePlayerIndex = 0;
  bool _isSoundEnabled = true;
  bool _isFavouriteJap = false;
  bool _isSavedJap = false;

  Future<void> _loadFavAndSavedState() async {
    final japId = widget.entry.id;
    final fav = await SavedItemsService.isJapFavourite(japId);
    final saved = await SavedItemsService.isJapSaved(japId);
    if (mounted) {
      setState(() {
        _isFavouriteJap = fav;
        _isSavedJap = saved;
      });
    }
  }

  Map<String, dynamic> _japPayloadMap() => {
        'id': widget.entry.id,
        'title': _effectiveFullName,
        'subtitle': _effectiveMantraText,
        'image': widget.entry.thumbnailUrl.isNotEmpty
            ? widget.entry.thumbnailUrl
            : widget.entry.darshanImageUrl,
        'targetCount': _target,
      };

  Future<void> _toggleFavouriteJap() async {
    final nowFav = await SavedItemsService.toggleFavouriteJap(_japPayloadMap());
    if (!mounted) return;
    setState(() => _isFavouriteJap = nowFav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFav ? 'Added to Your Favourites ❤️' : 'Removed from Your Favourites'),
        backgroundColor: const Color(0xFFFF7700),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleSaveJap() async {
    final nowSaved = await SavedItemsService.toggleSaveJap(_japPayloadMap());
    if (!mounted) return;
    setState(() => _isSavedJap = nowSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowSaved ? 'Saved to Saved Library 🔖' : 'Removed from Saved Library'),
        backgroundColor: const Color(0xFFFF7700),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  late final JapThemeConfig _theme = JapThemeConfig.resolveFromEntry(
    name: widget.entry.displayName.isNotEmpty ? widget.entry.displayName : widget.entry.name,
    shlokText: widget.entry.mantraText.isNotEmpty ? widget.entry.mantraText : widget.entry.shlokText,
  );

  String get _effectiveDisplayName => widget.entry.displayName.isNotEmpty
      ? widget.entry.displayName
      : (widget.entry.name.isNotEmpty ? widget.entry.name : _theme.displayName);

  String get _effectiveFullName => widget.entry.fullName.isNotEmpty
      ? widget.entry.fullName
      : (widget.entry.name.isNotEmpty ? widget.entry.name : _theme.fullName);

  String get _effectiveMantraText => widget.entry.mantraText.isNotEmpty
      ? widget.entry.mantraText
      : (widget.entry.shlokText.isNotEmpty ? widget.entry.shlokText : _theme.mantraText);

  String get _effectiveImageAsset => japEffectiveImageAsset;

  /// Returns the local asset path for the live darshan video of this deity.
  /// Returns null if no local video is available (e.g. custom jap or deity not yet produced).
  String? _getLocalDarshanVideoAsset() {
    if (widget.entry.isCustom) return null;
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
    return null;
  }

  // Flight State
  bool _isFlightAnimating = false;
  Offset? _malaCenterOffset;
  int _chantTrigger = 0;
  bool _isPaused = false;
  bool _isCompleted = false;

  Timer? _syncDebounceTimer;
  VideoPlayerController? _preloadedDarshanController;
  bool _isWarmingDarshanVideo = false;

  Future<void> _warmUpDarshanController() async {
    if (_preloadedDarshanController != null || _isWarmingDarshanVideo) return;
    _isWarmingDarshanVideo = true;
    try {
      final ctrl = await JapVideoPreloader.createInitializedController(
        videoUrl: japDarshanVideoUrl,
        fallbackAsset: _getLocalDarshanVideoAsset(),
        isSoundEnabled: _isSoundEnabled,
      );
      if (!mounted) {
        await ctrl?.dispose();
        return;
      }
      if (ctrl != null) {
        _preloadedDarshanController = ctrl;
        if (_isCompleted) {
          setState(() {});
        }
      }
    } finally {
      _isWarmingDarshanVideo = false;
    }
  }

  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Count & Progress FIRST before any mixin or async callbacks
    _target = widget.entry.targetCount > 0 ? widget.entry.targetCount : 108;
    _count = widget.entry.progress.clamp(0, _target);
    _completedMalas = _count >= _target ? 1 : 0;
    _isCompleted = _count >= _target;

    // 2. Mixin voice & live darshan initialization
    prepareJapVoice();
    _loadFavAndSavedState();
    refreshJapDarshanVideo();
    // Immediately prefetch MongoDB GridFS video & pre-initialize controller on screen open
    // so ANY admin targetCount (5, 11, 35, 108, etc.) plays Live Darshan in 0ms on completion!
    if (japDarshanVideoUrl.isNotEmpty) {
      JapVideoPreloader.prefetch(japDarshanVideoUrl).then((_) {
        if (mounted) _warmUpDarshanController();
      });
    } else {
      _warmUpDarshanController();
    }

    // 3. Full-screen immersive devotional mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Load previously revealed nodes if resuming existing session
    if (_isCompleted) {
      _revealedNodes = RamPathCalculator.revealNodes;
      _newestNode = _revealedNodes.last;
    } else if (_count > 0) {
      _revealedNodes = RamPathCalculator.getRevealedNodesForCount(_count, target: _target);
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

    // If opened directly in completed state ("View Darshan"), show live darshan video immediately
    if (_isCompleted) {
      _completionController.value = 1.0;
      _uiFadeController.value = 1.0;
    }

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEffect = await JapEffectSelectorSheet.loadSelectedEffect();
      if (mounted) {
        setState(() {
          _isSoundEnabled = prefs.getBool('jap_sound_enabled') ?? true;
          _isVoiceEnabled = widget.entry.voiceEnabled && (prefs.getBool('jap_voice_enabled') ?? true);
          _isMusicEnabled = widget.entry.musicEnabled && (prefs.getBool('jap_music_enabled') ?? true);
          _isInstrumentalOnly = prefs.getBool('jap_instrumental_only') ?? false;
          _voiceVolume = prefs.getDouble('jap_voice_volume') ?? 1.0;
          final savedMusicVol = prefs.getDouble('jap_music_volume');
          _musicVolume = (savedMusicVol != null && savedMusicVol <= 0.35) ? savedMusicVol : 0.22;
          _selectedEffect = savedEffect;
        });
        if (_isSoundEnabled && _isMusicEnabled) {
          _dhunService.playForDeity(
            deityId: _theme.id,
            deityName: _theme.fullName,
            customTrack: widget.entry.backgroundMusic,
            enabled: true,
            volume: _musicVolume,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _initBackgroundDhun() async {
    await _loadPreferences();
  }

  Future<void> _saveAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('jap_sound_enabled', _isSoundEnabled);
      await prefs.setBool('jap_voice_enabled', _isVoiceEnabled);
      await prefs.setBool('jap_music_enabled', _isMusicEnabled);
      await prefs.setBool('jap_instrumental_only', _isInstrumentalOnly);
      await prefs.setDouble('jap_voice_volume', _voiceVolume);
      await prefs.setDouble('jap_music_volume', _musicVolume);
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
    if (!_isSoundEnabled || !_isVoiceEnabled || _isInstrumentalOnly) return;
    try {
      setState(() => _isMantraHighlighted = true);
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _isMantraHighlighted = false);
      });

      final player = _voicePlayers[_voicePlayerIndex];
      _voicePlayerIndex = (_voicePlayerIndex + 1) % _voicePoolSize;
      player.setVolume(_voiceVolume);
      player.stop().then((_) {
        player.play(japChantSource).catchError((_) {});
      }).catchError((_) {
        player.play(japChantSource).catchError((_) {});
      });
    } catch (e) {
      debugPrint('[CinematicJapScreen] Voice error: $e');
    }
  }

  void _stopAllAudio() {
    _autoChantTimer?.cancel();
    _audioPlayer.stop().catchError((_) {});
    for (final p in _voicePlayers) {
      p.stop().catchError((_) {});
    }
    _dhunService.stop();
  }

  @override
  void dispose() {
    _autoChantTimer?.cancel();
    _syncDebounceTimer?.cancel();
    _flightTicker.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _completionController.dispose();
    _uiFadeController.dispose();
    _preloadedDarshanController?.dispose();
    _preloadedDarshanController = null;
    _stopAllAudio();
    _dhunService.dispose();
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
    if (_isCompleted) return;
    _executeChantStep();
  }

  void _executeChantStep() {
    if (_isCompleted || _count >= _target) return;

    if (_isSoundEnabled && _isMusicEnabled && !_dhunService.isPlaying) {
      _dhunService.playForDeity(
        deityId: _theme.id,
        deityName: _theme.fullName,
        customTrack: widget.entry.backgroundMusic,
        enabled: true,
        volume: _musicVolume,
      );
    }

    // 1. Advance Jap Count immediately on each tap!
    final nextCount = math.min(_target, _count + 1);
    final newlyNode = RamPathCalculator.getNodeForStep(_count, target: _target);

    // 2. Compute exact target coordinate on the aspect-ratio fitted portrait
    final Size screenSize = MediaQuery.of(context).size;
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    final normTarget = RamPathCalculator.getTargetNormalizedPoint(_count, target: _target);
    // Always fly directly to the exact random/dispersed reveal node position
    final targetPoint = Offset(
      dstRect.left + (normTarget.dx * dstRect.width),
      dstRect.top + (normTarget.dy * dstRect.height),
    );

    final startPoint = _malaCenterOffset ??
        Offset(screenSize.width * 0.50, screenSize.height * 0.70);

    // 3. Launch flying mantra text emerging from mala center!
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
    setState(() {
      _count = nextCount;
      _chantTrigger++;
      _isFlightAnimating = true;
      _isPaused = false;
    });

    HapticFeedback.lightImpact();

    // 5. Play exact matching voice chant audio
    _playRamVoiceChant();

    // 5B. Pre-initialize Live Darshan video controller 5 chants before 108/108 so completion is 0ms INSTANT!
    if (_count >= (_target - 5).clamp(1, _target) && _preloadedDarshanController == null) {
      _warmUpDarshanController();
    }

    // 6. Check for Jap Completion Sequence
    if (_count >= _target) {
      _isAutoChanting = false;
      _autoChantTimer?.cancel();
      _handle108CompletionSequence();
    } else {
      _persistProgress();
      if (_isAutoChanting) {
        _autoChantTimer?.cancel();
        _autoChantTimer = Timer(const Duration(milliseconds: 3200), () {
          if (mounted && _isAutoChanting && !_isPaused && _count < _target) {
            _executeChantStep();
          }
        });
      }
    }
  }

  void _toggleAutoChanting() {
    if (_isCompleted) return;
    setState(() {
      _isAutoChanting = !_isAutoChanting;
      _isPaused = !_isAutoChanting;
    });

    if (_isAutoChanting) {
      if (_isSoundEnabled && _isMusicEnabled) {
        _dhunService.playForDeity(
          deityId: _theme.id,
          deityName: _theme.fullName,
          customTrack: widget.entry.backgroundMusic,
          enabled: true,
          volume: _musicVolume,
        );
      }
      _executeChantStep();
    } else {
      _autoChantTimer?.cancel();
      _dhunService.pause();
    }
  }

  /// Exact 108th Jap Completion Sequence (Mandatory Section 7 of Prompt)
  void _handle108CompletionSequence() {
    setState(() {
      _isCompleted = true;
      _completedMalas++;
      _revealedNodes = RamPathCalculator.revealNodes; // 100% full reveal including face
    });
    refreshJapDarshanVideo(notifyIfPending: true);

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

  void _persistProgress({bool immediate = false}) {
    final int clampedCount = _count.clamp(0, _target);
    final int malas = _completedMalas;

    Future<void> runSave() async {
      try {
        await JapOfflineRepository.saveProgress(
          japId: widget.entry.id,
          count: clampedCount,
          completedMalas: malas,
          targetCount: _target,
        );

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
        if (token.isNotEmpty && widget.entry.id.length == 24) {
          await ApiService.syncJapProgress(
            token,
            widget.entry.id,
            clampedCount,
            completedMalas: malas,
          );
          await JapOfflineRepository.markSynced(widget.entry.id);
        }
      } catch (e) {
        debugPrint('[CinematicJapScreen] Sync error: $e');
      }
    }

    _syncDebounceTimer?.cancel();
    if (immediate) {
      runSave();
    } else {
      _syncDebounceTimer = Timer(const Duration(milliseconds: 500), runSave);
    }
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
    _syncDebounceTimer?.cancel();
    JapOfflineRepository.resetProgress(widget.entry.id);
    SharedPreferences.getInstance().then((prefs) {
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      if (token.isNotEmpty && widget.entry.id.length == 24) {
        ApiService.resetJapProgress(token, widget.entry.id).catchError((_) => <String, dynamic>{});
      }
    });
  }

  void _onSoundToggled() {
    _showAudioAndMalaControlsSheet();
  }

  void _onPauseToggled() {
    _toggleAutoChanting();
  }

  void _showMalaTargetPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161210),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Mala Target',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTargetOption(ctx, 108, '108 Jap (1 Mala)'),
                _buildTargetOption(ctx, 1008, '1008 Jap (Maha Mala)'),
                _buildCustomTargetOption(ctx),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetOption(BuildContext ctx, int count, String label) {
    final isSelected = _target == count;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF9900).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF9900) : Colors.white12,
          width: 1.2,
        ),
      ),
      child: ListTile(
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9900)) : null,
        onTap: () {
          setState(() {
            _target = count;
            _count = _count % _target;
          });
          Navigator.pop(ctx);
          _persistProgress();
        },
      ),
    );
  }

  Widget _buildCustomTargetOption(BuildContext ctx) {
    final isCustom = _target != 108 && _target != 1008;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCustom ? const Color(0xFFFF9900).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCustom ? const Color(0xFFFF9900) : Colors.white12,
          width: 1.2,
        ),
      ),
      child: ListTile(
        title: Text(
          isCustom ? 'Custom Target ($_target Jap)' : 'Custom Target Count...',
          style: GoogleFonts.outfit(
            color: isCustom ? const Color(0xFFFFD54F) : Colors.white,
            fontWeight: isCustom ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.edit_rounded, color: Color(0xFFFFD54F), size: 18),
        onTap: () {
          Navigator.pop(ctx);
          _promptCustomTarget();
        },
      ),
    );
  }

  void _promptCustomTarget() {
    final controller = TextEditingController(text: '$_target');
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1815),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFC8A882), width: 1.2),
        ),
        title: Text(
          'Set Custom Jap Target',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Enter target count (e.g. 54, 108, 1008)',
            hintStyle: GoogleFonts.outfit(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFFF9900).withValues(alpha: 0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF9900), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9900),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                setState(() {
                  _target = val;
                  _count = _count % _target;
                });
                _persistProgress();
              }
              Navigator.pop(dlgCtx);
            },
            child: Text('Save Target', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTarget(StateSetter setSheetState, int count, String label) {
    final isSelected = _target == count;
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _target = count;
          _count = _count % _target;
        });
        setState(() {});
        _persistProgress();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9900) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD54F) : Colors.white12,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  void _showAudioAndMalaControlsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161210),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jap Audio & Chanting Controls',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Chanting Play / Pause / Stop Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAutoChanting ? const Color(0xFFE65100) : const Color(0xFFFF9900),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(_isAutoChanting ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                            label: Text(
                              _isAutoChanting ? 'Pause Chanting' : (_isPaused ? 'Resume Chanting' : 'Start Chanting'),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _toggleAutoChanting();
                              });
                            },
                          ),
                        ),
                        if (_isAutoChanting || _count > 0) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF5252)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.stop_rounded, color: Color(0xFFFF5252)),
                            label: Text('Stop', style: GoogleFonts.outfit(color: const Color(0xFFFF5252), fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setSheetState(() {
                                _isAutoChanting = false;
                                _isPaused = false;
                                _autoChantTimer?.cancel();
                                _stopAllAudio();
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Voice Chanting Control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over_rounded, color: Color(0xFFFFD54F), size: 20),
                            const SizedBox(width: 8),
                            Text('Voice Chanting', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                        Switch(
                          value: _isVoiceEnabled && !_isInstrumentalOnly,
                          activeColor: const Color(0xFFFF9900),
                          onChanged: (val) {
                            setSheetState(() {
                              _isVoiceEnabled = val;
                              if (val) _isInstrumentalOnly = false;
                            });
                            setState(() {});
                            _saveAudioSettings();
                          },
                        ),
                      ],
                    ),
                    if (_isVoiceEnabled && !_isInstrumentalOnly) ...[
                      Slider(
                        value: _voiceVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFFFF9900),
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          setSheetState(() => _voiceVolume = val);
                          setState(() {});
                          _saveAudioSettings();
                        },
                      ),
                    ],

                    // Background Instrumental Music Control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.music_note_rounded, color: Color(0xFFFFD54F), size: 20),
                            const SizedBox(width: 8),
                            Text('Devotional Music', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                        Switch(
                          value: _isMusicEnabled,
                          activeColor: const Color(0xFFFF9900),
                          onChanged: (val) {
                            setSheetState(() {
                              _isMusicEnabled = val;
                              _dhunService.setEnabled(
                                enabled: val,
                                deityId: _theme.id,
                                deityName: _theme.fullName,
                                customTrack: widget.entry.backgroundMusic,
                                volume: _musicVolume,
                              );
                            });
                            setState(() {});
                            _saveAudioSettings();
                          },
                        ),
                      ],
                    ),
                    if (_isMusicEnabled) ...[
                      Slider(
                        value: _musicVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFFFF9900),
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          setSheetState(() {
                            _musicVolume = val;
                            _dhunService.setVolume(val);
                          });
                          setState(() {});
                          _saveAudioSettings();
                        },
                      ),
                    ],

                    // Instrumental-Only Mode Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.surround_sound_rounded, color: Color(0xFFFFD54F), size: 20),
                            const SizedBox(width: 8),
                            Text('Instrumental-Only Mode', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                        Switch(
                          value: _isInstrumentalOnly,
                          activeColor: const Color(0xFFFF9900),
                          onChanged: (val) {
                            setSheetState(() {
                              _isInstrumentalOnly = val;
                              if (val) {
                                _isMusicEnabled = true;
                                _dhunService.setEnabled(
                                  enabled: true,
                                  deityId: _theme.id,
                                  deityName: _theme.fullName,
                                  customTrack: widget.entry.backgroundMusic,
                                  volume: _musicVolume,
                                );
                              }
                            });
                            setState(() {});
                            _saveAudioSettings();
                          },
                        ),
                      ],
                    ),

                    const Divider(color: Colors.white12, height: 24),

                    // Mala Target Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mala Target', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildPillTarget(setSheetState, 108, '108'),
                            _buildPillTarget(setSheetState, 1008, '1008'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Build Method ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _persistProgress(immediate: true);
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
                final double dynamicRevealProgress =
                    _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0;
                if (widget.entry.isCustom || _selectedEffect == JapRevealEffectType.divineVerticalReveal) {
                  // MANDATORY PRESERVATION: Exact existing approved widget
                  return ProgressiveRamRevealWidget(
                    revealedNodes: _revealedNodes,
                    newestNode: _newestNode,
                    shimmerProgress: _shimmerController.value,
                    isCompleted: isFullCompleted,
                    completionGlowProgress: _completionController.value,
                    imageAsset: _effectiveImageAsset,
                    revealProgress: dynamicRevealProgress,
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
                    revealProgress: dynamicRevealProgress,
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

                        buildJapVoiceButton(),

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
                      chantText: _effectiveMantraText,
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
                        videoAsset: _getLocalDarshanVideoAsset(),
                        videoUrl: japDarshanVideoUrl,
                        preloadedController: _preloadedDarshanController,
                        showDeityHighlights: !widget.entry.isCustom,
                        isSoundEnabled: _isSoundEnabled,
                        onExitRequested: () {
                          Navigator.maybePop(context, _count.clamp(0, _target));
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
    return GestureDetector(
      onTap: _showMalaTargetPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
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
            const SizedBox(height: 2),

            // Numerical count and target
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_count',
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: const [
                      Shadow(color: Color(0xFFFF9900), blurRadius: 14.0),
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
                if (_completedMalas > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9900).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB300), width: 0.8),
                    ),
                    child: Text(
                      'Mala ${_completedMalas + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFE082),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Mala Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: 140,
                height: 4,
                child: LinearProgressIndicator(
                  value: (_target > 0 ? (_count / _target) : 0.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Devotional chant subtitle with voice highlight
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.notoSerifDevanagari(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _isMantraHighlighted ? const Color(0xFFFFF59D) : const Color(0xFFFFE082),
                letterSpacing: 1.1,
                shadows: _isMantraHighlighted
                    ? const [
                        Shadow(color: Color(0xFFFFD700), blurRadius: 18.0),
                        Shadow(color: Color(0xFFFF6D00), blurRadius: 26.0),
                        Shadow(color: Colors.black, blurRadius: 8.0, offset: Offset(0, 2)),
                      ]
                    : const [
                        Shadow(color: Colors.black, blurRadius: 6.0, offset: Offset(0, 1)),
                      ],
              ),
              child: Text(
                _effectiveMantraText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
              _persistProgress(immediate: true);
              Navigator.pop(context, _count.clamp(0, _target));
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

          // Glowing Single-word Display Name & Full Name Badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _effectiveDisplayName.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: const Color(0xFFFFB300),
                  shadows: const [
                    Shadow(color: Color(0xFFFF7700), blurRadius: 14),
                  ],
                ),
              ),
              Text(
                _effectiveFullName,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFFE082).withValues(alpha: 0.85),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          // Right Actions: [Dhup Mode] & [Effect Selector] & [Audio Settings] & [Favorite Heart]
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Saved / Bookmark Button
                GestureDetector(
                  onTap: _toggleSaveJap,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _isSavedJap
                          ? const Color(0xFFFF7700).withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isSavedJap
                            ? const Color(0xFFFFB300)
                            : const Color(0xFFC8A882).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isSavedJap ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isSavedJap ? const Color(0xFFFFB300) : const Color(0xFFC8A882),
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Favorite Heart Button
                GestureDetector(
                  onTap: _toggleFavouriteJap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isFavouriteJap
                          ? const Color(0xFFE53935).withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isFavouriteJap
                            ? const Color(0xFFFF5252)
                            : const Color(0xFFC8A882).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isFavouriteJap ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavouriteJap ? const Color(0xFFFF5252) : const Color(0xFFC8A882),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      final painter = SingleRamFlightPainter(
        progress: flight.progress,
        malaCenter: flight.startPoint,
        targetPoint: flight.targetPoint,
        screenSize: screenSize,
        chantText: chantText,
      );
      painter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant MultiRamFlightPainter oldDelegate) => true;
}

