import 'package:flutter/material.dart';
import 'language_manager.dart';

class LocalizedApiHelper {
  /// Extract localized string from dynamic API response.
  /// Handles:
  /// 1. Map format: {"en": "...", "hi": "...", "gu": "...", "mr": "..."}
  /// 2. Raw String format: "..."
  /// 3. Fallback priority: current selected language -> English -> first available non-empty -> defaultValue / empty
  static String parse(
    dynamic value, {
    String defaultValue = '',
    BuildContext? context,
  }) {
    if (value == null) return defaultValue;

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty ? trimmed : defaultValue;
    }

    if (value is Map) {
      final currentCode = context != null
          ? Localizations.localeOf(context).languageCode.toLowerCase()
          : LanguageManager.instance.currentLanguageCode.toLowerCase();

      // 1. Direct match with selected language code
      if (value.containsKey(currentCode)) {
        final val = value[currentCode]?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }

      // Also check full locale (e.g., 'en_US', 'hi_IN')
      for (final entry in value.entries) {
        if (entry.key.toString().toLowerCase().startsWith(currentCode)) {
          final val = entry.value?.toString().trim() ?? '';
          if (val.isNotEmpty) return val;
        }
      }

      // 2. Fallback to English
      if (value.containsKey('en')) {
        final val = value['en']?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }

      // 3. Fallback to Hindi
      if (value.containsKey('hi')) {
        final val = value['hi']?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }

      // 4. Fallback to any non-empty string in the map
      for (final val in value.values) {
        if (val != null) {
          final str = val.toString().trim();
          if (str.isNotEmpty) return str;
        }
      }
    }

    // Numbers or other primitive types
    final str = value.toString().trim();
    return str.isNotEmpty ? str : defaultValue;
  }

  /// Helper to convert a plain string into a multilingual Map if required for updates
  static Map<String, String> createMultilingualMap({
    required String text,
    String? currentLangCode,
  }) {
    final code = currentLangCode ?? LanguageManager.instance.currentLanguageCode;
    return {
      'en': text,
      code: text,
    };
  }
}

