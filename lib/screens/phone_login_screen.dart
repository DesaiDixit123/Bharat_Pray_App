import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';
import '../services/api_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF1A1225),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1E102F),
                        Color(0xFF0F081D),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Vignette overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          // Back Button in Header
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 2. Glassmorphic Form Container
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Phone Number Label
                          Text(
                            'Phone Number',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Phone Text Field (Figma: Max 10 digits, numeric only)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1.0,
                              ),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Enter your number',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_iphone_rounded,
                                  color: Color(0xFFFF7700), // Match saffron phone outline icon
                                  size: 22,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Get OTP Button
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
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final phone = _phoneController.text.trim();
                                      if (phone.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter your phone number'),
                                          ),
                                        );
                                        return;
                                      }
                                      if (phone.length != 10) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Phone number must be exactly 10 digits'),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        Map<String, dynamic> response;
                                        try {
                                          response = await ApiService.sendOtp(phone);
                                        } catch (e) {
                                          if (e.toString().contains('not registered') || e.toString().contains('sign up')) {
                                            response = await ApiService.registerUser(name: 'Devotee', contact: phone);
                                          } else {
                                            rethrow;
                                          }
                                        }
                                        final otp = response['Data']?['dev_mode_otp']?.toString();

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'OTP sent successfully on your mobile number.',
                                                style: GoogleFonts.outfit(color: Colors.white),
                                              ),
                                              backgroundColor: const Color(0xFFFF7A00),
                                            ),
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OtpVerificationScreen(
                                                phoneNumber: phone,
                                                initialOtp: otp,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                error.toString().replaceAll('Exception: ', ''),
                                                style: GoogleFonts.outfit(color: Colors.white),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    },
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
                                      'Get Otp',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final registeredPhone = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                                if (registeredPhone != null && context.mounted) {
                                  _phoneController.text = registeredPhone;
                                }
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFF7A00),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
    ),);
  }
}
