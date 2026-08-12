import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jap_models.dart';

/// Structured offline-first session record ready for immediate UI loading and background sync.
class JapOfflineSessionRecord {
  final String sessionId;
  final String? userId;
  final String japId;
  final int currentCount;
  final int targetCount;
  final int completedMalas;
  final JapLifecycle status;
  final DateTime startedAt;
  final DateTime lastJapAt;
  final bool isCompleted;
  final int schemaVersion;
  final bool isDirty;

  JapOfflineSessionRecord({
    required this.sessionId,
    this.userId,
    required this.japId,
    required this.currentCount,
    this.targetCount = 108,
    this.completedMalas = 0,
    required this.status,
    required this.startedAt,
    required this.lastJapAt,
    required this.isCompleted,
    this.schemaVersion = 1,
    this.isDirty = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'japId': japId,
      'currentCount': currentCount,
      'targetCount': targetCount,
      'completedMalas': completedMalas,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'lastJapAt': lastJapAt.toIso8601String(),
      'isCompleted': isCompleted,
      'schemaVersion': schemaVersion,
      'isDirty': isDirty,
    };
  }

  factory JapOfflineSessionRecord.fromJson(
    Map<String, dynamic> json, {
    int? targetCountOverride,
  }) {
    final rawTarget =
        targetCountOverride ??
        (json['targetCount'] is num
            ? (json['targetCount'] as num).toInt()
            : 108);
    final target = rawTarget > 0 ? rawTarget : 108;
    final rawCount = (json['currentCount'] is num)
        ? (json['currentCount'] as num).toInt()
        : 0;
    final count = rawCount.clamp(0, target);
    final malas = (json['completedMalas'] is num)
        ? (json['completedMalas'] as num).toInt()
        : 0;

    JapLifecycle status;
    try {
      status = JapLifecycle.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['status']?.toString().toLowerCase() ?? ''),
        orElse: () => count >= target
            ? JapLifecycle.completed
            : (count > 0 ? JapLifecycle.inProgress : JapLifecycle.idle),
      );
    } catch (_) {
      status = count >= target
          ? JapLifecycle.completed
          : (count > 0 ? JapLifecycle.inProgress : JapLifecycle.idle);
    }

    final startedAt = json['startedAt'] != null
        ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final lastJapAt = json['lastJapAt'] != null
        ? DateTime.tryParse(json['lastJapAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    final isCompleted =
        json['isCompleted'] == true ||
        count >= target ||
        status == JapLifecycle.completed;

    return JapOfflineSessionRecord(
      sessionId:
          json['sessionId']?.toString() ??
          'session_${json['japId']}_${startedAt.millisecondsSinceEpoch}',
      userId: json['userId']?.toString(),
      japId: json['japId']?.toString() ?? '',
      currentCount: count,
      targetCount: target,
      completedMalas: malas,
      status: status,
      startedAt: startedAt,
      lastJapAt: lastJapAt,
      isCompleted: isCompleted,
      schemaVersion: (json['schemaVersion'] is num)
          ? (json['schemaVersion'] as num).toInt()
          : 1,
      isDirty: json['isDirty'] == true,
    );
  }

  /// Creates a clean initial session fallback
  factory JapOfflineSessionRecord.empty(
    String japId, {
    int targetCount = 108,
    String? userId,
  }) {
    final now = DateTime.now();
    return JapOfflineSessionRecord(
      sessionId: 'session_${japId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      japId: japId,
      currentCount: 0,
      targetCount: targetCount > 0 ? targetCount : 108,
      completedMalas: 0,
      status: JapLifecycle.idle,
      startedAt: now,
      lastJapAt: now,
      isCompleted: false,
      isDirty: false,
    );
  }
}

/// Offline-first repository handling local caching, corrupted data recovery, and sync queue
class JapOfflineRepository {
  static const String _prefixSession = 'jap_session_v2_';
  static const String _prefixCount = 'jap_count_';
  static const String _prefixMalas = 'jap_malas_';
  static const String _prefixDirty = 'jap_dirty_';
  static const String _customJapsKey = 'user_custom_japs_list';

  /// Saves a complete structured session record to SharedPreferences
  static Future<void> saveSession(JapOfflineSessionRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Save full JSON record
      final jsonStr = json.encode(record.toJson());
      await prefs.setString('$_prefixSession${record.japId}', jsonStr);

      // 2. Mirror legacy keys for backward compatibility
      await prefs.setInt('$_prefixCount${record.japId}', record.currentCount);
      await prefs.setInt('$_prefixMalas${record.japId}', record.completedMalas);
      if (record.isDirty) {
        await prefs.setBool('$_prefixDirty${record.japId}', true);
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error saving structured session: $e');
    }
  }

