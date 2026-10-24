import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

enum DarshanAnimationMode {
  aiVideo,
  localDarshanEngine,
  offlineFallback,
}

class DarshanAnimationResult {
  final bool hasVideo;
  final DarshanAnimationMode mode;
  final String? videoUrl;
  final String? localFilePath;
  final String? assetVideoPath;
  final String message;
  final Map<String, dynamic>? engineConfig;

  const DarshanAnimationResult({
    required this.hasVideo,
    required this.mode,
    this.videoUrl,
    this.localFilePath,
    this.assetVideoPath,
    this.message = '',
    this.engineConfig,
  });
}

/// Service to query and cache AI-powered Live Darshan animations
class DarshanAnimationService {
  static final Map<String, DarshanAnimationResult> _memoryCache = {};

  /// Fetches animation metadata for the deity, checking local disk cache first,
  /// then backend API, and gracefully falling back to the local live darshan engine.
  static Future<DarshanAnimationResult> getDarshanAnimation({
    required String deityId,
    required String deityName,
    String? localImageAsset,
  }) async {
    final cacheKey = deityId.toLowerCase().trim();
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // Built-in live darshan video asset for Lord Shri Ram
    if (cacheKey.contains('ram') || deityName.toLowerCase().contains('ram')) {
      const result = DarshanAnimationResult(
        hasVideo: true,
        mode: DarshanAnimationMode.aiVideo,
        assetVideoPath: 'assets/videos/lord_shri_ram_live_darshan.mp4',
        message: 'Loaded Lord Shri Ram live darshan video asset',
      );
      _memoryCache[cacheKey] = result;
      return result;
    }

    try {
      // 1. Check local persistent disk cache for previously downloaded/generated MP4
      try {
        final cacheDir = await getTemporaryDirectory();
        final localFile = File('${cacheDir.path}/darshan_ai_$cacheKey.mp4');
        if (await localFile.exists() && (await localFile.length()) > 1024) {
          final result = DarshanAnimationResult(
            hasVideo: true,
            mode: DarshanAnimationMode.aiVideo,
            localFilePath: localFile.path,
            message: 'Loaded from local device video cache',
          );
          _memoryCache[cacheKey] = result;
          return result;
        }
      } catch (e) {
        debugPrint('[DarshanService] Disk cache check: $e');
      }

      // 2. Query backend endpoint /api/darshan/animation
      final uri = Uri.parse('${ApiService.baseUrl}/api/darshan/animation?deity_id=$cacheKey&deity_name=${Uri.encodeComponent(deityName)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final payload = data['Data'] as Map<String, dynamic>? ?? {};

        final bool hasVideo = payload['hasVideo'] == true;
        final String? relativeUrl = payload['videoUrl'];

        if (hasVideo && relativeUrl != null && relativeUrl.isNotEmpty) {
          final fullUrl = relativeUrl.startsWith('http')
              ? relativeUrl
              : '${ApiService.baseUrl}$relativeUrl';

          final result = DarshanAnimationResult(
            hasVideo: true,
            mode: DarshanAnimationMode.aiVideo,
            videoUrl: fullUrl,
            message: 'AI video streaming ready',
          );
          _memoryCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('[DarshanService] Backend query fallback: $e');
    }

    // 3. Fallback: High-Fidelity Local Devotional Darshan Animation Engine
    final fallbackResult = DarshanAnimationResult(
      hasVideo: false,
      mode: DarshanAnimationMode.localDarshanEngine,
      message: 'Active Local Devotional Darshan Engine (Zero-Latency Shader Motion)',
      engineConfig: {
        'breathingDurationMs': 6000,
        'auraGlowDurationMs': 2800,
        'raysDurationMs': 24000,
        'particles': 'celestial_petals_and_prana',
      },
    );

    _memoryCache[cacheKey] = fallbackResult;
    return fallbackResult;
  }
}
