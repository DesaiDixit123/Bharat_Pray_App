import 'package:flutter/material.dart';
import '../../../../core/localization/language_model.dart';

class LanguageCard extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF26183C)
            : const Color(0xFF180F2A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF7700) : const Color(0x334B366B),
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFFF7700).withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFFFF7700).withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Language Symbol / Avatar Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [const Color(0xFFFF8800), const Color(0xFFFF5500)]
                          : [const Color(0xFF2C1E45), const Color(0xFF1F1433)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.4)
                          : const Color(0x446A4D96),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      language.nativeName.substring(0, 1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFD8C7F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name and Native Script
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFEAE2F7),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            language.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFFFB366)
                                  : const Color(0xFF9E8DB8),
                            ),
                          ),
                          if (language.scriptHint.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFB366)
                                    : const Color(0xFF7A6A92),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              language.scriptHint,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isSelected
                                    ? const Color(0xFFFFD9B3)
                                    : const Color(0xFF7A6A92),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection Radio / Check indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFFFF7700)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF7700)
                          : const Color(0xFF6E568F),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

