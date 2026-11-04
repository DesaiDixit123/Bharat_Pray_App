import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/bhajan_track_item.dart';
import '../screens/details/bhajan_now_playing_screen.dart';
import 'api_service.dart';
import 'bhajan_library_service.dart';

/// Global singleton audio service managing devotional bhajan playback,
/// background audio persistence, queue management, and Spotify-style media notifications.
class BhajanAudioService {
  BhajanAudioService._internal() {
    _initAudioPlayer();
    _setupIsolatePort();
    _setupNativeMediaChannel();
  }

  static final BhajanAudioService instance = BhajanAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const MethodChannel _nativeMediaChannel = MethodChannel('com.bharatpray/native_media_player');

  static const String notificationChannelId = 'bharat_pray_bhajan_player_v5';
  static const String notificationChannelName = 'Bhajan Music Playback';
  static const int notificationId = 108;

  // Observable state
  final ValueNotifier<BhajanTrackItem?> currentTrackNotifier = ValueNotifier<BhajanTrackItem?>(null);
  final ValueNotifier<PlayerState> playerStateNotifier = ValueNotifier<PlayerState>(PlayerState.stopped);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<bool> isBufferingNotifier = ValueNotifier<bool>(false);

  List<BhajanTrackItem> _queue = [];
  int _currentIndex = -1;
  String _activeToken = '';
  int _lastNotificationPositionSec = -1;

  List<BhajanTrackItem> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  BhajanTrackItem? get currentTrack => currentTrackNotifier.value;
  bool get isPlaying => playerStateNotifier.value == PlayerState.playing;
  Duration get position => positionNotifier.value;
  Duration get duration => durationNotifier.value;

  void _initAudioPlayer() {
    // Configure audio context to continue playing in background
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );

