import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/jap_customization_models.dart';
import '../../animations/jap/jap_animation_type.dart';

/// Effects and Customization Gallery bottom sheet (Sections 10, 22, 23 of Master Prompt).
/// Allows devotee to personalize starting style, reveal mode, mala beads, chanting pace, and sounds.
class JapEffectsGallerySheet extends StatefulWidget {
  final JapCustomizationPreferences preferences;
  final JapAnimationType currentAnimType;
  final ValueChanged<JapCustomizationPreferences> onPreferencesChanged;
  final ValueChanged<JapAnimationType> onAnimTypeChanged;
  final VoidCallback onResetDefaults;

  const JapEffectsGallerySheet({
    super.key,
    required this.preferences,
    required this.currentAnimType,
    required this.onPreferencesChanged,
    required this.onAnimTypeChanged,
    required this.onResetDefaults,
  });

  static Future<void> show(
    BuildContext context, {
    required JapCustomizationPreferences preferences,
    required JapAnimationType currentAnimType,
    required ValueChanged<JapCustomizationPreferences> onPreferencesChanged,
    required ValueChanged<JapAnimationType> onAnimTypeChanged,
    required VoidCallback onResetDefaults,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JapEffectsGallerySheet(
        preferences: preferences,
        currentAnimType: currentAnimType,
        onPreferencesChanged: onPreferencesChanged,
        onAnimTypeChanged: onAnimTypeChanged,
        onResetDefaults: onResetDefaults,
      ),
    );
  }

  @override
  State<JapEffectsGallerySheet> createState() => _JapEffectsGallerySheetState();
}

