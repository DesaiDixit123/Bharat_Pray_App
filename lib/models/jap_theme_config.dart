import 'package:flutter/material.dart';
import 'jap_customization_models.dart';

/// Predefined Deity & Mantra Theme configurations for all 12 Default Jap Items.
class JapThemeConfig {
  final String id;
  final String name;
  final String displayName;
  final String fullName;
  final String deityName;
  final String mantraText;
  final String voiceText;
  final String mantraScript;
  final String audioAsset;
  final String backgroundMusicAsset;
  final String thumbnailAsset;
  final String coverAsset;
  final String imageAsset;
  final MalaBeadStyle defaultBeadStyle;
  final Color activeColor;
  final Color glowColor;
  final String blessingTitle;
  final String blessingSubtitle;
  final int displayOrder;

  const JapThemeConfig({
    required this.id,
    required this.name,
    String? displayName,
    String? fullName,
    required this.deityName,
    required this.mantraText,
    String? voiceText,
    this.mantraScript = 'Gujarati',
    required this.audioAsset,
    required this.backgroundMusicAsset,
    required this.thumbnailAsset,
    required this.coverAsset,
    required this.defaultBeadStyle,
    required this.activeColor,
    required this.glowColor,
    required this.blessingTitle,
    required this.blessingSubtitle,
    this.displayOrder = 0,
  })  : displayName = displayName ?? name,
        fullName = fullName ?? name,
        voiceText = voiceText ?? mantraText,
        imageAsset = coverAsset;

  /// 1. RAM
  static const JapThemeConfig ram = JapThemeConfig(
    id: 'ram',
    name: 'RAM',
    displayName: 'RAM',
    fullName: 'Shri Ram',
    deityName: 'Ram',
    mantraText: 'રામ',
    voiceText: 'રામ',
    audioAsset: 'assets/audio/voice_ram_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_ram_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/ram_thumbnail.webp',
    coverAsset: 'assets/images/jap/ram_cover.webp',
    defaultBeadStyle: MalaBeadStyle.rudraksha,
    activeColor: Color(0xFFFF9900),
    glowColor: Color(0xFFFFD54F),
    blessingTitle: '🙏 જય શ્રી રામ 🙏',
    blessingSubtitle: 'May Lord Ram bless your life with maryada, righteous action, courage, and supreme peace.',
    displayOrder: 1,
  );

