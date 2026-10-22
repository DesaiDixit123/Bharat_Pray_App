import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1. Starting styles for Jap meditation (Section 3 of Master Prompt)
enum JapStartingStyle {
  pureBlack('pure_black', 'Pure Black Meditation', 'Starts in deep sacred darkness; image emerges with devotion', Icons.nightlight_round),
  blackWithParticles('black_particles', 'Black with Golden Particles', 'Deep black void with floating golden embers', Icons.auto_awesome),
  gradualReveal('gradual_reveal', 'Gradual Divine Reveal', 'Faint silhouette visible from the very first chant', Icons.visibility_rounded),
  goldenTemple('golden_temple', 'Golden Temple Atmosphere', 'Warm sacred temple glow with diya ambiance', Icons.wb_incandescent_rounded),
  cosmicGlow('cosmic_glow', 'Cosmic Devotional Glow', 'Celestial midnight aura with shimmering starlight', Icons.brightness_high_rounded),
  minimalCounter('minimal_counter', 'Minimal Mala Counter', 'Pure high-contrast black focused purely on beads & mantra', Icons.radio_button_checked);

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const JapStartingStyle(this.id, this.title, this.subtitle, this.icon);

  static JapStartingStyle fromId(String? id) {
    if (id == null) return JapStartingStyle.pureBlack;
    for (final s in JapStartingStyle.values) {
      if (s.id == id) return s;
    }
    return JapStartingStyle.pureBlack;
  }
}

/// 2. Progressive Divine Image Reveal styles (Section 7 of Master Prompt)
enum JapRevealStyle {
  radialCenter('radial_center', 'Radial Center Reveal', 'Expands in a soft divine circle from the deity\'s face', Icons.panorama_fish_eye_rounded),
  clarityBrightness('clarity_brightness', 'Clarity & Divine Glow', 'Gradually transforms from darkness into full vibrant illumination', Icons.brightness_6_rounded),
  goldenCircleExpansion('golden_circle', 'Golden Circle Expansion', 'Radiant expanding halo of golden light unmasking the darshan', Icons.circle_outlined),
  topBottomLightSweep('light_sweep', 'Top-to-Bottom Light Sweep', 'Divine celestial light descends from heavens downward', Icons.arrow_downward_rounded),
  silhouetteDissolve('silhouette_dissolve', 'Silhouette Dissolve', 'Dark mystic silhouette dissolves smoothly into sacred colors', Icons.filter_b_and_w_rounded),
  particleReveal('particle_reveal', 'Particle-Based Reveal', 'Swirling golden particles dissolve the veil over the deity', Icons.grain_rounded);

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const JapRevealStyle(this.id, this.title, this.subtitle, this.icon);

  static JapRevealStyle fromId(String? id) {
    if (id == null) return JapRevealStyle.radialCenter;
    for (final s in JapRevealStyle.values) {
      if (s.id == id) return s;
    }
    return JapRevealStyle.radialCenter;
  }
}

/// 3. Mala Bead Styles (Section 4.C, 22.C of Master Prompt)
enum MalaBeadStyle {
  goldenBeads('golden', '24K Golden Beads', 'Radiant polished golden beads with sacred luster', Color(0xFFFFD700), Color(0xFFFF9900)),
  rudraksha('rudraksha', 'Sacred Rudraksha', 'Traditional organic Shiva rudraksha beads', Color(0xFF8D4004), Color(0xFF5A2500)),
  crystalQuartz('sphatik', 'Sphatik (Crystal Quartz)', 'Luminous transparent quartz beads with icy white sheen', Color(0xFFE8F4FC), Color(0xFF90CAF9)),
  lotusSeeds('kamal_gatta', 'Kamal Gatta (Lotus Seed)', 'Glossy dark devotional seeds beloved to Maa Lakshmi', Color(0xFF3E2723), Color(0xFF795548)),
  sandalwood('sandalwood', 'Chandan (Sandalwood)', 'Fragrant soothing sandalwood prayer beads', Color(0xFFD7A15C), Color(0xFF8D5B28)),
  glowingAura('glowing_aura', 'Celestial Halo Glow', 'Ethereal neon light beads radiating spiritual energy', Color(0xFFFF5722), Color(0xFFFFEB3B));

  final String id;
  final String title;
  final String subtitle;
  final Color activeColor;
  final Color highlightColor;

  const MalaBeadStyle(this.id, this.title, this.subtitle, this.activeColor, this.highlightColor);

  static MalaBeadStyle fromId(String? id) {
    if (id == null) return MalaBeadStyle.goldenBeads;
    for (final s in MalaBeadStyle.values) {
      if (s.id == id) return s;
    }
    return MalaBeadStyle.goldenBeads;
  }
}

