import 'package:flutter/material.dart';

/// Available Jap animation types:
/// - 5 Classic Video Animations (preserved 100%)
/// - 6 Premium Devotional Animations (customized & localized)
enum JapAnimationType {
  // Classic video animations (existing - untouched)
  dhupVideo('dhup', 'Dhoop Smoke Video', 'Classic video overlay with sacred incense', Icons.videocam_rounded, true),
  ramVideo('ram', 'Ram Ram Video', 'Classic video chanting Ram Ram', Icons.videocam_rounded, true),
  lotusVideo('lotus', 'Lotus Video', 'Classic sacred lotus opening video', Icons.videocam_rounded, true),
  peacockVideo('peakok', 'Peacock Feather Video', 'Classic feather flutter video', Icons.videocam_rounded, true),
  aartiVideo('arati', 'Temple Aarti Video', 'Classic brass Aarti lamp video', Icons.videocam_rounded, true),

  // Premium Devotional Animations
  radhaName('radha_name', 'Radha Name Reveal', 'Sacred "राधा" lotus mandala unfolds and glows directly at the revealed spot', Icons.favorite_rounded, false),
  ramSpread('ram_spread', 'Ram Ram Divine Spread', 'Sacred "राम राम" spreads across the screen with a prominent center and dissolves into divine golden light', Icons.auto_awesome, false),
  incenseSmoke('incense_smoke', 'Incense Smoke Reveal', 'Natural dense fragrant dhoop smoke curls and rises directly from the revealed spot', Icons.cloud_rounded, false),
  mantraLight('mantra_light', 'Mantra-to-Light', 'Celestial beam of divine light descends with streaming Sanskrit light runes into the revealed spot', Icons.text_fields_rounded, false),
  divineEnergy('divine_energy', 'Divine Energy Formation', 'Cosmic sparks converge into the revealed spot and burst with golden light', Icons.flare_rounded, false),
  sacredMandala('sacred_mandala', 'Sacred Mandala Formation', 'Radiant sacred geometric yantra mandala unfolds with divine sunbeams and rotating chakra', Icons.brightness_7_rounded, false);

  final String key;
  final String label;
  final String description;
  final IconData icon;
  final bool isVideo;

  const JapAnimationType(this.key, this.label, this.description, this.icon, this.isVideo);

  static JapAnimationType fromKey(String? key, {String? deityName}) {
    if (key == null || key.isEmpty || key == 'auto') {
      return resolveDefault(deityName ?? '');
    }
    final lower = key.toLowerCase().trim();
    for (final type in JapAnimationType.values) {
      if (type.key == lower) return type;
    }
    // Match aliases
    if (lower.contains('spread') || lower == 'ram_spread') return JapAnimationType.ramSpread;
    if (lower.contains('radha') || lower.contains('radhe')) return JapAnimationType.radhaName;
    if (lower.contains('smoke') || lower.contains('incense') || lower.contains('dhup_reveal')) return JapAnimationType.incenseSmoke;
    if (lower.contains('light') || lower.contains('mantra_light')) return JapAnimationType.mantraLight;
    if (lower.contains('energy') || lower.contains('formation')) return JapAnimationType.divineEnergy;
    if (lower.contains('mandala') || lower.contains('yantra')) return JapAnimationType.sacredMandala;
    if (lower.contains('dhoop') || lower.contains('dhup')) return JapAnimationType.dhupVideo;
    if (lower.contains('peacock') || lower.contains('peakok')) return JapAnimationType.peacockVideo;
    if (lower.contains('arati') || lower.contains('aarti')) return JapAnimationType.aartiVideo;
    if (lower.contains('lotus')) return JapAnimationType.lotusVideo;
    if (lower.contains('ram')) return JapAnimationType.ramVideo;

    return resolveDefault(deityName ?? '');
  }

  static JapAnimationType resolveDefault(String deityName) {
    final n = deityName.toLowerCase();
    if (n.contains('radha') || n.contains('radhe')) return JapAnimationType.radhaName;
    if (n.contains('ram') || n.contains('raghav') || n.contains('sita')) return JapAnimationType.ramSpread;
    if (n.contains('krishna') || n.contains('kanha')) return JapAnimationType.peacockVideo;
    if (n.contains('shiva') || n.contains('mahadev') || n.contains('bhole')) return JapAnimationType.dhupVideo;
    if (n.contains('durga') || n.contains('hanuman') || n.contains('aarti')) return JapAnimationType.aartiVideo;
    if (n.contains('ganesh') || n.contains('lakshmi') || n.contains('lotus')) return JapAnimationType.lotusVideo;
    return JapAnimationType.dhupVideo;
  }

  /// List of only the active premium animation presets
  static const List<JapAnimationType> premiumPresets = [
    JapAnimationType.radhaName,
    JapAnimationType.ramSpread,
    JapAnimationType.incenseSmoke,
    JapAnimationType.mantraLight,
    JapAnimationType.divineEnergy,
    JapAnimationType.sacredMandala,
  ];
}
