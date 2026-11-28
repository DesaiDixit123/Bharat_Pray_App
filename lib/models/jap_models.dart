import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/localization/localized_api_helper.dart';
import 'tts_voice_model.dart';

enum ParticleShapeType { petal, leaf, feather, spark, ash, flame, custom }
enum DivineSymbolType { trishul, shankh, flute, bowArrow, lotus, chakra, om, none }

class EffectPack {
  final String id;
  final ParticleShapeType shape;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color haloGlowColor;
  final double particleVelocity;
  final double smokeEmissionIntervalSec;
  final String blessingTitle;
  final String blessingSubtitle;
  final String? completionSoundUrl;
  final String? haloTextureUrl;
  final String? particleTextureUrl;
  final List<Color> particleColors;
  final DivineSymbolType divineSymbol;
  final List<String> tapMantras;

  String get code => id;

  const EffectPack({
    required this.id, required this.shape, required this.primaryColor,
    required this.secondaryColor, required this.accentColor, required this.haloGlowColor,
    this.particleVelocity = 1.0, this.smokeEmissionIntervalSec = 0.25,
    required this.blessingTitle, required this.blessingSubtitle,
    this.completionSoundUrl, this.haloTextureUrl, this.particleTextureUrl,
    required this.particleColors,
    this.divineSymbol = DivineSymbolType.om,
    this.tapMantras = const ['\u0950', '\u091c\u092f', '\u0939\u0930\u093f', '\u0928\u092e\u0903'],
  });

  factory EffectPack.fromJson(Map<String, dynamic> json) {
    final animConfig = json['animationConfig'] is Map<String, dynamic>
        ? json['animationConfig'] as Map<String, dynamic> : json;
    final shape = _parseShape(json['particleShape'] ?? animConfig['particleShape'] ?? json['shape']);
    final assetRefs = json['assetReferences'] is Map<String, dynamic>
        ? json['assetReferences'] as Map<String, dynamic> : {};
    final primary = _parseColor(animConfig['primaryColor'] ?? json['primaryColor'], const Color(0xFFFF7700));
    final secondary = _parseColor(animConfig['secondaryColor'] ?? json['secondaryColor'], const Color(0xFFFFD700));
    final accent = _parseColor(animConfig['accentColor'] ?? json['accentColor'], const Color(0xFFC8A882));
    final glow = _parseColor(animConfig['haloGlowColor'] ?? json['haloGlowColor'], const Color(0xFFFF9933));
    return EffectPack(
      id: json['code'] ?? json['id'] ?? json['_id'] ?? 'DEFAULT_GOLD',
      shape: shape, primaryColor: primary, secondaryColor: secondary,
      accentColor: accent, haloGlowColor: glow,
      particleVelocity: (animConfig['particleVelocity'] as num?)?.toDouble() ?? 1.0,
      smokeEmissionIntervalSec: (animConfig['smokeEmissionIntervalSec'] as num?)?.toDouble() ?? 0.25,
      blessingTitle: animConfig['blessingTitle'] ?? json['blessingTitle'] ?? '\ud83d\ude4f Divine Blessings \ud83d\ude4f',
      blessingSubtitle: animConfig['blessingSubtitle'] ?? json['blessingSubtitle'] ?? 'May peace guide your path.',
      completionSoundUrl: assetRefs['completionSound'] ?? json['completionSoundUrl'],
      haloTextureUrl: assetRefs['haloTexture'] ?? json['haloTextureUrl'],
      particleTextureUrl: assetRefs['particleTexture'] ?? json['particleTextureUrl'],
      particleColors: [primary, secondary, accent],
    );
  }

