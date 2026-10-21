import 'package:flutter/material.dart';
import 'jap_customization_models.dart';

/// Predefined Deity & Mantra Theme configurations (Section 6 of Master Prompt).
class JapThemeConfig {
  final String id;
  final String name;
  final String deityName;
  final String mantraText;
  final String mantraScript;
  final String audioAsset;
  final String imageAsset;
  final MalaBeadStyle defaultBeadStyle;
  final Color activeColor;
  final Color glowColor;
  final String blessingTitle;
  final String blessingSubtitle;

  const JapThemeConfig({
    required this.id,
    required this.name,
    required this.deityName,
    required this.mantraText,
    this.mantraScript = 'Devanagari',
    required this.audioAsset,
    required this.imageAsset,
    required this.defaultBeadStyle,
    required this.activeColor,
    required this.glowColor,
    required this.blessingTitle,
    required this.blessingSubtitle,
  });

  /// 1. Shri Radha — “श्री राधा” (Primary/Critical Theme)
  static const JapThemeConfig radha = JapThemeConfig(
    id: 'shri_radha',
    name: 'Shri Radha',
    deityName: 'Radha',
    mantraText: 'श्री राधा',
    audioAsset: 'assets/audio/radha_chant.mp3',
    imageAsset: 'assets/images/deity_krishna.png',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFF80AB),
    glowColor: Color(0xFFFF4081),
    blessingTitle: '🙏 श्री राधे राधे 🙏',
    blessingSubtitle: 'May Shri Radha Rani shower your soul with eternal devotion, unconditional love, and supreme divine grace.',
  );

  /// 2. Radha Krishna — “राधे कृष्ण”
  static const JapThemeConfig radhaKrishna = JapThemeConfig(
    id: 'radha_krishna',
    name: 'Radha Krishna',
    deityName: 'Krishna',
    mantraText: 'राधे कृष्ण',
    audioAsset: 'assets/audio/radhe_krishna_chant.mp3',
    imageAsset: 'assets/images/deity_krishna.png',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFF00E5FF),
    glowColor: Color(0xFF00B0FF),
    blessingTitle: '🙏 जय श्री राधे कृष्ण 🙏',
    blessingSubtitle: 'May the divine couple Radha and Krishna fill your home with infinite joy, melody, and harmony.',
  );

  /// 3. Lord Shiva — “ॐ नमः शिवाय”
  static const JapThemeConfig shiva = JapThemeConfig(
    id: 'shiva',
    name: 'Lord Shiva',
    deityName: 'Shiva',
    mantraText: 'ॐ नमः शिवाय',
    audioAsset: 'assets/audio/shiva_chant.mp3',
    imageAsset: 'assets/images/deity_shiva.png',
    defaultBeadStyle: MalaBeadStyle.rudraksha,
    activeColor: Color(0xFF81C784),
    glowColor: Color(0xFF64B5F6),
    blessingTitle: '🙏 हर हर महादेव 🙏',
    blessingSubtitle: 'May Mahadev grant you stillness of mind, detachment, deep peace, and divine liberation.',
  );

  /// 4. Lord Ram — “श्री राम जय राम”
  static const JapThemeConfig ram = JapThemeConfig(
    id: 'ram',
    name: 'Lord Ram',
    deityName: 'Ram',
    mantraText: 'श्री राम जय राम जय जय राम',
    audioAsset: 'assets/audio/ram_chant.mp3',
    imageAsset: 'assets/images/deity_ram.png',
    defaultBeadStyle: MalaBeadStyle.sandalwood,
    activeColor: Color(0xFFFF9900),
    glowColor: Color(0xFFFFD54F),
    blessingTitle: '🙏 जय श्री राम 🙏',
    blessingSubtitle: 'May Lord Ram bless your life with maryada, righteous action, courage, and unconditional devotion.',
  );

  /// 5. Lord Hanuman — “ॐ हनुमते नमः”
  static const JapThemeConfig hanuman = JapThemeConfig(
    id: 'hanuman',
    name: 'Lord Hanuman',
    deityName: 'Hanuman',
    mantraText: 'ॐ हनुमते नमः',
    audioAsset: 'assets/audio/hanuman_chant.mp3',
    imageAsset: 'assets/images/deity_hanuman.png',
    defaultBeadStyle: MalaBeadStyle.rudraksha,
    activeColor: Color(0xFFFF3D00),
    glowColor: Color(0xFFFF6E40),
    blessingTitle: '🙏 जय बजरंगबली 🙏',
    blessingSubtitle: 'May Sankat Mochan Hanuman grant you boundless spiritual strength, protection, and humility.',
  );

  /// 6. Ambe Maa — “जय अम्बे गौरी”
  static const JapThemeConfig ambe = JapThemeConfig(
    id: 'ambe_maa',
    name: 'Ambe Maa',
    deityName: 'Amba',
    mantraText: 'जय अम्बे गौरी',
    audioAsset: 'assets/audio/ambe_chant.mp3',
    imageAsset: 'assets/images/deity_amba.png',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFF1744),
    glowColor: Color(0xFFFF5252),
    blessingTitle: '🙏 जय माता दी 🙏',
    blessingSubtitle: 'May Jagadamba shower fearless strength, protection, victory, and auspicious prosperity upon you.',
  );

  /// 7. Lord Ganesha — “ॐ गं गणपतये नमः”
  static const JapThemeConfig ganesha = JapThemeConfig(
    id: 'ganesha',
    name: 'Lord Ganesha',
    deityName: 'Ganesh',
    mantraText: 'ॐ गं गणपतये नमः',
    audioAsset: 'assets/audio/ganesh_chant.mp3',
    imageAsset: 'assets/images/deity_ganesha.png',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFFAB00),
    glowColor: Color(0xFFFFD740),
    blessingTitle: '🙏 गणपति बाप्पा मोरया 🙏',
    blessingSubtitle: 'May Vighnaharta Ganesha remove all impediments and bless your endeavors with auspicious success.',
  );

  static const List<JapThemeConfig> allThemes = [
    radha,
    radhaKrishna,
    shiva,
    ram,
    hanuman,
    ambe,
    ganesha,
  ];

  static JapThemeConfig resolveFromEntry({
    required String name,
    required String shlokText,
    String? audioUrl,
  }) {
    final lowerName = name.toLowerCase();
    final lowerShlok = shlokText.toLowerCase();

    if (lowerName.contains('radha') && !lowerName.contains('krishna')) {
      return radha;
    } else if (lowerName.contains('krishna') || lowerName.contains('radha') || lowerShlok.contains('कृष्ण')) {
      return radhaKrishna;
    } else if (lowerName.contains('shiv') || lowerName.contains('mahadev') || lowerName.contains('bhole') || lowerShlok.contains('शिवाय')) {
      return shiva;
    } else if (lowerName.contains('ram') || lowerName.contains('raghav') || lowerShlok.contains('राम')) {
      return ram;
    } else if (lowerName.contains('hanuman') || lowerName.contains('bajrang') || lowerShlok.contains('हनुमत')) {
      return hanuman;
    } else if (lowerName.contains('amba') || lowerName.contains('durga') || lowerName.contains('mata') || lowerShlok.contains('दुर्गा') || lowerShlok.contains('अम्बे')) {
      return ambe;
    } else if (lowerName.contains('ganesh') || lowerName.contains('ganpati') || lowerShlok.contains('गणपतये')) {
      return ganesha;
    }
    // Default to Shri Radha if not matching any
    return radha;
  }
}
