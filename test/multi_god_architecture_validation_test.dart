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

  group('Phase 16: Full Multi-God Configuration Architecture Validation', () {
    late JapConfig shivaConfig;
    late JapConfig ganeshConfig;
    late JapConfig krishnaConfig;
    late JapConfig hanumanConfig;
    late JapConfig customDurgaConfig;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      EffectRegistry().reset();

      // God A: Shiva
      shivaConfig = JapConfig(
        id: 'god_shiva_108',
        name: 'Om Namah Shivaya',
        thumbnailUrl: 'https://cdn.bharatpray.org/gods/shiva.png',
        darshanImageUrl: 'https://cdn.bharatpray.org/darshan/kashi.png',
        shlokText: 'ॐ नमः शिवाय',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );

      // God B: Ganesh
      ganeshConfig = JapConfig(
        id: 'god_ganesh_108',
        name: 'Om Gam Ganapataye Namaha',
        thumbnailUrl: 'https://cdn.bharatpray.org/gods/ganesha.png',
        darshanImageUrl: 'https://cdn.bharatpray.org/darshan/siddhivinayak.png',
        shlokText: 'ॐ गं गणपतये नमः',
        targetCount: 108,
        effectPack: EffectPack.ganeshaPreset,
      );

      // God C: Krishna
      krishnaConfig = JapConfig(
        id: 'god_krishna_108',
        name: 'Hare Krishna Mahamantra',
        thumbnailUrl: 'https://cdn.bharatpray.org/gods/krishna.png',
        darshanImageUrl: 'https://cdn.bharatpray.org/darshan/vrindavan.png',
        shlokText: 'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे। हरे राम हरे राम राम राम हरे हरे॥',
        targetCount: 108,
        effectPack: EffectPack.krishnaPreset,
      );

      // God D: Hanuman
      hanumanConfig = JapConfig(
        id: 'god_hanuman_108',
        name: 'Hanuman Mool Mantra',
        thumbnailUrl: 'https://cdn.bharatpray.org/gods/hanuman.png',
        darshanImageUrl: 'https://cdn.bharatpray.org/darshan/salasar.png',
        shlokText: 'ॐ हं हनुमते नमः',
        targetCount: 108,
        effectPack: EffectPack.hanumanPreset,
      );

      // God E (Pure JSON-driven Dynamic Addition without code changes): Maa Durga
      customDurgaConfig = JapConfig.fromJson({
        'id': 'god_durga_custom_json',
        'name': 'Durga Dhyan Mantra',
        'thumbnailUrl': 'https://cdn.bharatpray.org/gods/durga.png',
        'darshanImageUrl': 'https://cdn.bharatpray.org/darshan/vaishnodevi.png',
        'shlokText': 'ॐ सर्वमङ्गलमाङ्गल्ये शिवे सर्वार्थसाधिके',
        'targetCount': 108,
        'effectPack': {
          'code': 'DURGA_VICTORY_V1',
          'shape': 'spark',
          'animationConfig': {
            'primaryColor': '#990000',
            'secondaryColor': '#FF1744',
            'accentColor': '#FFD700',
            'haloGlowColor': '#FF1744',
            'particleShape': 'spark',
            'particleVelocity': 1.25,
            'blessingTitle': '🙏 Jai Mata Di 🙏',
            'blessingSubtitle': 'May Maa Durga empower your spirit with fearless strength and victory.',
          },
        },
      });
    });

    // --- TEST 1: Decoupled Multi-God Visual & Aesthetic Configuration Validation ---
    test('1. Multi-God Profile Independence (Shiva, Ganesh, Krishna, Hanuman, Durga)', () {
      // 1. Shiva (Leaf, Forest Green/Cyan)
      expect(shivaConfig.effectPack.shape, ParticleShapeType.leaf);
      expect(shivaConfig.effectPack.primaryColor, const Color(0xFF81C784));
      expect(shivaConfig.effectPack.blessingTitle, '🙏 Har Har Mahadev 🙏');

      // 2. Ganesh (Petal, Marigold Orange/Gold)
      expect(ganeshConfig.effectPack.shape, ParticleShapeType.petal);
      expect(ganeshConfig.effectPack.primaryColor, const Color(0xFFFF6B35));
      expect(ganeshConfig.effectPack.blessingTitle, '🙏 Ganpati Bappa Morya 🙏');

      // 3. Krishna (Feather, Peacock Deep Blue/Emerald)
      expect(krishnaConfig.effectPack.shape, ParticleShapeType.feather);
      expect(krishnaConfig.effectPack.primaryColor, const Color(0xFF0D4F8B));
      expect(krishnaConfig.effectPack.blessingTitle, '🙏 Jai Shree Krishna 🙏');

      // 4. Hanuman (Spark, Vermillion Red/Saffron)
      expect(hanumanConfig.effectPack.shape, ParticleShapeType.spark);
      expect(hanumanConfig.effectPack.primaryColor, const Color(0xFFCC2200));
      expect(hanumanConfig.effectPack.blessingTitle, '🙏 Jai Bajrangbali 🙏');

      // 5. Dynamic Durga Config (Spark, Crimson Red)
      expect(customDurgaConfig.effectPack.shape, ParticleShapeType.spark);
      expect(customDurgaConfig.effectPack.primaryColor, const Color(0xFF990000));
      expect(customDurgaConfig.effectPack.blessingTitle, '🙏 Jai Mata Di 🙏');
    });

    // --- TEST 2: Dynamic Switching Across All 5 Deities with Zero State Contamination ---
    test('2. Dynamic Switch Progression (Shiva -> Ganesh -> Krishna -> Hanuman -> Durga)', () {
      final engine = DivineEffectEngine(pack: shivaConfig.effectPack);

      // 1. Shiva Active
      expect(engine.pack.shape, ParticleShapeType.leaf);
      expect(engine.pack.primaryColor, const Color(0xFF81C784));

      // 2. Switch to Ganesh
      engine.setEffectPack(ganeshConfig.effectPack);
      expect(engine.pack.shape, ParticleShapeType.petal);
      expect(engine.pack.primaryColor, const Color(0xFFFF6B35));

      // 3. Switch to Krishna
      engine.setEffectPack(krishnaConfig.effectPack);
      expect(engine.pack.shape, ParticleShapeType.feather);
      expect(engine.pack.primaryColor, const Color(0xFF0D4F8B));

      // 4. Switch to Hanuman
      engine.setEffectPack(hanumanConfig.effectPack);
      expect(engine.pack.shape, ParticleShapeType.spark);
      expect(engine.pack.primaryColor, const Color(0xFFCC2200));

      // 5. Switch to Custom Durga
      engine.setEffectPack(customDurgaConfig.effectPack);
      expect(engine.pack.shape, ParticleShapeType.spark);
      expect(engine.pack.primaryColor, const Color(0xFF990000));
      expect(engine.pack.blessingTitle, '🙏 Jai Mata Di 🙏');

      engine.dispose();
    });

    // --- TEST 3: Agnostic JapSessionController Counting & Completion for All 4 Gods ---
    test('3. Agnostic JapSessionController Executes Identical Counting & Completion Across Deities', () async {
      final configs = [shivaConfig, ganeshConfig, krishnaConfig, hanumanConfig];

      for (final config in configs) {
        bool completed = false;
        final controller = JapSessionController(
          config: config,
          initialCount: 107,
          onCompletion: () => completed = true,
        );

        await Future.delayed(const Duration(milliseconds: 230));
        final chantSuccess = controller.performChant();

        expect(chantSuccess, isTrue, reason: '${config.name} chant should succeed');
        expect(controller.currentCount, 108);
        expect(controller.isCompleted, isTrue);
        expect(controller.isDarshanUnlocked, isTrue);
        expect(completed, isTrue);
        expect(controller.config.effectPack.blessingTitle, config.effectPack.blessingTitle);

        controller.dispose();
      }
    });

    // --- TEST 4: Multi-God Darshan Runtime Screen Presentation ---
    testWidgets('4. Multi-God Darshan Runtime Screen Presentation (Krishna & Hanuman)', (WidgetTester tester) async {
      // 1. Krishna Darshan
      final krishnaController = JapSessionController(config: krishnaConfig, initialCount: 108);
      await tester.pumpWidget(
        MaterialApp(
          home: DarshanRuntimeScreen(
            config: krishnaConfig,
            sessionController: krishnaController,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे। हरे राम हरे राम राम राम हरे हरे॥'), findsOneWidget);
      expect(find.text('🙏 Jai Shree Krishna 🙏'), findsOneWidget);
      krishnaController.dispose();

      // 2. Hanuman Darshan
      final hanumanController = JapSessionController(config: hanumanConfig, initialCount: 108);
      await tester.pumpWidget(
        MaterialApp(
          home: DarshanRuntimeScreen(
            config: hanumanConfig,
            sessionController: hanumanController,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ॐ हं हनुमते नमः'), findsOneWidget);
      expect(find.text('🙏 Jai Bajrangbali 🙏'), findsOneWidget);
      hanumanController.dispose();
    });
  });
}
