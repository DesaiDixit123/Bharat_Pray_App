import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sacred devotional mantras for animations.
class JapMantraHelper {
  static final math.Random _rng = math.Random();

  static TextStyle getMantraTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    List<Shadow>? shadows,
  }) {
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: shadows,
      );
    }
    return GoogleFonts.notoSerifDevanagari(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      shadows: shadows,
    );
  }

  static const List<String> universalMantras = [
    'ॐ नमः शिवाय',
    'जय श्री राम',
    'हरे कृष्ण',
    'राधे राधे',
    'सीता राम',
    'राम राम',
    'ॐ',
    'जय हनुमान',
    'गणपति बाप्पा मोरया',
    'जय माता दी',
    'ॐ नमो नारायणाय',
    'हर हर महादेव',
    'जय श्री कृष्णा',
  ];

  static const Map<String, List<String>> deityMantras = {
    'shiva': [
      'ॐ नमः शिवाय',
      'हर हर महादेव',
      'बम बम भोले',
      'महाकाल',
      'शिव शंभू',
      'ॐ',
    ],
    'ram': [
      'जय श्री राम',
      'राम राम',
      'सियावर रामचंद्र',
      'रघुपति राघव',
      'सीता राम',
      'जय रघुनाथ',
    ],
    'krishna': [
      'हरे कृष्ण',
      'राधे राधे',
      'जय श्री कृष्णा',
      'जय गोविंद',
      'नंदलाला',
      'मुरलीधर',
    ],
    'hanuman': [
      'जय बजरंगबली',
      'जय हनुमान',
      'पवनपुत्र',
      'महावीर',
      'संकट मोचन',
    ],
    'ganesha': [
      'ॐ गं गणपतये नमः',
      'गणपति बाप्पा मोरया',
      'जय गणेश',
      'सिद्धिविनायक',
      'शुभ लाभ',
    ],
    'durga': [
      'जय माता दी',
      'जय माँ दुर्गा',
      'दुर्गे दुर्गे',
      'नवदुर्गे',
      'माँ शेरावाली',
    ],
    'lakshmi': [
      'ॐ श्रीं महालक्ष्म्यै नमः',
      'जय लक्ष्मी माता',
      'धनलक्ष्मी',
      'शुभ समृद्धि',
    ],
  };

  /// Returns a random devotional mantra tailored to the deity
  static String getRandomMantra(String deityName) {
    final lower = deityName.toLowerCase();
    for (final entry in deityMantras.entries) {
      if (lower.contains(entry.key)) {
        final list = entry.value;
        return list[_rng.nextInt(list.length)];
      }
    }
    return universalMantras[_rng.nextInt(universalMantras.length)];
  }

  /// Returns a short mantra for jump animation (1-3 words)
  static String getShortJumpMantra(String deityName) {
    final lower = deityName.toLowerCase();
    if (lower.contains('ram') || lower.contains('sita')) {
      const opts = ['राम राम', 'जय श्री राम', 'सीता राम', 'ॐ'];
      return opts[_rng.nextInt(opts.length)];
    }
    if (lower.contains('shiv') || lower.contains('mahadev')) {
      const opts = ['हर हर महादेव', 'ॐ नमः शिवाय', 'बम भोले', 'ॐ'];
      return opts[_rng.nextInt(opts.length)];
    }
    if (lower.contains('krishna') || lower.contains('radha')) {
      const opts = ['राधे राधे', 'हरे कृष्ण', 'जय श्री कृष्णा', 'ॐ'];
      return opts[_rng.nextInt(opts.length)];
    }
    if (lower.contains('hanuman') || lower.contains('bajrang')) {
      const opts = ['जय श्री राम', 'जय हनुमान', 'बजरंगबली', 'ॐ'];
      return opts[_rng.nextInt(opts.length)];
    }
    const opts = ['राम राम', 'जय श्री राम', 'ॐ नमः शिवाय', 'राधे राधे', 'ॐ'];
    return opts[_rng.nextInt(opts.length)];
  }
}
