import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/widgets/cinematic_jap/ram_path_calculator.dart';
import 'package:bharat_pray/widgets/prakash_jap/prakash_temple_background.dart';
import 'package:bharat_pray/widgets/prakash_jap/prakash_mandal_painter.dart';
import 'package:bharat_pray/widgets/prakash_jap/prakash_progressive_reveal_widget.dart';
import 'package:bharat_pray/widgets/prakash_jap/prakash_darshan_climax_view.dart';
import 'package:bharat_pray/screens/details/prakash_jap_screen.dart';

Future<ui.Image> createTestImage({int width = 100, int height = 150}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFD54F),
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

  group('Effect 4: Prakash Mandal — Specification & Rendering Tests', () {
    test('Reuses the exact 108 reveal nodes from RamPathCalculator', () {
      expect(RamPathCalculator.revealNodes.length, equals(108));
      expect(RamPathCalculator.targetJapCount, equals(108));

      final nodes0 = RamPathCalculator.getRevealedNodesForCount(0);
      expect(nodes0.isEmpty, isTrue);

      final nodes54 = RamPathCalculator.getRevealedNodesForCount(54);
      expect(nodes54.length, equals(54));

      final nodes108 = RamPathCalculator.getRevealedNodesForCount(108);
      expect(nodes108.length, equals(108));
    });

    test('GoldenParticle physics update lifetime, alpha, and position', () {
      final p = GoldenParticle(
        x: 200,
        y: 400,
        vx: 10,
        vy: -20,
        radius: 2.0,
        maxAlpha: 0.8,
        pulseSpeed: 2.0,
        maxLife: 2.0,
      );

      final stillActive = p.update(0.5);
      expect(stillActive, isTrue);
      expect(p.alpha, greaterThan(0.0));
      expect(p.y, lessThan(400)); // Rising upward

      final expired = p.update(2.5);
      expect(expired, isFalse);
    });

    test('PrakashMandalPainter renders at count 0, middle, and 108', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painter0 = PrakashMandalPainter(
        count: 0,
        ambientTime: 0.25,
        pulseValue: 0.0,
        completionGlow: 0.0,
        particles: [],
      );
      painter0.paint(canvas, const Size(400, 800));

      final painter54 = PrakashMandalPainter(
        count: 54,
        ambientTime: 0.50,
        pulseValue: 0.8,
        completionGlow: 0.0,
        particles: [
          GoldenParticle(
            x: 200,
            y: 300,
            vx: 0,
            vy: -10,
            radius: 2,
            maxAlpha: 0.8,
            pulseSpeed: 1,
            maxLife: 2,
          )..alpha = 0.5,
        ],
      );
      painter54.paint(canvas, const Size(400, 800));

      final painter108 = PrakashMandalPainter(
        count: 108,
        ambientTime: 1.0,
        pulseValue: 0.0,
        completionGlow: 1.0,
        particles: [],
      );
      painter108.paint(canvas, const Size(400, 800));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('PrakashProgressiveRevealPainter paints progressively without crashing', () async {
      final img = await createTestImage();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 800));

      final painter = PrakashProgressiveRevealPainter(
        image: img,
        count: 42,
        revealedNodes: RamPathCalculator.getRevealedNodesForCount(42),
        newestNode: RamPathCalculator.getRevealedNodesForCount(42).last,
        shimmerProgress: 0.5,
        isCompleted: false,
        completionGlow: 0.0,
      );

      painter.paint(canvas, const Size(400, 800));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    testWidgets('PrakashTempleBackground and Climax View render in tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const PrakashTempleBackground(ambientTime: 0.5),
                PrakashDarshanClimaxView(
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

    testWidgets('PrakashJapScreen mounts and displays initial 0 / 108 state', (tester) async {
      final entry = JapConfig(
        id: 'ram_jap_test_prakash',
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
          home: PrakashJapScreen(entry: entry),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify Counter & Mantra
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
