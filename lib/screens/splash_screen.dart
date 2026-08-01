import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _shineController;
  late AnimationController _bgController;
  late AnimationController _rotateController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotate;

  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _shineAnimation;
  late Animation<double> _bgScale;
  late Animation<double> _auraRotation;

  @override
  void initState() {
    super.initState();

    // Standard edge-to-edge rendering to auto-adjust display size correctly on all screens
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 1. Cinematic Background Zoom Controller (Ken Burns)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    _bgScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _bgController,
        curve: Curves.easeOutQuad,
      ),
    );

    _bgController.forward();

    // 2. Logo Animation (Smooth scale and fade)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // 3. Pulse Controller (Soft glow behind logo)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _pulseScale = Tween<double>(begin: 0.95, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseOpacity = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);

    // 4. Text Controller (Title and subtitle entrance)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _textSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 5. Title Text Shimmer Shine Controller
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _shineAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _shineController,
        curve: Curves.easeInOut,
      ),
    );

    _shineController.repeat();

    // 6. Slow Rotate Controller for Aura/Halo
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _auraRotation = Tween<double>(begin: 0.0, end: 2 * 3.14159265).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.linear,
      ),
    );

    _rotateController.repeat();

    // Sequential premium animation chain — navigate after logo + text finish + brief pause
    _logoController.forward().then((_) {
      _textController.forward().then((_) {
        // Wait 1.8s after text appears, then navigate
        Future.delayed(const Duration(milliseconds: 1800), _navigateToNextScreen);
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _shineController.dispose();
    _bgController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    bool isLoggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = (prefs.getBool('is_logged_in') ?? false) &&
          (prefs.getString('auth_token')?.isNotEmpty ?? false);
    } catch (e) {
      debugPrint("SharedPreferences init error: $e");
    }

    if (!mounted) return;

    // Restore system overlays (status bar and navigation bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: isLoggedIn ? const Color(0xFF1E102F) : const Color(0xFF1A1225),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Premium custom transition page route (Vanish fade + Scale merge)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.05, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F081D),
        body: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Background Image with Cinematic Ken Burns Zoom
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bgScale.value,
                      child: Image.asset(
                        'assets/images/login_bg.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF0F081D),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // 2. High-end Gradient overlay for a smooth, premium dark ambient look
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.75),
                        const Color(0xFF07040D).withValues(alpha: 0.98),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Central content layer
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Halo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Breathing & Slowly Rotating Aura
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulseController, _rotateController]),
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _auraRotation.value,
                            child: Transform.scale(
                              scale: _pulseScale.value,
                              child: Opacity(
                                opacity: _pulseOpacity.value,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFFF7A00).withValues(alpha: 0.6),
                                        const Color(0xFFFF4500).withValues(alpha: 0.15),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Main App Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.rotate(
                                angle: _logoRotate.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFFF7A00),
                                          child: const Icon(
                                            Icons.temple_hindu_rounded,
                                            color: Colors.white,
                                            size: 56,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Title and Slogan
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0.0, _textSlide.value),
                          child: Column(
                            children: [
                              // Premium Brand Name with Shiny Metallic Gold/Saffron Gradient & running light sheen
                              AnimatedBuilder(
                                animation: _shineController,
                                builder: (context, child) {
                                  return ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: const [
                                          Color(0xFFFF5200),
                                          Color(0xFFFF9F36),
                                          Color(0xFFFFDD77),
                                          Color(0xFFFF9F36),
                                          Color(0xFFFF5200),
                                        ],
                                        stops: [
                                          0.0,
                                          (_shineAnimation.value - 0.25).clamp(0.0, 1.0),
                                          _shineAnimation.value.clamp(0.0, 1.0),
                                          (_shineAnimation.value + 0.25).clamp(0.0, 1.0),
                                          1.0,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      'BHARAT PRAY',
                                      style: GoogleFonts.outfit(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              // Clean subtitle
                              Text(
                                'Daily Prayers, Pujas & Darshan',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
