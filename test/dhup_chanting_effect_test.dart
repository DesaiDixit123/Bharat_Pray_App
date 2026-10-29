import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/widgets/cinematic_jap/ram_path_calculator.dart';
import 'package:bharat_pray/widgets/dhup_jap/dhup_incense_reveal_painter.dart';
import 'package:bharat_pray/widgets/dhup_jap/dhup_smoke_painter.dart';
import 'package:bharat_pray/widgets/dhup_jap/dhup_temple_background.dart';
import 'package:bharat_pray/widgets/dhup_jap/dhup_burner_widget.dart';
import 'package:bharat_pray/screens/details/dhup_jap_screen.dart';
import 'package:bharat_pray/screens/details/cinematic_jap_screen.dart';

Future<ui.Image> createTestImage({int width = 100, int height = 150}) async {
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
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'jap_sound_enabled': false,
    });
  });

  group('Dhup Chanting Effect — Core Reusability & Specification Tests', () {
    test('Reuses the exact same 108 reveal nodes from RamPathCalculator', () {
      expect(RamPathCalculator.revealNodes.length, equals(108));
      expect(RamPathCalculator.targetJapCount, equals(108));

      // Test progressive nodes retrieval across milestones
      final nodes0 = RamPathCalculator.getRevealedNodesForCount(0);
      expect(nodes0.isEmpty, isTrue);

      final nodes10 = RamPathCalculator.getRevealedNodesForCount(10);
      expect(nodes10.length, equals(10));

      final nodes50 = RamPathCalculator.getRevealedNodesForCount(50);
      expect(nodes50.length, equals(50));

      final nodes108 = RamPathCalculator.getRevealedNodesForCount(108);
      expect(nodes108.length, equals(108));
    });

    test('Face protection is strictly preserved across all 108 steps', () {
      // First 102 steps: NO node inside faceBox
      for (int i = 0; i < 102; i++) {
        final node = RamPathCalculator.getNodeForStep(i);
        expect(
          RamPathCalculator.faceBox.contains(Offset(node.u, node.v)),
          isFalse,
          reason: 'Node $i (${node.label}) must not enter faceBox before Jap 103',
        );
      }

      // Steps 102..107 (Japs 103..108): Face climax nodes
      for (int i = 102; i < 108; i++) {
        final node = RamPathCalculator.getNodeForStep(i);
        expect(
          RamPathCalculator.faceBox.contains(Offset(node.u, node.v)),
          isTrue,
          reason: 'Climax node $i (${node.label}) reveals the sacred face',
        );
      }
    });

    test('DirectionalSmokeStream travels towards target and triggers arrival callback', () {
      bool arrived = false;
      final stream = DirectionalSmokeStream(
        step: 0,
        start: const Offset(200, 600),
        target: const Offset(80, 150), // Top-left
        duration: 0.5,
        onArrived: () {
          arrived = true;
        },
      );

      // Simulate stream updates
      for (int i = 0; i < 35; i++) {
        stream.update(0.016);
      }

      expect(arrived, isTrue);
      expect(stream.hasArrived, isTrue);
    });

    testWidgets('DhupSmokePainter updates streams and executes paint without crashing', (tester) async {
      final ambientWisps = [
        AmbientSmokeWisp(
          startX: 200,
          startY: 600,
          vy: -80,
          waveFreq: 1.0,
          waveAmp: 30,
          wavePhase: 0.0,
          maxRadius: 40,
          maxAlpha: 0.65,
          duration: 4.0,
          color: const Color(0xFFFFFDE7),
        ),
      ];

      final stream = DirectionalSmokeStream(
        step: 0,
        start: const Offset(200, 600),
        target: const Offset(80, 150),
        duration: 0.8,
        onArrived: () {},
      );
      stream.update(0.05);

      final painter = DhupSmokePainter(
        activeStreams: [stream],
        ambientWisps: ambientWisps,
        burnerMouthCenter: const Offset(200, 600),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: painter,
              size: const Size(400, 800),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('DhupTempleBackground renders columns and altar without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DhupTempleBackground(flameFlicker: 0.5),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DhupTempleBackground), findsOneWidget);
    });

    testWidgets('DhupBurnerWidget renders brass burner, glowing embers, and diyas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DhupBurnerWidget(
              emberGlow: 0.5,
              onBurnerMouthPositioned: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DhupBurnerWidget), findsOneWidget);
    });

    testWidgets('DhupJapScreen initializes with correct count and displays circular counter', (tester) async {
      final entry = JapConfig(
        id: 'ram_dhup_test',
        name: 'Shri Ram Dhup Chanting',
        shlokText: 'श्री राम जय राम जय जय राम',
        thumbnailUrl: '',
        darshanImageUrl: '',
        effectPack: EffectPack.ramPreset,
        progress: 0,
        targetCount: 108,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DhupJapScreen(entry: entry),
        ),
      );
      await tester.pump();

      // Verify devotional counter
      expect(find.text('0'), findsOneWidget);
      expect(find.text('/ 108'), findsOneWidget);

      // Verify circular Play button
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Verify bespoke incense smoke progressive reveal widget is present
      expect(find.byType(DhupIncenseRevealWidget), findsOneWidget);
    });

    testWidgets('Tapping Play button transforms icon to pause ("equal to" ||) and advances reveal', (tester) async {
      final entry = JapConfig(
        id: 'ram_dhup_test_tap',
        name: 'Shri Ram Dhup Chanting',
        shlokText: 'श्री राम जय राम जय जय राम',
        thumbnailUrl: '',
        darshanImageUrl: '',
        effectPack: EffectPack.ramPreset,
        progress: 0,
        targetCount: 108,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DhupJapScreen(entry: entry),
        ),
      );
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
      // Initially, Play button shows play_arrow_rounded
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Helper to simulate the 60fps smoke flight until arrival
      Future<void> advanceSmokeFlight() async {
        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      // Tap Play button to start chanting
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 50));

      // Button transforms to "equal to" / pause icon (||) during chant flight
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Let smoke stream & single 'राम' text travel to target node
      await advanceSmokeFlight();

      // Verify count increments to 1
      expect(find.text('1'), findsOneWidget);

      // Button returns to play_arrow_rounded when chant finishes
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap Play button again for second Jap
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 50));

      // Button transforms to pause icon (||) during second chant flight
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Advance smoke flight for second Jap
      await advanceSmokeFlight();
      expect(find.text('2'), findsOneWidget);

      // Button returns to play_arrow_rounded, ready for next tap
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('CinematicJapScreen still works and preserves its components', (tester) async {
      final entry = JapConfig(
        id: 'ram_cinematic_test',
        name: 'Lord Shri Ram 108 Jap',
        shlokText: 'श्री राम जय राम जय जय राम',
        thumbnailUrl: '',
        darshanImageUrl: '',
        effectPack: EffectPack.ramPreset,
        progress: 0,
        targetCount: 108,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CinematicJapScreen(entry: entry),
        ),
      );
      await tester.pump();

      expect(find.byType(CinematicJapScreen), findsOneWidget);
      expect(find.text('राम'), findsWidgets);
    });
  });
}
