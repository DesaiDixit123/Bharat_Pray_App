import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/models/particles.dart';
import 'package:bharat_pray/services/effect_engine/effect_engine.dart';
import 'package:bharat_pray/services/effect_engine/effect_asset_loader.dart';
import 'package:bharat_pray/services/effect_engine/effect_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 17: Production Performance Optimization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      EffectRegistry().reset();
    });

    test('1. Smoke particle pool never exceeds kMaxSmokeParticles cap', () {
      final engine = DivineEffectEngine(pack: EffectPack.shivaPreset);
      engine.setIncensePosition(const Offset(100, 100));
      for (int i = 0; i < 500; i++) {
        engine.update(0.016, screenWidth: 393, screenHeight: 852);
      }
      expect(engine.smokeParticles.length, lessThanOrEqualTo(kMaxSmokeParticles));
      engine.dispose();
    });

    test('2. EmberParticle from particles.dart is canonical (no class conflict)', () {
      final engine = DivineEffectEngine(pack: EffectPack.ganeshaPreset);
      expect(engine.embers.isNotEmpty, isTrue);
      expect(engine.embers.first, isA<EmberParticle>());
      engine.dispose();
    });

    test('3. notifyListeners guard skips rebuild when particle pools are empty', () {
      int notifyCount = 0;
      final engine = DivineEffectEngine(pack: EffectPack.shivaPreset);
      engine.addListener(() => notifyCount++);
      engine.embers.clear();
      final countBefore = notifyCount;
      for (int i = 0; i < 10; i++) {
        engine.update(0.016, screenWidth: 393, screenHeight: 852);
      }
      expect(notifyCount - countBefore, lessThan(10),
          reason: 'notifyListeners() should be skipped when all particle pools are empty');
      engine.dispose();
    });

    test('4. kMaxSmokeParticles constant = 20', () {
      expect(kMaxSmokeParticles, equals(20));
    });

    test('5. PetalParticle initialises correctly via shared RNG', () {
      final petal = PetalParticle(
        x: 100, y: 200, vy: 1.0, angle: 0, rotationSpeed: 0.01,
        size: 10, windFreq: 1.0, windAmp: 0.5,
        color: const Color(0xFFFF6B35), shape: ParticleShapeType.petal,
      );
      expect(petal.time, greaterThanOrEqualTo(0));
      expect(petal.time, lessThan(100));
    });

    test('6. Engine dispose clears all particle pools (no memory leak)', () {
      for (final pack in [EffectPack.shivaPreset, EffectPack.ganeshaPreset,
                           EffectPack.krishnaPreset, EffectPack.hanumanPreset]) {
        final engine = DivineEffectEngine(pack: pack);
        engine.setIncensePosition(const Offset(200, 300));
        for (int i = 0; i < 20; i++) {
          engine.update(0.016, screenWidth: 393, screenHeight: 852);
        }
        engine.dispose();
        expect(engine.embers.isEmpty, isTrue);
        expect(engine.smokeParticles.isEmpty, isTrue);
        expect(engine.petals.isEmpty, isTrue);
        expect(engine.glowRings.isEmpty, isTrue);
      }
    });

    test('7. EffectAssetLoader is a singleton', () {
      final loader1 = EffectAssetLoader();
      final loader2 = EffectAssetLoader();
      expect(identical(loader1, loader2), isTrue);
    });

    test('8. Smoke cap enforced across 3000 frames (50-second session)', () {
      final engine = DivineEffectEngine(pack: EffectPack.hanumanPreset);
      engine.setIncensePosition(const Offset(196, 300));
      for (int i = 0; i < 3000; i++) {
        engine.update(0.016, screenWidth: 393, screenHeight: 852);
        expect(engine.smokeParticles.length, lessThanOrEqualTo(kMaxSmokeParticles),
            reason: 'Cap violated at frame \$i');
      }
      engine.dispose();
    });
  });
}
