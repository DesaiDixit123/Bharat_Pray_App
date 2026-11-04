import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/language_manager.dart';
import '../../../../core/localization/language_model.dart';
import '../../../../screens/home_screen.dart';
import '../../../../screens/login_screen.dart';
import 'widgets/language_card.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFullScreen;
  final bool isDismissible;
  final VoidCallback? onLanguageApplied;

  const LanguageSelectionScreen({
    super.key,
    this.isFullScreen = true,
    this.isDismissible = true,
    this.onLanguageApplied,
  });

  /// Navigate to full-screen language selection page
  static Future<void> open(
    BuildContext context, {
    bool isDismissible = true,
    VoidCallback? onLanguageApplied,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanguageSelectionScreen(
          isFullScreen: true,
          isDismissible: isDismissible,
          onLanguageApplied: onLanguageApplied,
        ),
      ),
    );
  }

  /// Backward-compatible method — opens as full screen page as requested
  static Future<void> showAsSheet(
    BuildContext context, {
    bool isDismissible = true,
    VoidCallback? onLanguageApplied,
  }) {
    return open(
      context,
      isDismissible: isDismissible,
      onLanguageApplied: onLanguageApplied,
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

    if (!mounted) return;

    if (widget.onLanguageApplied != null) {
      widget.onLanguageApplied!();
    }

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }

    // Direct root navigation when opened from splash or initial launch
    bool isLoggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = (prefs.getBool('is_logged_in') ?? false) &&
          (prefs.getString('auth_token')?.isNotEmpty ?? false);
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
        (_) => false,
      );
    }
  }

  String _getBadgeText() {
    switch (_selectedCode.toLowerCase()) {
      case 'gu':
        return 'ભારત પ્રે';
      case 'hi':
        return 'भारत प्रे';
      case 'mr':
        return 'भारत प्रे';
      default:
        return 'BharatPray';
    }
  }

  String _getTitle() {
    switch (_selectedCode.toLowerCase()) {
      case 'gu':
        return 'તમારી પવિત્ર ભાષા પસંદ કરો';
      case 'hi':
        return 'अपनी आध्यात्मिक भाषा चुनें';
      case 'mr':
        return 'तुमची आध्यात्मिक भाषा निवडा';
      default:
        return 'Select Spiritual Language';
    }
  }

  String _getSubtitle() {
    switch (_selectedCode.toLowerCase()) {
      case 'gu':
        return 'દર્શન, જાપ અને ભજન માટે ભાષા પસંદ કરો';
      case 'hi':
        return 'दर्शन, जाप और भजन के लिए भाषा चुनें';
      case 'mr':
        return 'दर्शन, जाप आणि भजनासाठी भाषा निवडा';
      default:
        return 'Choose language for darshan, jap & bhajans';
    }
  }

  String _getContinueButtonText() {
    switch (_selectedCode.toLowerCase()) {
      case 'gu':
        return 'આગળ વધો';
      case 'hi':
        return 'आगे बढ़ें';
      case 'mr':
        return 'पुढे जा';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = LanguageManager.instance.getSupportedLanguages();

    return Scaffold(
      backgroundColor: const Color(0xFF0F081D),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F081D)),
            ),
          ),

          // Deep spiritual gradient vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F081D).withValues(alpha: 0.85),
                    const Color(0xFF1E102F).withValues(alpha: 0.95),
                    const Color(0xFF0F081D),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.isDismissible)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () =>
                                  Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 44),

                        // Spiritual Branding Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF221338).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFFF9933)
                                  .withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7700)
                                    .withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.temple_hindu_rounded,
                                size: 17,
                                color: Color(0xFFFF9933),
                              ),
                              const SizedBox(width: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _getBadgeText(),
                                  key: ValueKey('badge_$_selectedCode'),
                                  style: const TextStyle(
                                    color: Color(0xFFFFB366),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Balance spacer
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),

                          // Glowing Om Avatar
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8800), Color(0xFFFF5500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7700)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 22,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'ॐ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Dynamic Title with smooth transition
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _getTitle(),
                              key: ValueKey('title_$_selectedCode'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Dynamic Subtitle with smooth transition
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _getSubtitle(),
                              key: ValueKey('subtitle_$_selectedCode'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Language Selection Cards List
                          ...languages.map(
                            (lang) => LanguageCard(
                              language: lang,
                              isSelected: _selectedCode.toLowerCase() ==
                                  lang.code.toLowerCase(),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCode = lang.code);
                                // Immediately update app language instance in real-time
                                LanguageManager.instance
                                    .changeLanguageByCode(lang.code);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Pinned Continue Action Button
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _applyLanguage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7700),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 6,
                          shadowColor:
                              const Color(0xFFFF7700).withValues(alpha: 0.45),
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
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _getContinueButtonText(),
                                  key: ValueKey('btn_$_selectedCode'),
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
