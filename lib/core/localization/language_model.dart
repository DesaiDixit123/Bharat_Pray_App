import 'package:flutter/material.dart';

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String scriptHint;
  final String flagAsset;
  final Locale locale;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.scriptHint,
    this.flagAsset = '',
    required this.locale,
  });

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      scriptHint: 'English',
      locale: Locale('en'),
    ),
    LanguageModel(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      scriptHint: 'देवनागरी',
      locale: Locale('hi'),
    ),
    LanguageModel(
      code: 'gu',
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      scriptHint: 'ગુજરાતી',
      locale: Locale('gu'),
    ),
    LanguageModel(
      code: 'mr',
      name: 'Marathi',
      nativeName: 'मराठी',
      scriptHint: 'देवनागरी',
      locale: Locale('mr'),
    ),
  ];

  static LanguageModel fromCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
  }

  static LanguageModel fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}

