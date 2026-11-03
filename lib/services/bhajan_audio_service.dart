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

/// Global singleton audio service managing devotional bhajan playback,
/// background audio persistence, queue management, and Spotify-style media notifications.
class BhajanAudioService {
  BhajanAudioService._internal() {
    _initAudioPlayer();
    _setupIsolatePort();
  }

  static final BhajanAudioService instance = BhajanAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

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
      final currentSec = pos.inSeconds;
      if ((currentSec - _lastNotificationPositionSec).abs() >= 2) {
        _lastNotificationPositionSec = currentSec;
        _updateMediaNotification();
      }
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

    // If it's already the current track and is paused, simply resume
    if (currentTrack?.id == track.id && playerStateNotifier.value == PlayerState.paused) {
      await resume();
      return;
    }

    currentTrackNotifier.value = track;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    isBufferingNotifier.value = true;

    try {
      String streamUrl = track.audioUrl ?? '';
      if (streamUrl.isEmpty) {
        streamUrl = await ApiService.fetchBhajanStreamUrl(_activeToken, track.id);
      }

      if (streamUrl.isEmpty || streamUrl.startsWith('blob:')) {
        throw Exception('Invalid audio stream URL.');
      }

      await _audioPlayer.stop();
      await _audioPlayer.setSource(UrlSource(streamUrl));
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
    await _audioPlayer.pause();
    _updateMediaNotification();
  }

  Future<void> resume() async {
    if (_audioPlayer.source != null) {
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
  Future<AndroidBitmap<Object>> _resolveLargeIcon(BhajanTrackItem track) async {
    try {
      String path = track.imagePath.trim();
      if (path.isEmpty) {
        return const DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
      }
      if (path.startsWith('https://api.bharatpray.com/uploads/')) {
        path = path.replaceFirst('https://api.bharatpray.com/uploads/', '${ApiService.baseUrl}/uploads/');
      } else if (path.startsWith('/uploads/')) {
        path = '${ApiService.baseUrl}$path';
      }

      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/bhajan_art_${track.id.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}.png');

      if (await localFile.exists() && (await localFile.length()) > 500) {
        return FilePathAndroidBitmap(localFile.path);
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
        return FilePathAndroidBitmap(localFile.path);
      }
    } catch (e) {
      debugPrint('[BhajanAudioService] _resolveLargeIcon error: $e');
    }
    return const DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
  }

  /// Active media notification with live seek progress bar and authentic artwork
  Future<void> _updateMediaNotification() async {
    final track = currentTrack;
    if (track == null) return;

    final isPlayingNow = isPlaying;
    final durationSec = duration.inSeconds;
    final positionSec = position.inSeconds;

    final largeIcon = await _resolveLargeIcon(track);

    final String timeStr = durationSec > 0
        ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
        : '';
    final String bodyStr = timeStr.isNotEmpty
        ? '$timeStr • ${track.singer}'
        : (track.singer.isNotEmpty ? track.singer : 'Devotional Melody');

    final androidDetails = AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: 'Active devotional bhajan media playback controls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.transport,
      ongoing: isPlayingNow,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      visibility: NotificationVisibility.public,
      largeIcon: largeIcon,
      showProgress: durationSec > 0,
      maxProgress: durationSec > 0 ? durationSec : 100,
      progress: (positionSec <= durationSec && positionSec >= 0) ? positionSec : 0,
      indeterminate: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_prev',
          'Prev',
          icon: DrawableResourceAndroidBitmap('ic_media_prev'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'action_play_pause',
          isPlayingNow ? 'Pause' : 'Play',
          icon: DrawableResourceAndroidBitmap(isPlayingNow ? 'ic_media_pause' : 'ic_media_play'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'action_next',
          'Next',
          icon: DrawableResourceAndroidBitmap('ic_media_next'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
    try {
      await _notificationsPlugin.cancel(notificationId);
    } catch (_) {}
  }
}
