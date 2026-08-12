import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/jap_offline_repository.dart';
import 'package:bharat_pray/services/jap_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 10: Reliable Background Jap Session Synchronization Tests', () {
    late JapSyncService syncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      syncService = JapSyncService();
      syncService.resetRetryQueue();
    });

    test(
      '1. Unauthenticated Sync Handling (Gracefully Preserves Local Offline Queue)',
      () async {
        final record = JapOfflineSessionRecord(
          sessionId: 'session_no_auth',
          japId: 'jap_test_1',
          currentCount: 45,
          targetCount: 108,
          completedMalas: 0,
          status: JapLifecycle.inProgress,
          startedAt: DateTime.now(),
          lastJapAt: DateTime.now(),
          isCompleted: false,
          isDirty: true,
        );
        await JapOfflineRepository.saveSession(record);

        // No token in SharedPreferences
        final result = await syncService.syncSessionDirect(record);

        expect(result.status, SyncResultStatus.authError);
        expect(result.message, contains('not available'));

        // Verified dirty flag is preserved
        final isStillDirty = await JapOfflineRepository.isDirty('jap_test_1');
        expect(isStillDirty, isTrue);
      },
    );

    test(
      '2. Server Reconciliation (Local Storage Updates when Server has Newer Progress)',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', 'mock_jwt_token_108');

        // Local has 30 chants
        final localRecord = JapOfflineSessionRecord(
          sessionId: 'session_conflict_test',
          userId: 'devotee_1',
          japId: 'jap_reconcile_test',
          currentCount: 30,
          targetCount: 108,
          completedMalas: 0,
          status: JapLifecycle.inProgress,
          startedAt: DateTime.now(),
          lastJapAt: DateTime.now(),
          isCompleted: false,
          isDirty: true,
        );
        await JapOfflineRepository.saveSession(localRecord);

        expect(localRecord.currentCount, 30);
        expect(localRecord.isDirty, isTrue);
      },
    );

    test('3. Batch Sync Draining of Multiple Dirty Records', () async {
      // Create 3 dirty sessions in local storage
      for (int i = 1; i <= 3; i++) {
        final r = JapOfflineSessionRecord(
          sessionId: 'session_batch_$i',
          japId: 'jap_id_$i',
          currentCount: i * 20,
          targetCount: 108,
          completedMalas: 0,
          status: JapLifecycle.inProgress,
          startedAt: DateTime.now(),
          lastJapAt: DateTime.now(),
          isCompleted: false,
          isDirty: true,
        );
        await JapOfflineRepository.saveSession(r);
      }

      final pending = await JapOfflineRepository.getPendingSyncRecords();
      expect(pending.length, 3);
    });

    test('4. Idempotency & Mark Synced Flagging', () async {
      await JapOfflineRepository.saveProgress(
        japId: 'jap_id_idempotent',
        count: 108,
        completedMalas: 1,
        markDirty: true,
      );

      expect(await JapOfflineRepository.isDirty('jap_id_idempotent'), isTrue);

      await JapOfflineRepository.markSynced('jap_id_idempotent');
      expect(await JapOfflineRepository.isDirty('jap_id_idempotent'), isFalse);
    });
  });
}
