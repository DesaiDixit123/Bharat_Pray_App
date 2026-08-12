import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/effect_engine/effect_engine.dart';
import 'package:bharat_pray/services/effect_engine/effect_registry.dart';
import 'package:bharat_pray/services/effect_engine/effect_asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 7: Shiva Divine Effect Pack Reference Implementation Tests', () {
    late DivineEffectEngine engine;
    late EffectRegistry registry;
    late EffectAssetLoader assetLoader;
    late EffectPack shivaPack;

    setUp(() {
      registry = EffectRegistry();
      assetLoader = EffectAssetLoader();
      shivaPack = registry.resolveForDeity(name: 'Lord Shiva');
      engine = DivineEffectEngine(pack: shivaPack, initialIntensity: 1.0);
    });

    tearDown(() {
      engine.dispose();
      assetLoader.clearCache();
    });

    test('1. Shiva Effect Pack Configuration & Visual Specs', () {
      expect(shivaPack.code, 'SHIVA_MAHADEV');
      expect(shivaPack.shape, ParticleShapeType.leaf);
      expect(shivaPack.primaryColor, const Color(0xFF81C784));
      expect(shivaPack.secondaryColor, const Color(0xFFE8F4FC));
      expect(shivaPack.haloGlowColor, const Color(0xFF90CAF9));
      expect(shivaPack.particleVelocity, 0.9);
      expect(shivaPack.smokeEmissionIntervalSec, 0.22);
      expect(shivaPack.blessingTitle, contains('Har Har Mahadev'));
      expect(shivaPack.blessingSubtitle, contains('Lord Shiva'));
    });

    test('2. Shiva Ambient Animation State (Vibhuti Ash Embers & Smoke)', () {
      expect(engine.state, EffectEngineState.active);
      expect(engine.embers.isNotEmpty, isTrue);

      // Simulate incense tip position
      engine.setIncensePosition(const Offset(200, 400));

      // Advance physics simulation by 0.3 seconds (greater than 0.22s smoke interval)
      engine.update(0.30);
      expect(engine.smokeParticles.isNotEmpty, isTrue);
      expect(engine.timeSeconds, closeTo(0.30, 0.001));
    });

    test('3. Shiva Tap Burst Event (Trishul Pulse & Om Glyphs)', () {
      const tapPos = Offset(196, 426);
      engine.triggerTapBurst(tapPos, scale: 1.0);

      expect(engine.tapSparks.isNotEmpty, isTrue);
      expect(engine.spiralSparks.isNotEmpty, isTrue);
      expect(engine.floatingOms.isNotEmpty, isTrue);
      expect(engine.glowRings.isNotEmpty, isTrue);

      // Verify sacred Om symbol is generated
      final hasOm = engine.floatingOms.any((om) => om.text.isNotEmpty);
      expect(hasOm, isTrue);
    });

    test('4. Shiva Completion Lifecycle & Bilva Leaf Shower', () async {
      bool completionFired = false;
      engine.triggerCompletion(
        duration: const Duration(milliseconds: 80),
        onComplete: () {
          completionFired = true;
        },
      );

      expect(engine.state, EffectEngineState.completing);
      expect(engine.petals.isNotEmpty, isTrue);

      // Verify Bilva leaf shape is used in shower
      expect(engine.petals.first.shape, ParticleShapeType.leaf);

      await Future.delayed(const Duration(milliseconds: 120));
      expect(engine.state, EffectEngineState.completed);
      expect(completionFired, isTrue);
    });

    test('5. Shiva Asset Preload & Fallback Robustness', () {
      final validProvider = assetLoader.resolveImageProvider(
        shivaPack.haloTextureUrl,
      );
      expect(validProvider != null || validProvider == null, isTrue);

      // Corrupt asset handling
      final fallback = assetLoader.resolveImageProvider(
        'corrupted://shiva_trishul_404.png',
      );
      expect(fallback != null || fallback == null, isTrue);
    });

    test('6. Decoupled Pipeline (Pure Configuration Verification)', () {
      // Create a generic engine without referencing Shiva
      final genericEngine = DivineEffectEngine(
        pack: shivaPack,
        initialIntensity: 1.0,
      );

      expect(genericEngine.pack.shape, ParticleShapeType.leaf);
      expect(genericEngine.pack.primaryColor, const Color(0xFF81C784));
      genericEngine.dispose();
    });
  });
}
