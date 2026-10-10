import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bharat_pray/animations/jap/jap_animation_type.dart';
import 'package:bharat_pray/animations/jap/jap_mantra_helper.dart';
import 'package:bharat_pray/animations/jap/effects/radha_name_painter.dart';
import 'package:bharat_pray/animations/jap/effects/ram_spread_painter.dart';
import 'package:bharat_pray/animations/jap/effects/incense_smoke_painter.dart';
import 'package:bharat_pray/animations/jap/effects/mantra_light_painter.dart';
import 'package:bharat_pray/animations/jap/effects/divine_energy_painter.dart';
import 'package:bharat_pray/animations/jap/effects/sacred_mandala_painter.dart';
import 'package:bharat_pray/animations/jap/premium_jap_animator.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('JapAnimationType registry tests', () {
    test('All 11 animation types exist and have non-empty labels', () {
      expect(JapAnimationType.values.length, 11);
      for (final type in JapAnimationType.values) {
        expect(type.key.isNotEmpty, isTrue);
        expect(type.label.isNotEmpty, isTrue);
        expect(type.description.isNotEmpty, isTrue);
      }
    });

    test('Premium presets contains exactly the 6 premium animations', () {
      expect(JapAnimationType.premiumPresets.length, 6);
      for (final p in JapAnimationType.premiumPresets) {
        expect(p.isVideo, isFalse);
      }
    });

    test('Key resolution resolves accurately with aliases', () {
      expect(JapAnimationType.fromKey('radha_name'), JapAnimationType.radhaName);
      expect(JapAnimationType.fromKey('ram_spread'), JapAnimationType.ramSpread);
      expect(JapAnimationType.fromKey('incense_smoke'), JapAnimationType.incenseSmoke);
      expect(JapAnimationType.fromKey('mantra_light'), JapAnimationType.mantraLight);
      expect(JapAnimationType.fromKey('divine_energy'), JapAnimationType.divineEnergy);
      expect(JapAnimationType.fromKey('sacred_mandala'), JapAnimationType.sacredMandala);

      // Classic videos preserved
      expect(JapAnimationType.fromKey('dhup'), JapAnimationType.dhupVideo);
      expect(JapAnimationType.fromKey('ram'), JapAnimationType.ramVideo);
      expect(JapAnimationType.fromKey('lotus'), JapAnimationType.lotusVideo);
      expect(JapAnimationType.fromKey('peakok'), JapAnimationType.peacockVideo);
      expect(JapAnimationType.fromKey('arati'), JapAnimationType.aartiVideo);
    });

    test('Default fallback resolution preserves deity mappings', () {
      expect(JapAnimationType.resolveDefault('Radha Rani'), JapAnimationType.radhaName);
      expect(JapAnimationType.resolveDefault('Lord Ram'), JapAnimationType.ramSpread);
      expect(JapAnimationType.resolveDefault('Krishna'), JapAnimationType.peacockVideo);
      expect(JapAnimationType.resolveDefault('Mahadev Shiva'), JapAnimationType.dhupVideo);
      expect(JapAnimationType.resolveDefault('Ganesh'), JapAnimationType.lotusVideo);
      expect(JapAnimationType.resolveDefault('Hanuman Ji'), JapAnimationType.aartiVideo);
    });
  });

  group('JapMantraHelper tests', () {
    test('Returns sacred mantras for different deities', () {
      final shivaMantra = JapMantraHelper.getRandomMantra('Lord Shiva');
      expect(shivaMantra.isNotEmpty, isTrue);

      final ramMantra = JapMantraHelper.getRandomMantra('Shree Ram');
      expect(ramMantra.isNotEmpty, isTrue);
    });
  });

  group('Animation Painters Execution (No Exceptions)', () {
    const size = Size(353, 520);
    const revealPoint = Offset(160, 240);

    test('RadhaNamePainter paints without error at 0.0, 0.5, 1.0 with blooming lotus seal', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final p in [0.0, 0.5, 1.0]) {
        final painter = RadhaNamePainter(progress: p, revealPoint: revealPoint, seed: 0.77);
        painter.paint(canvas, size);
      }
    });

    test('RamSpreadPainter paints without error with centered Ram Ram and peripheral spots', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final p in [0.0, 0.25, 0.5, 0.85, 1.0]) {
        final painter = RamSpreadPainter(progress: p, revealPoint: revealPoint, seed: 0.55);
        painter.paint(canvas, size);
      }
    });

    test('IncenseSmokePainter paints without error at 0.0, 0.5, 1.0 with dense smoke and zero red spot', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final p in [0.0, 0.5, 1.0]) {
        final painter = IncenseSmokePainter(progress: p, revealPoint: revealPoint, seed: 0.12);
        painter.paint(canvas, size);
      }
    });

    test('MantraLightPainter paints without error as descending celestial beam with Sanskrit runes', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final p in [0.0, 0.45, 0.75, 1.0]) {
        final painter = MantraLightPainter(progress: p, mantra: 'ॐ नमः शिवाय', revealPoint: revealPoint, seed: 0.9);
        painter.paint(canvas, size);
      }
    });

    test('DivineEnergyPainter paints without error using strictly golden, orange, and yellow', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final p in [0.0, 0.5, 1.0]) {
        final painter = DivineEnergyPainter(progress: p, revealPoint: revealPoint, seed: 0.7);
        painter.paint(canvas, size);
      }
    });

    test('SacredMandalaPainter paints without error with divine sunburst and Sri Yantra geometry', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final p in [0.0, 0.5, 1.0]) {
        final painter = SacredMandalaPainter(progress: p, revealPoint: revealPoint, seed: 0.6);
        painter.paint(canvas, size);
      }
    });
  });

  group('PremiumJapAnimator Widget Tests', () {
    testWidgets('Renders all premium animations cleanly in widget tree', (tester) async {
      for (final type in JapAnimationType.premiumPresets) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 353,
              height: 520,
              child: PremiumJapAnimator(
                animationType: type,
                progress: 0.5,
                isPlaying: true,
                deityName: 'Ram',
                currentMantra: 'राम राम',
                revealPoint: const Offset(150, 220),
                seed: 0.42,
              ),
            ),
          ),
        );

        expect(find.byType(PremiumJapAnimator), findsOneWidget);
      }
    });

    testWidgets('Returns SizedBox.shrink when isPlaying is false', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PremiumJapAnimator(
            animationType: JapAnimationType.ramSpread,
            progress: 0.0,
            isPlaying: false,
            deityName: 'Ram',
            currentMantra: '',
            revealPoint: Offset.zero,
            seed: 0.0,
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(PremiumJapAnimator),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });
}
