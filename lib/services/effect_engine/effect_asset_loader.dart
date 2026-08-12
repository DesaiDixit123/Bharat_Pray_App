import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/jap_models.dart';

/// Preloads, caches, and handles texture/sound assets with graceful fallbacks for missing/corrupt assets.
class EffectAssetLoader {
  static final EffectAssetLoader _instance = EffectAssetLoader._internal();
  factory EffectAssetLoader() => _instance;
  EffectAssetLoader._internal();

  /// Bounded cache: keyed by URL/path. Max 30 entries — evict oldest when full.
  static const int _kMaxCacheEntries = 30;
  final Map<String, ImageProvider> _imageCache = {};
  final Set<String> _failedAssets = {};

  /// Preloads all visual assets referenced in an EffectPack
  Future<void> preloadEffectPackAssets(
    BuildContext context,
    EffectPack pack,
  ) async {
    final urlsToPreload = <String>[];

    if (pack.haloTextureUrl != null && pack.haloTextureUrl!.isNotEmpty) {
      urlsToPreload.add(pack.haloTextureUrl!);
    }
    if (pack.particleTextureUrl != null &&
        pack.particleTextureUrl!.isNotEmpty) {
      urlsToPreload.add(pack.particleTextureUrl!);
    }

    for (final url in urlsToPreload) {
      try {
        final provider = resolveImageProvider(url);
        if (provider != null &&
            !_imageCache.containsKey(url) &&
            !_failedAssets.contains(url)) {
          await precacheImage(provider, context);
          _imageCache[url] = provider;
        }
      } catch (e) {
        debugPrint(
          '[EffectAssetLoader] Failed to preload asset "$url": $e. Using fallback.',
        );
        _failedAssets.add(url);
      }
    }
  }

  /// Resolves an image URL, asset path, or file path into an ImageProvider with fallback
  ImageProvider? resolveImageProvider(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();

    if (_imageCache.containsKey(trimmed)) {
      return _imageCache[trimmed];
    }
    if (_failedAssets.contains(trimmed)) {
      return null;
    }

    try {
      ImageProvider provider;
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        provider = NetworkImage(trimmed);
      } else if (trimmed.startsWith('assets/')) {
        provider = AssetImage(trimmed);
      } else {
        provider = FileImage(File(trimmed));
      }
      _addToCache(trimmed, provider);
      return provider;
    } catch (e) {
      debugPrint(
        '[EffectAssetLoader] Error resolving image provider for "$trimmed": $e',
      );
      _failedAssets.add(trimmed);
      return null;
    }
  }

  /// Adds an entry to the bounded cache, evicting the oldest entry if at capacity.
  void _addToCache(String key, ImageProvider provider) {
    if (_imageCache.length >= _kMaxCacheEntries) {
      // Evict oldest entry (insertion-order of LinkedHashMap via Map in Dart)
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[key] = provider;
  }

  /// Clears the asset cache to release memory
  void clearCache() {
    _imageCache.clear();
    _failedAssets.clear();
  }
}
