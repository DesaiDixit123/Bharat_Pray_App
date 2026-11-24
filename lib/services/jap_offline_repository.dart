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

/// Offline-first repository handling local caching, corrupted data recovery, and sync queue (strictly user-scoped)
class JapOfflineRepository {
  static const String _prefixSession = 'jap_session_v2_';
  static const String _prefixCount = 'jap_count_';
  static const String _prefixMalas = 'jap_malas_';
  static const String _prefixDirty = 'jap_dirty_';
  static const String _customJapsKey = 'user_custom_japs_list';

  /// Resolves a unique key prefix per user so different logins never share Jap counts
  static Future<String> _userSuffix([String? explicitUserId]) async {
    if (explicitUserId != null && explicitUserId.trim().isNotEmpty) {
      return 'u_${explicitUserId.trim()}';
    }
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? prefs.getString('userId');
    if (uid != null && uid.trim().isNotEmpty) {
      return 'u_${uid.trim()}';
    }
    final phone = prefs.getString('user_phone') ?? prefs.getString('auth_mobile');
    if (phone != null && phone.trim().isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final clean = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
      if (clean.isNotEmpty) {
        return 'p_$clean';
      }
    }
    final email = prefs.getString('user_email');
    if (email != null && email.trim().isNotEmpty) {
      final cleanEmail = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      return 'e_$cleanEmail';
    }
    return 'guest';
  }

  /// Saves a complete structured session record to SharedPreferences (user-scoped)
  static Future<void> saveSession(JapOfflineSessionRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(record.userId);

      // 1. Save full JSON record
      final jsonStr = json.encode(record.toJson());
      await prefs.setString('${_prefixSession}${uSuffix}_${record.japId}', jsonStr);

      // 2. Count & Malas keys (user-scoped)
      await prefs.setInt('${_prefixCount}${uSuffix}_${record.japId}', record.currentCount);
      await prefs.setInt('${_prefixMalas}${uSuffix}_${record.japId}', record.completedMalas);
      if (record.currentCount > 0) {
        final baseId = record.japId.replaceAll(RegExp(r'_(jal|dhup|prakash|pushp)$'), '');
        await prefs.setString('last_active_jap_id_$uSuffix', baseId);
      }
      if (record.isDirty) {
        await prefs.setBool('${_prefixDirty}${uSuffix}_${record.japId}', true);
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error saving structured session: $e');
    }
  }

  /// Retrieves structured session record with resilient corrupted data recovery (user-scoped)
  static Future<JapOfflineSessionRecord> getSession(
    String japId, {
    int defaultTarget = 108,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);

      // 1. Try structured JSON session key
      final jsonStr = prefs.getString('${_prefixSession}${uSuffix}_$japId');
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        try {
          final decoded = json.decode(jsonStr) as Map<String, dynamic>;
          return JapOfflineSessionRecord.fromJson(
            decoded,
            targetCountOverride: defaultTarget,
          );
        } catch (e) {
          debugPrint(
            '[JapOfflineRepository] Corrupted session JSON for "$japId": $e.',
          );
        }
      }

      // 2. Fallback: Recover from count & malas keys for this user
      final legacyCount = prefs.getInt('${_prefixCount}${uSuffix}_$japId') ?? 0;
      final legacyMalas = prefs.getInt('${_prefixMalas}${uSuffix}_$japId') ?? 0;
      final target = defaultTarget > 0 ? defaultTarget : 108;
      final count = legacyCount.clamp(0, target);
      final isDirty = prefs.getBool('${_prefixDirty}${uSuffix}_$japId') ?? false;

      final now = DateTime.now();
      final status = count >= target
          ? JapLifecycle.completed
          : (count > 0 ? JapLifecycle.inProgress : JapLifecycle.idle);

      return JapOfflineSessionRecord(
        sessionId: 'session_${japId}_${now.millisecondsSinceEpoch}',
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

  /// Save current active progress to disk cache (user-scoped)
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

  /// Completely resets progress for a specific Jap back to 0 for the active user
  static Future<void> resetProgress(String japId, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      await prefs.remove('${_prefixSession}${uSuffix}_$japId');
      await prefs.remove('${_prefixCount}${uSuffix}_$japId');
      await prefs.remove('${_prefixMalas}${uSuffix}_$japId');
      await prefs.remove('${_prefixDirty}${uSuffix}_$japId');
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error resetting progress for "$japId": $e');
    }
  }

  /// Purges old un-scoped legacy keys from earlier versions so they never bleed into user accounts
  static Future<void> cleanupLegacyUnscopedKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasDoneClean = prefs.getBool('legacy_japs_cleaned_v4') ?? false;
      if (hasDoneClean) return;

