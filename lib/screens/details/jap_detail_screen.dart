import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/jap_models.dart';
import '../../models/jap_customization_models.dart';
import '../../models/jap_theme_config.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import '../../services/jap_background_dhun_service.dart';
import '../../animations/jap/jap_animation_type.dart';
import '../../animations/jap/premium_jap_animator.dart';
import '../../widgets/jap/circular_mala_painter.dart';
import '../../widgets/jap/divine_reveal_background.dart';
import '../../widgets/jap/jap_effects_gallery_sheet.dart';
import '../../widgets/jap/radial_mantra_burst_overlay.dart';
import 'darshan_runtime_screen.dart';
import 'cinematic_jap_screen.dart';
import 'dhup_jap_screen.dart';
import 'jal_jap_screen.dart';
import 'prakash_jap_screen.dart';
import 'pushp_varsha_jap_screen.dart';

/// Full-Screen Devotional Jap Experience 2.0 (Master Implementation).
/// Includes:
/// - 108-bead circular mala with dedicated Guru (Meru) crown bead & tassel
/// - Dynamic Deity & Mantra Selection (Shri Radha, Shiva, Krishna, Ram, Hanuman, Ambe Maa, Ganesha)
/// - Synchronized 2.0s mantra voice ("श्री राधा" default) with audio-aware mode
/// - Manual Tap to Count button with tactile golden ripple and haptics
/// - Auto-Chant mode with pause/resume and continuous mala mode
/// - Meditation Timer mode with auto-stop and summary
/// - Undo and Reset with safety confirmation
/// - Count-up and countdown display toggle
/// - Compact real-time statistics (Today, Mala #, Lifetime, Elapsed Time)
/// - Progressive divine image reveal from pure black starting state
/// - 108th Jap Special Divine Darshan reveal with sacred temple bell
class JapDetailScreen extends StatefulWidget {
  final JapConfig entry;
  const JapDetailScreen({super.key, required this.entry});

  @override
  State<JapDetailScreen> createState() => _JapDetailScreenState();
}

