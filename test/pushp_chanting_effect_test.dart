import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/widgets/cinematic_jap/ram_path_calculator.dart';
import 'package:bharat_pray/widgets/pushp_varsha/pushp_temple_background.dart';
import 'package:bharat_pray/widgets/pushp_varsha/pushp_petal_physics.dart';
import 'package:bharat_pray/widgets/pushp_varsha/pushp_petal_shower_painter.dart';
import 'package:bharat_pray/widgets/pushp_varsha/pushp_progressive_reveal_widget.dart';
import 'package:bharat_pray/widgets/pushp_varsha/pushp_darshan_climax_view.dart';
import 'package:bharat_pray/screens/details/pushp_varsha_jap_screen.dart';

Future<ui.Image> createTestImage({int width = 100, int height = 150}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF80AB),
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'jap_sound_enabled': false,
    });
  });

  group('Effect 5: Pushp Varsha — Specification & Rendering Tests', () {
    test('FallingPetal physics update position, rotation, and tumble', () {
      final petal = FallingPetal(
        x: 200,
        y: 50,
        vy: 80,
        swayAmp: 20,
        swayFreq: 1.0,
        phase: 0.0,
        rotation: 0.0,
        rotSpeed: 1.0,
        tumble: 0.0,
        tumbleSpeed: 2.0,
        size: 14.0,
        maxAlpha: 0.9,
        maxLife: 4.0,
        isBackground: false,
        type: PetalType.lotusPetal,
      );

      final stillActive = petal.update(0.5, 800);
      expect(stillActive, isTrue);
      expect(petal.y, greaterThan(50)); // Falling downward
      expect(petal.alpha, greaterThan(0.0));
      expect(petal.rotation, greaterThan(0.0));

      final expired = petal.update(5.0, 800);
      expect(expired, isFalse);
    });

    test('TargetedPetal swoops along Bezier trajectory towards target coordinate', () {
      final targeted = TargetedPetal(
        start: const Offset(200, 50),
        control: const Offset(280, 150),
        target: const Offset(180, 400),
        type: PetalType.lotusPetal,
        size: 16.0,
        duration: 0.50,
        rotSpeed: 2.0,
        tumbleSpeed: 3.0,
        swayAmp: 10.0,
        swayFreq: 1.5,
      );

      expect(targeted.hasArrived, isFalse);
      // Halfway through flight
      final active = targeted.update(0.25);
      expect(active, isTrue);
      expect(targeted.currentPos.dy, greaterThan(50));
      expect(targeted.currentPos.dy, lessThan(400));
      expect(targeted.alpha, greaterThan(0.0));

      // After flight finishes (reaches target)
      targeted.update(0.30);
      expect(targeted.hasArrived, isTrue);

      // Complete drift life
      final alive = targeted.update(0.40);
      expect(alive, isFalse);
    });

    test('PetalImpactSpark bursts and fades', () {
      final spark = PetalImpactSpark(
        position: const Offset(150, 300),
        velocity: const Offset(10, -20),
        size: 3.0,
        maxLife: 0.35,
        color: const Color(0xFFFFD54F),
      );

      final active = spark.update(0.15);
      expect(active, isTrue);
      expect(spark.position.dy, lessThan(300));
      expect(spark.alpha, lessThan(1.0));

      final done = spark.update(0.30);
      expect(done, isFalse);
    });

    test('FloatingRamText floats along Bezier arc, scales, arrives, and dissolves gracefully', () {
      final textParticle = FloatingRamText(
        text: 'श्री राम',
        start: const Offset(200, 700),
        control: const Offset(250, 500),
        target: const Offset(200, 300),
        duration: 1.38,
        fontSize: 20.0,
      );

      expect(textParticle.hasArrived, isFalse);
      expect(textParticle.currentPos, equals(const Offset(200, 700)));

      // Mid flight (0.6s into 1.38s)
      final midAlive = textParticle.update(0.60);
      expect(midAlive, isTrue);
      expect(textParticle.currentPos.dy, lessThan(700));
      expect(textParticle.currentPos.dy, greaterThan(300));
      expect(textParticle.alpha, greaterThan(0.5));
      expect(textParticle.scale, greaterThan(0.9));

      // Reaching destination (finish 1.38s flight, then begin drift)
      textParticle.update(0.78); // elapsed = 1.38s
      final arrivalAlive = textParticle.update(0.10); // now drifting
      expect(arrivalAlive, isTrue);
      expect(textParticle.hasArrived, isTrue);

      // Expiring after drift (maxDrift = 0.45s)
      final expired = textParticle.update(0.40);
      expect(expired, isFalse);
    });

    test('PushpPetalShowerPainter paints ambient, targeted petals, sparks, and floating text', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final petals = [
        FallingPetal(
          x: 150,
          y: 200,
          vy: 60,
          swayAmp: 10,
          swayFreq: 1,
          phase: 0,
          rotation: 0.5,
          rotSpeed: 1,
          tumble: 0.2,
          tumbleSpeed: 1,
          size: 15,
          maxAlpha: 0.8,
          maxLife: 4,
          isBackground: true,
          type: PetalType.lotusPetal,
        )..alpha = 0.8,
      ];

      final targeted = [
        TargetedPetal(
          start: const Offset(100, 50),
          control: const Offset(150, 100),
          target: const Offset(200, 250),
          type: PetalType.marigoldPetal,
          size: 14.0,
          duration: 0.50,
          rotSpeed: 1.0,
          tumbleSpeed: 2.0,
          swayAmp: 8.0,
          swayFreq: 1.2,
        )..alpha = 0.9,
      ];

      final sparks = [
        PetalImpactSpark(
          position: const Offset(200, 250),
          velocity: const Offset(5, 5),
          size: 3.0,
          maxLife: 0.40,
          color: const Color(0xFFFFD54F),
        )..alpha = 0.8,
      ];

      final floatingTexts = [
        FloatingRamText(
          text: 'श्री राम',
          start: const Offset(200, 700),
          control: const Offset(230, 500),
          target: const Offset(200, 300),
          duration: 1.38,
        )..alpha = 0.9,
      ];

      final bgPainter = PushpPetalShowerPainter(
        petals: petals,
        isBackgroundLayer: true,
        ambientTime: 0.5,
      );
      bgPainter.paint(canvas, const Size(400, 800));

      final fgPainter = PushpPetalShowerPainter(
        petals: petals,
        targetedPetals: targeted,
        impactSparks: sparks,
        floatingTexts: floatingTexts,
        isBackgroundLayer: false,
        ambientTime: 0.5,
      );
      fgPainter.paint(canvas, const Size(400, 800));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('PushpProgressiveRevealPainter paints progressively without error', () async {
      final img = await createTestImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painter = PushpProgressiveRevealPainter(
        image: img,
        count: 54,
        revealedNodes: RamPathCalculator.getRevealedNodesForCount(54),
        newestNode: RamPathCalculator.getRevealedNodesForCount(54).last,
        shimmerProgress: 0.5,
        isCompleted: false,
        completionGlow: 0.0,
      );

      painter.paint(canvas, const Size(400, 800));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    testWidgets('PushpTempleBackground and Climax View render in tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const PushpTempleBackground(ambientTime: 0.5),
                PushpDarshanClimaxView(
                  onNextMala: () {},
                  onExit: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('જય શ્રી રામ'), findsOneWidget);
      expect(find.text('Next Mala'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('PushpVarshaJapScreen mounts and increments counter on tap', (tester) async {
      final entry = JapConfig(
        id: 'ram_jap_test_pushp',
        name: 'શ્રી રામ',
        thumbnailUrl: 'assets/images/ram_jal_darshan.png',
        darshanImageUrl: 'assets/images/ram_jal_darshan.png',
        shlokText: 'શ્રી રામ જય રામ જય જય રામ',
        targetCount: 108,
        progress: 0,
        effectPack: EffectPack.ram,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PushpVarshaJapScreen(entry: entry),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify Counter & Controls
      expect(find.text('0'), findsOneWidget);
      expect(find.text('/ 108'), findsOneWidget);
      expect(find.text('શ્રી રામ જય રામ જય જય રામ'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Tap'), findsOneWidget);

      // Tap to increment
      await tester.tap(find.text('Tap'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
    });
  });
}
