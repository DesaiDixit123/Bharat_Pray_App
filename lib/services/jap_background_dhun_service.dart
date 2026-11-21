import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized service managing peaceful devotional background dhun playback
/// synchronized with the active deity during Jap meditation.
class JapBackgroundDhunService {
  final AudioPlayer _player = AudioPlayer();

  String? _currentTrack;
  bool _isPlaying = false;
  bool _isEnabled = true;
  double _volume = 0.22; // 22% meditative background: soft, audible, peaceful

  /// User/developer extensible registry for deity-specific background dhun tracks.
  static final Map<String, String> customDhunRegistry = {};

  bool get isPlaying => _isPlaying;
  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  String? get currentTrack => _currentTrack;

  Source _buildSource(String track) {
    final trimmed = track.trim();
    // Prefer bundled local asset when track matches one of our 4 core temple dhuns
    for (final name in const [
      'temple_peaceful_dhun.wav',
      'ram_mandir_dhun.wav',
      'krishna_flute_dhun.wav',
      'shiva_meditative_dhun.wav',
    ]) {
      if (trimmed.contains(name)) {
        return AssetSource('audio/$name');
      }
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return UrlSource(trimmed);
    }
    final cleanAsset = trimmed.startsWith('assets/') ? trimmed.substring(7) : trimmed;
    return AssetSource(cleanAsset);
  }

  JapBackgroundDhunService() {
    _initAudioContext();
    // Continuous gapless safeguard: automatically keep playing if player completes
    _player.onPlayerComplete.listen((_) {
      if (_isEnabled && _isPlaying && _currentTrack != null) {
        _player.play(_buildSource(_currentTrack!)).catchError((_) {});
      }
    });
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

  /// Resolves the dedicated devotional background instrumental track for each deity.
  static String resolveTrackForDeity(String deityId, String deityName) {
    final lowerId = deityId.toLowerCase();
    final lowerName = deityName.toLowerCase();

    // Check custom overrides first
    if (customDhunRegistry.containsKey(lowerId)) {
      return customDhunRegistry[lowerId]!;
    }

    // 1. Lord Ram & Hanuman & Vishnu (Ayodhya Ram Mandir bells, sitar and tanpura)
    if (lowerId.contains('ram') || lowerName.contains('ram') || lowerName.contains('raghav') ||
        lowerId.contains('hanuman') || lowerName.contains('hanuman') || lowerName.contains('bajrang') ||
        lowerId.contains('vishnu') || lowerName.contains('vishnu') || lowerName.contains('narayan')) {
      return 'audio/ram_mandir_dhun.wav';
    }

    // 2. Shri Radha & Krishna & Khatu Shyam (Vrindavan divine bansuri/flute & tanpura dhun)
    if (lowerId.contains('radha') || lowerName.contains('radha') ||
        lowerId.contains('krishna') || lowerName.contains('krishna') || lowerName.contains('kanha') ||
        lowerId.contains('khatu') || lowerName.contains('khatu') || lowerName.contains('shyam')) {
      return 'audio/krishna_flute_dhun.wav';
    }

    // 3. Lord Shiva / Mahadev (Cosmic 136.1Hz Om meditation, damru and sacred temple bells)
    if (lowerId.contains('shiva') || lowerName.contains('shiva') || lowerName.contains('shiv') ||
        lowerId.contains('mahadev') || lowerName.contains('bholenath')) {
      return 'audio/shiva_meditative_dhun.wav';
    }

    // 4. Maa Durga, Lakshmi, Ambe, Ganesh, Swaminarayan (Sacred Temple sanctum sanctorum dhun)
    return 'audio/temple_peaceful_dhun.wav';
  }

  /// Plays or transitions to the appropriate background dhun for the selected deity.
  Future<void> playForDeity({
    required String deityId,
    required String deityName,
    String? customTrack,
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

    final track = (customTrack != null && customTrack.trim().isNotEmpty)
        ? customTrack.trim()
        : resolveTrackForDeity(deityId, deityName);

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
      await _player.play(_buildSource(track));
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
    String? customTrack,
    double? volume,
  }) async {
    _isEnabled = enabled;
    if (_isEnabled) {
      await playForDeity(
        deityId: deityId,
        deityName: deityName,
        customTrack: customTrack,
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
