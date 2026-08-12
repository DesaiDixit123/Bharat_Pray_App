import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/models/darshan_model.dart';
import 'package:bharat_pray/services/jap_session_controller.dart';
import 'package:bharat_pray/services/effect_engine/effect_engine.dart';
import 'package:bharat_pray/services/effect_engine/effect_registry.dart';
import 'package:bharat_pray/screens/details/darshan_runtime_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 15: Ganesh Effect Pack & Multi-Deity Decoupled Verification', () {
    late JapConfig shivaConfig;
    late JapConfig ganeshConfig;
    late DarshanConfig ganeshDarshanConfig;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      EffectRegistry().reset();

      shivaConfig = JapConfig(
        id: 'shiva_session_id',
        name: 'Om Namah Shivaya',
        thumbnailUrl: 'https://cdn.bharatpray.org/gods/shiva.png',
        darshanImageUrl: 'https://cdn.bharatpray.org/darshan/kashi.png',
        shlokText: 'ॐ नमः शिवाय',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );

      ganeshConfig = JapConfig(
        id: 'ganesh_session_id',
        name: 'Om Gam Ganapataye Namaha',
        thumbnailUrl: 'https://cdn.bharatpray.org/gods/ganesha.png',
        darshanImageUrl: 'https://cdn.bharatpray.org/darshan/siddhivinayak.png',
        shlokText: 'ॐ गं गणपतये नमः',
        targetCount: 108,
        effectPack: EffectPack.ganeshaPreset,
      );

      ganeshDarshanConfig = DarshanConfig(
        id: 'darshan_siddhivinayak',
        godCategoryId: 'god_ganesh',
        name: 'Shree Siddhivinayak Temple Darshan',
        type: DarshanType.image,
        imageUrl: 'https://cdn.bharatpray.org/darshan/siddhivinayak.png',
        thumbnailUrl:
            'https://cdn.bharatpray.org/darshan/siddhivinayak_thumb.png',
        status: true,
      );
    });

    // --- TEST 1: Ganesh Visual Configuration & Aesthetics ---
    test(
      '1. Ganesh Effect Pack Configuration (Golden Aura, Petal Shape & Blessing Motif)',
      () {
        final pack = EffectPack.ganeshaPreset;

        expect(pack.id, 'GANESHA_DEV');
        expect(pack.shape, ParticleShapeType.petal);
        expect(
          pack.primaryColor,
          const Color(0xFFFF6B35),
        ); // Vibrant Marigold / Orange
        expect(
          pack.secondaryColor,
          const Color(0xFFFFB300),
        ); // Warm Golden Yellow
        expect(pack.accentColor, const Color(0xFFFFD700)); // Gold Accent
        expect(pack.haloGlowColor, const Color(0xFFFFAB40)); // Warm Aura Glow
        expect(pack.blessingTitle, '🙏 Ganpati Bappa Morya 🙏');
        expect(pack.blessingSubtitle, contains('remove all obstacles'));
      },
    );

    // --- TEST 2: Dynamic Engine Switching Between Shiva and Ganesh with Zero State Leakage ---
    test(
      '2. Dynamic Effect Engine Switching (Shiva <-> Ganesh) without State Leakage',
      () {
        final engine = DivineEffectEngine(pack: shivaConfig.effectPack);

        // Verify Shiva Pack Active
        expect(engine.pack.shape, ParticleShapeType.leaf);
        expect(engine.pack.primaryColor, const Color(0xFF81C784));

        // Trigger Tap Burst on Shiva
        engine.triggerTapBurst(const Offset(100, 100));
        expect(engine.tapSparks.isNotEmpty, isTrue);

        // Dynamically Switch to Ganesh
        engine.setEffectPack(ganeshConfig.effectPack);

        // Verify Ganesh Pack Active & Isolated
        expect(engine.pack.shape, ParticleShapeType.petal);
        expect(engine.pack.primaryColor, const Color(0xFFFF6B35));
        expect(engine.pack.blessingTitle, '🙏 Ganpati Bappa Morya 🙏');

        // Trigger Tap Burst on Ganesh
        engine.triggerTapBurst(const Offset(200, 200));
        expect(
          engine.pack.particleColors.contains(const Color(0xFFFF6B35)),
          isTrue,
        );

        engine.dispose();
      },
    );

    // --- TEST 3: Registry Dynamic Resolution for Ganesh ---
    test('3. EffectRegistry Resolves Ganesh Pack Accurately from API JSON', () {
      final registry = EffectRegistry();

      final resolved = registry.resolveForDeity(
        name: 'Lord Ganesha',
        particleShape: 'petal',
      );

      expect(resolved.shape, ParticleShapeType.petal);
      expect(resolved.primaryColor, const Color(0xFFFF6B35));
      expect(resolved.blessingTitle, '🙏 Ganpati Bappa Morya 🙏');
    });

    // --- TEST 4: Ganesh 108 Chanting & Completion Engine Flow ---
    test(
      '4. Ganesh 108 Chanting & Completion Flow (Unlocks Ganesh Blessing & Darshan)',
      () async {
        int effectFired = 0;
        bool completionFired = false;

        final controller = JapSessionController(
          config: ganeshConfig,
          initialCount: 107,
          onEffectTrigger: (pos, intensity) => effectFired++,
          onCompletion: () => completionFired = true,
        );

        expect(controller.currentCount, 107);
        expect(controller.isCompleted, isFalse);
        expect(controller.isDarshanUnlocked, isFalse);

        // 108th Chant for Lord Ganesh
        await Future.delayed(const Duration(milliseconds: 230));
        final chantResult = controller.performChant();

        expect(chantResult, isTrue);
        expect(controller.currentCount, 108);
        expect(controller.isCompleted, isTrue);
        expect(controller.isDarshanUnlocked, isTrue);
        expect(controller.lifecycle, JapLifecycle.completed);
        expect(completionFired, isTrue);

        // Verify Ganesh Blessing Motif Resolved Decoupled
        expect(
          controller.config.effectPack.blessingTitle,
          '🙏 Ganpati Bappa Morya 🙏',
        );

        controller.dispose();
      },
    );

    // --- TEST 5: Ganesh Darshan Runtime Screen Presentation ---
    testWidgets(
      '5. Ganesh Darshan Screen Renders Siddhivinayak Darshan and Blessings',
      (WidgetTester tester) async {
        final controller = JapSessionController(
          config: ganeshConfig,
          initialCount: 108,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: DarshanRuntimeScreen(
              config: ganeshConfig,
              darshanConfig: ganeshDarshanConfig,
              sessionController: controller,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('ॐ गं गणपतये नमः'), findsOneWidget);
        expect(find.text('🙏 Ganpati Bappa Morya 🙏'), findsOneWidget);
        expect(find.text('Offer Flowers'), findsOneWidget);
        expect(find.text('Light Diya'), findsOneWidget);

        // Tap Offer Flowers (Marigold flower petals)
        await tester.tap(find.text('Offer Flowers'));
        await tester.pump(const Duration(seconds: 2));

        controller.dispose();
      },
    );
  });
}
