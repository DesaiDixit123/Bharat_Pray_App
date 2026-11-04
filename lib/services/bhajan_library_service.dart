import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/localized_api_helper.dart';
import '../models/bhajan_track_item.dart';
import 'api_service.dart';

class BhajanPlaylistModel {
  final String id;
  String name;
  final String iconEmoji;
  final List<BhajanTrackItem> tracks;
  final bool isDefault;

  BhajanPlaylistModel({
    required this.id,
    required this.name,
    this.iconEmoji = '🎶',
    required this.tracks,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconEmoji': iconEmoji,
        'isDefault': isDefault,
        'tracks': tracks.map((t) => _trackToMap(t)).toList(),
      };

  factory BhajanPlaylistModel.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] is List ? (json['tracks'] as List) : [];
    final parsedTracks = <BhajanTrackItem>[];
    for (final item in rawTracks) {
      if (item is Map<String, dynamic>) {
        parsedTracks.add(BhajanTrackItem.fromJson(item));
      }
    }
    return BhajanPlaylistModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Sacred Playlist').toString(),
      iconEmoji: (json['iconEmoji'] ?? '🎶').toString(),
      isDefault: json['isDefault'] == true,
      tracks: parsedTracks,
    );
  }

  static Map<String, dynamic> _trackToMap(BhajanTrackItem t) => {
        '_id': t.id,
        'id': t.id,
        'title': t.title,
        'singer': t.singer,
        'image': t.imagePath,
        'audioUrl': t.audioUrl,
        'duration': t.duration,
        'isLiked': t.isLiked,
        'lyrics': t.lyrics,
      };
}

class BhajanLibraryService extends ChangeNotifier {
  BhajanLibraryService._();
  static final BhajanLibraryService instance = BhajanLibraryService._();

  static const String _kLikedKey = 'bhajan_realtime_liked_v1';
  static const String _kDownloadsKey = 'bhajan_offline_real_downloads_v2';
  static const String _kPlaylistsKey = 'bhajan_realtime_playlists_v1';
  static const String _kRecentKey = 'bhajan_realtime_recent_v1';

  final List<BhajanTrackItem> _likedTracks = [];
  final List<BhajanTrackItem> _downloadedTracks = [];
  final List<BhajanPlaylistModel> _playlists = [];
  final List<BhajanTrackItem> _recentTracks = [];
  final Map<String, String> _localAudioPaths = {};
  final Map<String, String> _localImagePaths = {};
  final Map<String, int> _trackFileSizes = {};
  final Set<String> _downloadingIds = {};
  final Map<String, double> _downloadProgress = {};
  int _totalOfflineStorageBytes = 0;
  bool _initialized = false;

  List<BhajanTrackItem> get likedTracks => List.unmodifiable(_likedTracks);
  List<BhajanTrackItem> get downloadedTracks => List.unmodifiable(_downloadedTracks);
  List<BhajanPlaylistModel> get playlists => List.unmodifiable(_playlists);
  List<BhajanTrackItem> get recentTracks => List.unmodifiable(_recentTracks);

  Set<String> get likedTrackIds => _likedTracks.map((e) => e.id).toSet();
  Set<String> get downloadedTrackIds => _downloadedTracks.map((e) => e.id).toSet();
  int get totalOfflineStorageBytes => _totalOfflineStorageBytes;
  String get formattedTotalStorage => formatBytes(_totalOfflineStorageBytes);

  bool isLiked(String trackId) => _likedTracks.any((t) => t.id == trackId);
  bool isDownloaded(String trackId) => _downloadedTracks.any((t) => t.id == trackId);
  bool isDownloading(String trackId) => _downloadingIds.contains(trackId);
  double getDownloadProgress(String trackId) => _downloadProgress[trackId] ?? 0.0;
  int getDownloadPercentage(String trackId) => ((_downloadProgress[trackId] ?? 0.0) * 100).round().clamp(0, 100);

  bool hasOfflineAudioFile(String trackId) {
    final p = _localAudioPaths[trackId];
    return p != null && p.isNotEmpty && File(p).existsSync();
  }

  String? getLocalAudioPath(String trackId) {
    final p = _localAudioPaths[trackId];
    if (p != null && p.isNotEmpty && File(p).existsSync()) {
      return p;
    }
    return null;
  }

