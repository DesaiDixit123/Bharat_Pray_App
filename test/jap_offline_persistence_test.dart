import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/jap_offline_repository.dart';
import 'package:bharat_pray/services/jap_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9: Offline-First Jap Session Persistence Tests', () {
    late JapConfig sampleConfig;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sampleConfig = JapConfig(
        id: 'shiva_offline_session_test',
        name: 'Maha Mrityunjaya Mantra',
        thumbnailUrl: 'https://example.com/shiva.png',
        darshanImageUrl: 'https://example.com/darshan.png',
        shlokText: 'ॐ त्र्यम्बकं यजामहे',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );
    });

    test(
      '1. Core Requirement: User reaches 70/108 -> App Closes -> Reopens at 70/108 (No Loss)',
      () async {
        // 1. User starts chanting and reaches 70/108
        final controller1 = JapSessionController(
          config: sampleConfig,
          initialCount: 69,
        );
        await Future.delayed(const Duration(milliseconds: 230));

        final chantSuccess = controller1.performChant();
        expect(chantSuccess, isTrue);
        expect(controller1.currentCount, 70);
        expect(controller1.lifecycle, JapLifecycle.inProgress);
        await controller1.persistState(userId: 'user_devotee_108');

        // 2. Simulate process kill / app close
        controller1.dispose();

        // 3. User reopens the app
        final controller2 = JapSessionController(config: sampleConfig);
        await controller2.initializeFromStorage(userId: 'user_devotee_108');

        // 4. Verification: Exact count, status, and zero count loss
        expect(controller2.currentCount, 70);
        expect(controller2.targetCount, 108);
        expect(controller2.lifecycle, JapLifecycle.inProgress);
        expect(controller2.progressFraction, closeTo(70 / 108, 0.001));
        expect(controller2.isCompleted, isFalse);

        controller2.dispose();
      },
    );

    test(
      '2. Complete Structured Session Record Preservation (Session ID, Timestamps, User ID)',
      () async {
        final startTime = DateTime.now().subtract(const Duration(minutes: 15));
        final lastAction = DateTime.now();

        final record = JapOfflineSessionRecord(
          sessionId: 'session_kashi_shiva_999',
          userId: 'devotee_uuid_42',
          japId: sampleConfig.id,
          currentCount: 54,
          targetCount: 108,
          completedMalas: 3,
          status: JapLifecycle.inProgress,
          startedAt: startTime,
          lastJapAt: lastAction,
          isCompleted: false,
          isDirty: true,
        );

        await JapOfflineRepository.saveSession(record);

        // Reopen session
        final restored = await JapOfflineRepository.getSession(sampleConfig.id);
        expect(restored.sessionId, 'session_kashi_shiva_999');
        expect(restored.userId, 'devotee_uuid_42');
        expect(restored.japId, sampleConfig.id);
        expect(restored.currentCount, 54);
        expect(restored.targetCount, 108);
        expect(restored.completedMalas, 3);
        expect(restored.status, JapLifecycle.inProgress);
        expect(restored.isCompleted, isFalse);
        expect(restored.isDirty, isTrue);
      },
    );

    test(
      '3. Device Offline Mode: Immediate UI Source without Blocking Network',
      () async {
        final controller = JapSessionController(
          config: sampleConfig,
          initialCount: 0,
        );

        // Chants purely local
        for (int i = 1; i <= 5; i++) {
          await Future.delayed(const Duration(milliseconds: 230));
          final ok = controller.performChant();
          expect(ok, isTrue);
          expect(controller.currentCount, i);
        }
        await controller.persistState();

        final stored = await JapOfflineRepository.getSession(sampleConfig.id);
        expect(stored.currentCount, 5);
        controller.dispose();
      },
    );

    test(
      '4. Corrupted Local Data Recovery (Graceful JSON Parsing Fallback)',
      () async {
        final prefs = await SharedPreferences.getInstance();

        // Corrupt the JSON string in SharedPreferences
        await prefs.setString(
          'jap_session_v2_${sampleConfig.id}',
          '{{ INVALID CORRUPT DATA !!!',
        );
        await prefs.setInt('jap_count_${sampleConfig.id}', 33);
        await prefs.setInt('jap_malas_${sampleConfig.id}', 1);

        // Must not throw, but recover 33 from legacy mirror
        final recovered = await JapOfflineRepository.getSession(
          sampleConfig.id,
        );
        expect(recovered.currentCount, 33);
        expect(recovered.completedMalas, 1);
        expect(recovered.status, JapLifecycle.inProgress);
      },
    );

    test(
      '5. Configuration Mismatch Handling (Target Count Changed from 108 to 54)',
      () async {
        final record = JapOfflineSessionRecord(
          sessionId: 'session_target_mismatch',
          japId: sampleConfig.id,
          currentCount: 70,
          targetCount: 108,
          completedMalas: 0,
          status: JapLifecycle.inProgress,
          startedAt: DateTime.now(),
          lastJapAt: DateTime.now(),
          isCompleted: false,
        );
        await JapOfflineRepository.saveSession(record);

        // Load with new target of 54
        final adapted = await JapOfflineRepository.getSession(
          sampleConfig.id,
          defaultTarget: 54,
        );
        expect(adapted.targetCount, 54);
        expect(adapted.currentCount, 54); // Clamped safely to new target
        expect(adapted.isCompleted, isTrue);
      },
    );

    test('6. Completed Session State Preservation', () async {
      final completedRecord = JapOfflineSessionRecord(
        sessionId: 'session_completed_108',
        japId: sampleConfig.id,
        currentCount: 108,
        targetCount: 108,
        completedMalas: 5,
        status: JapLifecycle.completed,
        startedAt: DateTime.now(),
        lastJapAt: DateTime.now(),
        isCompleted: true,
      );
      await JapOfflineRepository.saveSession(completedRecord);

      final controller = JapSessionController(config: sampleConfig);
      await controller.initializeFromStorage();

      expect(controller.currentCount, 108);
      expect(controller.completedMalas, 5);
      expect(controller.isCompleted, isTrue);
      expect(controller.lifecycle, JapLifecycle.completed);
      controller.dispose();
    });

    test(
      '7. Synchronization-Ready Data Structure & Dirty Queue Flagging',
      () async {
        final record = JapOfflineSessionRecord(
          sessionId: 'session_sync_ready',
          japId: 'sync_test_jap_id',
          currentCount: 108,
          targetCount: 108,
          completedMalas: 1,
          status: JapLifecycle.completed,
          startedAt: DateTime.now(),
          lastJapAt: DateTime.now(),
          isCompleted: true,
          isDirty: true,
        );
        await JapOfflineRepository.saveSession(record);

        // Fetch pending sync queue
        final pending = await JapOfflineRepository.getPendingSyncRecords();
        expect(
          pending.any((r) => r.japId == 'sync_test_jap_id' && r.isDirty),
          isTrue,
        );

        // Mark synced
        await JapOfflineRepository.markSynced('sync_test_jap_id');
        final dirtyAfter = await JapOfflineRepository.isDirty(
          'sync_test_jap_id',
        );
        expect(dirtyAfter, isFalse);
      },
    );
  });
}
