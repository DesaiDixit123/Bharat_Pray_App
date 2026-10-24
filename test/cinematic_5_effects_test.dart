import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_animation_effect.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/widgets/cinematic_jap/ram_path_calculator.dart';
import 'package:bharat_pray/widgets/cinematic_jap/effects/shared_vertical_ram_flight_painter.dart';
import 'package:bharat_pray/widgets/cinematic_jap/effects/golden_aura_reveal_painter.dart';
import 'package:bharat_pray/widgets/cinematic_jap/effects/lotus_bloom_reveal_painter.dart';
import 'package:bharat_pray/widgets/cinematic_jap/effects/dhoop_smoke_reveal_painter.dart';
import 'package:bharat_pray/widgets/cinematic_jap/effects/divine_particle_reveal_painter.dart';
import 'package:bharat_pray/widgets/cinematic_jap/effects/jap_effect_selector_sheet.dart';
import 'package:bharat_pray/screens/details/cinematic_jap_screen.dart';

Future<ui.Image> createTestImage({int width = 100, int height = 177}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF9900),
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jap_sound_enabled': false,
    });
  });

  group('Section 2: 5 Effects Model & Registration Specification', () {
    test('Exactly 5 effects are supported in designated order', () {
      expect(JapRevealEffectConfig.allEffects.length, equals(5));
      expect(JapRevealEffectConfig.allEffects[0].type, equals(JapRevealEffectType.divineVerticalReveal));
      expect(JapRevealEffectConfig.allEffects[1].type, equals(JapRevealEffectType.goldenAuraReveal));
      expect(JapRevealEffectConfig.allEffects[2].type, equals(JapRevealEffectType.lotusBloomReveal));
      expect(JapRevealEffectConfig.allEffects[3].type, equals(JapRevealEffectType.dhoopSmokeReveal));
      expect(JapRevealEffectConfig.allEffects[4].type, equals(JapRevealEffectType.divineParticleReveal));
    });

    test('Existing Live Darshan Effect is the default and preserved', () {
      final defaultEffect = JapRevealEffectConfig.fromId(null);
      expect(defaultEffect.id, equals('divine_vertical_reveal'));
      expect(defaultEffect.name, equals('Live Darshan Effect'));
      expect(defaultEffect.type, equals(JapRevealEffectType.divineVerticalReveal));
    });

    test('All 4 new effects have correct IDs, badges, and descriptions', () {
      final golden = JapRevealEffectConfig.fromId('golden_aura_reveal');
      expect(golden.id, equals('golden_aura_reveal'));
      expect(golden.badge, equals('RADIANT'));

      final lotus = JapRevealEffectConfig.fromId('lotus_bloom_reveal');
      expect(lotus.id, equals('lotus_bloom_reveal'));
      expect(lotus.badge, equals('SACRED'));

      final dhoop = JapRevealEffectConfig.fromId('dhoop_smoke_reveal');
      expect(dhoop.id, equals('dhoop_smoke_reveal'));
      expect(dhoop.badge, equals('DIVINE'));

      final particle = JapRevealEffectConfig.fromId('divine_particle_reveal');
      expect(particle.id, equals('divine_particle_reveal'));
      expect(particle.badge, equals('CELESTIAL'));
    });
  });

  group('Section 3A: Shared Vertical Ram Flight Painter in Widget Tree', () {
    testWidgets('Renders straight vertical Ram flight widget across progress timeline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: SharedVerticalRamFlightPainter(
                progress: 0.50,
                startPoint: const Offset(200, 600),
                targetPoint: const Offset(200, 200),
                screenSize: const Size(400, 800),
              ),
              size: const Size(400, 800),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Section 4-7: 4 New Effect Painters & Face Shield Integrity', () {
    test('Golden Aura Reveal Painter renders in-progress and completion states', () async {
      final image = await createTestImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painterProgress = GoldenAuraRevealPainter(
        image: image,
        revealedNodes: RamPathCalculator.getRevealedNodesForCount(50),
        newestNode: RamPathCalculator.getNodeForStep(49),
        shimmerProgress: 0.5,
        isCompleted: false,
        completionGlowProgress: 0.0,
      );
      expect(() => painterProgress.paint(canvas, const Size(400, 800)), returnsNormally);

      final painterComplete = GoldenAuraRevealPainter(
        image: image,
        revealedNodes: RamPathCalculator.revealNodes,
        shimmerProgress: 1.0,
        isCompleted: true,
        completionGlowProgress: 0.8,
      );
      expect(() => painterComplete.paint(canvas, const Size(400, 800)), returnsNormally);

      recorder.endRecording();
    });

    test('Lotus Bloom Reveal Painter renders unfolding petals', () async {
      final image = await createTestImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painter = LotusBloomRevealPainter(
        image: image,
        revealedNodes: RamPathCalculator.getRevealedNodesForCount(75),
        newestNode: RamPathCalculator.getNodeForStep(74),
        shimmerProgress: 0.3,
        isCompleted: false,
        completionGlowProgress: 0.0,
      );
      expect(() => painter.paint(canvas, const Size(400, 800)), returnsNormally);

      recorder.endRecording();
    });

    test('Dhoop Smoke Reveal Painter renders rising curling incense wisps', () async {
      final image = await createTestImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painter = DhoopSmokeRevealPainter(
        image: image,
        revealedNodes: RamPathCalculator.getRevealedNodesForCount(60),
        newestNode: RamPathCalculator.getNodeForStep(59),
        shimmerProgress: 0.4,
        isCompleted: false,
        completionGlowProgress: 0.0,
      );
      expect(() => painter.paint(canvas, const Size(400, 800)), returnsNormally);

      recorder.endRecording();
    });

    test('Divine Particle Reveal Painter renders stardust constellation', () async {
      final image = await createTestImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painter = DivineParticleRevealPainter(
        image: image,
        revealedNodes: RamPathCalculator.getRevealedNodesForCount(90),
        newestNode: RamPathCalculator.getNodeForStep(89),
        shimmerProgress: 0.6,
        isCompleted: false,
        completionGlowProgress: 0.0,
      );
      expect(() => painter.paint(canvas, const Size(400, 800)), returnsNormally);

      recorder.endRecording();
    });
  });

  group('Section 8: Animation Effect Selector UI & Persistence', () {
    testWidgets('JapEffectSelectorSheet renders all 5 effects and allows selection', (tester) async {
      JapRevealEffectType selectedEffect = JapRevealEffectType.divineVerticalReveal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  JapEffectSelectorSheet.show(
                    ctx,
                    currentEffect: selectedEffect,
                    onEffectSelected: (newEffect) {
                      selectedEffect = newEffect;
                    },
                  );
                },
                child: const Text('Open Selector'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Selector'));
      await tester.pumpAndSettle();

      // Verify all 5 effects exist in the modal
      expect(find.text('Darshan Animation Effects'), findsOneWidget);
      expect(find.text('Live Darshan Effect'), findsOneWidget);
      expect(find.text('Golden Aura Reveal'), findsOneWidget);
      expect(find.text('Lotus Bloom Reveal'), findsOneWidget);
      expect(find.text('Dhoop Smoke Reveal'), findsOneWidget);
      expect(find.text('Divine Particle Reveal'), findsOneWidget);

      // Select Dhoop Smoke Reveal
      await tester.tap(find.text('Dhoop Smoke Reveal'));
      await tester.pumpAndSettle();

      expect(selectedEffect, equals(JapRevealEffectType.dhoopSmokeReveal));

      // Verify preference saved in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jap_selected_reveal_effect'), equals('dhoop_smoke_reveal'));
    });
  });

  group('CinematicJapScreen 5-Effects Integration', () {
    final entry = JapConfig(
      id: 'lord_shri_ram_test',
      name: 'Lord Shri Ram 108 Jap',
      thumbnailUrl: 'assets/images/lord_shri_ram_darshan.png',
      darshanImageUrl: 'assets/images/lord_shri_ram_darshan.png',
      shlokText: 'श्री राम जय राम जय जय राम',
      targetCount: 108,
      progress: 0,
      effectPack: EffectPack.ram,
    );

    testWidgets('CinematicJapScreen includes Effect Selector button in top bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicJapScreen(entry: entry),
        ),
      );
      await tester.pump();

      // Verify effect selector button is present (auto_awesome_rounded icon)
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });
}
