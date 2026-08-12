import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/jap_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 11: 108 Completion Engine Tests', () {
    late JapConfig shivaConfig;
    late JapConfig krishnaConfig;
    late JapConfig ganeshaConfig;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      shivaConfig = JapConfig(
        id: 'shiva_completion_test',
        name: 'Maha Mrityunjaya',
        thumbnailUrl: 'https://example.com/shiva.png',
        darshanImageUrl: 'https://example.com/darshan.png',
        shlokText: 'ॐ त्र्यम्बकं यजामहे',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );

      krishnaConfig = JapConfig(
        id: 'krishna_completion_test',
        name: 'Hare Krishna Maha Mantra',
        thumbnailUrl: 'https://example.com/krishna.png',
        darshanImageUrl: 'https://example.com/krishna_darshan.png',
        shlokText: 'हरे कृष्ण हरे कृष्ण',
        targetCount: 108,
        effectPack: EffectPack.krishnaPreset,
      );

      ganeshaConfig = JapConfig(
        id: 'ganesha_completion_test',
        name: 'Vakratunda Mahakaya',
        thumbnailUrl: 'https://example.com/ganesha.png',
        darshanImageUrl: 'https://example.com/ganesha_darshan.png',
        shlokText: 'वक्रतुण्ड महाकाय',
        targetCount: 108,
        effectPack: EffectPack.ganeshaPreset,
      );
    });

    test(
      '1. Full Lifecycle Transition: IN_PROGRESS -> COMPLETED -> DARSHAN_REVEAL -> DARSHAN_ACTIVE',
      () async {
        int completionCount = 0;
        final controller = JapSessionController(
          config: shivaConfig,
          initialCount: 107,
          onCompletion: () {
            completionCount++;
          },
        );

        expect(controller.lifecycle, JapLifecycle.inProgress);
        expect(controller.isDarshanUnlocked, isFalse);

        // Perform 108th chant
        await Future.delayed(const Duration(milliseconds: 230));
        final success = controller.performChant();

        // State 1: COMPLETED
        expect(success, isTrue);
        expect(controller.currentCount, 108);
        expect(controller.lifecycle, JapLifecycle.completed);
        expect(controller.isCompleted, isTrue);
        expect(controller.isDarshanUnlocked, isTrue);
        expect(completionCount, 1);

        // State 2: DARSHAN_REVEAL
        final revealOk = controller.transitionToDarshanReveal();
        expect(revealOk, isTrue);
        expect(controller.lifecycle, JapLifecycle.darshanReveal);

        // State 3: DARSHAN_ACTIVE
        final activeOk = controller.transitionToDarshanActive();
        expect(activeOk, isTrue);
        expect(controller.lifecycle, JapLifecycle.darshanActive);

        controller.dispose();
      },
    );

    test('2. Exactly-Once Completion Execution & 108 -> 109 Lock', () async {
      int completionCallbacks = 0;
      final controller = JapSessionController(
        config: shivaConfig,
        initialCount: 107,
        onCompletion: () {
          completionCallbacks++;
        },
      );

      // 107 -> 108
      await Future.delayed(const Duration(milliseconds: 230));
      controller.performChant();
      expect(completionCallbacks, 1);
      expect(controller.currentCount, 108);

      // Attempt 108 -> 109 (5 rapid taps)
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 230));
        final blocked = controller.performChant();
        expect(blocked, isFalse);
      }

      // Count remains 108, callback still exactly 1
      expect(controller.currentCount, 108);
      expect(completionCallbacks, 1);
      controller.dispose();
    });

    test(
      '3. Darshan Unlock Gate: Cannot Reveal Darshan Before Reaching Target',
      () {
        final controller = JapSessionController(
          config: shivaConfig,
          initialCount: 50,
        );

        expect(controller.isDarshanUnlocked, isFalse);
        final attemptReveal = controller.transitionToDarshanReveal();

        // Must be rejected
        expect(attemptReveal, isFalse);
        expect(controller.lifecycle, JapLifecycle.inProgress);
        controller.dispose();
      },
    );

    test(
      '4. Configured Effect Pack Blessing Theming (No Hardcoded Shiva Logic)',
      () {
        // 1. Shiva Effect Pack Blessing
        expect(
          shivaConfig.effectPack.blessingTitle,
          contains('Har Har Mahadev'),
        );
        expect(shivaConfig.effectPack.shape, ParticleShapeType.leaf);

        // 2. Krishna Effect Pack Blessing
        expect(
          krishnaConfig.effectPack.blessingTitle,
          contains('Jai Shree Krishna'),
        );
        expect(krishnaConfig.effectPack.shape, ParticleShapeType.feather);

        // 3. Ganesha Effect Pack Blessing
        expect(
          ganeshaConfig.effectPack.blessingTitle,
          contains('Ganpati Bappa Morya'),
        );
        expect(ganeshaConfig.effectPack.shape, ParticleShapeType.petal);
      },
    );

    test(
      '5. Instant App Close Recovery (State Preserved as Completed with Darshan Unlocked)',
      () async {
        // Session 1 completes at 108
        final controller1 = JapSessionController(
          config: shivaConfig,
          initialCount: 107,
        );
        await Future.delayed(const Duration(milliseconds: 230));
        controller1.performChant();
        await controller1.persistState();

        // App killed immediately
        controller1.dispose();

        // App reopened
        final controller2 = JapSessionController(config: shivaConfig);
        await controller2.initializeFromStorage();

        expect(controller2.currentCount, 108);
        expect(controller2.isCompleted, isTrue);
        expect(controller2.isDarshanUnlocked, isTrue);
        expect(controller2.lifecycle, JapLifecycle.completed);

        // Can reveal Darshan after reopen
        expect(controller2.transitionToDarshanReveal(), isTrue);
        controller2.dispose();
      },
    );

    test(
      '6. Advance Mala: Increments Completed Malas & Resets Round to 0',
      () async {
        final controller = JapSessionController(
          config: shivaConfig,
          initialCount: 108,
          initialMalas: 0,
        );
        expect(controller.isCompleted, isTrue);

        controller.advanceMala();
        expect(controller.currentCount, 0);
        expect(controller.completedMalas, 1);
        expect(controller.totalLifetimeCount, 108);
        expect(controller.lifecycle, JapLifecycle.started);
        expect(controller.isCompleted, isFalse);

        await Future.delayed(const Duration(milliseconds: 230));
        final nextChant = controller.performChant();
        expect(nextChant, isTrue);
        expect(controller.currentCount, 1);
        controller.dispose();
      },
    );
  });
}
