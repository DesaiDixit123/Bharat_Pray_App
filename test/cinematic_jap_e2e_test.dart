import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/screens/details/cinematic_jap_screen.dart';
import 'package:bharat_pray/widgets/cinematic_jap/cinematic_rudraksha_mala.dart';
import 'package:bharat_pray/widgets/cinematic_jap/cinematic_chanting_controls.dart';
import 'package:bharat_pray/widgets/cinematic_jap/cinematic_darshan_view.dart';
import 'package:bharat_pray/models/jap_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jap_sound_enabled': false,
    });
  });

  testWidgets('E2E: CinematicJapScreen full lifecycle from 0 to 108 completion', (tester) async {
    final entry = JapConfig(
      id: 'ram_test',
      name: 'Lord Ram',
      thumbnailUrl: 'assets/images/lord_shri_ram_darshan.png',
      darshanImageUrl: 'assets/images/lord_shri_ram_darshan.png',
      shlokText: 'श्री राम जय राम जय जय राम',
      targetCount: 108,
      progress: 0,
      effectPack: EffectPack.resolve(name: 'Lord Ram'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CinematicJapScreen(entry: entry),
      ),
    );
    await tester.pump();

    // 1. Initial State Check
    expect(find.byType(CinematicRudrakshaMala), findsOneWidget);
    expect(find.byType(CinematicChantingControls), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('/ 108'), findsOneWidget);
    expect(find.text('श्री राम जय राम जय जय राम'), findsOneWidget);
    expect(find.byType(CinematicDarshanView), findsNothing);

    // 2. Tap Chant Action (Single "राम" emerges from mala center)
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(); // Start flight

    // Play button stays active (showing Pause icon) while voice is playing!
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Advance flight past arrival threshold (0.72 of 5280ms = 3801ms)
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.text('1'), findsOneWidget);

    // Complete flight animation (voice duration ends: play button turns OFF and waits for next manual tap)
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);

    // 3. Test Reset
    await tester.tap(find.text('Reset'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reset Jap Session?'), findsOneWidget);
    await tester.tap(find.text('Reset').last);
    await tester.pump(const Duration(milliseconds: 300));

    // Count is back to 0
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('E2E: 108 Jap Completion transitions to pure darshan without controls', (tester) async {
    final entry = JapConfig(
      id: 'ram_test_108',
      name: 'Lord Ram',
      thumbnailUrl: 'assets/images/lord_shri_ram_darshan.png',
      darshanImageUrl: 'assets/images/lord_shri_ram_darshan.png',
      shlokText: 'श्री राम जय राम जय जय राम',
      targetCount: 108,
      progress: 107, // 1 Jap away from 108
      effectPack: EffectPack.resolve(name: 'Lord Ram'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CinematicJapScreen(entry: entry),
      ),
    );
    await tester.pump();

    expect(find.text('107'), findsOneWidget);

    // Tap the final 108th Jap
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Advance flight past arrival threshold (3900ms) -> count becomes 108
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.text('108'), findsOneWidget);

    // Complete flight animation (1400ms) -> triggers completion sequence
    await tester.pump(const Duration(milliseconds: 1400));

    // Advance UI fade animation (1000ms) -> Mala, counter, controls completely removed!
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 300));

    // FINAL SCREEN RULE VERIFICATION:
    // Only CinematicDarshanView is active!
    expect(find.byType(CinematicDarshanView), findsOneWidget);
    // Mala is completely removed
    expect(find.text('/ 108'), findsNothing);
    // Controls are completely removed
    expect(find.text('Reset'), findsNothing);
    expect(find.text('Sound'), findsNothing);
  });
}
