import 'package:flutter/material.dart';
import 'dynamic_translation_service.dart';
import 'localized_api_helper.dart';

/// A reactive Text widget that automatically translates its content
/// based on the globally selected language in LanguageManager.
class AutoTranslateText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const AutoTranslateText(
    this.text, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DynamicTranslationService.instance,
      builder: (context, _) {
        final translated = LocalizedApiHelper.parse(text, context: context);
        return Text(
          translated,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        );
      },
    );
  }
}

/// Extension on String to easily translate strings in place
extension TranslatableString on String {
  /// Synchronous translation looking into canonical dictionary & dynamic cache
  String tr({BuildContext? context}) {
    return LocalizedApiHelper.parse(this, context: context);
  }

  /// Asynchronous translation with Google Translator engine
  Future<String> trAsync({String? targetLang}) {
    return DynamicTranslationService.instance.translateAsync(this, targetLang: targetLang);
  }
}
