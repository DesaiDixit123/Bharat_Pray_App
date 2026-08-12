import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class JapAudioService {
  final AudioPlayer _player = AudioPlayer();

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;

  double get progressFraction {
    if (_duration.inMilliseconds <= 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _stateSub;

  void initialize({
    Function(Duration duration)? onDurationChanged,
    Function(Duration position, double progress)? onPositionChanged,
    VoidCallback? onComplete,
  }) {
    _durationSub = _player.onDurationChanged.listen((d) {
      _duration = d;
      if (onDurationChanged != null) onDurationChanged(d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      _position = p;
      if (onPositionChanged != null) onPositionChanged(p, progressFraction);
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      if (onComplete != null) onComplete();
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
    });
  }

  Future<void> playUrl(String? url, {bool loop = false}) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      await _player.stop();
      if (loop) {
        await _player.setReleaseMode(ReleaseMode.loop);
      } else {
        await _player.setReleaseMode(ReleaseMode.release);
      }
      await _player.play(UrlSource(url.trim()));
      _isPlaying = true;
    } catch (e) {
      debugPrint('[JapAudioService] Error playing audio URL: $e');
      _isPlaying = false;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('[JapAudioService] Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('[JapAudioService] Error resuming: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _position = Duration.zero;
    } catch (e) {
      debugPrint('[JapAudioService] Error stopping: $e');
    }
  }

  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
  }
}
