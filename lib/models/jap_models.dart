import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
    final n = name.toLowerCase();
    EffectPack base;
    if (n.contains('shiva') || n.contains('mahadev') || n.contains('shankar')) base = shiva;
    else if (n.contains('krishna') || n.contains('radha') || n.contains('govind')) base = krishna;
    else if (n.contains('ganesh') || n.contains('ganpati') || n.contains('ganapati')) base = ganesha;
    else if (n.contains('hanuman') || n.contains('bajrang') || n.contains('maruti')) base = hanuman;
    else if (n.contains('durga') || n.contains('kali') || n.contains('shakti') || n.contains('mata')) base = durga;
    else if (n.contains('lakshmi') || n.contains('laxmi')) base = lakshmi;
    else if (n.contains('vishnu') || n.contains('narayan') || n.contains('hari')) base = vishnu;
    else if (n.contains('ram') || n.contains('raghav') || n.contains('sita')) base = ram;
    else base = defaultGold;
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

class JapConfig {
  final String id; final String name; final String? godCategoryId; final String? templeId;
  final String thumbnailUrl; final String darshanImageUrl; final String shlokText;
  final String? shlokAudioUrl; final int targetCount; int progress; final EffectPack effectPack;
  JapConfig({required this.id, required this.name, this.godCategoryId, this.templeId,
    required this.thumbnailUrl, required this.darshanImageUrl, required this.shlokText,
    this.shlokAudioUrl, this.targetCount = 108, this.progress = 0, required this.effectPack});
  static String _sanitizeUrl(String? url) => ApiService.resolveImageUrl(url);
  factory JapConfig.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    EffectPack effectPack;
    if (json['effectPack'] is Map<String, dynamic>) {
      effectPack = EffectPack.fromJson(json['effectPack'] as Map<String, dynamic>);
    } else {
      effectPack = EffectPack.resolve(name: name, particleShape: json['particleShape'],
          customTitle: json['blessingTitle'], customSubtitle: json['blessingSubtitle']);
    }
    return JapConfig(
      id: json['_id'] ?? json['id'] ?? '', name: name,
      godCategoryId: json['godCategory'] is Map ? json['godCategory']['_id']?.toString() : json['godCategory']?.toString(),
      templeId: json['temple'] is Map ? json['temple']['_id']?.toString() : json['temple']?.toString(),
      thumbnailUrl: _sanitizeUrl(json['thumbnail'] ?? ''),
      darshanImageUrl: _sanitizeUrl(json['darshanImage'] ?? json['thumbnail'] ?? ''),
      shlokText: json['shlokText'] ?? '',
      shlokAudioUrl: _sanitizeUrl(json['shlokAudio'] ?? ''),
      targetCount: (json['targetCount'] is num) ? (json['targetCount'] as num).toInt() : 108,
      progress: (json['progress'] is num) ? (json['progress'] as num).toInt() : 0,
      effectPack: effectPack,
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
