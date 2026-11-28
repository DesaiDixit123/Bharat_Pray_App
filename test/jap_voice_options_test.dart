import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/jap_models.dart';
import 'package:bharat_pray/services/jap_voice_service.dart';
import 'package:bharat_pray/widgets/jap/jap_custom_voice_selector_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Temporary Ram Voice Jap configuration', () {
    test('JapConfig.fromJson parses voiceOptions, targetCount 108, and ram_special image fallback', () {
      final json = {
        '_id': '6b0000000000000000000108',
        'name': 'Shri Ram (Voice Edition)',
        'displayName': 'RAM VOICE',
        'fullName': 'Shri Ram (Voice Edition)',
        'shlokText': 'રામ',
        'voiceText': 'રામ',
        'thumbnail': 'https://api.bharatpray.com/uploads/jap/ram_special_thumbnail.webp',
        'darshanImage': 'https://api.bharatpray.com/uploads/jap/ram_special_cover.webp',
        'targetCount': 108,
        'isTemporary': true,
        'voiceOptions': [
          {
            'id': 'ram_voice_1',
            'name': 'Voice 1 · Temple Echo',
            'title': 'Echoing Ram Ram Chant',
            'description': 'Sacred echoing chant.',
            'gender': 'Male',
            'audioUrl': 'jap/audio/ram_special_voice_1.mp3',
            'assetPath': 'assets/audio/ram_special_voice_1.mp3',
          },
          {
            'id': 'ram_voice_2',
            'name': 'Voice 2 · Deep Resonance',
            'title': 'Deep Meditative Ram Chant',
            'description': 'Deep chant.',
            'gender': 'Male',
            'audioUrl': 'jap/audio/ram_special_voice_2.mp3',
            'assetPath': 'assets/audio/ram_special_voice_2.mp3',
          },
          {
            'id': 'ram_voice_3',
            'name': 'Voice 3 · Calm Serenity',
            'title': 'Soft Peaceful Ram Chant',
            'description': 'Soft chant.',
            'gender': 'Male',
            'audioUrl': 'jap/audio/ram_special_voice_3.mp3',
            'assetPath': 'assets/audio/ram_special_voice_3.mp3',
          },
        ],
      };

      final config = JapConfig.fromJson(json);

      expect(config.id, '6b0000000000000000000108');
      expect(config.displayName, 'RAM VOICE');
      expect(config.fullName, 'Shri Ram (Voice Edition)');
      expect(config.targetCount, 108);
      expect(config.isTemporary, isTrue);
      expect(config.localDarshanAsset, 'assets/images/jap/ram_special_cover.webp');
      expect(config.voiceOptions.length, 3);
      expect(config.voiceOptions[0].id, 'ram_voice_1');
      expect(config.voiceOptions[1].id, 'ram_voice_2');
      expect(config.voiceOptions[2].id, 'ram_voice_3');
      expect(config.voiceOptions[0].assetPath, 'assets/audio/ram_special_voice_1.mp3');
    });

    test('JapVoiceService persists per-Jap selected voice independently', () async {
      SharedPreferences.setMockInitialValues({});
      final service = JapVoiceService();
      const options = [
        JapVoiceOption(id: 'ram_voice_1', name: 'Voice 1', assetPath: 'assets/audio/ram_special_voice_1.mp3'),
        JapVoiceOption(id: 'ram_voice_2', name: 'Voice 2', assetPath: 'assets/audio/ram_special_voice_2.mp3'),
        JapVoiceOption(id: 'ram_voice_3', name: 'Voice 3', assetPath: 'assets/audio/ram_special_voice_3.mp3'),
      ];

      // Defaults to first option
      expect(await service.loadSelectedVoiceForJap('6b0000000000000000000108', options), 'ram_voice_1');

      // Saving per-Jap voice does not change global voice
      await service.saveSelectedVoiceForJap('6b0000000000000000000108', 'ram_voice_3');
      expect(await service.loadSelectedVoiceForJap('6b0000000000000000000108', options), 'ram_voice_3');
      expect(await service.loadSelectedVoiceId(), JapVoiceService.defaultVoiceId);
    });

    testWidgets('JapCustomVoiceSelectorSheet displays all 3 voices and saves selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      const options = [
        JapVoiceOption(
          id: 'ram_voice_1',
          name: 'Voice 1 · Temple Echo',
          title: 'Echoing Ram Ram Chant',
          assetPath: 'assets/audio/ram_special_voice_1.mp3',
        ),
        JapVoiceOption(
          id: 'ram_voice_2',
          name: 'Voice 2 · Deep Resonance',
          title: 'Deep Meditative Ram Chant',
          assetPath: 'assets/audio/ram_special_voice_2.mp3',
        ),
        JapVoiceOption(
          id: 'ram_voice_3',
          name: 'Voice 3 · Calm Serenity',
          title: 'Soft Peaceful Ram Chant',
          assetPath: 'assets/audio/ram_special_voice_3.mp3',
        ),
      ];

      var changedCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    JapCustomVoiceSelectorSheet.show(
                      ctx,
                      japId: '6b0000000000000000000108',
                      voiceOptions: options,
                      onVoiceChanged: () => changedCalled = true,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Voice 1 · Temple Echo'), findsOneWidget);
      expect(find.text('Voice 2 · Deep Resonance'), findsOneWidget);
      expect(find.text('Voice 3 · Calm Serenity'), findsOneWidget);

      await tester.tap(find.text('Voice 2 · Deep Resonance'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply Voice Preference'));
      await tester.pumpAndSettle();

      expect(changedCalled, isTrue);
      final saved = await JapVoiceService().loadSelectedVoiceForJap(
        '6b0000000000000000000108',
        options,
      );
      expect(saved, 'ram_voice_2');
    });
  });
}