  String? getLocalImagePath(String trackId) {
    final p = _localImagePaths[trackId];
    if (p != null && p.isNotEmpty && File(p).existsSync()) {
      return p;
    }
    return null;
  }

  int getTrackFileSizeBytes(String trackId) => _trackFileSizes[trackId] ?? 0;

  String getFormattedTrackSize(String trackId) {
    final bytes = _trackFileSizes[trackId] ?? 0;
    if (bytes <= 0) return '';
    return formatBytes(bytes);
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    final kb = bytes / 1024.0;
    if (kb < 1024.0) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024.0;
    return '${mb.toStringAsFixed(2)} MB';
  }

  static String _safeKey(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<Directory> _getOfflineDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/bhajan_offline_storage');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _scanOfflineStorage() async {
    try {
      final dir = await _getOfflineDir();
      int total = 0;
      _localAudioPaths.clear();
      _localImagePaths.clear();
      _trackFileSizes.clear();

      for (final t in _downloadedTracks) {
        final key = _safeKey(t.id.isNotEmpty ? t.id : t.title);
        final audioFile = File('${dir.path}/audio_$key.mp3');
        final coverFile = File('${dir.path}/cover_$key.jpg');
        int trackBytes = 0;

        if (audioFile.existsSync()) {
          final len = audioFile.lengthSync();
          if (len > 0) {
            _localAudioPaths[t.id] = audioFile.path;
            trackBytes += len;
          }
        }
        if (coverFile.existsSync()) {
          final len = coverFile.lengthSync();
          if (len > 0) {
            _localImagePaths[t.id] = coverFile.path;
            trackBytes += len;
          }
        }
        if (trackBytes > 0) {
          _trackFileSizes[t.id] = trackBytes;
          total += trackBytes;
        }
      }

      // Also sum any extra files in bhajan_offline_storage
      if (dir.existsSync()) {
        int rawDirTotal = 0;
        for (final entity in dir.listSync()) {
          if (entity is File) {
            rawDirTotal += entity.lengthSync();
          }
        }
        if (rawDirTotal > total) {
          total = rawDirTotal;
        }
      }

      _totalOfflineStorageBytes = total;
      notifyListeners();
    } catch (_) {}
  }

  /// Resolves local offline `.mp3` path if downloaded in App Storage
  Future<String?> resolveOfflineAudioFilePath(BhajanTrackItem track) async {
    final cached = getLocalAudioPath(track.id);
    if (cached != null) return cached;

    try {
      final dir = await _getOfflineDir();
      final key = _safeKey(track.id.isNotEmpty ? track.id : track.title);
      final audioFile = File('${dir.path}/audio_$key.mp3');
      if (audioFile.existsSync() && audioFile.lengthSync() > 0) {
        _localAudioPaths[track.id] = audioFile.path;
        return audioFile.path;
      }
    } catch (_) {}
    return null;
  }

  Future<void> init({String? token}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!_initialized) {
      _initialized = true;
      _loadTrackListFromPrefs(prefs, _kLikedKey, _likedTracks);
      _loadTrackListFromPrefs(prefs, _kDownloadsKey, _downloadedTracks);
      _loadTrackListFromPrefs(prefs, _kRecentKey, _recentTracks);
      _loadPlaylistsFromPrefs(prefs);
      notifyListeners();
    }

    await _scanOfflineStorage();

