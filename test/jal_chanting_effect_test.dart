import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/widgets/cinematic_jap/ram_path_calculator.dart';
import 'package:bharat_pray/widgets/jal_jap/jal_water_ripple_painter.dart';
import 'package:bharat_pray/widgets/jal_jap/jal_temple_background.dart';
import 'package:bharat_pray/widgets/jal_jap/jal_lotus_row_widget.dart';
import 'package:bharat_pray/widgets/jal_jap/jal_progressive_water_reveal_widget.dart';
import 'package:bharat_pray/widgets/jal_jap/jal_darshan_climax_view.dart';
import 'package:bharat_pray/screens/details/jal_jap_screen.dart';

Future<ui.Image> createTestImage({int width = 100, int height = 150}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF00ACC1),
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

  group('Divine Jal Darshan — Sacred Water Reveal Specification Tests', () {
    test('Reuses the exact same 108 reveal nodes from RamPathCalculator', () {
      expect(RamPathCalculator.revealNodes.length, equals(108));
      expect(RamPathCalculator.targetJapCount, equals(108));

      // Test progressive nodes retrieval across milestones
      final nodes0 = RamPathCalculator.getRevealedNodesForCount(0);
      expect(nodes0.isEmpty, isTrue);

      final nodes1 = RamPathCalculator.getRevealedNodesForCount(1);
      expect(nodes1.length, equals(1));

      final nodes27 = RamPathCalculator.getRevealedNodesForCount(27);
      expect(nodes27.length, equals(27));

      final nodes54 = RamPathCalculator.getRevealedNodesForCount(54);
      expect(nodes54.length, equals(54));

      final nodes108 = RamPathCalculator.getRevealedNodesForCount(108);
      expect(nodes108.length, equals(108));
    });

    test('Sacred face is protected beneath holy water until final climax', () {
      // First 102 steps: NO node inside faceBox
      for (int i = 0; i < 102; i++) {
        final node = RamPathCalculator.getNodeForStep(i);
        expect(
          RamPathCalculator.faceBox.contains(Offset(node.u, node.v)),
          isFalse,
          reason: 'Node $i (${node.label}) must not enter faceBox before Jap 103',
        );
      }

      // Steps 102..107 (Japs 103..108): Face climax nodes emerge from water
      for (int i = 102; i < 108; i++) {
        final node = RamPathCalculator.getNodeForStep(i);
        expect(
          RamPathCalculator.faceBox.contains(Offset(node.u, node.v)),
          isTrue,
          reason: 'Climax node $i (${node.label}) reveals the divine face',
        );
      }
    });

    test('WaterRipple expands and returns false on duration expiration', () {
      final ripple = WaterRipple(
        center: const Offset(200, 400),
        maxRadius: 180,
        duration: 1.0,
      );

      final initialRadius = ripple.radius;
      final stillActive = ripple.update(0.5);
      expect(stillActive, isTrue);
      expect(ripple.radius, greaterThan(initialRadius));

      final expired = ripple.update(0.6);
      expect(expired, isFalse);
    });

    test('WaterDrop physics update position and advance age', () {
      final drop = WaterDrop(
        x: 200,
        y: 500,
        vx: 20,
        vy: -120,
        radius: 3.5,
        duration: 0.8,
        color: const Color(0xFF80DEEA),
      );

      final initialY = drop.y;
      final stillAlive = drop.update(0.1);

      expect(stillAlive, isTrue);
      expect(drop.age, closeTo(0.1, 0.01));
      expect(drop.y, isNot(equals(initialY)));
    });

    testWidgets('JalWaterRipplePainter paints active ripples and droplets without errors', (tester) async {
      final ripple = WaterRipple(
        center: const Offset(150, 300),
        maxRadius: 120,
      );
      final droplet = WaterDrop(
        x: 150,
        y: 300,
        vx: 10,
        vy: -80,
        radius: 3.0,
        duration: 0.8,
        color: const Color(0xFFE0F7FA),
      );

      final painter = JalWaterRipplePainter(
        ripples: [ripple],
        droplets: [droplet],
        petals: [],
        ambientTime: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: painter,
              size: const Size(360, 700),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('JalTempleBackground renders sanctum, lamp glow, and water pool caustics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JalTempleBackground(flameFlicker: 0.5),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(JalTempleBackground), findsOneWidget);
    });

    testWidgets('JalLotusRowWidget renders floating pink lotuses and burning brass diyas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JalLotusRowWidget(waveTime: 0.5),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(JalLotusRowWidget), findsOneWidget);
    });

    testWidgets('JalProgressiveWaterRevealPainter paints at count 0 without black overlay and at count 50 smoothly', (tester) async {
      final img = await createTestImage();

      // At count 0: does not draw black overlay
      final painter0 = JalProgressiveWaterRevealPainter(
        image: img,
        count: 0,
        ambientTime: 0.3,
        isCompleted: false,
        completionGlow: 0.0,
      );

      // At count 50: paints organic water emergence mask
      final painter50 = JalProgressiveWaterRevealPainter(
        image: img,
        count: 50,
        ambientTime: 0.5,
        isCompleted: false,
        completionGlow: 0.0,
      );

      // At count 108: paints completion aura
      final painter108 = JalProgressiveWaterRevealPainter(
        image: img,
        count: 108,
        ambientTime: 0.5,
        isCompleted: true,
        completionGlow: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomPaint(painter: painter0, size: const Size(200, 200)),
                CustomPaint(painter: painter50, size: const Size(200, 200)),
                CustomPaint(painter: painter108, size: const Size(200, 200)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('JalDarshanClimaxView renders blessing banner and action controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JalDarshanClimaxView(
              imageAsset: 'assets/images/ram_jal_darshan.png',
              videoAsset: 'assets/videos/ram_jal_live_darshan.mp4',
              onNextMala: () {},
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Check blessing banner text
      expect(find.text('🙏 जय श्री राम — दिव्य जल दर्शन 🙏'), findsOneWidget);
      expect(find.text('Next Mala'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('JalJapScreen initializes with correct count and devotional elements', (tester) async {
      final entry = JapConfig(
        id: 'ram_jal_test',
        name: 'Shri Ram Jal Darshan',
        shlokText: 'श्री राम जय राम जय जय राम',
        thumbnailUrl: '',
        darshanImageUrl: '',
        effectPack: EffectPack.ramPreset,
        progress: 0,
        targetCount: 108,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JalJapScreen(entry: entry),
        ),
      );
      await tester.pump();

      // Check top Devanagari Title
      expect(find.text('राम'), findsWidgets);

      // Check initial counter (0 / 108)
      expect(find.text('0'), findsOneWidget);
      expect(find.text('/ 108'), findsOneWidget);

      // Check circular Play button
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Check Progressive water reveal widget is in the tree
      expect(find.byType(JalProgressiveWaterRevealWidget), findsOneWidget);
    });

    testWidgets('Tapping the sacred water button increments counter and advances reveal', (tester) async {
      final entry = JapConfig(
        id: 'ram_jal_tap_test',
        name: 'Shri Ram Jal Darshan',
        shlokText: 'श्री राम जय राम जय जय राम',
        thumbnailUrl: '',
        darshanImageUrl: '',
        effectPack: EffectPack.ramPreset,
        progress: 0,
        targetCount: 108,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JalJapScreen(entry: entry),
        ),
      );
      await tester.pump();

      expect(find.text('0'), findsOneWidget);

      // Tap the circular play button
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();

      // Counter should now be 1
      expect(find.text('1'), findsOneWidget);
      expect(find.text('/ 108'), findsOneWidget);
    });
  });
}
