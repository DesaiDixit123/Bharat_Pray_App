import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/jap_animation_effect.dart';

/// Devotional bottom sheet modal for choosing among the 5 Divine Darshan Animation Effects.
/// - Preserves the existing approved effect as the default.
/// - Persists user preference under SharedPreferences key 'jap_selected_reveal_effect'.
class JapEffectSelectorSheet extends StatelessWidget {
  final JapRevealEffectType currentEffect;
  final ValueChanged<JapRevealEffectType> onEffectSelected;

  const JapEffectSelectorSheet({
    super.key,
    required this.currentEffect,
    required this.onEffectSelected,
  });

  static const String prefsKey = 'jap_selected_reveal_effect';

  static Future<JapRevealEffectType> loadSelectedEffect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(prefsKey);
      if (savedId != null && savedId.isNotEmpty) {
        return JapRevealEffectConfig.fromId(savedId).type;
      }
    } catch (_) {}
    return JapRevealEffectType.divineVerticalReveal; // Existing approved default
  }

  static Future<void> saveSelectedEffect(JapRevealEffectType effect) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final config = JapRevealEffectConfig.fromType(effect);
      await prefs.setString(prefsKey, config.id);
    } catch (_) {}
  }

  static void show(
    BuildContext context, {
    required JapRevealEffectType currentEffect,
    required ValueChanged<JapRevealEffectType> onEffectSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => JapEffectSelectorSheet(
        currentEffect: currentEffect,
        onEffectSelected: (selected) {
          saveSelectedEffect(selected);
          onEffectSelected(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF140F0D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: const Color(0xFFC8A882).withValues(alpha: 0.50),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFB300),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Darshan Animation Effects',
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select divine animation and progressive reveal effect for your Jap session:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable list of all 5 effects for any screen height
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: JapRevealEffectConfig.allEffects.map((effectConfig) {
                    final bool isSelected = effectConfig.type == currentEffect;
                    return _buildEffectTile(context, effectConfig, isSelected);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectTile(
    BuildContext context,
    JapRevealEffectConfig effect,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEffectSelected(effect.type);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2A1C14)
              : const Color(0xFF1E1714),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB300)
                : const Color(0xFF4A3428).withValues(alpha: 0.6),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9900).withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Preview Icon Container with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: effect.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: effect.gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  effect.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          effect.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF9900).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          effect.badge,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? const Color(0xFFFFB300) : Colors.white60,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    effect.description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Radio / Check Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFFFB300) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFB300) : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.black,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