  /// 2. RADHA
  static const JapThemeConfig radha = JapThemeConfig(
    id: 'radha',
    name: 'RADHA',
    displayName: 'RADHA',
    fullName: 'Shri Radha',
    deityName: 'Radha',
    mantraText: 'રાધે',
    voiceText: 'રાધે',
    audioAsset: 'assets/audio/voice_radha_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_radha_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/radha_thumbnail.webp',
    coverAsset: 'assets/images/jap/radha_cover.webp',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFF80AB),
    glowColor: Color(0xFFFF4081),
    blessingTitle: '🙏 શ્રી રાધે રાધે 🙏',
    blessingSubtitle: 'May Shri Radha Rani shower your soul with eternal devotion, unconditional love, and supreme divine grace.',
    displayOrder: 2,
  );

  /// 3. KRISHNA
  static const JapThemeConfig krishna = JapThemeConfig(
    id: 'krishna',
    name: 'KRISHNA',
    displayName: 'KRISHNA',
    fullName: 'Shri Krishna',
    deityName: 'Krishna',
    mantraText: 'કૃષ્ણ',
    voiceText: 'કૃષ્ણ',
    audioAsset: 'assets/audio/voice_krishna_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_krishna_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/krishna_thumbnail.webp',
    coverAsset: 'assets/images/jap/krishna_cover.webp',
    defaultBeadStyle: MalaBeadStyle.sandalwood,
    activeColor: Color(0xFF00E5FF),
    glowColor: Color(0xFFFFD54F),
    blessingTitle: '🙏 હરે કૃષ્ણ 🙏',
    blessingSubtitle: 'May Lord Shri Krishna illuminate your spiritual path with divine love, wisdom, and eternal joy.',
    displayOrder: 3,
  );

  /// 4. SHIVA
  static const JapThemeConfig shiva = JapThemeConfig(
    id: 'shiva',
    name: 'SHIVA',
    displayName: 'SHIVA',
    fullName: 'Lord Shiva',
    deityName: 'Shiva',
    mantraText: 'શિવ',
    voiceText: 'શિવ',
    audioAsset: 'assets/audio/voice_shiva_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_shiva_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/shiva_thumbnail.webp',
    coverAsset: 'assets/images/jap/shiva_cover.webp',
    defaultBeadStyle: MalaBeadStyle.rudraksha,
    activeColor: Color(0xFF81C784),
    glowColor: Color(0xFF64B5F6),
    blessingTitle: '🙏 હર હર મહાદેવ 🙏',
    blessingSubtitle: 'May Mahadev grant you stillness of mind, detachment, deep peace, and divine liberation.',
    displayOrder: 4,
  );

  /// 5. HANUMAN
  static const JapThemeConfig hanuman = JapThemeConfig(
    id: 'hanuman',
    name: 'HANUMAN',
    displayName: 'HANUMAN',
    fullName: 'Shri Hanuman',
    deityName: 'Hanuman',
    mantraText: 'હનુમાન',
    voiceText: 'હનુમાન',
    audioAsset: 'assets/audio/voice_hanuman_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_hanuman_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/hanuman_thumbnail.webp',
    coverAsset: 'assets/images/jap/hanuman_cover.webp',
    defaultBeadStyle: MalaBeadStyle.rudraksha,
    activeColor: Color(0xFFFF3D00),
    glowColor: Color(0xFFFF6E40),
    blessingTitle: '🙏 જય બજરંગબલી 🙏',
    blessingSubtitle: 'May Sankat Mochan Hanuman grant you boundless spiritual strength, protection, and humility.',
    displayOrder: 5,
  );

  /// 6. GANESH
  static const JapThemeConfig ganesh = JapThemeConfig(
    id: 'ganesh',
    name: 'GANESH',
    displayName: 'GANESH',
    fullName: 'Shri Ganesh',
    deityName: 'Ganesh',
    mantraText: 'ગણેશ',
    voiceText: 'ગણેશ',
    audioAsset: 'assets/audio/voice_ganesh_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_ganesh_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/ganesh_thumbnail.webp',
    coverAsset: 'assets/images/jap/ganesh_cover.webp',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFFAB00),
    glowColor: Color(0xFFFFD740),
    blessingTitle: '🙏 ગણપતિ બાપ્પા મોરિયા 🙏',
    blessingSubtitle: 'May Vighnaharta Ganesha remove all impediments and bless your endeavors with auspicious success.',
    displayOrder: 6,
  );

  /// 7. DURGA
  static const JapThemeConfig durga = JapThemeConfig(
    id: 'durga',
    name: 'DURGA',
    displayName: 'DURGA',
    fullName: 'Maa Durga',
    deityName: 'Durga',
    mantraText: 'દુર્ગા',
    voiceText: 'દુર્ગા',
    audioAsset: 'assets/audio/voice_durga_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_durga_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/durga_thumbnail.webp',
    coverAsset: 'assets/images/jap/durga_cover.webp',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFF3366),
    glowColor: Color(0xFFFF5252),
    blessingTitle: '🙏 જય મા દુર્ગા 🙏',
    blessingSubtitle: 'May Maa Durga protect you with divine courage, strength, and triumph over all darkness.',
    displayOrder: 7,
  );

  /// 8. LAKSHMI
  static const JapThemeConfig lakshmi = JapThemeConfig(
    id: 'lakshmi',
    name: 'LAKSHMI',
    displayName: 'LAKSHMI',
    fullName: 'Maa Lakshmi',
    deityName: 'Lakshmi',
    mantraText: 'લક્ષ્મી',
    voiceText: 'લક્ષ્મી',
    audioAsset: 'assets/audio/voice_lakshmi_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_lakshmi_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/lakshmi_thumbnail.webp',
    coverAsset: 'assets/images/jap/lakshmi_cover.webp',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFFD700),
    glowColor: Color(0xFFFFE082),
    blessingTitle: '🙏 ૐ મહાલક્ષ્મી નમો નમઃ 🙏',
    blessingSubtitle: 'May Goddess Lakshmi bestow abundant auspiciousness, peace, wisdom, and spiritual prosperity.',
    displayOrder: 8,
  );

  /// 9. VISHNU
  static const JapThemeConfig vishnu = JapThemeConfig(
    id: 'vishnu',
    name: 'VISHNU',
    displayName: 'VISHNU',
    fullName: 'Shri Vishnu',
    deityName: 'Vishnu',
    mantraText: 'વિષ્ણુ',
    voiceText: 'વિષ્ણુ',
    audioAsset: 'assets/audio/voice_vishnu_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_vishnu_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/vishnu_thumbnail.webp',
    coverAsset: 'assets/images/jap/vishnu_cover.webp',
    defaultBeadStyle: MalaBeadStyle.tulsi,
    activeColor: Color(0xFF29B6F6),
    glowColor: Color(0xFF81D4FA),
    blessingTitle: '🙏 ૐ નમો ભગવતે વાસુદેવાય 🙏',
    blessingSubtitle: 'May Lord Vishnu preserve your peace, sustain your dharma, and guide you towards divine bliss.',
    displayOrder: 9,
  );

  /// 10. SWAMINARAYAN
  static const JapThemeConfig swaminarayan = JapThemeConfig(
    id: 'swaminarayan',
    name: 'SWAMINARAYAN',
    displayName: 'SWAMINARAYAN',
    fullName: 'Bhagwan Swaminarayan',
    deityName: 'Swaminarayan',
    mantraText: 'સ્વામિનારાયણ',
    voiceText: 'સ્વામિનારાયણ',
    audioAsset: 'assets/audio/voice_swaminarayan_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_swaminarayan_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/swaminarayan_thumbnail.webp',
    coverAsset: 'assets/images/jap/swaminarayan_cover.webp',
    defaultBeadStyle: MalaBeadStyle.sandalwood,
    activeColor: Color(0xFFFF7043),
    glowColor: Color(0xFFFFAB91),
    blessingTitle: '🙏 જય સ્વામિનારાયણ 🙏',
    blessingSubtitle: 'May Bhagwan Swaminarayan purify your heart, impart eternal peace, and grant supreme salvation.',
    displayOrder: 10,
  );

  /// 11. AMBE
  static const JapThemeConfig ambe = JapThemeConfig(
    id: 'ambe',
    name: 'AMBE',
    displayName: 'AMBE',
    fullName: 'Ambe Maa',
    deityName: 'Ambe',
    mantraText: 'અંબે',
    voiceText: 'અંબે',
    audioAsset: 'assets/audio/voice_ambe_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_ambe_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/ambe_thumbnail.webp',
    coverAsset: 'assets/images/jap/ambe_cover.webp',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFFF1744),
    glowColor: Color(0xFFFF5252),
    blessingTitle: '🙏 જય માતાજી 🙏',
    blessingSubtitle: 'May Jagadamba Ambe Maa shower fearless strength, protection, victory, and auspicious prosperity.',
    displayOrder: 11,
  );

  /// 12. KHATU
  static const JapThemeConfig khatu = JapThemeConfig(
    id: 'khatu',
    name: 'KHATU',
    displayName: 'KHATU',
    fullName: 'Shri Khatu Shyam',
    deityName: 'Khatu',
    mantraText: 'શ્યામ',
    voiceText: 'શ્યામ',
    audioAsset: 'assets/audio/voice_khatu_chant.mp3',
    backgroundMusicAsset: 'assets/audio/music_khatu_instrumental.wav',
    thumbnailAsset: 'assets/images/jap/khatu_thumbnail.webp',
    coverAsset: 'assets/images/jap/khatu_cover.webp',
    defaultBeadStyle: MalaBeadStyle.goldenBeads,
    activeColor: Color(0xFFAB47BC),
    glowColor: Color(0xFFCE93D8),
    blessingTitle: '🙏 જય શ્રી શ્યામ 🙏',
    blessingSubtitle: 'May Shri Khatu Shyam Ji grant you divine refuge, bless your prayers, and remove all hardships.',
    displayOrder: 12,
  );

  // Backward compatibility alias
  static const JapThemeConfig ganesha = ganesh;

  static const List<JapThemeConfig> allThemes = [
    ram,
    radha,
    krishna,
    shiva,
    hanuman,
    ganesh,
    durga,
    lakshmi,
    vishnu,
    swaminarayan,
    ambe,
    khatu,
  ];

  static JapThemeConfig resolveFromEntry({
    required String name,
    required String shlokText,
    String? audioUrl,
  }) {
    final lowerName = name.trim().toLowerCase();
    final lowerShlok = shlokText.trim().toLowerCase();

    if (lowerName.contains('swaminarayan') || lowerShlok.contains('સ્વામિનારાયણ') || lowerShlok.contains('स्वामिनारायण')) {
      return swaminarayan;
    }
    if (lowerName.contains('khatu') || lowerName.contains('shyam') || lowerShlok.contains('શ્યામ') || lowerShlok.contains('श्याम')) {
      return khatu;
    }
    if (lowerName.contains('lakshmi') || lowerName.contains('laxmi') || lowerShlok.contains('મહાલક્ષ્મી') || lowerShlok.contains('महालक्ष्मी')) {
      return lakshmi;
    }
    if (lowerName.contains('durga') || lowerShlok.contains('દુર્ગા') || lowerShlok.contains('दुर्गा')) {
      return durga;
    }
    if (lowerName.contains('vishnu') || lowerName.contains('narayan') || lowerShlok.contains('વાસુદેવાય') || lowerShlok.contains('वासुदेवाय')) {
      return vishnu;
    }
    if (lowerName.contains('hanuman') || lowerName.contains('bajrang') || lowerShlok.contains('હનુમતે') || lowerShlok.contains('हनुमत')) {
      return hanuman;
    }
    if (lowerName.contains('ganesh') || lowerName.contains('ganpati') || lowerShlok.contains('ગણપતયે') || lowerShlok.contains('गणपत')) {
      return ganesh;
    }
    if (lowerName.contains('shiv') || lowerName.contains('mahadev') || lowerName.contains('bhole') || lowerShlok.contains('શિવાય') || lowerShlok.contains('शिवाय')) {
      return shiva;
    }
    if (lowerName.contains('radha') && !lowerName.contains('krishna')) {
      return radha;
    }
    if (lowerName.contains('krishna') || lowerName.contains('kanha') || lowerShlok.contains('કૃષ્ણ') || lowerShlok.contains('कृष्ण')) {
      return krishna;
    }
    if (lowerName.contains('amba') || lowerName.contains('ambe') || lowerShlok.contains('અંબે') || lowerShlok.contains('अम्बे')) {
      return ambe;
    }
    if (lowerName.contains('ram') || lowerName.contains('raghav') || lowerShlok.contains('રામ') || lowerShlok.contains('राम')) {
      return ram;
    }

    return ram;
  }
}
