import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/models/tts_voice_model.dart';
import 'package:bharat_pray/services/tts_service.dart';
import 'package:bharat_pray/widgets/granth/granth_voice_selector_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async {
        return 1;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async {
        return 1;
      },
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'tts_voice_gujarati': 'gu-IN-Standard-A',
      'tts_voice_hindi': 'hi-IN-Neural2-B',
      'tts_voice_sanskrit': 'hi-IN-Neural2-B',
      'tts_voice_english': 'en-IN-Neural2-D',
      'tts_speaking_rate': 0.90,
      'tts_pitch': 0.0,
    });
  });

  group('Phase 1: TTS Model & Preferences Unit Tests', () {
    test('1. TtsVoice deserialization from JSON', () {
      final json = {
        'id': 'gu-IN-Standard-A',
        'name': 'Dhwani (ધ્વનિ)',
        'gender': 'Female',
        'locale': 'gu-IN',
        'tier': 'Standard',
        'languages': ['Gujarati'],
        'title': 'Devotional Gujarati Female Voice',
        'description': 'Clear, gentle, and sacred Gujarati female voice.',
        'previewUrl': 'uploads/granth_audio/previews/preview_gu-IN-DhwaniNeural.mp3',
        'defaultRate': 0.92,
        'isDefault': true,
        'languageCategory': 'Gujarati',
      };

      final voice = TtsVoice.fromJson(json);
      expect(voice.id, 'gu-IN-Standard-A');
      expect(voice.name, 'Dhwani (ધ્વનિ)');
      expect(voice.gender, 'Female');
      expect(voice.locale, 'gu-IN');
      expect(voice.tier, 'Standard');
      expect(voice.languageCategory, 'Gujarati');
      expect(voice.isDefault, true);

      final outJson = voice.toJson();
      expect(outJson['id'], 'gu-IN-Standard-A');
      expect(outJson['gender'], 'Female');
    });

    test('2. TtsPreferences defaults and copyWith', () {
      final prefs = TtsPreferences();
      expect(prefs.gujaratiVoiceId, 'gu-IN-Chirp3-HD-Kore');
      expect(prefs.hindiVoiceId, 'hi-IN-Chirp3-HD-Kore');
      expect(prefs.sanskritVoiceId, 'hi-IN-Chirp3-HD-Charon');
      expect(prefs.englishVoiceId, 'en-IN-Neural2-D');
      expect(prefs.speakingRate, 0.92);

      final updated = prefs.copyWith(
        gujaratiVoiceId: 'gu-IN-Chirp3-HD-Puck',
        speakingRate: 1.0,
      );
      expect(updated.gujaratiVoiceId, 'gu-IN-Chirp3-HD-Puck');
      expect(updated.hindiVoiceId, 'hi-IN-Chirp3-HD-Kore');
      expect(updated.speakingRate, 1.0);
    });

    test('3. TtsService voice resolution by language', () {
      final ttsService = TtsService();
      final prefs = TtsPreferences(
        gujaratiVoiceId: 'gu-IN-Standard-B',
        hindiVoiceId: 'hi-IN-Neural2-B',
        sanskritVoiceId: 'hi-IN-Neural2-B',
        englishVoiceId: 'en-IN-Neural2-D',
      );

      expect(ttsService.getVoiceForLanguage('Gujarati', prefs: prefs), 'gu-IN-Standard-B');
      expect(ttsService.getVoiceForLanguage('ગુજરાતી', prefs: prefs), 'hi-IN-Neural2-B');
      expect(ttsService.getVoiceForLanguage('Sanskrit', prefs: prefs), 'hi-IN-Neural2-B');
      expect(ttsService.getVoiceForLanguage('Hindi', prefs: prefs), 'hi-IN-Neural2-B');
      expect(ttsService.getVoiceForLanguage('English', prefs: prefs), 'en-IN-Neural2-D');
    });
  });

  group('Phase 2: Granth Voice Selector Widget Tests', () {
    testWidgets('4. GranthVoiceSelectorSheet renders header, tabs, and action button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GranthVoiceSelectorSheet(
              initialLanguage: 'Gujarati',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check header title
      expect(find.text('Scripture Narration Voice'), findsOneWidget);
      expect(find.text('Natural Google Cloud AI devotional recitation'), findsOneWidget);

      // Check language tabs
      expect(find.text('ગુજરાતી'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('संस्कृत'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Check Apply button
      expect(find.text('Apply Voice Preference'), findsOneWidget);
    });

    testWidgets('5. Tab switching displays corresponding language voices',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GranthVoiceSelectorSheet(
              initialLanguage: 'Gujarati',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Hindi tab
      await tester.tap(find.text('हिन्दी'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Sanskrit tab
      await tester.tap(find.text('संस्कृत'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Apply Voice Preference'), findsOneWidget);
    });
  });
}