/// 4. Chanting Mode (Manual Tap vs Auto-Chanting)
enum ChantingMode {
  manualTap('manual', 'Manual Tap Chanting', 'Tap bead to chant each mantra with your own rhythm', Icons.touch_app_rounded),
  autoChant('auto', 'Automatic Chanting Mode', 'Continuous rhythmic chanting at exactly 2.0s per repetition', Icons.play_circle_fill_rounded);

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const ChantingMode(this.id, this.title, this.subtitle, this.icon);

  static ChantingMode fromId(String? id) {
    if (id == null) return ChantingMode.manualTap;
    for (final m in ChantingMode.values) {
      if (m.id == id) return m;
    }
    return ChantingMode.manualTap;
  }
}

/// 5. Persistent Customization Preferences (Section 22, 24)
class JapCustomizationPreferences {
  JapStartingStyle startingStyle;
  JapRevealStyle revealStyle;
  MalaBeadStyle malaStyle;
  ChantingMode chantingMode;
  int chantIntervalMs; // Default 2000ms (2 seconds)
  bool soundEnabled;
  bool backgroundDhunEnabled;
  double backgroundDhunVolume;
  bool bellAtCompletion;
  bool hapticsEnabled;
  bool mantraTextVisible;
  bool continuousMalaMode;
  bool audioAwareMode;
  bool countdownMode;
  int timerMinutes;

  JapCustomizationPreferences({
    this.startingStyle = JapStartingStyle.pureBlack,
    this.revealStyle = JapRevealStyle.radialCenter,
    this.malaStyle = MalaBeadStyle.goldenBeads,
    this.chantingMode = ChantingMode.manualTap,
    this.chantIntervalMs = 2000,
    this.soundEnabled = true,
    this.backgroundDhunEnabled = true,
    this.backgroundDhunVolume = 0.60,
    this.bellAtCompletion = true,
    this.hapticsEnabled = true,
    this.mantraTextVisible = true,
    this.continuousMalaMode = false,
    this.audioAwareMode = false,
    this.countdownMode = false,
    this.timerMinutes = 0,
  });

  static const String _prefKey = 'bharatpray_jap_user_prefs';

  static Future<JapCustomizationPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return JapCustomizationPreferences(
          startingStyle: JapStartingStyle.fromId(data['startingStyle']),
          revealStyle: JapRevealStyle.fromId(data['revealStyle']),
          malaStyle: MalaBeadStyle.fromId(data['malaStyle']),
          chantingMode: ChantingMode.fromId(data['chantingMode']),
          chantIntervalMs: (data['chantIntervalMs'] as num?)?.toInt() ?? 2000,
          soundEnabled: data['soundEnabled'] as bool? ?? true,
          backgroundDhunEnabled: data['backgroundDhunEnabled'] as bool? ?? true,
          backgroundDhunVolume: () {
            final val = (data['backgroundDhunVolume'] as num?)?.toDouble();
            if (val == null || val < 0.40) return 0.60;
            return val;
          }(),
          bellAtCompletion: data['bellAtCompletion'] as bool? ?? true,
          hapticsEnabled: data['hapticsEnabled'] as bool? ?? true,
          mantraTextVisible: data['mantraTextVisible'] as bool? ?? true,
          continuousMalaMode: data['continuousMalaMode'] as bool? ?? false,
          audioAwareMode: data['audioAwareMode'] as bool? ?? false,
          countdownMode: data['countdownMode'] as bool? ?? false,
          timerMinutes: (data['timerMinutes'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (e) {
      debugPrint('[JapCustomizationPreferences] Error loading preferences: $e');
    }
    return JapCustomizationPreferences();
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'startingStyle': startingStyle.id,
        'revealStyle': revealStyle.id,
        'malaStyle': malaStyle.id,
        'chantingMode': chantingMode.id,
        'chantIntervalMs': chantIntervalMs,
        'soundEnabled': soundEnabled,
        'backgroundDhunEnabled': backgroundDhunEnabled,
        'backgroundDhunVolume': backgroundDhunVolume,
        'bellAtCompletion': bellAtCompletion,
        'hapticsEnabled': hapticsEnabled,
        'mantraTextVisible': mantraTextVisible,
        'continuousMalaMode': continuousMalaMode,
        'audioAwareMode': audioAwareMode,
        'countdownMode': countdownMode,
        'timerMinutes': timerMinutes,
      };
      await prefs.setString(_prefKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[JapCustomizationPreferences] Error saving preferences: $e');
    }
  }

  void resetToDefaults() {
    startingStyle = JapStartingStyle.pureBlack;
    revealStyle = JapRevealStyle.radialCenter;
    malaStyle = MalaBeadStyle.goldenBeads;
    chantingMode = ChantingMode.manualTap;
    chantIntervalMs = 2000;
    soundEnabled = true;
    backgroundDhunEnabled = true;
    backgroundDhunVolume = 0.60;
    bellAtCompletion = true;
    hapticsEnabled = true;
    mantraTextVisible = true;
    continuousMalaMode = false;
    audioAwareMode = false;
    countdownMode = false;
    timerMinutes = 0;
  }
}
