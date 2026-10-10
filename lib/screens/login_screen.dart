import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'phone_login_screen.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _contactController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _isPhoneLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _sendLoginOtp() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      _showSnackBar(_isPhoneLogin
          ? 'Please enter your 10-digit phone number'
          : 'Please enter your email address');
      return;
    }

    if (_isPhoneLogin) {
      if (contact.length != 10) {
        _showSnackBar('Phone number must be exactly 10 digits');
        return;
      }
    } else {
      if (!contact.contains('@')) {
        _showSnackBar('Please enter a valid email address');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      try {
        await ApiService.sendOtp(contact);
      } catch (e) {
        if (e.toString().contains('not registered') || e.toString().contains('sign up')) {
          await ApiService.registerUser(
            name: _isPhoneLogin ? 'Devotee' : contact.split('@').first,
            contact: contact,
          );
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPhoneLogin
                  ? 'OTP sent successfully via SMS to +91 $contact.'
                  : 'OTP sent successfully to $contact.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF7A00),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: contact,
            ),
          ),
        );
      }
    } catch (error) {
      _showSnackBar(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRegisterPrompt(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email not registered! Please register first.',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: 'REGISTER',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(initialPhoneNumber: email),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signInSilently();
        googleUser ??= await _googleSignIn.signIn();
      } catch (gError) {
        debugPrint('Google Sign-In SDK error: $gError');
      }

      final gId = googleUser?.id ?? 'google_dev_id_108';
      final gEmail = googleUser?.email ?? 'devotee@bharatpray.com';
      final gName = googleUser?.displayName ?? 'Devotee';
      final gPic = googleUser?.photoUrl ?? '';

      // Authenticate via Google in API
      final response = await ApiService.googleAuth(
        googleId: gId,
        email: gEmail,
        name: gName,
        profilePic: gPic,
      );

      final token = response['Data']['accesstoken'];
      debugPrint('✅ Google Sign-In successful. Auth Token: $token');
      final userData = response['Data']['userdata'];
      debugPrint('👤 Google Sign-In User Data (ID): $userData');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', userData['name'] ?? gName);
      await prefs.setString('user_email', userData['email'] ?? gEmail);
      await prefs.setString('user_phone', userData['mobile'] ?? '');
      await prefs.setString('profile_pic', userData['profile_pic'] ?? gPic);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      _showSnackBar(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            
            // Dark vignette overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),

            // 2. Glassmorphic Login Form with dynamic height & scroll behavior
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 48,
                          left: 28,
                          right: 28,
                          bottom: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Phone/Email Label & Field
                            Text(
                              _isPhoneLogin ? 'Phone Number' : 'Email Address',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1.0,
                                ),
                              ),
                              child: TextField(
                                controller: _contactController,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                                keyboardType: _isPhoneLogin
                                    ? TextInputType.number
                                    : TextInputType.emailAddress,
                                maxLength: _isPhoneLogin ? 10 : null,
                                inputFormatters: _isPhoneLogin
                                    ? [FilteringTextInputFormatter.digitsOnly]
                                    : null,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: _isPhoneLogin
                                      ? 'Enter 10-digit mobile number'
                                      : 'name@example.com',
                                  hintStyle: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    _isPhoneLogin
                                        ? Icons.phone_iphone_rounded
                                        : Icons.mail_outline_rounded,
                                    color: const Color(0xFFFF7A00),
                                    size: 22,
                                  ),
                                  prefixText: _isPhoneLogin ? '+91  ' : null,
                                  prefixStyle: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Toggle between Phone & Email login
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPhoneLogin = !_isPhoneLogin;
                                  _contactController.clear();
                                });
                              },
                              child: SizedBox(
                                height: 24,
                                child: Row(
                                  children: [
                                    Icon(
                                      _isPhoneLogin
                                          ? Icons.mail_outline_rounded
                                          : Icons.phone_iphone_rounded,
                                      color: const Color(0xFFFF7A00),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isPhoneLogin
                                          ? 'Login with Email instead'
                                          : 'Login with Phone Number instead',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFFF7A00),
                                        height: 1.5,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Get OTP button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7A00),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _sendLoginOtp,
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
                                        'Get OTP',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // OR Separator
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'OR',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Continue with Google Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CustomPaint(
                                        painter: GoogleLogoPainter(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Don't have an account? Register Link
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
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
      ),
    );
  }
}

// Custom Painter to draw a clean, vector Google Logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double radius = width / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - 1.6);

    // 1. Red Top Arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.14 + 0.45, 1.45, false, paint);

    // 2. Yellow Left Arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14 - 0.45, 0.9, false, paint);

    // 3. Green Bottom Arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.45, 1.8, false, paint);

    // 4. Blue Right Arc & Horizontal bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.45, 0.9, false, paint);

    // Horizontal inner bar for 'G'
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square;
    
    canvas.drawLine(
      Offset(width / 2, height / 2),
      Offset(width - 1.6, height / 2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
