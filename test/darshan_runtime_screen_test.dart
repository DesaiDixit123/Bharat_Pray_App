import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/models/darshan_model.dart';
import 'package:bharat_pray/services/jap_session_controller.dart';
import 'package:bharat_pray/screens/details/darshan_runtime_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13: Darshan Runtime Experience Tests', () {
    late JapConfig shivaConfig;
    late DarshanConfig liveDarshan;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      shivaConfig = JapConfig(
        id: 'shiva_darshan_test',
        name: 'Om Namah Shivaya',
        thumbnailUrl: 'https://example.com/shiva.png',
        darshanImageUrl: 'https://example.com/kashi.png',
        shlokText: 'ॐ नमः शिवाय',
        targetCount: 108,
        effectPack: EffectPack.shivaPreset,
      );

      liveDarshan = DarshanConfig(
        id: 'darshan_somnath_live',
        godCategoryId: 'god_shiva',
        name: 'Somnath Live',
        type: DarshanType.live,
        liveStreamUrl: 'https://stream.invalid/nonexistent.m3u8',
        fallbackType: DarshanFallbackType.image,
        fallbackImageUrl: 'https://cdn.example.com/somnath_fallback.jpg',
        imageUrl: 'https://cdn.example.com/somnath_main.jpg',
      );
    });

    testWidgets('1. Security Gate: Locked Screen Shown when Count < 108', (
      WidgetTester tester,
    ) async {
      final controller = JapSessionController(
        config: shivaConfig,
        initialCount: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DarshanRuntimeScreen(
            config: shivaConfig,
            sessionController: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Darshan Is Locked'), findsOneWidget);
      expect(
        find.textContaining('Please complete your sacred 108 Jap Mala'),
        findsOneWidget,
      );
      expect(find.text('Offer Flowers'), findsNothing);

      controller.dispose();
    });

    testWidgets(
      '2. Full Devotional Experience Shown upon Valid 108 Completion',
      (WidgetTester tester) async {
        final controller = JapSessionController(
          config: shivaConfig,
          initialCount: 108,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: DarshanRuntimeScreen(
              config: shivaConfig,
              sessionController: controller,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Darshan Is Locked'), findsNothing);
        expect(find.text('ॐ नमः शिवाय'), findsOneWidget);
        expect(find.text('Offer Flowers'), findsOneWidget);
        expect(find.text('Light Diya'), findsOneWidget);
        expect(find.text('Next Mala'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets(
      '3. Fallback Cascade for LIVE Darshan (Gracefully Falls Back to Image on Stream Offline)',
      (WidgetTester tester) async {
        final controller = JapSessionController(
          config: shivaConfig,
          initialCount: 108,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: DarshanRuntimeScreen(
              config: shivaConfig,
              darshanConfig: liveDarshan,
              sessionController: controller,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verified fallback message rendered instead of blank screen
        expect(
          find.text('Live stream offline. Showing Sacred Deity Photo.'),
          findsOneWidget,
        );
        expect(find.text('ॐ नमः शिवाय'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets('4. Devotional Action: Next Mala Advances Session', (
      WidgetTester tester,
    ) async {
      final controller = JapSessionController(
        config: shivaConfig,
        initialCount: 108,
        initialMalas: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DarshanRuntimeScreen(
            config: shivaConfig,
            sessionController: controller,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Next Mala
      await tester.tap(find.text('Next Mala'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verified session was advanced
      expect(controller.completedMalas, 1);
      expect(controller.currentCount, 0);

      controller.dispose();
    });
  });
}