    _initNotificationChannel();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      playerStateNotifier.value = state;
      _updateMediaNotification();
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      positionNotifier.value = pos;
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      durationNotifier.value = dur;
      _updateMediaNotification();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      next();
    });
  }

  void _setupIsolatePort() {
    final receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping('bhajan_audio_action_port');
    IsolateNameServer.registerPortWithName(receivePort.sendPort, 'bhajan_audio_action_port');
    receivePort.listen((message) {
      debugPrint('[BhajanAudioService] Action from background isolate: $message');
      if (message == 'action_play_pause') {
        togglePlayPause();
      } else if (message == 'action_next') {
        next();
      } else if (message == 'action_prev') {
        previous();
      }
    });
  }

  void _setupNativeMediaChannel() {
    _nativeMediaChannel.setMethodCallHandler((call) async {
      debugPrint('[BhajanAudioService] Native channel message: ${call.method}, args: ${call.arguments}');
      if (call.method == 'onMediaAction') {
        final action = call.arguments is Map ? call.arguments['action'] : null;
        if (action == 'action_pause') {
          pause();
        } else if (action == 'action_resume') {
          resume();
        } else if (action == 'action_play_pause') {
          togglePlayPause();
        } else if (action == 'action_next') {
          next();
        } else if (action == 'action_prev') {
          previous();
        }
      } else if (call.method == 'onSeekTo') {
        final posMs = call.arguments is Map ? call.arguments['positionMs'] : null;
        if (posMs is num) {
          seek(Duration(milliseconds: posMs.toInt()));
        }
      } else if (call.method == 'openNowPlaying') {
        openNowPlayingFromNotification();
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _initNotificationChannel() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await androidPlugin.deleteNotificationChannel('bhajan_media_playback_channel');
      } catch (_) {}
      const androidChannel = AndroidNotificationChannel(
        notificationChannelId,
        notificationChannelName,
        description: 'Active devotional bhajan media playback controls',
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Opens the now playing screen from notification click
  void openNowPlayingFromNotification() {
    final track = currentTrack;
    if (track == null) return;

    void pushScreen(int retries) {
      final state = rootNavigatorKey.currentState;
      if (state != null) {
        state.push(
          MaterialPageRoute(
            builder: (_) => BhajanNowPlayingScreen(
              currentTrack: track,
              queue: queue,
            ),
          ),
        );
      } else if (retries > 0) {
        Future.delayed(const Duration(milliseconds: 250), () => pushScreen(retries - 1));
      }
    }

    pushScreen(6);
  }

  /// Plays a track. If the same track is paused, it simply resumes.
  Future<void> playTrack(
    BhajanTrackItem track, {
    List<BhajanTrackItem>? queue,
    String? token,
  }) async {
    if (token != null && token.isNotEmpty) {
      _activeToken = token;
    } else if (_activeToken.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _activeToken = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    }

    if (queue != null && queue.isNotEmpty) {
      _queue = List.from(queue);
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
      if (_currentIndex == -1) {
        _queue.insert(0, track);
        _currentIndex = 0;
      }
    } else if (_queue.isEmpty || !_queue.any((t) => t.id == track.id)) {
      _queue = [track];
      _currentIndex = 0;
    }

    // Always move this track to the #1 position in Recent Plays immediately
    BhajanLibraryService.instance.recordRecentPlay(track);

    final isSameTrack = currentTrack != null &&
        ((currentTrack!.id.isNotEmpty && currentTrack!.id == track.id) ||
            currentTrack!.title.trim().toLowerCase() == track.title.trim().toLowerCase());

    // If it's already the current track and is playing (or buffering), keep playing from current position!
    if (isSameTrack) {
      if (playerStateNotifier.value == PlayerState.playing || isBufferingNotifier.value) {
        return;
      }
      if (playerStateNotifier.value == PlayerState.paused) {
        await resume();
        return;
      }
    }

    currentTrackNotifier.value = track;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    isBufferingNotifier.value = true;

    try {
      // 1. Check if this bhajan is downloaded locally in App Offline Storage (Spotify-style offline play!)
      final localAudioPath = await BhajanLibraryService.instance.resolveOfflineAudioFilePath(track);
      if (localAudioPath != null && File(localAudioPath).existsSync()) {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(DeviceFileSource(localAudioPath));
        playerStateNotifier.value = PlayerState.playing;
        await _audioPlayer.resume();
        isBufferingNotifier.value = false;
        _recordPlay(track.id);
        _updateMediaNotification();
        return;
      }

      // Also check if track.audioUrl itself points to a local file on disk
      final rawUrl = track.audioUrl ?? '';
      if (rawUrl.isNotEmpty && !rawUrl.startsWith('http') && File(rawUrl).existsSync()) {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(DeviceFileSource(rawUrl));
        playerStateNotifier.value = PlayerState.playing;
        await _audioPlayer.resume();
        isBufferingNotifier.value = false;
        _recordPlay(track.id);
        _updateMediaNotification();
        return;
      }

      // 2. Otherwise stream over network
      String streamUrl = rawUrl;
      if (streamUrl.isEmpty || !streamUrl.startsWith('http')) {
        streamUrl = await ApiService.fetchBhajanStreamUrl(_activeToken, track.id);
      }

      if (streamUrl.isEmpty || streamUrl.startsWith('blob:')) {
        throw Exception('Invalid audio stream URL.');
      }

      await _audioPlayer.stop();
      await _audioPlayer.setSource(UrlSource(streamUrl));
      playerStateNotifier.value = PlayerState.playing;
      await _audioPlayer.resume();
      isBufferingNotifier.value = false;

      // Record play count on backend
      _recordPlay(track.id);
      _updateMediaNotification();
    } catch (e) {
      isBufferingNotifier.value = false;
      debugPrint('[BhajanAudioService] playTrack error: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    playerStateNotifier.value = PlayerState.paused;
    try {
      final pos = await _audioPlayer.getCurrentPosition();
      if (pos != null) {
        positionNotifier.value = pos;
      }
    } catch (_) {}
    await _audioPlayer.pause();
    _updateMediaNotification();
  }

  Future<void> resume() async {
    if (_audioPlayer.source != null) {
      playerStateNotifier.value = PlayerState.playing;
      await _audioPlayer.resume();
      _updateMediaNotification();
    } else if (currentTrack != null) {
      await playTrack(currentTrack!, queue: _queue, token: _activeToken);
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    int nextIdx = _currentIndex + 1;
    if (nextIdx >= _queue.length) {
      nextIdx = 0; // loop queue
    }
    _currentIndex = nextIdx;
    await playTrack(_queue[_currentIndex], token: _activeToken);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    int prevIdx = _currentIndex - 1;
    if (prevIdx < 0) {
      prevIdx = _queue.length - 1;
    }
    _currentIndex = prevIdx;
    await playTrack(_queue[_currentIndex], token: _activeToken);
  }

  Future<void> seek(Duration targetPosition) async {
    await _audioPlayer.seek(targetPosition);
    positionNotifier.value = targetPosition;
    _updateMediaNotification();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    currentTrackNotifier.value = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    _cancelMediaNotification();
  }

  void _recordPlay(String trackId) {
    if (trackId.isEmpty) return;
    ApiService.recordBhajanPlay(trackId, token: _activeToken).catchError((e) {
      debugPrint('[BhajanAudioService] recordPlay error: $e');
      return <String, dynamic>{};
    });
  }

  /// Resolves the actual track deity/bhajan image as high-resolution notification artwork via disk cache
  Future<String> _resolveLocalArtworkPath(BhajanTrackItem track) async {
    try {
      String path = track.imagePath.trim();
      if (path.isEmpty) return '';

      if (path.startsWith('https://api.bharatpray.com/uploads/')) {
        path = path.replaceFirst('https://api.bharatpray.com/uploads/', '${ApiService.baseUrl}/uploads/');
      } else if (path.startsWith('/uploads/')) {
        path = '${ApiService.baseUrl}$path';
      }

      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/bhajan_art_${track.id.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}.png');

      if (await localFile.exists() && (await localFile.length()) > 500) {
        return localFile.path;
      }

      Uint8List? bytes;
      if (path.startsWith('data:image')) {
        final commaIdx = path.indexOf(',');
        final base64Str = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        bytes = base64Decode(base64Str);
      } else if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        bytes = byteData.buffer.asUint8List();
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        final res = await http.get(Uri.parse(path)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          bytes = res.bodyBytes;
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        await localFile.writeAsBytes(bytes);
        return localFile.path;
      }
    } catch (e) {
      debugPrint('[BhajanAudioService] _resolveLocalArtworkPath error: $e');
    }
    return '';
  }

  /// Spotify-style rich active native media notification with live progress bar and authentic artwork
  Future<void> _updateMediaNotification() async {
    final track = currentTrack;
    if (track == null) return;

    final isPlayingNow = isPlaying;
    final durationSec = duration.inSeconds;
    final positionSec = position.inSeconds;

    final String localArtPath = await _resolveLocalArtworkPath(track);

    final String timeStr = durationSec > 0
        ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
        : '';
    final String bodyStr = timeStr.isNotEmpty
        ? '$timeStr • ${track.singer}'
        : (track.singer.isNotEmpty ? track.singer : 'Devotional Melody');

    if (Platform.isAndroid) {
      try {
        await _nativeMediaChannel.invokeMethod('showMediaNotification', {
          'title': track.title,
          'subtitle': bodyStr,
          'isPlaying': isPlayingNow,
          'imagePath': localArtPath,
          'durationSec': durationSec,
          'positionSec': positionSec,
        });
        return;
      } catch (e) {
        debugPrint('[BhajanAudioService] native showMediaNotification error: $e');
      }
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = const NotificationDetails(iOS: iosDetails);

    try {
      await _notificationsPlugin.show(
        notificationId,
        track.title,
        bodyStr,
        notificationDetails,
        payload: 'bhajan_now_playing',
      );
    } catch (e) {
      debugPrint('[BhajanAudioService] notification update error: $e');
    }
  }

  Future<void> _cancelMediaNotification() async {
    if (Platform.isAndroid) {
      try {
        await _nativeMediaChannel.invokeMethod('cancelMediaNotification');
      } catch (_) {}
    }
    try {
      await _notificationsPlugin.cancel(notificationId);
    } catch (_) {}
  }
}