      final allKeys = prefs.getKeys().toList();
      for (final k in allKeys) {
        if (k.startsWith(_prefixSession) ||
            k.startsWith(_prefixCount) ||
            k.startsWith(_prefixMalas) ||
            k.startsWith(_prefixDirty)) {
          // If it doesn't contain user-scoped tags (_u_, _p_, _e_, _guest_)
          if (!k.contains('_u_') && !k.contains('_p_') && !k.contains('_e_') && !k.contains('guest')) {
            await prefs.remove(k);
          }
        }
      }
      await prefs.remove('user_custom_japs_list');
      await prefs.remove('has_reset_ram_v6');
      await prefs.setBool('legacy_japs_cleaned_v4', true);
      debugPrint('[JapOfflineRepository] Legacy unscoped keys successfully purged.');
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error purging legacy unscoped keys: $e');
    }
  }

  /// Ensures daily Jap progress resets automatically when a new calendar day starts.
  /// Returns true if a new-day reset was performed.
  static Future<bool> ensureDailyReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastDate = prefs.getString('jap_daily_reset_date');

      if (lastDate == null) {
        await prefs.setString('jap_daily_reset_date', todayKey);
        return false;
      }

      if (lastDate != todayKey) {
        final keysToRemove = prefs.getKeys().where((k) =>
            k.startsWith(_prefixSession) ||
            k.startsWith(_prefixCount) ||
            k.startsWith(_prefixMalas) ||
            k.startsWith(_prefixDirty)).toList();

        for (final key in keysToRemove) {
          await prefs.remove(key);
        }
        await prefs.setString('jap_daily_reset_date', todayKey);
        debugPrint('[JapOfflineRepository] Automatic daily Jap reset completed for $todayKey (${keysToRemove.length} keys cleared)');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error during daily reset check: $e');
      return false;
    }
  }

  /// Retrieve locally cached progress map (user-scoped)
  static Future<Map<String, int>> getProgress(
    String japId, {
    int defaultTarget = 108,
    String? userId,
  }) async {
    final session = await getSession(japId, defaultTarget: defaultTarget, userId: userId);
    return {
      'count': session.currentCount,
      'completedMalas': session.completedMalas,
    };
  }

  /// Mark progress as synced to cloud (user-scoped)
  static Future<void> markSynced(String japId, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      await prefs.remove('${_prefixDirty}${uSuffix}_$japId');

      final sessionStr = prefs.getString('${_prefixSession}${uSuffix}_$japId');
      if (sessionStr != null) {
        final decoded = json.decode(sessionStr) as Map<String, dynamic>;
        decoded['isDirty'] = false;
        await prefs.setString('${_prefixSession}${uSuffix}_$japId', json.encode(decoded));
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error clearing dirty flag: $e');
    }
  }

  /// Check if a Jap has unsynced local counts (user-scoped)
  static Future<bool> isDirty(String japId, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      return prefs.getBool('${_prefixDirty}${uSuffix}_$japId') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all pending dirty Jap records for background batch sync (user-scoped)
  static Future<List<JapOfflineSessionRecord>> getPendingSyncRecords({String? userId}) async {
    List<JapOfflineSessionRecord> list = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      final searchPrefix = '${_prefixSession}${uSuffix}_';
      final keys = prefs.getKeys().where((k) => k.startsWith(searchPrefix));
      for (final sessionKey in keys) {
        final japId = sessionKey.replaceFirst(searchPrefix, '');
        final record = await getSession(japId, userId: userId);
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
  static Future<List<Map<String, dynamic>>> getPendingSyncs({String? userId}) async {
    final records = await getPendingSyncRecords(userId: userId);
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

  /// Save a user custom Jap locally (user-scoped)
  static Future<void> saveCustomJap(Map<String, dynamic> customJapJson, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      final key = '${_customJapsKey}_$uSuffix';
      final existingStr = prefs.getString(key);
      List<dynamic> list = existingStr != null ? json.decode(existingStr) : [];
      final newId = customJapJson['id'] ?? customJapJson['_id'];
      if (newId != null) {
        list.removeWhere((item) => (item['id'] ?? item['_id']) == newId);
      }
      list.insert(0, customJapJson);
      await prefs.setString(key, json.encode(list));
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error saving custom Jap: $e');
    }
  }

  /// Remove a user custom Jap locally by ID (user-scoped)
  static Future<void> removeCustomJap(String id, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      final key = '${_customJapsKey}_$uSuffix';
      final existingStr = prefs.getString(key);
      if (existingStr != null) {
        List<dynamic> list = json.decode(existingStr);
        list.removeWhere((item) => (item['id'] ?? item['_id']) == id);
        await prefs.setString(key, json.encode(list));
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error removing custom Jap: $e');
    }
  }

  /// Get all user custom Japs (user-scoped)
  static Future<List<Map<String, dynamic>>> getCustomJaps({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      final key = '${_customJapsKey}_$uSuffix';
      final existingStr = prefs.getString(key);
      if (existingStr != null) {
        final decoded = json.decode(existingStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error fetching custom Japs: $e');
    }
    return [];
  }

  /// Remove/clear all user custom Japs completely (user-scoped)
  static Future<void> clearAllCustomJaps({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uSuffix = await _userSuffix(userId);
      await prefs.remove('${_customJapsKey}_$uSuffix');
      final customKeys = prefs.getKeys().where((k) => k.contains('custom_') && k.contains(uSuffix)).toList();
      for (final key in customKeys) {
        await prefs.remove(key);
      }
      debugPrint('[JapOfflineRepository] Cleared local custom japs for $uSuffix successfully');
    } catch (e) {
      debugPrint('[JapOfflineRepository] Error clearing custom Japs: $e');
    }
  }
}