  /// Retrieves structured session record with resilient corrupted data recovery
  static Future<JapOfflineSessionRecord> getSession(
    String japId, {
    int defaultTarget = 108,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Try structured JSON session key
      final jsonStr = prefs.getString('$_prefixSession$japId');
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        try {
          final decoded = json.decode(jsonStr) as Map<String, dynamic>;
          return JapOfflineSessionRecord.fromJson(
            decoded,
            targetCountOverride: defaultTarget,
          );
        } catch (e) {
          debugPrint(
            '[JapOfflineRepository] Corrupted session JSON for "$japId": $e. Recovering from legacy store.',
          );
        }
      }

      // 2. Fallback: Recover from legacy count & malas keys
      final legacyCount = prefs.getInt('$_prefixCount$japId') ?? 0;
      final legacyMalas = prefs.getInt('$_prefixMalas$japId') ?? 0;
      final target = defaultTarget > 0 ? defaultTarget : 108;
      final count = legacyCount.clamp(0, target);
      final isDirty = prefs.getBool('$_prefixDirty$japId') ?? false;

      final now = DateTime.now();
      final status = count >= target
          ? JapLifecycle.completed
          : (count > 0 ? JapLifecycle.inProgress : JapLifecycle.idle);

      return JapOfflineSessionRecord(
        sessionId: 'session_${japId}_recovered_${now.millisecondsSinceEpoch}',
        userId: userId,
        japId: japId,
        currentCount: count,
        targetCount: target,
        completedMalas: legacyMalas,
        status: status,
        startedAt: now,
        lastJapAt: now,
        isCompleted: count >= target,
        isDirty: isDirty,
      );
    } catch (e) {
      debugPrint(
        '[JapOfflineRepository] Critical error reading session for "$japId": $e',
      );
      return JapOfflineSessionRecord.empty(
        japId,
        targetCount: defaultTarget,
        userId: userId,
      );
    }
  }

  /// Save current active progress to disk cache
  static Future<void> saveProgress({
    required String japId,
    required int count,
    required int completedMalas,
    int targetCount = 108,
    JapLifecycle status = JapLifecycle.inProgress,
    String? userId,
    bool markDirty = true,
  }) async {
    final now = DateTime.now();
    final record = JapOfflineSessionRecord(
      sessionId: 'session_${japId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      japId: japId,
      currentCount: count,
      targetCount: targetCount,
      completedMalas: completedMalas,
      status: status,
      startedAt: now,
      lastJapAt: now,
      isCompleted: count >= targetCount,
      isDirty: markDirty,
    );
    await saveSession(record);
  }

  /// Retrieve locally cached progress map
  static Future<Map<String, int>> getProgress(
    String japId, {
    int defaultTarget = 108,
  }) async {
    final session = await getSession(japId, defaultTarget: defaultTarget);
    return {
      'count': session.currentCount,
      'completedMalas': session.completedMalas,
    };
  }

  /// Mark progress as synced to cloud
  static Future<void> markSynced(String japId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefixDirty$japId');

      final sessionStr = prefs.getString('$_prefixSession$japId');
      if (sessionStr != null) {
        final decoded = json.decode(sessionStr) as Map<String, dynamic>;
        decoded['isDirty'] = false;
        await prefs.setString('$_prefixSession$japId', json.encode(decoded));
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error clearing dirty flag: $e');
    }
  }

  /// Check if a Jap has unsynced local counts
  static Future<bool> isDirty(String japId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefixDirty$japId') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all pending dirty Jap records for background batch sync
  static Future<List<JapOfflineSessionRecord>> getPendingSyncRecords() async {
    List<JapOfflineSessionRecord> list = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefixSession));
      for (final sessionKey in keys) {
        final japId = sessionKey.replaceFirst(_prefixSession, '');
        final record = await getSession(japId);
        if (record.isDirty) {
          list.add(record);
        }
      }
    } catch (e) {
      debugPrint(
        '[JapOfflineRepository] Error fetching pending sync records: $e',
      );
    }
    return list;
  }

  /// Legacy helper for pending syncs
  static Future<List<Map<String, dynamic>>> getPendingSyncs() async {
    final records = await getPendingSyncRecords();
    return records
        .map(
          (r) => {
            'japId': r.japId,
            'totalCount': (r.completedMalas * r.targetCount) + r.currentCount,
            'completedMalas': r.completedMalas,
            'currentCount': r.currentCount,
          },
        )
        .toList();
  }

  /// Save a user custom Jap locally
  static Future<void> saveCustomJap(Map<String, dynamic> customJapJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(_customJapsKey);
      List<dynamic> list = existingStr != null ? json.decode(existingStr) : [];
      final newId = customJapJson['id'] ?? customJapJson['_id'];
      if (newId != null) {
        list.removeWhere((item) => (item['id'] ?? item['_id']) == newId);
      }
      list.insert(0, customJapJson);
      await prefs.setString(_customJapsKey, json.encode(list));
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error saving custom Jap: $e');
    }
  }

  /// Get all user custom Japs
  static Future<List<Map<String, dynamic>>> getCustomJaps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(_customJapsKey);
      if (existingStr != null) {
        final decoded = json.decode(existingStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error fetching custom Japs: $e');
    }
    return [];
  }
}
