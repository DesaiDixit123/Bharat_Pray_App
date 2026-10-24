import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bharat_pray/widgets/cinematic_jap/ram_path_calculator.dart';
import 'package:bharat_pray/widgets/cinematic_jap/cinematic_rudraksha_mala.dart';
import 'package:bharat_pray/widgets/cinematic_jap/cinematic_chanting_controls.dart';
import 'package:bharat_pray/models/jap_theme_config.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/models/jap_customization_models.dart';

void main() {
  group('Cinematic 108 Jap - RamPathCalculator & Face Protection Tests', () {
    test('Verify 108 reveal nodes integrity and coordinate boundaries', () {
      expect(RamPathCalculator.targetJapCount, 108);

      final nodes = RamPathCalculator.revealNodes;
      expect(nodes.length, 108);

      for (int i = 0; i < 108; i++) {
        final node = nodes[i];
        expect(node.step, i);
        expect(node.u >= 0.0 && node.u <= 1.0, isTrue);
        expect(node.v >= 0.0 && node.v <= 1.0, isTrue);
        expect(node.radiusNorm > 0.05, isTrue);
      }
    });

    test('CRITICAL: Verify face protection mask — NO early nodes touch Lord Ram face', () {
      const faceBox = RamPathCalculator.faceBox; // Rect.fromLTRB(0.36, 0.32, 0.64, 0.54)
      final nodes = RamPathCalculator.revealNodes;

      // Japs 1..102 (indices 0..101) must NEVER touch the central face box
      for (int i = 0; i < 102; i++) {
        final node = nodes[i];
        final bool insideFace = (node.u >= faceBox.left &&
            node.u <= faceBox.right &&
            node.v >= faceBox.top &&
            node.v <= faceBox.bottom);

        expect(insideFace, isFalse,
            reason: 'Node $i (${node.label}) at (${node.u}, ${node.v}) violates face protection mask!');
      }
    });

    test('CRITICAL: Verify face reveals LAST in exact devotional order (Japs 103..108)', () {
      final nodes = RamPathCalculator.revealNodes;

      // 102 (Jap 103): Forehead & Tilak
      expect(nodes[102].label, contains('Tilak'));
      expect(nodes[102].v < 0.38, isTrue);

      // 103 (Jap 104): Left Eye
      expect(nodes[103].label, contains('Left Divine Eye'));

      // 104 (Jap 105): Right Eye
      expect(nodes[104].label, contains('Right Divine Eye'));

      // 105 (Jap 106): Nose & Cheeks
      expect(nodes[105].label, contains('Nose'));

      // 106 (Jap 107): Smiling Lips
      expect(nodes[106].label, contains('Lips'));

      // 107 (Jap 108): Full Divine Darshan Climax
      expect(nodes[107].label, contains('Full Divine Darshan Climax'));
    });

    test('Verify progressive reveal mapping across all 108 steps', () {
      expect(RamPathCalculator.getRevealedNodesForCount(0).length, 0);

      // Monotonic growth
      for (int count = 1; count <= 108; count++) {
        final revealed = RamPathCalculator.getRevealedNodesForCount(count);
        expect(revealed.length, count);
      }

      // Exactly at Jap 108, all 108 nodes are active
      expect(RamPathCalculator.getRevealedNodesForCount(108).length, 108);
    });

    test('Verify distributed reveal across different regions and strict face protection', () {
      final nodesAt50 = RamPathCalculator.getRevealedNodesForCount(50);
      expect(nodesAt50.length, 50);

      // Verify that the first 50 nodes are not clustered in one spot, but widely dispersed
      double totalDist = 0;
      for (int i = 0; i < 49; i++) {
        final n1 = nodesAt50[i];
        final n2 = nodesAt50[i + 1];
        final d = (Offset(n1.u, n1.v) - Offset(n2.u, n2.v)).distance;
        totalDist += d;
      }
      final double avgConsecutiveDist = totalDist / 49;
      expect(avgConsecutiveDist > 0.35, isTrue,
          reason: 'Consecutive nodes must jump to different regions across the screen!');

      // Face is strictly untouched in all first 102 nodes
      for (final node in nodesAt50) {
        expect(RamPathCalculator.faceBox.contains(Offset(node.u, node.v)), isFalse);
      }
    });

    test('Verify curved trajectory path emerging from mala center', () {
      const screenSize = Size(390, 844);
      const malaCenter = Offset(195, 390);
      final target = Offset(screenSize.width * 0.75, screenSize.height * 0.22);

      final path = RamPathCalculator.computeTrajectoryPath(
        screenSize: screenSize,
        malaCenter: malaCenter,
        targetPoint: target,
      );

      final metrics = path.computeMetrics().toList();
      expect(metrics.isNotEmpty, isTrue);
      // Path starts at malaCenter
      final startPos = metrics.first.getTangentForOffset(0.0)?.position;
      expect(startPos?.dx, closeTo(malaCenter.dx, 1.0));
      expect(startPos?.dy, closeTo(malaCenter.dy, 1.0));
    });
  });

  group('Cinematic 108 Jap - Theme & Deity Config Tests', () {
    test('Lord Ram theme resolution uses high-res portrait and Rudraksha mala', () {
      final ramTheme = JapThemeConfig.ram;
      expect(ramTheme.imageAsset, 'assets/images/lord_shri_ram_darshan.png');
      expect(ramTheme.defaultBeadStyle, MalaBeadStyle.rudraksha);
      expect(ramTheme.mantraText, contains('राम'));

      final resolvedImage = JapConfig.defaultDeityImage('Lord Ram');
      expect(resolvedImage, 'assets/images/lord_shri_ram_darshan.png');
    });
  });

  group('Cinematic 108 Jap - Widget Component Tests', () {
    testWidgets('Rudraksha Mala renders with 108 beads, center counter, and reports center', (tester) async {
      Offset? reportedCenter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CinematicRudrakshaMala(
                count: 18,
                target: 108,
                pulseValue: 0.5,
                isCompleted: false,
                subtitle: 'Shri Ram Jai Ram Jai Jai Ram',
                onCenterCalculated: (c) => reportedCenter = c,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ॐ'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('/ 108'), findsOneWidget);
      expect(find.text('Shri Ram Jai Ram Jai Jai Ram'), findsOneWidget);
      expect(reportedCenter, isNotNull);
    });

    testWidgets('Rudraksha Mala upward rotation triggers when count increments', (tester) async {
      int count = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: CinematicRudrakshaMala(
                    count: count,
                    target: 108,
                    pulseValue: 0.5,
                    isCompleted: false,
                    subtitle: 'Shri Ram Jai Ram Jai Jai Ram',
                    onTap: () {
                      setState(() {
                        count++;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      // Tap to increment count
      await tester.tap(find.byType(CinematicRudrakshaMala));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Verify animation frames smoothly progress
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Chanting controls render Reset, Action, and Sound buttons', (tester) async {
      bool chantTapped = false;
      bool resetTapped = false;
      bool soundToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicChantingControls(
              onChantTap: () => chantTapped = true,
              onResetTap: () => resetTapped = true,
              onSoundToggle: () => soundToggled = true,
              onPauseToggle: () {},
              isSoundEnabled: true,
            ),
          ),
        ),
      );

      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      await tester.tap(find.text('Reset'));
      expect(resetTapped, isTrue);

      await tester.tap(find.text('Sound'));
      expect(soundToggled, isTrue);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(chantTapped, isTrue);
    });
  });
}
