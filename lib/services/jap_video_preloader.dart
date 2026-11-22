import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Downloads and caches MongoDB GridFS Jap Live Darshan MP4 videos locally on the device
/// so 108/108 completion and "Live Darshan" open with ZERO network buffering delay.
class JapVideoPreloader {
  static final Map<String, Future<File?>> _inFlight = {};
  static Directory? _cacheDir;
  static bool _isQueueRunning = false;
  static final List<String> _prefetchQueue = [];
  static final Set<String> _queuedSet = {};

  static Future<Directory> _getCacheDir() async {
    if (_cacheDir != null && await _cacheDir!.exists()) return _cacheDir!;
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/jap_darshan_videos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  static String? _extractFilename(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final raw = uri.pathSegments.last;
    if (raw.isEmpty || !raw.toLowerCase().endsWith('.mp4')) return null;
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Returns the locally cached MongoDB video file if already downloaded (> 100 KB).
  static Future<File?> getCachedFile(String? url) async {
    if (url == null || url.isEmpty) return null;
    final filename = _extractFilename(url);
    if (filename == null) return null;
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/$filename');
      if (await file.exists()) {
        final len = await file.length();
        if (len > 100 * 1024) return file;
      }
    } catch (_) {}
    return null;
  }

  /// Downloads a single deity video from MongoDB GridFS API into local device cache.
  /// Deduplicates concurrent calls for the same file.
  static Future<File?> prefetch(String? url) async {
    if (url == null || url.isEmpty) return null;
    final filename = _extractFilename(url);
    if (filename == null) return null;

    final existing = await getCachedFile(url);
    if (existing != null) return existing;

    if (_inFlight.containsKey(filename)) {
      return _inFlight[filename];
    }

    final future = _downloadToCache(url, filename);
    _inFlight[filename] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(filename);
    }
  }

  static Future<File?> _downloadToCache(String url, String filename) async {
    File? tmpFile;
    try {
      final dir = await _getCacheDir();
      final targetFile = File('${dir.path}/$filename');
      tmpFile = File('${dir.path}/$filename.${DateTime.now().millisecondsSinceEpoch}.tmp');

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request).timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) {
          debugPrint('[JapVideoPreloader] HTTP ${response.statusCode} for $filename');
          return null;
        }
        final sink = tmpFile.openWrite();
        await response.stream.pipe(sink);
        await sink.close();

        final len = await tmpFile.length();
        if (len > 100 * 1024) {
          if (await targetFile.exists()) await targetFile.delete();
          await tmpFile.rename(targetFile.path);
          debugPrint('[JapVideoPreloader] Cached $filename (${(len / 1048576).toStringAsFixed(2)} MB)');
          return targetFile;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[JapVideoPreloader] Prefetch error ($filename): $e');
    }
    try {
      if (tmpFile != null && await tmpFile.exists()) await tmpFile.delete();
    } catch (_) {}
    return null;
  }

  /// Sequentially prefetches multiple deity videos in the background (1 at a time)
  /// so tapping any deity's "Live Darshan" opens instantaneously without hogging bandwidth.
  static void prefetchAll(Iterable<String> urls) {
    for (final url in urls) {
      final filename = _extractFilename(url);
      if (filename != null && !_queuedSet.contains(filename)) {
        _queuedSet.add(filename);
        _prefetchQueue.add(url);
      }
    }
    if (!_isQueueRunning) {
      _drainQueue();
    }
  }

  static Future<void> _drainQueue() async {
    if (_isQueueRunning) return;
    _isQueueRunning = true;
    try {
      while (_prefetchQueue.isNotEmpty) {
        final nextUrl = _prefetchQueue.removeAt(0);
        await prefetch(nextUrl);
      }
    } finally {
      _isQueueRunning = false;
    }
  }

  /// Creates and initializes a VideoPlayerController using:
  /// 1. Locally cached MongoDB GridFS file (~30–60ms instant!)
  /// 2. Live network stream from MongoDB GridFS (while caching in background for next time)
  /// 3. Bundled asset fallback if offline
  static Future<VideoPlayerController?> createInitializedController({
    String? videoUrl,
    String? fallbackAsset,
    bool isSoundEnabled = true,
  }) async {
    final options = VideoPlayerOptions(mixWithOthers: true);
    VideoPlayerController? ctrl;

    // 1. Instant local cache (downloaded from MongoDB GridFS)
    if (videoUrl != null && videoUrl.isNotEmpty && !videoUrl.startsWith('assets/')) {
      final cachedFile = await getCachedFile(videoUrl);
      if (cachedFile != null) {
        VideoPlayerController? fileCtrl;
        try {
          fileCtrl = VideoPlayerController.file(cachedFile, videoPlayerOptions: options);
          await fileCtrl.initialize().timeout(const Duration(seconds: 8));
          ctrl = fileCtrl;
        } catch (e) {
          debugPrint('[JapVideoPreloader] Cached file init failed: $e');
          try {
            await fileCtrl?.dispose();
          } catch (_) {}
        }
      }
    }

    // 2. Network stream from MongoDB GridFS (also cache in background for instant replay)
    if (ctrl == null && videoUrl != null && videoUrl.isNotEmpty) {
      if (!videoUrl.startsWith('assets/')) {
        // Kick off background cache without blocking playback
        prefetch(videoUrl);
      }
      VideoPlayerController? netCtrl;
      try {
        netCtrl = videoUrl.startsWith('assets/')
            ? VideoPlayerController.asset(videoUrl, videoPlayerOptions: options)
            : VideoPlayerController.networkUrl(Uri.parse(videoUrl), videoPlayerOptions: options);
        await netCtrl.initialize().timeout(const Duration(seconds: 12));
        ctrl = netCtrl;
      } catch (e) {
        debugPrint('[JapVideoPreloader] Network/primary init failed: $e');
        try {
          await netCtrl?.dispose();
        } catch (_) {}
      }
    }

    // 3. Asset fallback if offline
    if (ctrl == null && fallbackAsset != null && fallbackAsset.isNotEmpty) {
      VideoPlayerController? assetCtrl;
      try {
        assetCtrl = VideoPlayerController.asset(fallbackAsset, videoPlayerOptions: options);
        await assetCtrl.initialize().timeout(const Duration(seconds: 8));
        ctrl = assetCtrl;
      } catch (e) {
        debugPrint('[JapVideoPreloader] Asset fallback init failed: $e');
        try {
          await assetCtrl?.dispose();
        } catch (_) {}
      }
    }

    if (ctrl != null) {
      try {
        await ctrl.setLooping(true);
        await ctrl.setVolume(isSoundEnabled ? 1.0 : 0.0);
      } catch (e) {
        debugPrint('[JapVideoPreloader] Controller setup error: $e');
      }
    }
    return ctrl;
  }
}
