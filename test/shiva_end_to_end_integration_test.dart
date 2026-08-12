import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/models/darshan_model.dart';
import 'package:bharat_pray/services/jap_session_controller.dart';
import 'package:bharat_pray/screens/details/darshan_runtime_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 14: Complete Shiva End-to-End Verification & QA Suite', () {
    late JapConfig shivaJapConfig;
    late DarshanConfig shivaDarshanConfig;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      shivaJapConfig = JapConfig(
        id: 'shiva_kashi_108',
        name: 'Maha Mrityunjaya Mantra',
        thumbnailUrl: 'https://cdn.example.com/shiva_thumb.png',
        darshanImageUrl: 'https://cdn.example.com/kashi_vishwanath.png',
        shlokText:
            'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्॥',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );

      shivaDarshanConfig = DarshanConfig(
        id: 'darshan_kashi_shiva',
        godCategoryId: 'god_shiva',
        name: 'Kashi Vishwanath Jyotirlinga',
        type: DarshanType.image,
        imageUrl: 'https://cdn.example.com/kashi_vishwanath.png',
        thumbnailUrl: 'https://cdn.example.com/kashi_thumb.png',
        status: true,
      );
    });

    // --- TEST 1: Full Chanting & Progression Pipeline ---
    test(
      '1. Shiva Chanting & Visual Progression (1 -> 108 -> Completion)',
      () async {
        int effectCallCount = 0;
        int completionCallCount = 0;

        final controller = JapSessionController(
          config: shivaJapConfig,
          initialCount: 0,
          onEffectTrigger: (pos, intensity) {
            effectCallCount++;
          },
          onCompletion: () {
            completionCallCount++;
          },
        );

        // Start
        controller.start();
        expect(controller.lifecycle, JapLifecycle.started);
        expect(controller.currentCount, 0);

        // Chant 1..107
        for (int i = 1; i <= 107; i++) {
          await Future.delayed(const Duration(milliseconds: 230));
          final chantSuccess = controller.performChant();
          expect(chantSuccess, isTrue);
          expect(controller.currentCount, i);
          expect(controller.lifecycle, JapLifecycle.inProgress);
        }
        expect(effectCallCount, 107);
        expect(completionCallCount, 0);

        // Final 108th Chant
        await Future.delayed(const Duration(milliseconds: 230));
        final finalChant = controller.performChant();
        expect(finalChant, isTrue);
        expect(controller.currentCount, 108);
        expect(controller.lifecycle, JapLifecycle.completed);
        expect(controller.isCompleted, isTrue);
        expect(controller.isDarshanUnlocked, isTrue);
        expect(completionCallCount, 1);

        controller.dispose();
      },
    );

    // --- TEST 2: Strict Boundary & Duplicate Completion Lock (108 -> 109 Blocked) ---
    test(
      '2. Boundary Lock: Prevents 108 -> 109 and Duplicate Completion Calls',
      () async {
        int completionCallbacks = 0;
        final controller = JapSessionController(
          config: shivaJapConfig,
          initialCount: 107,
          onCompletion: () => completionCallbacks++,
        );

        await Future.delayed(const Duration(milliseconds: 230));
        controller.performChant(); // 108
        expect(completionCallbacks, 1);
        expect(controller.currentCount, 108);

        // Attempt 10 over-boundary taps
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 230));
          final overChant = controller.performChant();
          expect(overChant, isFalse);
        }

        expect(controller.currentCount, 108);
        expect(completionCallbacks, 1);
        controller.dispose();
      },
    );

    // --- TEST 3: Hardware Double-Tap Debounce (220ms Protection) ---
    test(
      '3. Hardware Double-Tap Debounce Protection (Rapid consecutive taps dropped)',
      () {
        final controller = JapSessionController(config: shivaJapConfig);

        // Rapid successive taps with 0ms interval
        final tap1 = controller.performChant();
        final tap2 = controller.performChant();
        final tap3 = controller.performChant();

        expect(tap1, isTrue);
        expect(tap2, isFalse);
        expect(tap3, isFalse);
        expect(controller.currentCount, 1);

        controller.dispose();
      },
    );

    // --- TEST 4: Offline Operation & Zero Count Loss on App Restart ---
    test(
      '4. App Close at 70/108 -> Cold Reopen at 70/108 (Zero Count Loss)',
      () async {
        final controller1 = JapSessionController(
          config: shivaJapConfig,
          initialCount: 69,
        );
        await Future.delayed(const Duration(milliseconds: 230));
        controller1.performChant(); // 70
        await controller1.persistState(userId: 'shiva_bhakt_108');
        controller1.dispose();

        // Cold Restart
        final controller2 = JapSessionController(config: shivaJapConfig);
        await controller2.initializeFromStorage(userId: 'shiva_bhakt_108');

        expect(controller2.currentCount, 70);
        expect(controller2.targetCount, 108);
        expect(controller2.lifecycle, JapLifecycle.inProgress);
        expect(controller2.isDarshanUnlocked, isFalse);

        controller2.dispose();
      },
    );

    // --- TEST 5: Animation / GPU Crash Isolation ---
    test(
      '5. Animation Crash Resilience (Shader/Canvas exception never corrupts count)',
      () async {
        final controller = JapSessionController(
          config: shivaJapConfig,
          onEffectTrigger: (pos, intensity) {
            throw Exception('Simulated Metal/Vulkan Texture GPU Crash');
          },
        );

        final success = controller.performChant();
        expect(success, isTrue);
        expect(controller.currentCount, 1);
        expect(controller.lifecycle, JapLifecycle.inProgress);

        controller.dispose();
      },
    );

    // --- TEST 6: Shiva Darshan Screen Access Gating & Navigation ---
    testWidgets('6. Shiva Darshan Access Gating & Next Mala Navigation', (
      WidgetTester tester,
    ) async {
      final controller = JapSessionController(
        config: shivaJapConfig,
        initialCount: 108,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DarshanRuntimeScreen(
            config: shivaJapConfig,
            darshanConfig: shivaDarshanConfig,
            sessionController: controller,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Devotional Visuals Verified
      expect(
        find.text(
          'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्॥',
        ),
        findsOneWidget,
      );
      expect(find.text('🙏 Har Har Mahadev 🙏'), findsOneWidget);
      expect(find.text('Offer Flowers'), findsOneWidget);
      expect(find.text('Light Diya'), findsOneWidget);
      expect(find.text('Next Mala'), findsOneWidget);

      // Offer Flowers Interaction
      await tester.tap(find.text('Offer Flowers'));
      await tester.pump(const Duration(seconds: 2));

      // Next Mala Interaction
      await tester.tap(find.text('Next Mala'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.completedMalas, 1);
      expect(controller.currentCount, 0);
      expect(controller.lifecycle, JapLifecycle.started);

      controller.dispose();
    });
  });
}
