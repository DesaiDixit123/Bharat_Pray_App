import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bharat_pray/core/localization/language_manager.dart';
import 'package:bharat_pray/core/localization/language_model.dart';
import 'package:bharat_pray/core/localization/localized_api_helper.dart';
import 'package:bharat_pray/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageManager.instance.initialize();
  });

  group('BharatPray Multilingual Localization System Unit & Widget Tests', () {
    test('1. Verify exactly 4 supported languages: en, hi, gu, mr', () {
      final supported = LanguageManager.instance.getSupportedLanguages();
      expect(supported.length, 4);

      final codes = supported.map((l) => l.code).toList();
      expect(codes, containsAll(['en', 'hi', 'gu', 'mr']));

      final gu = LanguageModel.fromCode('gu');
      expect(gu.nativeName, 'ગુજરાતી');

      final hi = LanguageModel.fromCode('hi');
      expect(hi.nativeName, 'हिन्दी');

      final mr = LanguageModel.fromCode('mr');
      expect(mr.nativeName, 'मराठी');

      final en = LanguageModel.fromCode('en');
      expect(en.nativeName, 'English');
    });

    test('2. Verify persistent language changes in LanguageManager', () async {
      // Default initial state
      expect(LanguageManager.instance.currentLanguageCode, 'en');
      expect(LanguageManager.instance.hasUserSelectedLanguage, isFalse);

      // Change to Gujarati
      await LanguageManager.instance.changeLanguageByCode('gu');
      expect(LanguageManager.instance.currentLanguageCode, 'gu');
      expect(LanguageManager.instance.hasUserSelectedLanguage, isTrue);

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LanguageManager.prefKeyLanguageCode), 'gu');
      expect(prefs.getBool(LanguageManager.prefKeyLanguageSelected), isTrue);

      // Re-initialize manager and verify saved value is retained
      await LanguageManager.instance.initialize();
      expect(LanguageManager.instance.currentLanguageCode, 'gu');
      expect(LanguageManager.instance.hasUserSelectedLanguage, isTrue);
    });

    test('3. Verify LocalizedApiHelper dynamic JSON and fallback logic', () {
      final multilingualData = {
        'en': 'Somnath Temple',
        'hi': 'सोमनाथ मंदिर',
        'gu': 'સોમનાથ મંદિર',
        'mr': 'सोमनाथ मंदिर',
      };

      // Set to Gujarati
      LanguageManager.instance.changeLanguageByCode('gu');
      expect(LocalizedApiHelper.parse(multilingualData), 'સોમનાથ મંદિર');

      // Set to Hindi
      LanguageManager.instance.changeLanguageByCode('hi');
      expect(LocalizedApiHelper.parse(multilingualData), 'सोमनाथ मंदिर');

      // Set to English
      LanguageManager.instance.changeLanguageByCode('en');
      expect(LocalizedApiHelper.parse(multilingualData), 'Somnath Temple');

      // Test fallback to English when requested language is missing
      final missingGu = {
        'en': 'Kedarnath Temple',
        'hi': 'केदारनाथ मंदिर',
      };
      LanguageManager.instance.changeLanguageByCode('gu');
      expect(LocalizedApiHelper.parse(missingGu), 'Kedarnath Temple');

      // Test fallback when input is raw string
      expect(LocalizedApiHelper.parse('Direct Text'), 'Direct Text');

      // Test null safe fallback
      expect(LocalizedApiHelper.parse(null, defaultValue: 'Default'), 'Default');
    });

    testWidgets('4. Verify ARB strings render accurately across all 4 locales', (tester) async {
      for (final code in ['en', 'hi', 'gu', 'mr']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(code),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  body: Column(
                    children: [
                      Text('appName: ${l10n.appName}'),
                      Text('chooseLanguage: ${l10n.chooseLanguage}'),
                      Text('home: ${l10n.home}'),
                      Text('darshan: ${l10n.darshan}'),
                      Text('jap: ${l10n.jap}'),
                      Text('yatra: ${l10n.yatra}'),
                      Text('profile: ${l10n.profile}'),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (code == 'en') {
          expect(find.text('chooseLanguage: Choose Your Preferred Language'), findsOneWidget);
          expect(find.text('home: Home'), findsOneWidget);
        } else if (code == 'hi') {
          expect(find.text('chooseLanguage: अपनी पसंदीदा भाषा चुनें'), findsOneWidget);
          expect(find.text('home: होम'), findsOneWidget);
        } else if (code == 'gu') {
          expect(find.text('chooseLanguage: તમારી મનપસંદ ભાષા પસંદ કરો'), findsOneWidget);
          expect(find.text('home: હોમ'), findsOneWidget);
        } else if (code == 'mr') {
          expect(find.text('chooseLanguage: तुमची पसंतीची भाषा निवडा'), findsOneWidget);
          expect(find.text('home: मुख्यपृष्ठ'), findsOneWidget);
        }
      }
    });
  });
}

