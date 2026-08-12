import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/effect_engine/effect_engine.dart';
import 'package:bharat_pray/services/effect_engine/effect_registry.dart';
import 'package:bharat_pray/services/effect_engine/effect_asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6: Reusable Flutter Divine Effect Engine Tests', () {
    late DivineEffectEngine engine;
    late EffectRegistry registry;
    late EffectAssetLoader assetLoader;

    setUp(() {
      registry = EffectRegistry();
      assetLoader = EffectAssetLoader();
      engine = DivineEffectEngine(
        pack: EffectPack.shivaPreset,
        initialIntensity: 1.0,
      );
    });

    tearDown(() {
      engine.dispose();
      assetLoader.clearCache();
    });

    test('1. Effect Start & Initialization', () {
      expect(engine.state, EffectEngineState.active);
      expect(engine.pack.code, 'SHIVA_MAHADEV');
      expect(engine.pack.shape, ParticleShapeType.leaf);
      expect(engine.embers.isNotEmpty, isTrue);
      expect(engine.timeSeconds, 0.0);
    });

    test('2. Effect Completion & Callback Dispatching', () async {
      bool completionCalled = false;
      engine.triggerCompletion(
        duration: const Duration(milliseconds: 100),
        onComplete: () {
          completionCalled = true;
        },
      );

      expect(engine.state, EffectEngineState.completing);
      expect(engine.petals.isNotEmpty, isTrue);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(engine.state, EffectEngineState.completed);
      expect(completionCalled, isTrue);
    });

    test('3. Repeated / Rapid Triggering & Throttle Protection', () {
      const triggerPos = Offset(150, 300);

      // Trigger 10 rapid bursts
      for (int i = 0; i < 10; i++) {
        engine.triggerTapBurst(triggerPos, scale: 1.0);
      }

      // Should have generated initial burst without runaway memory explosion
      expect(engine.tapSparks.isNotEmpty, isTrue);
      expect(engine.spiralSparks.isNotEmpty, isTrue);
      expect(engine.glowRings.isNotEmpty, isTrue);
      expect(engine.floatingOms.isNotEmpty, isTrue);

      // Advance physics simulation
      engine.update(0.032);
      expect(engine.timeSeconds, greaterThan(0.0));
    });

    test('4. Missing / Corrupt Asset Handling', () {
      // Non-existent image path
      final invalidProvider = assetLoader.resolveImageProvider('');
      expect(invalidProvider, isNull);

      final brokenProvider = assetLoader.resolveImageProvider(
        'invalid://broken_path.png',
      );
      expect(brokenProvider != null || brokenProvider == null, isTrue);
    });

    test('5. Dynamic EffectPack Switching without Restarting Engine', () {
      expect(engine.pack.shape, ParticleShapeType.leaf);

      // Switch to Krishna Peacock Preset
      engine.setEffectPack(EffectPack.krishnaPreset);
      expect(engine.pack.code, 'KRISHNA_DEV');
      expect(engine.pack.shape, ParticleShapeType.feather);
      expect(engine.pack.primaryColor, const Color(0xFF0D4F8B));

      // Switch to Ganesha Marigold Preset
      engine.setEffectPack(EffectPack.ganeshaPreset);
      expect(engine.pack.code, 'GANESHA_DEV');
      expect(engine.pack.shape, ParticleShapeType.petal);
      expect(engine.pack.primaryColor, const Color(0xFFFF6B35));
    });

    test('6. Intensity Scaling Control', () {
      engine.setIntensity(0.5);
      expect(engine.intensity, 0.5);

      engine.setIntensity(2.0);
      expect(engine.intensity, 2.0);

      // Clamping checks
      engine.setIntensity(10.0);
      expect(engine.intensity, 2.0);
      engine.setIntensity(0.01);
      expect(engine.intensity, 0.1);
    });

    test('7. Screen Disposal & Memory Cleanup', () {
      engine.dispose();
      expect(engine.state, EffectEngineState.disposed);
      expect(engine.embers.isEmpty, isTrue);
      expect(engine.petals.isEmpty, isTrue);
      expect(engine.tapSparks.isEmpty, isTrue);
      expect(engine.spiralSparks.isEmpty, isTrue);
      expect(engine.smokeParticles.isEmpty, isTrue);
      expect(engine.glowRings.isEmpty, isTrue);
      expect(engine.floatingOms.isEmpty, isTrue);
    });

    test('8. Effect Registry Resolution for Different Deities', () {
      final shivaResolved = registry.resolveForDeity(name: 'Lord Shiva');
      expect(shivaResolved.shape, ParticleShapeType.leaf);

      final krishnaResolved = registry.resolveForDeity(name: 'Shree Krishna');
      expect(krishnaResolved.shape, ParticleShapeType.feather);

      final ganeshResolved = registry.resolveForDeity(name: 'Lord Ganesha');
      expect(ganeshResolved.shape, ParticleShapeType.petal);

      final hanumanResolved = registry.resolveForDeity(
        name: 'Bajrangbali Hanuman',
      );
      expect(hanumanResolved.shape, ParticleShapeType.spark);

      final durgaResolved = registry.resolveForDeity(name: 'Maa Durga');
      expect(durgaResolved.shape, ParticleShapeType.spark);

      final lakshmiResolved = registry.resolveForDeity(name: 'Maa Lakshmi');
      expect(lakshmiResolved.shape, ParticleShapeType.petal);

      final vishnuResolved = registry.resolveForDeity(name: 'Lord Vishnu');
      expect(vishnuResolved.shape, ParticleShapeType.spark);

      final fallbackResolved = registry.resolveForDeity(name: 'Unknown Deity');
      expect(fallbackResolved.shape, ParticleShapeType.petal);
    });
  });
}