  static ParticleShapeType _parseShape(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'leaf': return ParticleShapeType.leaf;
      case 'feather': return ParticleShapeType.feather;
      case 'spark': return ParticleShapeType.spark;
      case 'ash': return ParticleShapeType.ash;
      case 'flame': return ParticleShapeType.flame;
      default: return ParticleShapeType.petal;
    }
  }

  static Color _parseColor(dynamic raw, Color fallback) {
    if (raw == null) return fallback;
    if (raw is Color) return raw;
    if (raw is int) return Color(raw);
    if (raw is String) {
      var hex = raw.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  static const EffectPack shiva = EffectPack(
    id: 'SHIVA_MAHADEV', shape: ParticleShapeType.flame,
    primaryColor: Color(0xFF81C784), secondaryColor: Color(0xFFE8F4FC),
    accentColor: Color(0xFF90CAF9), haloGlowColor: Color(0xFF90CAF9),
    particleVelocity: 0.9, smokeEmissionIntervalSec: 0.22,
    blessingTitle: '\ud83d\ude4f Har Har Mahadev \ud83d\ude4f',
    blessingSubtitle: 'May Lord Shiva bless you with inner peace, courage, and divine liberation.',
    particleColors: [Color(0xFFE8F4FC), Color(0xFF90CAF9), Color(0xFF81C784)],
    divineSymbol: DivineSymbolType.trishul,
    tapMantras: ['\u0950 \u0928\u092e\u0903 \u0936\u093f\u0935\u093e\u092f', '\u0939\u0930 \u0939\u0930 \u092e\u0939\u093e\u0926\u0947\u0935', '\u092c\u092e \u092c\u092e \u092d\u094b\u0932\u0947', '\u0936\u093f\u0935 \u0936\u0902\u0915\u0930', '\u092e\u0939\u093e\u0915\u093e\u0932'],
  );

  static const EffectPack krishna = EffectPack(
    id: 'KRISHNA_DEV', shape: ParticleShapeType.feather,
    primaryColor: Color(0xFF0D4F8B), secondaryColor: Color(0xFF50C878),
    accentColor: Color(0xFFFF80AB), haloGlowColor: Color(0xFF4FC3F7),
    particleVelocity: 1.1, smokeEmissionIntervalSec: 0.24,
    blessingTitle: '\ud83d\ude4f Jai Shree Krishna \ud83d\ude4f',
    blessingSubtitle: 'May Lord Krishna fill your life with eternal joy, love, and divine grace.',
    particleColors: [Color(0xFF0D4F8B), Color(0xFF50C878), Color(0xFFFF80AB)],
    divineSymbol: DivineSymbolType.flute,
    tapMantras: ['\u0939\u0930\u0947 \u0915\u0943\u0937\u094d\u0923', '\u0930\u093e\u0927\u0947 \u0930\u093e\u0927\u0947', '\u091c\u092f \u0917\u094b\u0935\u093f\u0902\u0926', '\u0928\u0902\u0926\u0932\u093e\u0932', '\u092e\u0941\u0930\u0932\u0940\u0927\u0930'],
  );

  static const EffectPack ganesha = EffectPack(
    id: 'GANESHA_DEV', shape: ParticleShapeType.petal,
    primaryColor: Color(0xFFFF6B35), secondaryColor: Color(0xFFFFB300),
    accentColor: Color(0xFFFFD700), haloGlowColor: Color(0xFFFFAB40),
    particleVelocity: 1.0, smokeEmissionIntervalSec: 0.25,
    blessingTitle: '\ud83d\ude4f Ganpati Bappa Morya \ud83d\ude4f',
    blessingSubtitle: 'May Lord Ganesha remove all obstacles and bestow wisdom upon your path.',
    particleColors: [Color(0xFFFF6B35), Color(0xFFFFB300), Color(0xFFFFD700)],
    divineSymbol: DivineSymbolType.om,
    tapMantras: ['\u091c\u092f \u0917\u0923\u0947\u0936', '\u0917\u0923\u092a\u0924\u093f \u092c\u092a\u094d\u092a\u093e', '\u0936\u0941\u092d \u0932\u093e\u092d', '\u0938\u093f\u0926\u094d\u0927\u093f\u0935\u093f\u0928\u093e\u092f\u0915', '\u092e\u094b\u0930\u092f\u093e'],
  );

  static const EffectPack hanuman = EffectPack(
    id: 'HANUMAN_DEV', shape: ParticleShapeType.spark,
    primaryColor: Color(0xFFCC2200), secondaryColor: Color(0xFFFF6600),
    accentColor: Color(0xFFFFD700), haloGlowColor: Color(0xFFFF5722),
    particleVelocity: 1.3, smokeEmissionIntervalSec: 0.20,
    blessingTitle: '\ud83d\ude4f Jai Bajrangbali \ud83d\ude4f',
    blessingSubtitle: 'May Lord Hanuman grant you immense strength, devotion, and divine protection.',
    particleColors: [Color(0xFFCC2200), Color(0xFFFF6600), Color(0xFFFFD700)],
    divineSymbol: DivineSymbolType.bowArrow,
    tapMantras: ['\u091c\u092f \u092c\u091c\u0930\u0902\u0917', '\u0939\u0928\u0941\u092e\u093e\u0928 \u0915\u0940 \u091c\u092f', '\u091c\u092f \u0936\u094d\u0930\u0940 \u0930\u093e\u092e', '\u092a\u0935\u0928\u092a\u0941\u0924\u094d\u0930', '\u092e\u0939\u093e\u0935\u0940\u0930'],
  );

  static const EffectPack durga = EffectPack(
    id: 'DURGA_MAA', shape: ParticleShapeType.spark,
    primaryColor: Color(0xFF990000), secondaryColor: Color(0xFFFF1744),
    accentColor: Color(0xFFFFD700), haloGlowColor: Color(0xFFFF1744),
    particleVelocity: 1.25, smokeEmissionIntervalSec: 0.20,
    blessingTitle: '\ud83d\ude4f Jai Mata Di \ud83d\ude4f',
    blessingSubtitle: 'May Maa Durga empower your spirit with fearless strength and victory.',
    particleColors: [Color(0xFF990000), Color(0xFFFF1744), Color(0xFFFFD700)],
    divineSymbol: DivineSymbolType.chakra,
    tapMantras: ['\u091c\u092f \u092e\u093e\u0901 \u0926\u0941\u0930\u094d\u0917\u093e', '\u0926\u0941\u0930\u094d\u0917\u0947 \u0926\u0941\u0930\u094d\u0917\u0947', '\u092e\u093e\u0901 \u0936\u0947\u0930\u093e\u0935\u093e\u0932\u0940', '\u0928\u0935\u0926\u0941\u0930\u094d\u0917\u0947', '\u0936\u0915\u094d\u0924\u093f'],
  );

  static const EffectPack lakshmi = EffectPack(
    id: 'LAKSHMI_MAA', shape: ParticleShapeType.petal,
    primaryColor: Color(0xFFFF80AB), secondaryColor: Color(0xFFFFE082),
    accentColor: Color(0xFFFFD700), haloGlowColor: Color(0xFFFF80AB),
    particleVelocity: 0.95, smokeEmissionIntervalSec: 0.26,
    blessingTitle: '\ud83d\ude4f Shreem Mahalakshmiye Namah \ud83d\ude4f',
    blessingSubtitle: 'May Maa Lakshmi shower your home with eternal abundance, peace, and grace.',
    particleColors: [Color(0xFFFF80AB), Color(0xFFFFE082), Color(0xFFFFD700)],
    divineSymbol: DivineSymbolType.lotus,
    tapMantras: ['\u0936\u094d\u0930\u0940\u0902', '\u091c\u092f \u0932\u0915\u094d\u0937\u094d\u092e\u0940', '\u0927\u0928 \u0932\u0915\u094d\u0937\u094d\u092e\u0940', '\u092e\u0939\u093e\u0932\u0915\u094d\u0937\u094d\u092e\u0940', '\u0938\u092e\u0943\u0926\u094d\u0927\u093f'],
  );

  static const EffectPack vishnu = EffectPack(
    id: 'VISHNU_DEV', shape: ParticleShapeType.leaf,
    primaryColor: Color(0xFF0277BD), secondaryColor: Color(0xFFFFD700),
    accentColor: Color(0xFFFF8F00), haloGlowColor: Color(0xFF29B6F6),
    particleVelocity: 1.0, smokeEmissionIntervalSec: 0.25,
    blessingTitle: '\ud83d\ude4f Om Namo Narayanaya \ud83d\ude4f',
    blessingSubtitle: 'May Lord Vishnu preserve harmony, righteousness, and peace in your life.',
    particleColors: [Color(0xFF0277BD), Color(0xFFFFD700), Color(0xFFFF8F00)],
    divineSymbol: DivineSymbolType.shankh,
    tapMantras: ['\u0950 \u0928\u092e\u094b \u0928\u093e\u0930\u093e\u092f\u0923\u093e\u092f', '\u091c\u092f \u0935\u093f\u0937\u094d\u0923\u0941', '\u0939\u0930\u093f \u0939\u0930\u093f', '\u0928\u093e\u0930\u093e\u092f\u0923', '\u0935\u0948\u0915\u0941\u0923\u094d\u0920'],
  );

  static const EffectPack ram = EffectPack(
    id: 'RAM_DEV', shape: ParticleShapeType.leaf,
    primaryColor: Color(0xFFFF6F00), secondaryColor: Color(0xFFFFD700),
    accentColor: Color(0xFF4CAF50), haloGlowColor: Color(0xFFFFAB40),
    particleVelocity: 1.05, smokeEmissionIntervalSec: 0.23,
    blessingTitle: '\ud83d\ude4f Jai Shree Ram \ud83d\ude4f',
    blessingSubtitle: 'May Lord Ram bless you with righteousness, devotion, and inner strength.',
    particleColors: [Color(0xFFFF6F00), Color(0xFFFFD700), Color(0xFF4CAF50)],
    divineSymbol: DivineSymbolType.bowArrow,
    tapMantras: ['\u091c\u092f \u0936\u094d\u0930\u0940 \u0930\u093e\u092e', '\u0930\u093e\u092e \u0930\u093e\u092e', '\u0938\u093f\u092f\u093e\u0935\u0930 \u0930\u093e\u092e\u091a\u0902\u0926\u094d\u0930', '\u0930\u093e\u0918\u0935', '\u092e\u0930\u094d\u092f\u093e\u0926\u093e \u092a\u0941\u0930\u0941\u0937\u094b\u0924\u094d\u0924\u092e'],
  );

  static const EffectPack defaultGold = EffectPack(
    id: 'DEFAULT_GOLD', shape: ParticleShapeType.petal,
    primaryColor: Color(0xFFFF9933), secondaryColor: Color(0xFFFF5500),
    accentColor: Color(0xFFFFD700), haloGlowColor: Color(0xFFFFB74D),
    particleVelocity: 1.0, smokeEmissionIntervalSec: 0.25,
    blessingTitle: '\ud83d\ude4f Divine Blessings \ud83d\ude4f',
    blessingSubtitle: 'May peace, strength, wisdom and divine grace always guide your sacred path.',
    particleColors: [Color(0xFFFF9933), Color(0xFFFF5500), Color(0xFFFFD700)],
    divineSymbol: DivineSymbolType.om,
    tapMantras: ['\u0950', '\u091c\u092f \u091c\u092f', '\u0939\u0930\u093f \u0950', '\u0928\u092e\u094b', '\u091c\u092f \u0939\u094b'],
  );

  static const EffectPack shivaPreset = shiva;
  static const EffectPack krishnaPreset = krishna;
  static const EffectPack ganeshaPreset = ganesha;
  static const EffectPack hanumanPreset = hanuman;
  static const EffectPack durgaPreset = durga;
  static const EffectPack lakshmiPreset = lakshmi;
  static const EffectPack vishnuPreset = vishnu;
  static const EffectPack ramPreset = ram;
  static const EffectPack defaultGoldPreset = defaultGold;

  static EffectPack resolve({required String name, String? particleShape, String? customTitle, String? customSubtitle}) {
    final shapeKey = (particleShape ?? '').toLowerCase().trim();
    final n = name.toLowerCase();
    EffectPack base;
    if (shapeKey.contains('ram') || (shapeKey.isEmpty || shapeKey == 'auto') && (n.contains('ram') || n.contains('raghav') || n.contains('sita'))) {
      base = ram;
    } else if (shapeKey.contains('radhe') || shapeKey.contains('krishna') || (shapeKey.isEmpty || shapeKey == 'auto') && (n.contains('krishna') || n.contains('radha') || n.contains('govind'))) {
      base = krishna;
    } else if (shapeKey.contains('hanuman') || (shapeKey.isEmpty || shapeKey == 'auto') && (n.contains('hanuman') || n.contains('bajrang') || n.contains('maruti'))) {
      base = hanuman;
    } else if (shapeKey.contains('shiva') || shapeKey.contains('shiv') || (shapeKey.isEmpty || shapeKey == 'auto') && (n.contains('shiva') || n.contains('mahadev') || n.contains('shankar') || n.contains('somnath'))) {
      base = shiva;
    } else if (shapeKey.contains('durga') || (shapeKey.isEmpty || shapeKey == 'auto') && (n.contains('durga') || n.contains('kali') || n.contains('shakti') || n.contains('mata') || n.contains('amba'))) {
      base = durga;
    } else if (shapeKey.contains('ganesh') || shapeKey.contains('om') || (shapeKey.isEmpty || shapeKey == 'auto') && (n.contains('ganesh') || n.contains('ganpati') || n.contains('om'))) {
      base = ganesha;
    } else if (n.contains('lakshmi') || n.contains('laxmi')) {
      base = lakshmi;
    } else if (n.contains('vishnu') || n.contains('narayan') || n.contains('hari')) {
      base = vishnu;
    } else {
      base = defaultGold;
    }
    final shape = (particleShape != null && particleShape.isNotEmpty && particleShape != 'auto')
        ? _parseShape(particleShape) : base.shape;
    final title = (customTitle != null && customTitle.trim().isNotEmpty) ? customTitle.trim() : base.blessingTitle;
    final subtitle = (customSubtitle != null && customSubtitle.trim().isNotEmpty) ? customSubtitle.trim() : base.blessingSubtitle;
    return EffectPack(
      id: base.id, shape: shape, primaryColor: base.primaryColor, secondaryColor: base.secondaryColor,
      accentColor: base.accentColor, haloGlowColor: base.haloGlowColor,
      particleVelocity: base.particleVelocity, smokeEmissionIntervalSec: base.smokeEmissionIntervalSec,
      blessingTitle: title, blessingSubtitle: subtitle, completionSoundUrl: base.completionSoundUrl,
      particleColors: base.particleColors, divineSymbol: base.divineSymbol, tapMantras: base.tapMantras,
    );
  }
}

class JapVoiceOption {
  final String id;
  final String name;
  final String title;
  final String description;
  final String gender;
  final String audioUrl;
  final String assetPath;

  const JapVoiceOption({
    required this.id,
    required this.name,
    this.title = '',
    this.description = '',
    this.gender = 'Male',
    this.audioUrl = '',
    this.assetPath = '',
  });

  factory JapVoiceOption.fromJson(Map<String, dynamic> json) {
    final rawAudio = (json['audioUrl'] ?? '').toString().trim();
    final rawAsset = (json['assetPath'] ?? '').toString().trim();
    return JapVoiceOption(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      gender: (json['gender'] ?? 'Male').toString(),
      audioUrl: rawAudio.isNotEmpty ? ApiService.resolveImageUrl(rawAudio) : '',
      assetPath: rawAsset,
    );
  }

  TtsVoice toTtsVoice({bool isDefault = false}) {
    return TtsVoice(
      id: id,
      name: name,
      gender: gender.isNotEmpty ? gender : 'Male',
      locale: 'hi-IN',
      tier: 'Jap Voice',
      languages: const ['Hindi', 'Gujarati'],
      title: title,
      description: description,
      previewUrl: audioUrl,
      defaultRate: 1.0,
      isDefault: isDefault,
      languageCategory: 'Hindi',
      localAudioSample: assetPath.isNotEmpty ? assetPath : null,
    );
  }
}

class JapConfig {
  final String id;
  final String name;
  final String displayName;
  final String fullName;
  final String mantraText;
  final String voiceText;
  final String? godCategoryId;
  final String? templeId;
  final String thumbnailUrl;
  final String darshanImageUrl;
  final String? localDarshanAsset;
  final String? backgroundMusic;
  final String shlokText;
  final String? shlokAudioUrl;
  final int targetCount;
  int progress;
  final EffectPack effectPack;
  final String? particleShape;
  final bool isCustom;
  final bool isTemporary;
  final String darshanVideoUrl;
  final bool voiceEnabled;
  final bool musicEnabled;
  final bool isActive;
  final int displayOrder;
  final List<JapVoiceOption> voiceOptions;

  JapConfig({
    required this.id,
    required this.name,
    String? displayName,
    String? fullName,
    String? mantraText,
    String? voiceText,
    this.godCategoryId,
    this.templeId,
    required this.thumbnailUrl,
    required this.darshanImageUrl,
    this.localDarshanAsset,
    this.backgroundMusic,
    required this.shlokText,
    this.shlokAudioUrl,
    this.targetCount = 108,
    this.progress = 0,
    required this.effectPack,
    this.particleShape,
    this.isCustom = false,
    this.isTemporary = false,
    this.darshanVideoUrl = '',
    this.voiceEnabled = true,
    this.musicEnabled = true,
    this.isActive = true,
    this.displayOrder = 0,
    this.voiceOptions = const [],
  })  : displayName = displayName ?? _resolveDisplayName(name),
        fullName = fullName ?? _resolveFullName(name),
        mantraText = mantraText ?? shlokText,
        voiceText = voiceText ?? mantraText ?? shlokText;

  static String _resolveDisplayName(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('swaminarayan')) return 'SWAMINARAYAN';
    if (lower.contains('khatu') || lower.contains('shyam')) return 'KHATU';
    if (lower.contains('lakshmi') || lower.contains('laxmi')) return 'LAKSHMI';
    if (lower.contains('durga')) return 'DURGA';
    if (lower.contains('vishnu') || lower.contains('narayan')) return 'VISHNU';
    if (lower.contains('hanuman') || lower.contains('bajrang')) return 'HANUMAN';
    if (lower.contains('ganesh') || lower.contains('ganpati') || lower.contains('vinayak')) return 'GANESH';
    if (lower.contains('radha') && !lower.contains('krishna')) return 'RADHA';
    if (lower.contains('krishna') || lower.contains('kanha')) return 'KRISHNA';
    if (lower.contains('shiv') || lower.contains('mahadev') || lower.contains('bhole')) return 'SHIVA';
    if (lower.contains('ram') || lower.contains('raghav')) return 'RAM';
    if (lower.contains('amba') || lower.contains('ambe')) return 'AMBE';
    final parts = raw.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first.toUpperCase() : 'JAP';
  }

  static String _resolveFullName(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('swaminarayan')) return 'Bhagwan Swaminarayan';
    if (lower.contains('khatu') || lower.contains('shyam')) return 'Shri Khatu Shyam';
    if (lower.contains('lakshmi') || lower.contains('laxmi')) return 'Maa Lakshmi';
    if (lower.contains('durga')) return 'Maa Durga';
    if (lower.contains('vishnu') || lower.contains('narayan')) return 'Shri Vishnu';
    if (lower.contains('hanuman') || lower.contains('bajrang')) return 'Shri Hanuman';
    if (lower.contains('ganesh') || lower.contains('ganpati')) return 'Shri Ganesh';
    if (lower.contains('radha') && !lower.contains('krishna')) return 'Shri Radha';
    if (lower.contains('krishna') || lower.contains('kanha')) return 'Shri Krishna';
    if (lower.contains('shiv') || lower.contains('mahadev')) return 'Lord Shiva';
    if (lower.contains('ram') || lower.contains('raghav')) return 'Shri Ram';
    if (lower.contains('amba') || lower.contains('ambe')) return 'Ambe Maa';
    return raw;
  }

  static String defaultDeityThumbnail(String name) {
    final n = name.toLowerCase();
    if (n.contains('ram voice') || n.contains('ram_special') || n.contains('voice edition')) {
      return 'assets/images/jap/ram_special_cover.webp';
    }
    if (n.contains('swaminarayan')) return 'assets/images/jap/swaminarayan_thumbnail.webp';
    if (n.contains('khatu') || n.contains('shyam')) return 'assets/images/jap/khatu_thumbnail.webp';
    if (n.contains('lakshmi') || n.contains('laxmi')) return 'assets/images/jap/lakshmi_thumbnail.webp';
    if (n.contains('durga')) return 'assets/images/jap/durga_thumbnail.webp';
    if (n.contains('vishnu') || n.contains('narayan')) return 'assets/images/jap/vishnu_thumbnail.webp';
    if (n.contains('hanuman') || n.contains('bajrang')) return 'assets/images/jap/hanuman_thumbnail.webp';
    if (n.contains('ganesh') || n.contains('ganpati')) return 'assets/images/jap/ganesh_thumbnail.webp';
    if (n.contains('shiv') || n.contains('mahadev') || n.contains('shankar')) return 'assets/images/jap/shiva_thumbnail.webp';
    if (n.contains('radha') && !n.contains('krishna')) return 'assets/images/jap/radha_thumbnail.webp';
    if (n.contains('krishna') || n.contains('kanha')) return 'assets/images/jap/krishna_thumbnail.webp';
    if (n.contains('ram') || n.contains('raghav')) return 'assets/images/jap/ram_thumbnail.webp';
    if (n.contains('amba') || n.contains('ambe')) return 'assets/images/jap/ambe_thumbnail.webp';
    return 'assets/images/jap/ram_thumbnail.webp';
  }

  static String defaultDeityCover(String name) {
    final n = name.toLowerCase();
    if (n.contains('ram voice') || n.contains('ram_special') || n.contains('voice edition')) {
      return 'assets/images/jap/ram_special_cover.webp';
    }
    if (n.contains('swaminarayan')) return 'assets/images/jap/swaminarayan_cover.webp';
    if (n.contains('khatu') || n.contains('shyam')) return 'assets/images/jap/khatu_cover.webp';
    if (n.contains('lakshmi') || n.contains('laxmi')) return 'assets/images/jap/lakshmi_cover.webp';
    if (n.contains('durga')) return 'assets/images/jap/durga_cover.webp';
    if (n.contains('vishnu') || n.contains('narayan')) return 'assets/images/jap/vishnu_cover.webp';
    if (n.contains('hanuman') || n.contains('bajrang')) return 'assets/images/jap/hanuman_cover.webp';
    if (n.contains('ganesh') || n.contains('ganpati')) return 'assets/images/jap/ganesh_cover.webp';
    if (n.contains('shiv') || n.contains('mahadev') || n.contains('shankar')) return 'assets/images/jap/shiva_cover.webp';
    if (n.contains('radha') && !n.contains('krishna')) return 'assets/images/jap/radha_cover.webp';
    if (n.contains('krishna') || n.contains('kanha')) return 'assets/images/jap/krishna_cover.webp';
    if (n.contains('ram') || n.contains('raghav')) return 'assets/images/jap/ram_cover.webp';
    if (n.contains('amba') || n.contains('ambe')) return 'assets/images/jap/ambe_cover.webp';
    return 'assets/images/jap/ram_cover.webp';
  }

  static String defaultDeityImage(String name) => defaultDeityThumbnail(name);

  static String _sanitizeUrl(String? url) => ApiService.resolveImageUrl(url);

  factory JapConfig.fromJson(Map<String, dynamic> json) {
    final rawName = LocalizedApiHelper.parse(json['name']);
    final dispName = json['displayName']?.toString() ?? json['display_name']?.toString() ?? _resolveDisplayName(rawName);
    final fName = json['fullName']?.toString() ?? json['full_name']?.toString() ?? _resolveFullName(rawName);
    final pShape = json['particleShape']?.toString() ?? json['particleEffect']?.toString();

    EffectPack effectPack;
    if (json['effectPack'] is Map<String, dynamic>) {
      effectPack = EffectPack.fromJson(json['effectPack'] as Map<String, dynamic>);
    } else {
      effectPack = EffectPack.resolve(
        name: fName.isNotEmpty ? fName : rawName,
        particleShape: pShape,
        customTitle: json['blessingTitle'],
        customSubtitle: json['blessingSubtitle'],
      );
    }

    final defaultThumb = defaultDeityThumbnail(dispName);
    final defaultCover = defaultDeityCover(dispName);

    final rawThumb = _sanitizeUrl(json['thumbnail'] ?? json['thumbnail_image'] ?? json['thumbnailUrl'] ?? '');
    final rawDarshan = _sanitizeUrl(json['darshanImage'] ?? json['cover_image'] ?? json['darshanImageUrl'] ?? '');
    final thumb = rawThumb.isNotEmpty ? rawThumb : defaultThumb;
    final darshan = rawDarshan.isNotEmpty ? rawDarshan : defaultCover;

    final rawMantra = LocalizedApiHelper.parse(json['mantraText'] ?? json['mantra_text'] ?? json['shlokText'] ?? '');
    final rawVoice = json['voiceText']?.toString() ?? json['voice_text']?.toString() ?? rawMantra;
    final rawMusic = _sanitizeUrl(json['backgroundMusic']?.toString() ?? json['background_music']?.toString() ?? '');
    final rawVoiceOptions = json['voiceOptions'];
    final parsedVoiceOptions = rawVoiceOptions is List
        ? rawVoiceOptions
            .whereType<Map>()
            .map((e) => JapVoiceOption.fromJson(Map<String, dynamic>.from(e)))
            .where((v) => v.id.isNotEmpty)
            .toList()
        : const <JapVoiceOption>[];
    final localDarshan = (darshan.contains('ram_special') ||
            dispName.toUpperCase().contains('RAM VOICE'))
        ? 'assets/images/jap/ram_special_cover.webp'
        : null;

    return JapConfig(
      id: json['_id'] ?? json['id'] ?? '',
      name: dispName,
      displayName: dispName,
      fullName: fName,
      mantraText: rawMantra,
      voiceText: rawVoice,
      godCategoryId: json['godCategory'] is Map ? json['godCategory']['_id']?.toString() : json['godCategory']?.toString(),
      templeId: json['temple'] is Map ? json['temple']['_id']?.toString() : json['temple']?.toString(),
      thumbnailUrl: thumb,
      darshanImageUrl: darshan,
      localDarshanAsset: localDarshan,
      backgroundMusic: rawMusic.isNotEmpty ? rawMusic : null,
      shlokText: rawMantra,
      shlokAudioUrl: _sanitizeUrl(json['shlokAudio'] ?? json['shlokAudioUrl'] ?? ''),
      targetCount: (json['targetCount'] is num) ? (json['targetCount'] as num).toInt() : (json['target_count'] is num ? (json['target_count'] as num).toInt() : 108),
      progress: (json['progress'] is num) ? (json['progress'] as num).toInt() : (json['chanting_count'] is num ? (json['chanting_count'] as num).toInt() : 0),
      effectPack: effectPack,
      particleShape: pShape,
      isCustom: json['isCustom'] == true || json['is_custom'] == true || (json['_id'] ?? json['id'] ?? '').toString().startsWith('custom_'),
      isTemporary: json['isTemporary'] == true,
      darshanVideoUrl: _sanitizeUrl(json['darshanVideo'] ?? ''),
      voiceEnabled: json['voiceEnabled'] ?? json['voice_enabled'] ?? true,
      musicEnabled: json['musicEnabled'] ?? json['music_enabled'] ?? true,
      isActive: json['isActive'] ?? json['is_active'] ?? json['status'] ?? true,
      displayOrder: (json['displayOrder'] is num) ? (json['displayOrder'] as num).toInt() : (json['display_order'] is num ? (json['display_order'] as num).toInt() : 0),
      voiceOptions: parsedVoiceOptions,
    );
  }
}

typedef JapEntry = JapConfig;
enum JapLifecycle { idle, started, inProgress, paused, resumed, completed, darshanReveal, darshanActive }
class JapSessionState {
  final String japId; final int currentCount; final int targetCount; final int completedMalas;
  final JapLifecycle lifecycle; final DateTime startedAt; final DateTime lastActionAt;
  final bool isAudioPlaying; final bool isMaskRevealed;
  const JapSessionState({required this.japId, required this.currentCount, this.targetCount = 108,
    required this.completedMalas, required this.lifecycle, required this.startedAt,
    required this.lastActionAt, this.isAudioPlaying = false, this.isMaskRevealed = false});
  int get totalLifetimeCount => (completedMalas * targetCount) + currentCount;
  double get progressFraction => (currentCount / targetCount).clamp(0.0, 1.0);
}