    final authToken = token ?? prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    if (authToken.isNotEmpty) {
      _syncWithBackend(authToken, prefs);
    }
  }

  void _loadTrackListFromPrefs(
    SharedPreferences prefs,
    String key,
    List<BhajanTrackItem> target,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        target.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            target.add(BhajanTrackItem.fromJson(item));
          }
        }
      }
    } catch (_) {}
  }

  void _loadPlaylistsFromPrefs(SharedPreferences prefs) {
    final raw = prefs.getString(_kPlaylistsKey);
    _playlists.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final model = BhajanPlaylistModel.fromJson(item);
              // Skip old 3 default playlists so only "Listen Later" is the default playlist
              if (model.id == 'default_morning' ||
                  model.id == 'default_evening' ||
                  model.id == 'default_shiv') {
                continue;
              }
              _playlists.add(model);
            }
          }
        }
      } catch (_) {}
    }

    if (!_playlists.any((p) => p.id == 'default_listen_later')) {
      _playlists.insert(
        0,
        BhajanPlaylistModel(
          id: 'default_listen_later',
          name: 'Listen Later',
          iconEmoji: '',
          tracks: [],
          isDefault: true,
        ),
      );
    }
    _savePlaylistsToPrefs(prefs);
  }

  Future<void> _saveTrackListToPrefs(
    String key,
    List<BhajanTrackItem> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      list.map((t) => BhajanPlaylistModel._trackToMap(t)).toList(),
    );
    await prefs.setString(key, encoded);
  }

  Future<void> _savePlaylistsToPrefs([SharedPreferences? existingPrefs]) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    final encoded = jsonEncode(_playlists.map((p) => p.toJson()).toList());
    await prefs.setString(_kPlaylistsKey, encoded);
  }

  Future<void> _syncWithBackend(String token, SharedPreferences prefs) async {
    try {
      final remoteFavs = await ApiService.getFavouriteBhajans(token);
      if (remoteFavs.isNotEmpty) {
        for (final item in remoteFavs) {
          if (item is Map<String, dynamic>) {
            final map = item['bhajan'] is Map<String, dynamic>
                ? item['bhajan'] as Map<String, dynamic>
                : item;
            final track = BhajanTrackItem.fromJson(map);
            if (track.id.isNotEmpty && !_likedTracks.any((e) => e.id == track.id)) {
              _likedTracks.add(track.copyWith(isLiked: true));
            }
          }
        }
        await _saveTrackListToPrefs(_kLikedKey, _likedTracks);
        notifyListeners();
      }
    } catch (_) {}

    // Note: Do NOT auto-populate _downloadedTracks from backend getDownloadedBhajans.
    // Only bhajans explicitly downloaded by the user into local App Storage belong in Downloads,
    // and removed downloads must never reappear when re-entering My Bhajan Library.

    try {
      final remoteHistory = await ApiService.getBhajanHistory(token);
      if (remoteHistory.isNotEmpty) {
        bool addedAny = false;
        for (final item in remoteHistory) {
          if (item is Map<String, dynamic>) {
            final map = item['bhajan'] is Map<String, dynamic>
                ? item['bhajan'] as Map<String, dynamic>
                : (item['bhajanId'] is Map<String, dynamic>
                    ? item['bhajanId'] as Map<String, dynamic>
                    : item);
            final track = BhajanTrackItem.fromJson(map);
            if (track.id.isNotEmpty &&
                !_recentTracks.any((e) => e.id == track.id || e.title.toLowerCase() == track.title.toLowerCase())) {
              if (_recentTracks.length < 30) {
                _recentTracks.add(track);
                addedAny = true;
              }
            }
          }
        }
        if (addedAny) {
          await _saveTrackListToPrefs(_kRecentKey, _recentTracks);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Ensures Recent Plays has a rich pool (20–30 tracks) while keeping
  /// the user's most recently played bhajans strictly at the top (index 0 first).
  void seedRecentPlaysPool(Iterable<BhajanTrackItem> tracks) {
    bool changed = false;
    for (final t in tracks) {
      if (_recentTracks.length >= 30) break;
      final exists = _recentTracks.any(
        (e) => (e.id.isNotEmpty && e.id == t.id) || e.title.toLowerCase() == t.title.toLowerCase(),
      );
      if (!exists) {
        _recentTracks.add(t);
        changed = true;
      }
    }
    if (changed) {
      _saveTrackListToPrefs(_kRecentKey, _recentTracks);
      notifyListeners();
    }
  }

  /// Seed initial liked state from loaded tracks if not already tracked
  void syncLikedFromTracks(Iterable<BhajanTrackItem> tracks) {
    bool changed = false;
    for (final t in tracks) {
      if (t.isLiked && !_likedTracks.any((e) => e.id == t.id)) {
        _likedTracks.insert(0, t.copyWith(isLiked: true));
        changed = true;
      }
    }
    if (changed) {
      _saveTrackListToPrefs(_kLikedKey, _likedTracks);
      notifyListeners();
    }
  }

  /// Toggle Like in real time
  Future<bool> toggleLike(BhajanTrackItem track, {String? token}) async {
    final existingIdx = _likedTracks.indexWhere((t) => t.id == track.id);
    final bool nowLiked;
    if (existingIdx >= 0) {
      _likedTracks.removeAt(existingIdx);
      nowLiked = false;
    } else {
      _likedTracks.insert(0, track.copyWith(isLiked: true));
      nowLiked = true;
    }
    notifyListeners();
    await _saveTrackListToPrefs(_kLikedKey, _likedTracks);

    final prefs = await SharedPreferences.getInstance();
    final authToken = token ?? prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    if (authToken.isNotEmpty) {
      try {
        if (nowLiked) {
          await ApiService.likeBhajan(authToken, track.id);
          await ApiService.addFavouriteBhajan(authToken, track.id);
        } else {
          await ApiService.unlikeBhajan(authToken, track.id);
          await ApiService.removeFavouriteBhajan(authToken, track.id);
        }
      } catch (_) {}
    }
    return nowLiked;
  }

  /// Spotify-style In-App Offline Download with Percentage Progress (0% -> 100%):
  /// Saves `.mp3` audio and `.jpg` cover directly into internal App Storage (`bhajan_offline_storage`),
  /// prevents duplicate downloads, and enables 100% offline playback when internet is OFF.
  Future<bool> downloadTrack(BhajanTrackItem track, {String? token}) async {
    // Prevent downloading a second time if already downloaded or currently downloading
    if (isDownloaded(track.id) || _downloadingIds.contains(track.id)) {
      return false;
    }

    _downloadingIds.add(track.id);
    _downloadProgress[track.id] = 0.02;
    notifyListeners();

    // Smooth visual progress ticker up to 90% while network file transfer completes
    final progressTimer = Timer.periodic(const Duration(milliseconds: 85), (timer) {
      if (!_downloadingIds.contains(track.id)) {
        timer.cancel();
        return;
      }
      final current = _downloadProgress[track.id] ?? 0.02;
      if (current < 0.90) {
        _downloadProgress[track.id] = (current + 0.03).clamp(0.02, 0.90);
        notifyListeners();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final authToken = token ?? prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    String? savedAudioPath;

    try {
      String streamUrl = track.audioUrl ?? '';
      if (streamUrl.isEmpty || !streamUrl.startsWith('http')) {
        streamUrl = await ApiService.fetchBhajanStreamUrl(authToken, track.id);
      }

      final dir = await _getOfflineDir();
      final key = _safeKey(track.id.isNotEmpty ? track.id : track.title);

      if (streamUrl.isNotEmpty && streamUrl.startsWith('http')) {
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(streamUrl));
          final streamedResponse = await client.send(request).timeout(const Duration(seconds: 60));
          if (streamedResponse.statusCode == 200) {
            final totalBytes = streamedResponse.contentLength ?? 0;
            final List<int> bytes = [];
            int received = 0;

            await for (final chunk in streamedResponse.stream) {
              bytes.addAll(chunk);
              received += chunk.length;
              if (totalBytes > 0) {
                final realProgress = (received / totalBytes).clamp(0.05, 0.94);
                if (realProgress > (_downloadProgress[track.id] ?? 0.0)) {
                  _downloadProgress[track.id] = realProgress;
                  notifyListeners();
                }
              }
            }

            if (bytes.isNotEmpty) {
              final audioFile = File('${dir.path}/audio_$key.mp3');
              await audioFile.writeAsBytes(bytes, flush: true);
              _localAudioPaths[track.id] = audioFile.path;
              savedAudioPath = audioFile.path;
            }
          }
        } finally {
          client.close();
        }
      }

      // Also save cover image locally so artwork loads when internet is OFF
      if (track.imagePath.startsWith('http')) {
        try {
          final imgRes = await http.get(Uri.parse(track.imagePath)).timeout(const Duration(seconds: 20));
          if (imgRes.statusCode == 200 && imgRes.bodyBytes.isNotEmpty) {
            final coverFile = File('${dir.path}/cover_$key.jpg');
            await coverFile.writeAsBytes(imgRes.bodyBytes, flush: true);
            _localImagePaths[track.id] = coverFile.path;
          }
        } catch (_) {}
      }

      if (authToken.isNotEmpty && track.id.isNotEmpty) {
        try {
          await ApiService.downloadBhajan(authToken, track.id);
        } catch (_) {}
      }

      // Ensure smooth percentage progression through 100% so it never feels like an instant jump
      progressTimer.cancel();
      double cur = _downloadProgress[track.id] ?? 0.30;
      while (cur < 1.0) {
        cur = (cur + 0.06).clamp(0.0, 1.0);
        _downloadProgress[track.id] = cur;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 55));
      }

      if (!_downloadedTracks.any((t) => t.id == track.id)) {
        _downloadedTracks.insert(
          0,
          track.copyWith(
            audioUrl: savedAudioPath ?? track.audioUrl,
            isDownloaded: true,
          ),
        );
        await _saveTrackListToPrefs(_kDownloadsKey, _downloadedTracks);
      }
    } catch (e) {
      debugPrint('[BhajanLibraryService] Offline download error: $e');
    } finally {
      progressTimer.cancel();
      _downloadingIds.remove(track.id);
      _downloadProgress.remove(track.id);
      await _scanOfflineStorage();
      notifyListeners();
    }

    return true;
  }

  /// Remove downloaded bhajan & delete its `.mp3` / `.jpg` files from App Storage
  Future<void> removeDownload(String trackId) async {
    final existing = _downloadedTracks.where((t) => t.id == trackId).toList();
    _downloadedTracks.removeWhere(
      (t) => t.id == trackId || (existing.isNotEmpty && t.title == existing.first.title),
    );
    notifyListeners();
    await _saveTrackListToPrefs(_kDownloadsKey, _downloadedTracks);

    try {
      final dir = await _getOfflineDir();
      final key = _safeKey(
        trackId.isNotEmpty
            ? trackId
            : (existing.isNotEmpty ? existing.first.title : ''),
      );
      final audioFile = File('${dir.path}/audio_$key.mp3');
      if (audioFile.existsSync()) {
        await audioFile.delete();
      }
      final coverFile = File('${dir.path}/cover_$key.jpg');
      if (coverFile.existsSync()) {
        await coverFile.delete();
      }
    } catch (_) {}

    _localAudioPaths.remove(trackId);
    _localImagePaths.remove(trackId);
    _trackFileSizes.remove(trackId);

    await _scanOfflineStorage();
    notifyListeners();
  }

  /// Record Recently Played track in real time (Last played ALWAYS at index 0)
  Future<void> recordRecentPlay(BhajanTrackItem track) async {
    _recentTracks.removeWhere(
      (t) => (t.id.isNotEmpty && t.id == track.id) || t.title.toLowerCase() == track.title.toLowerCase(),
    );
    _recentTracks.insert(0, track);
    if (_recentTracks.length > 30) {
      _recentTracks.removeRange(30, _recentTracks.length);
    }
    notifyListeners();
    await _saveTrackListToPrefs(_kRecentKey, _recentTracks);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      if (authToken.isNotEmpty && track.id.isNotEmpty) {
        await ApiService.saveBhajanHistory(authToken, track.id, 0);
      }
    } catch (_) {}
  }

  /// Create a new custom playlist
  Future<BhajanPlaylistModel> createPlaylist(String name, {String emoji = '🎶', BhajanTrackItem? initialTrack}) async {
    final cleanName = name.trim();
    final playlist = BhajanPlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      iconEmoji: emoji,
      tracks: initialTrack != null ? [initialTrack] : [],
      isDefault: false,
    );
    _playlists.insert(0, playlist);
    notifyListeners();
    await _savePlaylistsToPrefs();
    return playlist;
  }

  /// Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    await _savePlaylistsToPrefs();
  }

  /// Toggle track inside a playlist
  Future<bool> toggleTrackInPlaylist(String playlistId, BhajanTrackItem track) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return false;
    final playlist = _playlists[idx];
    final existingTrackIdx = playlist.tracks.indexWhere((t) => t.id == track.id);
    final bool added;
    if (existingTrackIdx >= 0) {
      playlist.tracks.removeAt(existingTrackIdx);
      added = false;
    } else {
      playlist.tracks.insert(0, track);
      added = true;
    }
    notifyListeners();
    await _savePlaylistsToPrefs();
    return added;
  }

  bool isTrackInPlaylist(String playlistId, String trackId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return false;
    return _playlists[idx].tracks.any((t) => t.id == trackId);
  }

  static OverlayEntry? _activeNotificationEntry;

  /// Show Top In-App Notification Banner (Visible above all bottom sheets, dialogs & screens!)
  static void showLightSnackBar(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
  }) {
    try {
      _activeNotificationEntry?.remove();
      _activeNotificationEntry = null;
    } catch (_) {}

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final topPadding = MediaQuery.of(ctx).padding.top + 12;
        return Positioned(
          top: topPadding,
          left: 18,
          right: 18,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - val) * -28),
                  child: Opacity(
                    opacity: val.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFF7700), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: const Color(0xFFFF7700), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2E2A36),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeNotificationEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (_activeNotificationEntry == entry) {
        try {
          entry.remove();
        } catch (_) {}
        _activeNotificationEntry = null;
      }
    });
  }

  /// Show Light-Themed Interactive "Add to Playlist" Bottom Sheet with options & Create New Playlist
  static Future<void> showAddToPlaylistSheet(
    BuildContext context,
    BhajanTrackItem track,
  ) async {
    await instance.init();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddToPlaylistBottomSheet(track: track),
    );
  }
}

