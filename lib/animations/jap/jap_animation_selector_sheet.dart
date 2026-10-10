import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jap_animation_type.dart';

class JapAnimationSelectorSheet extends StatelessWidget {
  final JapAnimationType currentType;
  final ValueChanged<JapAnimationType> onSelected;

  const JapAnimationSelectorSheet({
    super.key,
    required this.currentType,
    required this.onSelected,
  });

  static Future<JapAnimationType?> show(
    BuildContext context, {
    required JapAnimationType currentType,
    required ValueChanged<JapAnimationType> onSelected,
  }) {
    return showModalBottomSheet<JapAnimationType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => JapAnimationSelectorSheet(
        currentType: currentType,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFF7700),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Jap Animation',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        Text(
                          'Select your favorite devotional darshan effect',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF8C8A94),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8C8A94)),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Scrollable list of options
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  const SizedBox(height: 14),
                  _buildSectionHeader('✨ NEW PREMIUM ANIMATIONS'),

                  ...JapAnimationType.premiumPresets.map((t) => _buildOptionTile(
                    context: context,
                    type: t,
                  )),

                  const SizedBox(height: 14),
                  _buildSectionHeader('🎬 CLASSIC VIDEO ANIMATIONS'),

                  _buildOptionTile(context: context, type: JapAnimationType.dhupVideo),
                  _buildOptionTile(context: context, type: JapAnimationType.ramVideo),
                  _buildOptionTile(context: context, type: JapAnimationType.lotusVideo),
                  _buildOptionTile(context: context, type: JapAnimationType.peacockVideo),
                  _buildOptionTile(context: context, type: JapAnimationType.aartiVideo),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF9E9AA6),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required JapAnimationType type,
    bool isHighlight = false,
  }) {
    final isSelected = currentType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFF7ED)
            : (isHighlight ? const Color(0xFFFAF5FF) : const Color(0xFFFBFBFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFF7700)
              : (isHighlight ? const Color(0xFFE9D5FF) : const Color(0xFFEEEEEE)),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7700)
                : (isHighlight ? const Color(0xFF9333EA) : const Color(0xFFF0F0F2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            type.icon,
            color: isSelected || isHighlight ? Colors.white : const Color(0xFF555555),
            size: 20,
          ),
        ),
        title: Text(
          type.label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? const Color(0xFFFF7700) : const Color(0xFF2E2A36),
          ),
        ),
        subtitle: Text(
          type.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: const Color(0xFF757575),
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7700),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              )
            : null,
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(type);
          Navigator.pop(context, type);
        },
      ),
    );
  }
}
