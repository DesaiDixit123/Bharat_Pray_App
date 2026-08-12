import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'jap_offline_repository.dart';

enum SyncResultStatus {
  success,
  serverNewer,
  offline,
  authError,
  notFound,
  error,
}

class SyncResult {
  final SyncResultStatus status;
  final String message;
  final Map<String, dynamic>? serverData;

  SyncResult({required this.status, required this.message, this.serverData});
}

/// Reliable background synchronization service coordinating offline records with backend cloud storage.
class JapSyncService {
  static final JapSyncService _instance = JapSyncService._internal();
  factory JapSyncService() => _instance;
  JapSyncService._internal();

  bool _isSyncing = false;
  final Map<String, int> _retryCounts = {};
  static const int _maxRetries = 3;

  /// Directly synchronizes a single offline session record with the cloud backend
  Future<SyncResult> syncSessionDirect(JapOfflineSessionRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      if (token == null || token.trim().isEmpty) {
        debugPrint(
          '[JapSyncService] User is not authenticated. Session remains cached locally.',
        );
        return SyncResult(
          status: SyncResultStatus.authError,
          message: 'User authentication is not available.',
        );
      }

      final response = await ApiService.syncJapProgress(
        token,
        record.japId,
        record.currentCount,
        completedMalas: record.completedMalas,
        sessionId: record.sessionId,
        lastJapAt: record.lastJapAt,
      ).timeout(const Duration(seconds: 12));

      // 1. Process server reconciliation
      final serverProgress = (response['progress'] is num)
          ? (response['progress'] as num).toInt()
          : record.currentCount;
      final serverMalas = (response['completedMalas'] is num)
          ? (response['completedMalas'] as num).toInt()
          : record.completedMalas;
      final serverTarget = (response['targetCount'] is num)
          ? (response['targetCount'] as num).toInt()
          : record.targetCount;

      final serverLifetime = (serverMalas * serverTarget) + serverProgress;
      final localLifetime =
          (record.completedMalas * record.targetCount) + record.currentCount;

      if (serverLifetime > localLifetime) {
        // Server has newer/higher progress from another synchronized session -> Reconcile local storage
        debugPrint(
          '[JapSyncService] Reconciling with newer server state: $serverLifetime > $localLifetime',
        );
        await JapOfflineRepository.saveProgress(
          japId: record.japId,
          count: serverProgress,
          completedMalas: serverMalas,
          targetCount: serverTarget,
          markDirty: false,
        );
        await JapOfflineRepository.markSynced(record.japId);
        _retryCounts.remove(record.japId);
        return SyncResult(
          status: SyncResultStatus.serverNewer,
          message: 'Reconciled local store with newer server progress.',
          serverData: response,
        );
      }

      // Local count was accepted by server
      await JapOfflineRepository.markSynced(record.japId);
      _retryCounts.remove(record.japId);

      return SyncResult(
        status: SyncResultStatus.success,
        message: 'Jap session synchronized successfully.',
        serverData: response,
      );
    } on SocketException catch (e) {
      debugPrint(
        '[JapSyncService] Device is offline / network unreachable: $e',
      );
      _recordRetry(record.japId);
      return SyncResult(
        status: SyncResultStatus.offline,
        message: 'Device is offline. Changes preserved in local queue.',
      );
    } on TimeoutException catch (e) {
      debugPrint('[JapSyncService] Network timeout during sync: $e');
      _recordRetry(record.japId);
      return SyncResult(
        status: SyncResultStatus.offline,
        message: 'Network request timed out. Will retry.',
      );
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('401') ||
          errorMsg.contains('403') ||
          errorMsg.contains('unauthorized')) {
        return SyncResult(
          status: SyncResultStatus.authError,
          message: 'Authentication failed. Please login again.',
        );
      } else if (errorMsg.contains('404') ||
          errorMsg.contains('not found') ||
          errorMsg.contains('disabled')) {
        // Jap deleted/disabled -> Mark synced to prevent infinite retry loops
        await JapOfflineRepository.markSynced(record.japId);
        return SyncResult(
          status: SyncResultStatus.notFound,
          message: 'Jap configuration not found or disabled.',
        );
      }

      debugPrint('[JapSyncService] Unexpected sync error: $e');
      _recordRetry(record.japId);
      return SyncResult(status: SyncResultStatus.error, message: e.toString());
    }
  }

  /// Drains all pending dirty sessions and syncs them to backend
  Future<int> syncAllPending() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    int successCount = 0;

    try {
      final pendingRecords = await JapOfflineRepository.getPendingSyncRecords();
      for (final record in pendingRecords) {
        final retries = _retryCounts[record.japId] ?? 0;
        if (retries >= _maxRetries) {
          debugPrint(
            '[JapSyncService] Skipping "${record.japId}" (exceeded $_maxRetries retry attempts).',
          );
          continue;
        }

        final result = await syncSessionDirect(record);
        if (result.status == SyncResultStatus.success ||
            result.status == SyncResultStatus.serverNewer) {
          successCount++;
        } else if (result.status == SyncResultStatus.authError ||
            result.status == SyncResultStatus.offline) {
          // If network is offline or unauthenticated, break early to conserve device battery
          break;
        }
      }
    } catch (e) {
      debugPrint('[JapSyncService] Error during syncAllPending: $e');
    } finally {
      _isSyncing = false;
    }
    return successCount;
  }

  void _recordRetry(String japId) {
    final current = _retryCounts[japId] ?? 0;
    _retryCounts[japId] = current + 1;
  }

  /// Resets retry counters (e.g. on network reconnection)
  void resetRetryQueue() {
    _retryCounts.clear();
  }
}