class _JapEffectsGallerySheetState extends State<JapEffectsGallerySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _update() {
    widget.preferences.save();
    widget.onPreferencesChanged(widget.preferences);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF141218),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFC8A882), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFF7700), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Devotional Effects & Pace',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.onResetDefaults();
                    setState(() {});
                  },
                  child: Text(
                    'Reset Defaults',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF9933),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFFFF7700),
            indicatorWeight: 2.5,
            labelColor: const Color(0xFFFF9933),
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
            tabs: const [
              Tab(text: 'Starting Style'),
              Tab(text: 'Divine Reveal'),
              Tab(text: 'Mala Beads'),
              Tab(text: 'Pace & Sound'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStartingStyleTab(),
                _buildRevealStyleTab(),
                _buildMalaBeadTab(),
                _buildPaceAndSoundTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Starting Styles ──────────────────────────────────────────
  Widget _buildStartingStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: JapStartingStyle.values.map((style) {
        final bool isSelected = widget.preferences.startingStyle == style;
        return _buildSelectionTile(
          title: style.title,
          subtitle: style.subtitle,
          icon: style.icon,
          isSelected: isSelected,
          onTap: () {
            widget.preferences.startingStyle = style;
            _update();
          },
        );
      }).toList(),
    );
  }

  // ── Tab 2: Progressive Reveal Styles ────────────────────────────────
  Widget _buildRevealStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: JapRevealStyle.values.map((reveal) {
        final bool isSelected = widget.preferences.revealStyle == reveal;
        return _buildSelectionTile(
          title: reveal.title,
          subtitle: reveal.subtitle,
          icon: reveal.icon,
          isSelected: isSelected,
          onTap: () {
            widget.preferences.revealStyle = reveal;
            _update();
          },
        );
      }).toList(),
    );
  }

  // ── Tab 3: Mala Bead Styles ─────────────────────────────────────────
  Widget _buildMalaBeadTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: MalaBeadStyle.values.map((bead) {
        final bool isSelected = widget.preferences.malaStyle == bead;
        return _buildSelectionTile(
          title: bead.title,
          subtitle: bead.subtitle,
          icon: Icons.lens,
          iconColor: bead.activeColor,
          isSelected: isSelected,
          onTap: () {
            widget.preferences.malaStyle = bead;
            _update();
          },
        );
      }).toList(),
    );
  }

  // ── Tab 4: Pace & Sound ─────────────────────────────────────────────
  Widget _buildPaceAndSoundTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Chanting Mode
        Text(
          'CHANTING MODE',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF9933),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                mode: ChantingMode.manualTap,
                title: 'Manual Tap',
                subtitle: 'Tap each bead',
                icon: Icons.touch_app_rounded,
                isSelected: widget.preferences.chantingMode == ChantingMode.manualTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                mode: ChantingMode.autoChant,
                title: 'Auto Chant',
                subtitle: 'Continuous rhythm',
                icon: Icons.play_circle_fill_rounded,
                isSelected: widget.preferences.chantingMode == ChantingMode.autoChant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Default 2-second Interval Selector
        Text(
          'CHANTING SPEED (INTERVAL PER JAP)',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF9933),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [1500, 2000, 2500, 3000, 4000].map((ms) {
            final bool isSelected = widget.preferences.chantIntervalMs == ms;
            final String label = '${(ms / 1000).toStringAsFixed(1)}s${ms == 2000 ? ' (Default)' : ''}';
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: const Color(0xFFFF7700),
              backgroundColor: const Color(0xFF221E28),
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) {
                  widget.preferences.chantIntervalMs = ms;
                  _update();
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Sound & Haptics Toggles
        Text(
          'AUDIO & DEVOTIONAL FEEDBACK',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF9933),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        _buildToggleTile(
          title: 'Devotional Audio Chanting',
          subtitle: 'Play sacred audio recording during each chant',
          value: widget.preferences.soundEnabled,
          onChanged: (val) {
            widget.preferences.soundEnabled = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Divine Background Dhun',
          subtitle: 'Continuous peaceful temple flute & tanpura in background',
          value: widget.preferences.backgroundDhunEnabled,
          onChanged: (val) {
            widget.preferences.backgroundDhunEnabled = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Completion Bell / Shankh',
          subtitle: 'Play sacred temple bell when completing 108 japs',
          value: widget.preferences.bellAtCompletion,
          onChanged: (val) {
            widget.preferences.bellAtCompletion = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Haptic Devotional Pulse',
          subtitle: 'Gentle vibration feedback on each bead',
          value: widget.preferences.hapticsEnabled,
          onChanged: (val) {
            widget.preferences.hapticsEnabled = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Display Mantra Text',
          subtitle: 'Show Sanskrit/Hindi mantra below the mala',
          value: widget.preferences.mantraTextVisible,
          onChanged: (val) {
            widget.preferences.mantraTextVisible = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Continuous Mala Mode',
          subtitle: 'Automatically advance to next mala after 108 japs',
          value: widget.preferences.continuousMalaMode,
          onChanged: (val) {
            widget.preferences.continuousMalaMode = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Audio-Aware Synchronization',
          subtitle: 'Wait for audio chanting to finish before next count',
          value: widget.preferences.audioAwareMode,
          onChanged: (val) {
            widget.preferences.audioAwareMode = val;
            _update();
          },
        ),
        _buildToggleTile(
          title: 'Countdown Mode',
          subtitle: 'Display remaining repetitions instead of count up',
          value: widget.preferences.countdownMode,
          onChanged: (val) {
            widget.preferences.countdownMode = val;
            _update();
          },
        ),

        const SizedBox(height: 16),

        // Meditation Timer Selection
        Text(
          'MEDITATION TIMER (AUTO-STOP)',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF9933),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [0, 5, 10, 15, 20, 30].map((mins) {
            final isSelected = widget.preferences.timerMinutes == mins;
            return ChoiceChip(
              label: Text(mins == 0 ? 'Off' : '$mins min'),
              selected: isSelected,
              selectedColor: const Color(0xFFFF7700),
              backgroundColor: const Color(0xFF1E1A24),
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) {
                  widget.preferences.timerMinutes = mins;
                  _update();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required ChantingMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        widget.preferences.chantingMode = mode;
        _update();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C1E14) : const Color(0xFF1E1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7700) : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF7700) : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C1E14) : const Color(0xFF1A1720),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7700) : Colors.white10,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isSelected ? const Color(0xFFFF7700) : const Color(0xFFC8A882)),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFFF7700),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFFF7700),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
