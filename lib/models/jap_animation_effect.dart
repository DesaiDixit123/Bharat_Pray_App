import 'package:flutter/material.dart';

/// Enum representing the 5 available image reveal and animation effects in Bharat Pray.
/// IMPORTANT: [divineVerticalReveal] is the existing client-approved effect and is ALWAYS the default.
enum JapRevealEffectType {
  divineVerticalReveal,
  goldenAuraReveal,
  lotusBloomReveal,
  dhoopSmokeReveal,
  divineParticleReveal,
}

class JapRevealEffectConfig {
  final JapRevealEffectType type;
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String badge;
  final List<Color> gradientColors;

  const JapRevealEffectConfig({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.badge,
    required this.gradientColors,
  });

  /// The existing approved effect (Default)
  static const JapRevealEffectConfig existingLiveDarshan = JapRevealEffectConfig(
    type: JapRevealEffectType.divineVerticalReveal,
    id: 'divine_vertical_reveal',
    name: 'Live Darshan Effect',
    description: 'Current approved devotional animation with circular trajectory.',
    icon: Icons.temple_hindu_rounded,
    badge: 'DEFAULT',
    gradientColors: [Color(0xFFFF9900), Color(0xFFFF5500)],
  );

  /// 1. Golden Aura Reveal
  static const JapRevealEffectConfig goldenAura = JapRevealEffectConfig(
    type: JapRevealEffectType.goldenAuraReveal,
    id: 'golden_aura_reveal',
    name: 'Golden Aura Reveal',
    description: 'Gradually reveal the deity through radiant golden light & halo.',
    icon: Icons.wb_sunny_rounded,
    badge: 'RADIANT',
    gradientColors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
  );

  /// 2. Lotus Bloom Reveal
  static const JapRevealEffectConfig lotusBloom = JapRevealEffectConfig(
    type: JapRevealEffectType.lotusBloomReveal,
    id: 'lotus_bloom_reveal',
    name: 'Lotus Bloom Reveal',
    description: 'Reveal the deity through expanding sacred lotus petals.',
    icon: Icons.spa_rounded,
    badge: 'SACRED',
    gradientColors: [Color(0xFFFF80AB), Color(0xFFFFB300)],
  );

  /// 3. Dhoop Smoke Reveal
  static const JapRevealEffectConfig dhoopSmoke = JapRevealEffectConfig(
    type: JapRevealEffectType.dhoopSmokeReveal,
    id: 'dhoop_smoke_reveal',
    name: 'Dhoop Smoke Reveal',
    description: 'Reveal the deity through rising sacred incense smoke.',
    icon: Icons.waves_rounded,
    badge: 'DIVINE',
    gradientColors: [Color(0xFFE0E0E0), Color(0xFFFFB300)],
  );

  /// 4. Divine Particle Reveal
  static const JapRevealEffectConfig divineParticle = JapRevealEffectConfig(
    type: JapRevealEffectType.divineParticleReveal,
    id: 'divine_particle_reveal',
    name: 'Divine Particle Reveal',
    description: 'Reveal the deity through gently rising golden particles.',
    icon: Icons.auto_awesome_rounded,
    badge: 'CELESTIAL',
    gradientColors: [Color(0xFFFFE082), Color(0xFFFF6F00)],
  );

  /// Full list containing all 5 effects in standard order
  static const List<JapRevealEffectConfig> allEffects = [
    existingLiveDarshan,
    goldenAura,
    lotusBloom,
    dhoopSmoke,
    divineParticle,
  ];

  static JapRevealEffectConfig fromId(String? id) {
    if (id == null || id.isEmpty) return existingLiveDarshan;
    return allEffects.firstWhere(
      (e) => e.id == id,
      orElse: () => existingLiveDarshan,
    );
  }

  static JapRevealEffectConfig fromType(JapRevealEffectType type) {
    return allEffects.firstWhere(
      (e) => e.type == type,
      orElse: () => existingLiveDarshan,
    );
  }
}