class _AddToPlaylistBottomSheet extends StatefulWidget {
  final BhajanTrackItem track;
  const _AddToPlaylistBottomSheet({required this.track});

  @override
  State<_AddToPlaylistBottomSheet> createState() => _AddToPlaylistBottomSheetState();
}

class _AddToPlaylistBottomSheetState extends State<_AddToPlaylistBottomSheet> {
  final TextEditingController _newPlaylistController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  Future<void> _handleCreatePlaylist() async {
    final name = _newPlaylistController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.lightImpact();
    final created = await BhajanLibraryService.instance.createPlaylist(
      name,
      initialTrack: widget.track,
    );
    _newPlaylistController.clear();
    if (mounted) {
      BhajanLibraryService.showLightSnackBar(
        context,
        '✅ "${widget.track.title}" ${LocalizedApiHelper.parse("Added to")} "${created.name}"',
        icon: Icons.playlist_add_check_rounded,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: BhajanLibraryService.instance,
      builder: (context, _) {
        final playlists = BhajanLibraryService.instance.playlists;

        return Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFFFFD8B3), width: 1.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8C4AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.queue_music_rounded,
                          color: Color(0xFFFF7700),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizedApiHelper.parse('Add to Playlist'),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            Text(
                              '${widget.track.title} • ${widget.track.singer}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: const Color(0xFF8C7B6E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF8C7B6E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Create New Playlist Input Box (No icon/image picker)
                  if (_isCreatingNew)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizedApiHelper.parse('Create New Playlist'),
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newPlaylistController,
                                  autofocus: true,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: LocalizedApiHelper.parse('Enter playlist name...'),
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF8C7B6E),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFFFF8F2),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFEFE6DB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFEFE6DB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFFF7700)),
                                    ),
                                  ),
                                  onSubmitted: (_) => _handleCreatePlaylist(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _handleCreatePlaylist,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7700),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  LocalizedApiHelper.parse('Create'),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _isCreatingNew = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: Color(0xFFFF7700), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              LocalizedApiHelper.parse('Create New Playlist'),
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF7700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Playlists List (Listen Later + User Created Playlists)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final pl = playlists[index];
                        final inPlaylist = BhajanLibraryService.instance.isTrackInPlaylist(
                          pl.id,
                          widget.track.id,
                        );
                        final isListenLater = pl.id == 'default_listen_later';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: inPlaylist
                                  ? const Color(0xFFFF7700).withValues(alpha: 0.5)
                                  : const Color(0xFFF3E4D6),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final added = await BhajanLibraryService.instance.toggleTrackInPlaylist(
                                pl.id,
                                widget.track,
                              );
                              if (context.mounted) {
                                BhajanLibraryService.showLightSnackBar(
                                  context,
                                  added
                                      ? '✅ "${widget.track.title}" ${LocalizedApiHelper.parse("Added to")} "${LocalizedApiHelper.parse(pl.name)}"'
                                      : '"${widget.track.title}" ${LocalizedApiHelper.parse("Removed from")} "${LocalizedApiHelper.parse(pl.name)}"',
                                  icon: added ? Icons.playlist_add_check_rounded : Icons.remove_circle_outline_rounded,
                                );
                                if (added) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5EB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC8A882), width: 0.8),
                              ),
                              child: Center(
                                child: Icon(
                                  isListenLater ? Icons.watch_later_outlined : Icons.queue_music_rounded,
                                  color: const Color(0xFFFF7700),
                                  size: 21,
                                ),
                              ),
                            ),
                            title: Text(
                              LocalizedApiHelper.parse(pl.name),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            subtitle: Text(
                              '${pl.tracks.length} ${LocalizedApiHelper.parse("Bhajans")}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF8C7B6E),
                              ),
                            ),
                            trailing: Icon(
                              inPlaylist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              color: inPlaylist ? const Color(0xFF2E7D32) : const Color(0xFFFF7700),
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