class _JapDetailScreenState extends State<JapDetailScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late int _count;
  late int _target;
  int _completedMalas = 0;
  JapLifecycle _lifecycle = JapLifecycle.idle;
  JapLifecycle get lifecycle => _lifecycle;

  Timer? _syncDebounceTimer;
  Timer? _autoChantTimer;
  Timer? _elapsedTimer;
  Timer? _countdownTimer;

  // Statistics
  int _elapsedSeconds = 0;
  int _timerRemainingSeconds = 0;
  bool _isTimerRunning = false;
  int _todayCount = 0;
  int _lifetimeTotal = 0;

  late final AudioPlayer _audioPlayer;
  final JapBackgroundDhunService _dhunService = JapBackgroundDhunService();
  late final AnimationController _revealController;
  late final AnimationController _completionController;
  late final AnimationController _ambientController;
  late final AnimationController _beadPulseController;
  late final AnimationController _premiumAnimController;
  late final AnimationController _tapRippleController;
  late final AnimationController _malaFadeController;

  bool _canTap = true;
  bool _isAudioPlaying = false;
  bool _isChanting = false;
  bool _isAutoChantingActive = false;
  bool _showCompletionBanner = false;

  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _debounceDuration = Duration(milliseconds: 180);

  ImageProvider? _imageProvider;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  String _currentVideoAsset = '';

  // Theme & Preferences
  late JapThemeConfig _activeTheme;
  late JapCustomizationPreferences _preferences;
  late JapAnimationType _activeAnimationType;
  bool _isPremiumAnimPlaying = false;
  final String _currentMantra = '';
  final double _animSeed = 0.0;
  Offset? _currentRevealPoint;
  final RadialMantraBurstController _burstController = RadialMantraBurstController();
  bool _darshanStarted = false;

  int get _totalProgress => (_completedMalas * _target) + _count;

  @override
  void initState() {
    super.initState();

    // 1. Full-Screen Immersive Sticky mode & Lifecycle Observer
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);

    // 2. Resolve Active Theme
    _activeTheme = JapThemeConfig.resolveFromEntry(
      name: widget.entry.name,
      shlokText: widget.entry.shlokText,
      audioUrl: widget.entry.shlokAudioUrl,
    );

    _preferences = JapCustomizationPreferences();
    _initBackgroundDhun();
    _loadPreferences();
    _loadStatistics();

    _count = widget.entry.progress % widget.entry.targetCount;
    _target = widget.entry.targetCount > 0 ? widget.entry.targetCount : 108;
    _completedMalas = widget.entry.progress ~/ _target;

    // 3. Audio Player Setup (Configured with AndroidAudioFocus.none so it does not interrupt background dhun)
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
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isAudioPlaying = false);
        _tryUnlockTap();

        // Audio-aware mode auto-chant progression
        if (_isAutoChantingActive && _preferences.audioAwareMode) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _isAutoChantingActive && _count < _target) {
              _increment();
            }
          });
        }
      }
    });

    // 4. Animation Controllers
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _beadPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _tapRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _premiumAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _malaFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (_count >= _target) {
      _malaFadeController.value = 1.0;
    }

    if (_completedMalas > 0) {
      _completionController.value = 1.0;
      _showCompletionBanner = true;
      _lifecycle = JapLifecycle.darshanActive;
    } else if (_count > 0) {
      _lifecycle = JapLifecycle.inProgress;
    } else {
      _lifecycle = JapLifecycle.started;
    }

    _activeAnimationType = JapAnimationType.fromKey(
      widget.entry.particleShape,
      deityName: _activeTheme.name,
    );

    _initImageProvider();
    _initVideoAnimation();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  Future<void> _loadPreferences() async {
    final loaded = await JapCustomizationPreferences.load();
    if (mounted) {
      setState(() {
        _preferences = loaded;
      });
      _initBackgroundDhun();
      // Start timer if configured
      if (_preferences.timerMinutes > 0) {
        _startMeditationTimer(_preferences.timerMinutes);
      }
    }
  }

  void _initBackgroundDhun() {
    final bool shouldPlay = _preferences.soundEnabled && _preferences.backgroundDhunEnabled;
    _dhunService.playForDeity(
      deityId: _activeTheme.id,
      deityName: _activeTheme.name,
      enabled: shouldPlay,
      volume: _preferences.backgroundDhunVolume,
    );
  }

  void _syncAudioState() {
    final bool shouldPlay = _preferences.soundEnabled && _preferences.backgroundDhunEnabled;
    _dhunService.setEnabled(
      enabled: shouldPlay,
      deityId: _activeTheme.id,
      deityName: _activeTheme.name,
      volume: _preferences.backgroundDhunVolume,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _dhunService.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_preferences.soundEnabled && _preferences.backgroundDhunEnabled) {
        _dhunService.resume();
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = 'jap_stat_today_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      setState(() {
        _todayCount = prefs.getInt(todayKey) ?? 0;
        _lifetimeTotal = prefs.getInt('jap_stat_lifetime') ?? 0;
      });
    } catch (e) {
      debugPrint('[JapDetailScreen] Error loading statistics: $e');
    }
  }

  Future<void> _recordStatIncrement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = 'jap_stat_today_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      _todayCount++;
      _lifetimeTotal++;
      await prefs.setInt(todayKey, _todayCount);
      await prefs.setInt('jap_stat_lifetime', _lifetimeTotal);
    } catch (_) {}
  }

  void _initImageProvider() {
    final url = _activeTheme.imageAsset;
    if (url.startsWith('http')) {
      _imageProvider = NetworkImage(url);
    } else if (url.startsWith('assets/')) {
      _imageProvider = AssetImage(url);
    } else if (url.isNotEmpty && File(url).existsSync()) {
      _imageProvider = FileImage(File(url));
    } else {
      _imageProvider = AssetImage(JapConfig.defaultDeityImage(_activeTheme.name));
    }
  }

  void _initVideoAnimation() {
    _currentVideoAsset = _resolveAnimationVideo();
    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(_currentVideoAsset)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      })
      ..setLooping(false);
    _videoController?.setVolume(0.0);
  }

  String _resolveAnimationVideo() {
    switch (_activeAnimationType) {
      case JapAnimationType.dhupVideo:
        return 'assets/videos/dhup_animation.mp4';
      case JapAnimationType.ramVideo:
        return 'assets/videos/ram-ram-animation.mp4';
      case JapAnimationType.lotusVideo:
        return 'assets/videos/lotus-animation.mp4';
      case JapAnimationType.peacockVideo:
        return 'assets/videos/peakok-feather.mp4';
      case JapAnimationType.aartiVideo:
        return 'assets/videos/arati-animation.mp4';
      default:
        break;
    }
    final name = _activeTheme.name.toLowerCase();
    if (name.contains('ram')) {
      return 'assets/videos/ram-ram-animation.mp4';
    } else if (name.contains('radha') || name.contains('krishna')) {
      return 'assets/videos/peakok-feather.mp4';
    } else if (name.contains('lotus') || name.contains('laxmi')) {
      return 'assets/videos/lotus-animation.mp4';
    }
    return 'assets/videos/dhup_animation.mp4';
  }

  void _tryUnlockTap() {
    if (!_isAudioPlaying && !_isVideoPlaying && !_isPremiumAnimPlaying && _count < _target) {
      if (mounted) {
        setState(() {
          _canTap = true;
          _isChanting = false;
        });
      }
    }
  }

  // ── Deity Selector Sheet (Section 6) ─────────────────────────────────
  void _openDeitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Color(0xFF141218),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFFC8A882), width: 1.5)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF9933), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Select Sacred Deity & Mantra',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: JapThemeConfig.allThemes.length,
                  itemBuilder: (ctx, index) {
                    final theme = JapThemeConfig.allThemes[index];
                    final isSelected = theme.id == _activeTheme.id;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _switchTheme(theme);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2C1E14) : const Color(0xFF1A1720),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF7700) : Colors.white10,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.activeColor, width: 1.5),
                                image: DecorationImage(
                                  image: AssetImage(theme.imageAsset),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    theme.mantraText,
                                    style: GoogleFonts.notoSerifDevanagari(
                                      color: theme.activeColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFFF7700), size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _switchTheme(JapThemeConfig newTheme) {
    setState(() {
      _activeTheme = newTheme;
      _preferences.malaStyle = newTheme.defaultBeadStyle;
      _initImageProvider();
      _initVideoAnimation();
    });
    _preferences.save();
    HapticFeedback.mediumImpact();

    // Dynamically transition background dhun for the new deity
    final bool shouldPlay = _preferences.soundEnabled && _preferences.backgroundDhunEnabled;
    _dhunService.playForDeity(
      deityId: newTheme.id,
      deityName: newTheme.name,
      enabled: shouldPlay,
      volume: _preferences.backgroundDhunVolume,
    );
  }

  // ── Meditation Timer Logic ──────────────────────────────────────────
  void _startMeditationTimer(int minutes) {
    _countdownTimer?.cancel();
    if (minutes <= 0) {
      setState(() {
        _isTimerRunning = false;
        _timerRemainingSeconds = 0;
      });
      return;
    }
    setState(() {
      _isTimerRunning = true;
      _timerRemainingSeconds = minutes * 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_timerRemainingSeconds <= 1) {
        t.cancel();
        setState(() {
          _isTimerRunning = false;
          _timerRemainingSeconds = 0;
        });
        _stopAutoChant();
        _playCompletionBell();
        _showTimerCompletionSummary();
      } else {
        setState(() => _timerRemainingSeconds--);
      }
    });
  }

  void _showTimerCompletionSummary() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: Color(0xFFFF9933)),
            const SizedBox(width: 8),
            Text(
              'Meditation Completed',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your scheduled ${_preferences.timerMinutes}-minute chanting session has finished peacefully.',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Japs Done', '$_count'),
                  _buildStatItem('Malas', '$_completedMalas'),
                  _buildStatItem('Session Time', _formatDuration(_elapsedSeconds)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continue Meditation', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Undo Single Count ────────────────────────────────────────────────
  void _undoCount() {
    if (_count <= 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _count--;
      if (_count < _target) {
        _darshanStarted = false;
        if (_malaFadeController.value > 0.0) {
          _malaFadeController.reverse();
        }
      }
      if (_count == 0 && _completedMalas == 0) {
        _lifecycle = JapLifecycle.started;
      }
      _showCompletionBanner = false;
    });
    JapOfflineRepository.saveProgress(
      japId: widget.entry.id,
      count: _count,
      completedMalas: _completedMalas,
    );
  }

  // ── Reset Current Mala with Confirmation ─────────────────────────────
  void _resetMala() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Color(0xFFFF7700)),
            const SizedBox(width: 8),
            Text('Reset Current Mala?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Do you wish to reset current Mala count to 0?\n(Your completed malas and lifetime statistics will remain safe.)',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    _stopAutoChant();
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
      _darshanStarted = false;
      _canTap = true;
      _isChanting = false;
      _isAudioPlaying = false;
      _isVideoPlaying = false;
      _isPremiumAnimPlaying = false;
      _showCompletionBanner = false;
      _lifecycle = JapLifecycle.started;
    });
    _completionController.reset();
    _revealController.reset();
    _malaFadeController.reset();

    JapOfflineRepository.saveProgress(
      japId: widget.entry.id,
      count: 0,
      completedMalas: _completedMalas,
    );
    _triggerBackgroundSync();
  }

  void _openEffectsGallery() {
    JapEffectsGallerySheet.show(
      context,
      preferences: _preferences,
      currentAnimType: _activeAnimationType,
      onPreferencesChanged: (newPrefs) {
        setState(() {
          _preferences = newPrefs;
        });
        if (_preferences.chantingMode == ChantingMode.autoChant && !_isAutoChantingActive) {
          _startAutoChant();
        } else if (_preferences.chantingMode == ChantingMode.manualTap && _isAutoChantingActive) {
          _stopAutoChant();
        }
        if (_preferences.timerMinutes > 0 && !_isTimerRunning) {
          _startMeditationTimer(_preferences.timerMinutes);
        } else if (_preferences.timerMinutes == 0 && _isTimerRunning) {
          _startMeditationTimer(0);
        }
        _syncAudioState();
      },
      onAnimTypeChanged: (newType) {
        setState(() {
          _activeAnimationType = newType;
        });
        if (newType.isVideo) {
          _initVideoAnimation();
        }
      },
      onResetDefaults: () {
        setState(() {
          _preferences.resetToDefaults();
          _preferences.save();
        });
        _syncAudioState();
      },
    );
  }

  void _toggleAutoChant() {
    if (_isAutoChantingActive) {
      _stopAutoChant();
    } else {
      _startAutoChant();
    }
  }

  void _startAutoChant() {
    _autoChantTimer?.cancel();
    setState(() {
      _isAutoChantingActive = true;
      _preferences.chantingMode = ChantingMode.autoChant;
    });

    if (_canTap && _count < _target) {
      _increment();
    }

    if (!_preferences.audioAwareMode) {
      final interval = Duration(milliseconds: _preferences.chantIntervalMs);
      _autoChantTimer = Timer.periodic(interval, (_) {
        if (!mounted) {
          _autoChantTimer?.cancel();
          return;
        }
        if (_count >= _target) {
          if (_preferences.continuousMalaMode) {
            _startNextMala();
          } else {
            _stopAutoChant();
            return;
          }
        }
        if (_canTap) {
          _increment();
        }
      });
    }
  }

  void _stopAutoChant() {
    _autoChantTimer?.cancel();
    if (mounted) {
      setState(() {
        _isAutoChantingActive = false;
        _preferences.chantingMode = ChantingMode.manualTap;
      });
    }
  }

  @override
  void dispose() {
    _autoChantTimer?.cancel();
    _elapsedTimer?.cancel();
    _countdownTimer?.cancel();
    _syncDebounceTimer?.cancel();
    _triggerBackgroundSync();
    _premiumAnimController.dispose();
    _tapRippleController.dispose();
    _videoController?.dispose();
    _audioPlayer.dispose();
    _dhunService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _revealController.dispose();
    _completionController.dispose();
    _ambientController.dispose();
    _beadPulseController.dispose();
    _malaFadeController.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Increment Handler (Manual & Auto Synchronized at 2.0s pace) ──────
  void _increment() async {
    final now = DateTime.now();
    if (now.difference(_lastTapTime) < _debounceDuration) {
      return;
    }
    _lastTapTime = now;

    if (!_canTap) return;
    if (_count >= _target) {
      _startNextMala();
      return;
    }

    // 1. Haptic Feedback
    if (_preferences.hapticsEnabled) {
      final int halfTarget = _target ~/ 2;
      final int nearCompletion = (_target * 0.9).round();
      if ((_count + 1) == halfTarget) {
        HapticFeedback.mediumImpact();
      } else if ((_count + 1) == nearCompletion) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    // 2. State & Count Update
    setState(() {
      _canTap = false;
      _isChanting = true;
      _count = math.min(_count + 1, _target);
      _lifecycle = _count >= _target ? JapLifecycle.completed : JapLifecycle.inProgress;
    });

    _recordStatIncrement();

    // 3. Audio Chanting Playback
    _playMantraAudio();

    // 4. Trigger "શ્રી રાધા" Outward Radial Expansion Animation
    final String burstText = (_activeTheme.id == 'shri_radha' || _activeTheme.id == 'radha_krishna')
        ? 'શ્રી રાધા'
        : _activeTheme.mantraText;

    _burstController.trigger(
      text: burstText,
      primaryColor: const Color(0xFFFFD700),
      glowColor: _activeTheme.glowColor,
    );

    // 5. Background Reveal Controller
    _revealController.forward(from: 0.0);

    // 5. Local Cache & Sync
    JapOfflineRepository.saveProgress(
      japId: widget.entry.id,
      count: _count,
      completedMalas: _completedMalas,
    );

    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _triggerBackgroundSync();
    });

    if (_count % 27 == 0 || _count >= _target) {
      _triggerBackgroundSync();
    }

    // 6. 108 Completion Trigger
    if (_count >= _target) {
      _handle108Completion();
    } else {
      // Re-enable tap lock after pace window
      final lockDuration = math.min(300, _preferences.chantIntervalMs ~/ 4);
      Future.delayed(Duration(milliseconds: lockDuration), () {
        if (mounted) {
          setState(() {
            _canTap = true;
            _isChanting = false;
          });
        }
      });
    }
  }

  void _playMantraAudio() async {
    if (!_preferences.soundEnabled) return;
    try {
      await _audioPlayer.stop();
      final audioAsset = _activeTheme.audioAsset;
      if (audioAsset.startsWith('assets/')) {
        await _audioPlayer.play(AssetSource(audioAsset.replaceFirst('assets/', '')));
      } else if (audioAsset.startsWith('http')) {
        await _audioPlayer.play(UrlSource(audioAsset));
      } else {
        await _audioPlayer.play(DeviceFileSource(audioAsset));
      }
      if (mounted) setState(() => _isAudioPlaying = true);
    } catch (e) {
      debugPrint('[JapAudio] Playback exception: $e');
    }
  }

  void _playCompletionBell() async {
    if (!_preferences.bellAtCompletion) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/temple_bell.wav'));
    } catch (e) {
      debugPrint('[JapAudio] Temple bell playback error: $e');
    }
  }

  void _handle108Completion() {
    _stopAutoChant();
    _playCompletionBell();

    if (_preferences.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }

    _completionController.forward(from: 0.0);

    if (!_malaFadeController.isAnimating && _malaFadeController.value < 1.0) {
      _malaFadeController.forward();
    }

    if (!_darshanStarted) {
      _darshanStarted = true;
      _startDarshanPlayback();
    }

    setState(() {
      _showCompletionBanner = true;
      _lifecycle = JapLifecycle.darshanReveal;
      _canTap = true;
      _isChanting = false;
    });

    if (_preferences.continuousMalaMode) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _preferences.continuousMalaMode) {
          _startNextMala();
          _startAutoChant();
        }
      });
    }
  }

  void _startDarshanPlayback() {
    debugPrint('[JapDarshan] Full 100% reveal reached for ${_activeTheme.name}! Transitioning to live devotional darshan.');
  }

  void _startNextMala() {
    HapticFeedback.mediumImpact();
    setState(() {
      _completedMalas++;
      _count = 0;
      _darshanStarted = false;
      _showCompletionBanner = false;
      _lifecycle = JapLifecycle.started;
      _canTap = true;
      _isChanting = false;
    });
    _completionController.reset();
    _revealController.reset();
    _malaFadeController.reset();

    JapOfflineRepository.saveProgress(
      japId: widget.entry.id,
      count: 0,
      completedMalas: _completedMalas,
    );
    _triggerBackgroundSync();
  }

  Future<void> _triggerBackgroundSync() async {
    try {
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
      debugPrint('[JapDetailScreen] Background sync: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_count == 0 && _completedMalas == 0) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.spa_rounded, color: Color(0xFFFF9933)),
            const SizedBox(width: 8),
            Text('Leave Jap Session?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your sacred count ($_count of $_target) is preserved offline and synced.',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Continue Chanting', style: GoogleFonts.outfit(color: const Color(0xFFFF9933))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Leave', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double malaDiameter = math.min(size.width * 0.88, 360.0);
    final bool isCompleted = _count >= _target;
    final pack = widget.entry.effectPack;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted && context.mounted) {
          _dhunService.stop();
          Navigator.pop(context, _totalProgress);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Guaranteed deep black starting baseline
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── LAYER 1: Full-Screen Progressive Divine Image Reveal ─────────
            DivineRevealBackground(
              imageProvider: _imageProvider,
              deityId: widget.entry.id.isNotEmpty ? widget.entry.id : _activeTheme.id,
              deityName: widget.entry.name.isNotEmpty ? widget.entry.name : _activeTheme.name,
              count: _count,
              target: _target,
              startingStyle: _preferences.startingStyle,
              revealStyle: _preferences.revealStyle,
              effectPack: pack,
              isCompleted: isCompleted,
              activeColor: _activeTheme.activeColor,
              glowColor: _activeTheme.glowColor,
            ),

            // ── LAYER 2: Radiant Golden Aura & Completion Radial Light Rays ───
            AnimatedBuilder(
              animation: _completionController,
              builder: (ctx, _) {
                if (_completionController.value <= 0.01) return const SizedBox.shrink();
                return IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2 * _completionController.value,
                        colors: [
                          _activeTheme.activeColor.withValues(alpha: 0.35 * _completionController.value),
                          const Color(0xFFFFD700).withValues(alpha: 0.20 * _completionController.value),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── LAYER 3: Particle Effects ────────────────────────────────────
            AnimatedBuilder(
              animation: _premiumAnimController,
              builder: (ctx, _) {
                return Positioned.fill(
                  child: PremiumJapAnimator(
                    animationType: _activeAnimationType,
                    progress: _premiumAnimController.value,
                    isPlaying: _isPremiumAnimPlaying,
                    deityName: _activeTheme.name,
                    currentMantra: _currentMantra,
                    revealPoint: _currentRevealPoint ?? Offset(size.width / 2, size.height * 0.45),
                    seed: _animSeed,
                  ),
                );
              },
            ),

            // ── LAYER 4: Full-Screen Devotional UI Tree ──────────────────────
            SafeArea(
              child: Column(
                children: [
                  // A. Minimal Full-Screen Header Controls
                  _buildTopBar(),

                  // B. Devotional Mantra Banner (Smoothly collapses to zero layout space on 100% full reveal)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 400),
                    sizeCurve: Curves.easeInOutCubic,
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeInCubic,
                    crossFadeState: (isCompleted || !_preferences.mantraTextVisible)
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildMantraBanner(),
                    secondChild: const SizedBox.shrink(),
                  ),

                  const Spacer(),

                  // C & D. Central 108-Bead Mala & Animated Counter
                  AnimatedBuilder(
                    animation: _malaFadeController,
                    builder: (ctx, child) {
                      final double fadeVal = _malaFadeController.value;
                      if (fadeVal >= 1.0 && _count >= _target) {
                        return const SizedBox.shrink();
                      }
                      final double curve = Curves.easeInOutCubic.transform(fadeVal);
                      final double opacity = (1.0 - curve).clamp(0.0, 1.0);
                      final double scale = 1.0 - (0.15 * curve);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: IgnorePointer(
                            ignoring: _count >= _target,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _buildCentralMalaAndCounter(malaDiameter, isCompleted, pack),
                  ),

                  const Spacer(),

                  // E. Prominent "Tap to Count" Button
                  _buildTapToCountButton(isCompleted),

                  const SizedBox(height: 10),

                  // F. Accessible Control Toolbar (Auto, Undo, Timer, Reset)
                  _buildControlToolbar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── LAYER 5: 108 Jap Completion Celebration Modal ────────────────
            if (_showCompletionBanner) _buildCompletionBanner(pack),
          ],
        ),
      ),
    );
  }

  // ── UI Components ──────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () async {
              final shouldLeave = await _onWillPop();
              if (shouldLeave && mounted && context.mounted) {
                _dhunService.stop();
                Navigator.pop(context, _totalProgress);
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.5), width: 1.0),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC8A882), size: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Deity Selector Dropdown Chip
          Expanded(
            child: GestureDetector(
              onTap: _openDeitySelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _activeTheme.activeColor.withValues(alpha: 0.4), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: AssetImage(_activeTheme.imageAsset),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _activeTheme.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF9933), size: 16),
                            ],
                          ),
                          Text(
                            _isTimerRunning
                                ? '⏳ ${_formatDuration(_timerRemainingSeconds)} left'
                                : '${(_preferences.chantIntervalMs / 1000).toStringAsFixed(1)}s Pace',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _isTimerRunning ? const Color(0xFFFFD700) : const Color(0xFFFF9933),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Header Actions (Sound, Effects)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sound Toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _preferences.soundEnabled = !_preferences.soundEnabled;
                    _preferences.backgroundDhunEnabled = _preferences.soundEnabled;
                    _preferences.save();
                  });
                  _syncAudioState();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.0),
                  ),
                  child: Icon(
                    _preferences.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 17,
                    color: _preferences.soundEnabled ? const Color(0xFFFF9933) : Colors.white38,
                  ),
                ),
              ),

              if (_activeTheme.name.toLowerCase().contains('ram')) ...[
                GestureDetector(
                  onTap: () async {
                    _dhunService.stop();
                    final updated = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CinematicJapScreen(entry: widget.entry),
                      ),
                    );
                    if (updated != null && mounted) {
                      setState(() {
                        _count = updated % _target;
                        _completedMalas = updated ~/ _target;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9900), Color(0xFFFF5500)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie_filter_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '108 Darshan',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    _dhunService.stop();
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
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E140F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9900).withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.waves_rounded, size: 14, color: Color(0xFFFFD54F)),
                        const SizedBox(width: 4),
                        Text(
                          'Dhup Darshan',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    _dhunService.stop();
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
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1C24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF80DEEA), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00ACC1).withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF80DEEA)),
                        const SizedBox(width: 4),
                        Text(
                          'Jal Darshan 🌊',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFF80DEEA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    _dhunService.stop();
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
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E130B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9900).withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFFFD54F)),
                        const SizedBox(width: 4),
                        Text(
                          'Prakash Mandal ✨',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    _dhunService.stop();
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
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF261217),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF80AB), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.spa_rounded, size: 14, color: Color(0xFFFF80AB)),
                        const SizedBox(width: 4),
                        Text(
                          'Pushp Varsha 🌸',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFFFF80AB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Effects Button
              GestureDetector(
                onTap: _openEffectsGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8A882), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFF7700)),
                      const SizedBox(width: 4),
                      Text(
                        'Effects',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMantraBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isChanting ? _activeTheme.activeColor : const Color(0xFFC8A882).withValues(alpha: 0.4),
            width: _isChanting ? 1.6 : 1.0,
          ),
          boxShadow: _isChanting
              ? [
                  BoxShadow(
                    color: _activeTheme.glowColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Text(
          _activeTheme.mantraText,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerifDevanagari(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _isChanting ? const Color(0xFFFFD700) : Colors.white,
            shadows: [
              Shadow(
                color: _isChanting ? _activeTheme.glowColor : Colors.black87,
                blurRadius: _isChanting ? 12 : 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentralMalaAndCounter(double malaDiameter, bool isCompleted, EffectPack pack) {
    final int displayCount = _preferences.countdownMode ? (_target - _count) : _count;
    final String countLabel = _preferences.countdownMode ? 'REMAINING' : 'OF $_target';

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _increment,
        child: SizedBox(
          width: malaDiameter,
          height: malaDiameter,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Circular 108-Bead Mala Painter with Guru (Meru) Crown Bead & Tassel
              AnimatedBuilder(
                animation: _beadPulseController,
                builder: (ctx, _) {
                  return CustomPaint(
                    size: Size(malaDiameter, malaDiameter),
                    painter: CircularMalaPainter(
                      count: _count,
                      target: _target,
                      pulseValue: _beadPulseController.value,
                      style: _preferences.malaStyle,
                      themeAccentColor: _activeTheme.activeColor,
                      isCompleted: isCompleted,
                    ),
                  );
                },
              ),

              // 2. Central Jap Counter Core (Inner circle outline, border, and orange tap highlight removed)
              SizedBox(
                width: malaDiameter * 0.60,
                height: malaDiameter * 0.60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sacred OM or Chanting Wave Icon
                    if (_isAudioPlaying)
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: Color(0xFFFFD700),
                        size: 24,
                      )
                    else
                      Text(
                        'ॐ',
                        style: GoogleFonts.notoSerifDevanagari(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),

                    const SizedBox(height: 2),

                    // Large Animated Counter
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        '$displayCount',
                        key: ValueKey<int>(displayCount),
                        style: GoogleFonts.outfit(
                          fontSize: malaDiameter * 0.17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.1,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),

                    // Subtitle
                    Text(
                      '$countLabel • ${((_count / _target) * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF9933),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Radial Mantra Burst Overlay (“શ્રી રાધા” outward expansion on each tap)
              RadialMantraBurstOverlay(
                controller: _burstController,
                defaultCenter: Offset(malaDiameter / 2, malaDiameter / 2),
                defaultMaxRadius: malaDiameter * 0.95,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapToCountButton(bool isCompleted) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _increment,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8800), Color(0xFFFF6600)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Tap',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildControlToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Auto Chant Button
          GestureDetector(
            onTap: _toggleAutoChant,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isAutoChantingActive
                    ? const Color(0xFFD32F2F).withValues(alpha: 0.8)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isAutoChantingActive ? const Color(0xFFFF5252) : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAutoChantingActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAutoChantingActive ? 'Pause' : 'Auto 2s',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Undo Count Button
          GestureDetector(
            onTap: _undoCount,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.undo_rounded, color: Colors.white70, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    'Undo',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timer Toggle
          GestureDetector(
            onTap: () {
              // Quick cycle through timers: 0 -> 5 -> 10 -> 15 -> 0
              final next = _preferences.timerMinutes == 0
                  ? 5
                  : (_preferences.timerMinutes == 5
                      ? 10
                      : (_preferences.timerMinutes == 10 ? 15 : 0));
              setState(() => _preferences.timerMinutes = next);
              _preferences.save();
              _startMeditationTimer(next);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isTimerRunning
                    ? const Color(0xFFFF9933).withValues(alpha: 0.25)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isTimerRunning ? const Color(0xFFFF9933) : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    color: _isTimerRunning ? const Color(0xFFFF9933) : Colors.white70,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _preferences.timerMinutes > 0 ? '${_preferences.timerMinutes}m' : 'Timer',
                    style: GoogleFonts.outfit(
                      color: _isTimerRunning ? const Color(0xFFFF9933) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reset Button
          GestureDetector(
            onTap: _resetMala,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white70, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    'Reset',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionBanner(EffectPack pack) {
    return Positioned(
      bottom: 20,
      left: 18,
      right: 18,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E140C).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFFF7700), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7700).withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 32),
            const SizedBox(height: 4),
            Text(
              '108 જાપ પૂર્ણ થયા 🙏',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _activeTheme.blessingTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _activeTheme.blessingSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF9933)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _startNextMala,
                    child: Text(
                      'Next Mala (108)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF9933),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Replay Live Darshan',
                  icon: const Icon(Icons.replay_circle_filled_rounded, color: Color(0xFFFFD700), size: 28),
                  onPressed: () {
                    _completionController.forward(from: 0.0);
                    _playCompletionBell();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7700),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DarshanRuntimeScreen(
                            config: widget.entry,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Darshan 🙏',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
