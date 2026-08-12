import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/jap_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 8: Jap State Machine & Core Session Engine Tests', () {
    late JapConfig sampleConfig;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sampleConfig = JapConfig(
        id: 'test_jap_shiva_108',
        name: 'Om Namah Shivaya',
        thumbnailUrl: 'https://example.com/shiva.png',
        darshanImageUrl: 'https://example.com/kashi.png',
        shlokText: 'ॐ नमः शिवाय',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );
    });

    test('1. Initial State: Count 0 and Lifecycle IDLE', () {
      final controller = JapSessionController(config: sampleConfig);

      expect(controller.currentCount, 0);
      expect(controller.targetCount, 108);
      expect(controller.completedMalas, 0);
      expect(controller.lifecycle, JapLifecycle.idle);
      expect(controller.isCompleted, isFalse);
      expect(controller.progressFraction, 0.0);
    });

    test('2. First Chant: 0 -> 1 (Transitions to IN_PROGRESS)', () {
      final controller = JapSessionController(config: sampleConfig);

      final success = controller.performChant();
      expect(success, isTrue);
      expect(controller.currentCount, 1);
      expect(controller.lifecycle, JapLifecycle.inProgress);
      expect(controller.progressFraction, closeTo(1 / 108, 0.001));
    });

    test('3. Second Chant: 1 -> 2', () async {
      final controller = JapSessionController(
        config: sampleConfig,
        initialCount: 1,
      );

      // Wait past debounce threshold
      await Future.delayed(const Duration(milliseconds: 230));

      final success = controller.performChant();
      expect(success, isTrue);
      expect(controller.currentCount, 2);
      expect(controller.lifecycle, JapLifecycle.inProgress);
    });

    test(
      '4. Boundary Chant: 107 -> 108 (Transitions to COMPLETED and fires callback)',
      () async {
        bool completionFired = false;
        final controller = JapSessionController(
          config: sampleConfig,
          initialCount: 107,
          onCompletion: () {
            completionFired = true;
          },
        );

        expect(controller.currentCount, 107);
        expect(controller.isCompleted, isFalse);

        await Future.delayed(const Duration(milliseconds: 230));
        final success = controller.performChant();

        expect(success, isTrue);
        expect(controller.currentCount, 108);
        expect(controller.lifecycle, JapLifecycle.completed);
        expect(controller.isCompleted, isTrue);
        expect(controller.progressFraction, 1.0);
        expect(completionFired, isTrue);
      },
    );

    test('5. Invalid Over-Boundary Chant: 108 -> 109 Blocked', () async {
      final controller = JapSessionController(
        config: sampleConfig,
        initialCount: 108,
      );

      await Future.delayed(const Duration(milliseconds: 230));
      final success = controller.performChant();

      // Must be rejected and count must remain 108
      expect(success, isFalse);
      expect(controller.currentCount, 108);
      expect(controller.lifecycle, JapLifecycle.completed);
    });

    test('6. Rapid Double Taps / Hardware Debounce Protection (220ms)', () {
      final controller = JapSessionController(config: sampleConfig);

      // First tap succeeds
      final firstTap = controller.performChant();
      expect(firstTap, isTrue);
      expect(controller.currentCount, 1);

      // Rapid consecutive taps (0ms delay) must be ignored
      final secondTap = controller.performChant();
      final thirdTap = controller.performChant();
      final fourthTap = controller.performChant();

      expect(secondTap, isFalse);
      expect(thirdTap, isFalse);
      expect(fourthTap, isFalse);
      expect(controller.currentCount, 1);
    });

    test('7. Animation Failure Does NOT Lose Count', () async {
      final controller = JapSessionController(
        config: sampleConfig,
        onEffectTrigger: (pos, intensity) {
          throw Exception('Simulated GPU/Shader Texture Failure');
        },
      );

      final success = controller.performChant();
      expect(success, isTrue);
      expect(controller.currentCount, 1);
      expect(controller.lifecycle, JapLifecycle.inProgress);
    });

    test('8. Pause & Resume Session Controls', () async {
      final controller = JapSessionController(
        config: sampleConfig,
        initialCount: 15,
      );
      expect(controller.lifecycle, JapLifecycle.inProgress);

      controller.pause();
      expect(controller.lifecycle, JapLifecycle.paused);

      await Future.delayed(const Duration(milliseconds: 230));
      // Chant blocked while paused
      final chantWhilePaused = controller.performChant();
      expect(chantWhilePaused, isFalse);
      expect(controller.currentCount, 15);

      controller.resume();
      expect(controller.lifecycle, JapLifecycle.inProgress);

      await Future.delayed(const Duration(milliseconds: 230));
      final chantAfterResume = controller.performChant();
      expect(chantAfterResume, isTrue);
      expect(controller.currentCount, 16);
    });

    test(
      '9. Screen Close & Reopen (Offline Storage Persistence & Restore)',
      () async {
        // Session 1: User chants up to 45
        final controller1 = JapSessionController(
          config: sampleConfig,
          initialCount: 44,
        );
        await Future.delayed(const Duration(milliseconds: 230));
        controller1.performChant();
        expect(controller1.currentCount, 45);
        await controller1.persistState();

        // Simulate screen close
        controller1.dispose();

        // Session 2: User reopens screen
        final controller2 = JapSessionController(config: sampleConfig);
        await controller2.initializeFromStorage();

        // Verified exact count is restored
        expect(controller2.currentCount, 45);
        expect(controller2.lifecycle, JapLifecycle.inProgress);
        controller2.dispose();
      },
    );

    test('10. Custom Target Count (e.g. 21, 54, 1008)', () async {
      final shortConfig = JapConfig(
        id: 'short_jap_21',
        name: 'Ganesh Shlok 21',
        thumbnailUrl: '',
        darshanImageUrl: '',
        shlokText: 'Gam Ganapataye',
        targetCount: 21,
        effectPack: EffectPack.ganeshaPreset,
      );

      final controller = JapSessionController(
        config: shortConfig,
        initialCount: 20,
      );
      await Future.delayed(const Duration(milliseconds: 230));
      final completion = controller.performChant();

      expect(completion, isTrue);
      expect(controller.currentCount, 21);
      expect(controller.isCompleted, isTrue);
      expect(controller.lifecycle, JapLifecycle.completed);
    });
  });
}
