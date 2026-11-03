import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/language_manager.dart';
import '../../../../core/localization/language_model.dart';
import 'widgets/language_card.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isDismissible;
  final VoidCallback? onLanguageApplied;

  const LanguageSelectionScreen({
    super.key,
    this.isDismissible = false,
    this.onLanguageApplied,
  });

  /// Present as modal bottom sheet with modern spiritual styling
  static Future<void> showAsSheet(
    BuildContext context, {
    bool isDismissible = true,
    VoidCallback? onLanguageApplied,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSelectionScreen(
        isDismissible: isDismissible,
        onLanguageApplied: onLanguageApplied,
      ),
    );
  }

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedCode;
  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnimation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = LanguageManager.instance.currentLanguageCode;

    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimController.forward();
  }

  @override
  void dispose() {
    _fadeAnimController.dispose();
    super.dispose();
  }

  Future<void> _applyLanguage() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    await LanguageManager.instance.changeLanguageByCode(_selectedCode);

    if (mounted) {
      widget.onLanguageApplied?.call();
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final languages = LanguageManager.instance.getSupportedLanguages();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF120924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Color(0x44FF7700), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 20),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Notch handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0x44FFFFFF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header with BharatPray Branding & Om Symbol
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8800), Color(0xFFFF5500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ॐ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Your Preferred Language',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Select your language to continue',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isDismissible)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9E8DB8),
                      size: 22,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Language Cards List
            ...languages.map(
              (lang) => LanguageCard(
                language: lang,
                isSelected: _selectedCode.toLowerCase() == lang.code.toLowerCase(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCode = lang.code);
                },
              ),
            ),

            const SizedBox(height: 22),

            // Continue Action Button
            ElevatedButton(
              onPressed: _isSaving ? null : _applyLanguage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFFF7700).withValues(alpha: 0.5),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

