import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline Location Queue Service
/// Queues GPS location updates locally when device is offline or network is weak.
/// Flushes location logs to backend in a single batch when connection is restored.
class OfflineLocationQueueService {
  static const String _queueKey = 'offline_yatra_location_queue';
  static final OfflineLocationQueueService _instance = OfflineLocationQueueService._internal();

  factory OfflineLocationQueueService() => _instance;
  OfflineLocationQueueService._internal();

  /// Enqueue a single GPS position update
  Future<void> enqueueLocation({
    required String journeyId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    required double heading,
    required double distanceCompletedKm,
    required double progressPercent,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawQueue = prefs.getStringList(_queueKey) ?? [];

      final item = {
        'journeyId': journeyId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'distanceCompletedKm': distanceCompletedKm,
        'progressPercent': progressPercent,
        'isOfflineSync': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      rawQueue.add(jsonEncode(item));

      // Limit queue to last 500 records to prevent memory overflow
      if (rawQueue.length > 500) {
        rawQueue.removeAt(0);
      }

      await prefs.setStringList(_queueKey, rawQueue);
      debugPrint('📍 [OfflineQueue] Enqueued location fix. Queue size: ${rawQueue.length}');
    } catch (e) {
      debugPrint('Error enqueuing offline location: $e');
    }
  }

  /// Get all queued location items
  Future<List<Map<String, dynamic>>> getQueuedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawQueue = prefs.getStringList(_queueKey) ?? [];
      return rawQueue.map((itemStr) {
        return jsonDecode(itemStr) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('Error reading offline location queue: $e');
      return [];
    }
  }

  /// Flush queued locations by passing a batch handler callback
  Future<bool> flushQueue(Future<bool> Function(List<Map<String, dynamic>> items) batchHandler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawQueue = prefs.getStringList(_queueKey) ?? [];

      if (rawQueue.isEmpty) return true;

      final List<Map<String, dynamic>> items = rawQueue.map((str) => jsonDecode(str) as Map<String, dynamic>).toList();

      final success = await batchHandler(items);
      if (success) {
        await prefs.remove(_queueKey);
        debugPrint('✅ [OfflineQueue] Successfully flushed ${items.length} queued location records.');
        return true;
      }
    } catch (e) {
      debugPrint('Error flushing offline location queue: $e');
    }
    return false;
  }

  /// Clear queue
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}
