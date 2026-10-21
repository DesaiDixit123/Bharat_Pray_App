import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized service managing peaceful devotional background dhun playback
/// synchronized with the active deity during Jap meditation.
class JapBackgroundDhunService {
  final AudioPlayer _player = AudioPlayer();

  String? _currentTrack;
  bool _isPlaying = false;
  bool _isEnabled = true;
  double _volume = 0.60; // 60% default: clearly audible and peaceful

  /// User/developer extensible registry for deity-specific background dhun tracks.
  static final Map<String, String> customDhunRegistry = {};

  bool get isPlaying => _isPlaying;
  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  String? get currentTrack => _currentTrack;

  JapBackgroundDhunService() {
    _initAudioContext();
  }

  void _initAudioContext() {
    try {
      // Configure audio session so background music mixes smoothly without cutting off or being cut off by mantra voice
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none, // Do not interrupt other players
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      _player.setAudioContext(
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
    } catch (e) {
      debugPrint('[JapDhunService] Error setting AudioContext: $e');
    }
  }

  /// Resolves the most appropriate devotional background track based on deity ID and name
  static String resolveTrackForDeity(String deityId, String deityName) {
    final lowerId = deityId.toLowerCase();
    final lowerName = deityName.toLowerCase();

    // Check custom overrides first
    if (customDhunRegistry.containsKey(lowerId)) {
      return customDhunRegistry[lowerId]!;
    }

    // 1. Lord Krishna & Shri Radha (Peaceful, soft Vrindavan flute & tanpura dhun)
    if (lowerId.contains('radha') ||
        lowerId.contains('krishna') ||
        lowerName.contains('radha') ||
        lowerName.contains('krishna')) {
      return 'audio/krishna_flute_dhun.wav';
    }

    // 2. Lord Ram & Hanuman (Serene Ayodhya Ram Mandir chimes and tanpura)
    if (lowerId.contains('ram') ||
        lowerId.contains('hanuman') ||
        lowerName.contains('ram') ||
        lowerName.contains('hanuman') ||
        lowerName.contains('sita')) {
      return 'audio/ram_mandir_dhun.wav';
    }

    // 3. Lord Shiva / Mahadev (Cosmic 136.1Hz Om meditation & singing bowl resonance)
    if (lowerId.contains('shiva') ||
        lowerId.contains('mahadev') ||
        lowerName.contains('shiv') ||
        lowerName.contains('mahadev') ||
        lowerName.contains('bholenath')) {
      return 'audio/shiva_meditative_dhun.wav';
    }

    // 4. Default Universal Temple Devotional Instrumental
    return 'audio/temple_peaceful_dhun.wav';
  }

  /// Plays or transitions to the appropriate background dhun for the selected deity.
  Future<void> playForDeity({
    required String deityId,
    required String deityName,
    bool enabled = true,
    double? volume,
  }) async {
    _isEnabled = enabled;
    if (volume != null) {
      _volume = volume.clamp(0.0, 1.0);
    }

    if (!_isEnabled) {
      await stop();
      return;
    }

    final track = resolveTrackForDeity(deityId, deityName);

    try {
      if (_currentTrack == track && _isPlaying) {
        await _player.setVolume(_volume);
        return;
      }

      _currentTrack = track;
      _initAudioContext();

      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(track));
      _isPlaying = true;

      debugPrint('[JapDhunService] Playing devotional background dhun: $track at volume: $_volume');
    } catch (e) {
      debugPrint('[JapDhunService] Error playing background dhun ($track): $e');
      _isPlaying = false;
      // Secondary fallback
      try {
        await _player.play(AssetSource('audio/temple_peaceful_dhun.wav'));
        _isPlaying = true;
      } catch (_) {}
    }
  }

  /// Sets playback volume smoothly (0.0 to 1.0)
  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('[JapDhunService] Error setting volume: $e');
    }
  }

  /// Updates enabled state: starts playing if enabled, stops if disabled
  Future<void> setEnabled({
    required bool enabled,
    required String deityId,
    required String deityName,
    double? volume,
  }) async {
    _isEnabled = enabled;
    if (_isEnabled) {
      await playForDeity(
        deityId: deityId,
        deityName: deityName,
        enabled: true,
        volume: volume ?? _volume,
      );
    } else {
      await stop();
    }
  }

  /// Temporarily pauses the background dhun
  Future<void> pause() async {
    if (_isPlaying) {
      try {
        await _player.pause();
        _isPlaying = false;
      } catch (e) {
        debugPrint('[JapDhunService] Error pausing: $e');
      }
    }
  }

  /// Resumes playback if previously paused and enabled
  Future<void> resume() async {
    if (_isEnabled && !_isPlaying) {
      try {
        if (_currentTrack != null) {
          await _player.resume();
          _isPlaying = true;
        }
      } catch (e) {
        debugPrint('[JapDhunService] Error resuming: $e');
      }
    }
  }

  /// Stops background dhun playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentTrack = null;
    } catch (e) {
      debugPrint('[JapDhunService] Error stopping: $e');
    }
  }

  /// Disposes audio player resources cleanly
  Future<void> dispose() async {
    try {
      await _player.stop();
      await _player.dispose();
      _isPlaying = false;
    } catch (e) {
      debugPrint('[JapDhunService] Error disposing player: $e');
    }
  }
}
