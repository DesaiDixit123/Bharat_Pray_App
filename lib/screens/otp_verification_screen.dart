import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? initialOtp;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.initialOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  // OTP state
  String _generatedOtp = '';

  // Timer state
  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isLoading = false;

  // ─────────────────────────────────────────── lifecycle ──

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    // Use dev-mode OTP from backend if provided
    _generatedOtp = widget.initialOtp ?? '';

    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────── helpers ──

  String _getMaskedPhoneNumber() {
    final cleaned = widget.phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleaned.contains('@')) {
      return cleaned;
    }
    if (!cleaned.startsWith('+') && cleaned.length == 10) {
      return '+91 $cleaned';
    }
    return cleaned;
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ─────────────────────────────────────────── actions ──

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.sendOtp(widget.phoneNumber);
      final newOtp = response['Data']?['dev_mode_otp']?.toString();

      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      if (newOtp != null && newOtp.isNotEmpty) {
        setState(() {
          _generatedOtp = newOtp;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifyOtp(widget.phoneNumber, enteredOtp);
      final token = response['Data']['accesstoken'];
      debugPrint('✅ OTP Verified. Auth Token: $token');
      final userData = response['Data']['userdata'];
      debugPrint('👤 OTP Verified User Data (ID): $userData');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('auth_token', token ?? '');
      await prefs.setString('user_name', userData['name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_phone', userData['mobile'] ?? '');
      await prefs.setString('profile_pic', userData['profile_pic'] ?? '');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────── build ──

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _getMaskedPhoneNumber();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF1A1225),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      // Outer Stack so notification and loader can float above the Scaffold
      child: Stack(
        children: [
          // ── Scaffold (background + main content) ───────────────────────
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/login_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1E102F), Color(0xFF0F081D)],
                        ),
                      ),
                    ),
                  ),
                ),

                // Dark vignette
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),

                // Back button
                Positioned(
                  top: 50,
                  left: 16,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

                // Glassmorphic OTP card
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),

                                // Lock icon
                                Container(
                                  height: 70,
                                  width: 70,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF7700),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Text(
                                  'Enter OTP',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Text(
                                  'A verification code has been sent to',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  maskedPhone,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF7700),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_generatedOtp.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7700).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFF7700).withValues(alpha: 0.24),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      'Demo OTP: $_generatedOtp',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFF7700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),

                                // 6-digit OTP boxes
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (i) {
                                    return SizedBox(
                                      width: 44,
                                      height: 50,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _controllers[i],
                                          focusNode: _focusNodes[i],
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (v) {
                                            if (v.length > 1) {
                                              final digits = v.replaceAll(RegExp(r'\D'), '');
                                              if (digits.length >= 6) {
                                                final code = digits.substring(0, 6);
                                                for (int j = 0; j < 6; j++) {
                                                  _controllers[j].text = code[j];
                                                }
                                                _focusNodes[5].requestFocus();
                                                _focusNodes[5].unfocus();
                                                return;
                                              }
                                              // Truncate to the last character typed/pasted if not full code
                                              _controllers[i].text = v.substring(v.length - 1);
                                            }
                                            if (_controllers[i].text.isNotEmpty) {
                                              if (i < 5) {
                                                _focusNodes[i + 1].requestFocus();
                                              } else {
                                                _focusNodes[i].unfocus();
                                              }
                                            } else {
                                              if (i > 0) {
                                                _focusNodes[i - 1].requestFocus();
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 24),

                                // Resend timer
                                GestureDetector(
                                  onTap: _canResend ? _resendOtp : null,
                                  child: RichText(
                                    text: TextSpan(
                                      text: _canResend ? '' : 'Resend in ',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _canResend
                                              ? 'Resend OTP'
                                              : '${_secondsRemaining}s',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFFF7700),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            decoration: _canResend
                                                ? TextDecoration.underline
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Verify button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF7700),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _verifyOtp,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.0,
                                            ),
                                          )
                                        : Text(
                                            'Verify',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Text(
                                  'By clicking verify, you agree to receive spiritual updates and daily prayer notifications.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
