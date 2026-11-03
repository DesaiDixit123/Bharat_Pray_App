import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_model.dart';

class LanguageManager extends ChangeNotifier {
  LanguageManager._internal();
  static final LanguageManager instance = LanguageManager._internal();

  static const String prefKeyLanguageCode = 'user_preferred_language_code';
  static const String prefKeyLanguageSelected = 'user_has_selected_language';

  Locale _currentLocale = const Locale('en');
  bool _hasUserSelectedLanguage = false;
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get hasUserSelectedLanguage => _hasUserSelectedLanguage;
  bool get isInitialized => _isInitialized;

  LanguageModel get currentLanguageModel =>
      LanguageModel.fromLocale(_currentLocale);

  List<LanguageModel> getSupportedLanguages() =>
      LanguageModel.supportedLanguages;

  List<Locale> get supportedLocales =>
      LanguageModel.supportedLanguages.map((l) => l.locale).toList();

  /// Initialize and load saved preference from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasUserSelectedLanguage =
          prefs.getBool(prefKeyLanguageSelected) ?? false;
      final savedCode = prefs.getString(prefKeyLanguageCode);

      if (savedCode != null && savedCode.isNotEmpty) {
        _currentLocale = Locale(savedCode);
      } else {
        // Default to English initially
        _currentLocale = const Locale('en');
      }
    } catch (e) {
      debugPrint('[LanguageManager] Init error: $e');
      _currentLocale = const Locale('en');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change active language and immediately notify UI across whole app
  Future<void> changeLanguage(Locale locale) async {
    final langCode = locale.languageCode.toLowerCase();
    final matched = LanguageModel.fromCode(langCode);
    _currentLocale = matched.locale;
    _hasUserSelectedLanguage = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyLanguageCode, _currentLocale.languageCode);
      await prefs.setBool(prefKeyLanguageSelected, true);
    } catch (e) {
      debugPrint('[LanguageManager] Save error: $e');
    }

    notifyListeners();
  }

  /// Convenience method to change language by string code
  Future<void> changeLanguageByCode(String code) async {
    await changeLanguage(Locale(code));
  }

  /// Check if first-launch or post-login language selection is required
  Future<bool> shouldShowLanguageSelection() async {
    if (!_isInitialized) {
      await initialize();
    }
    return !_hasUserSelectedLanguage;
  }
}

