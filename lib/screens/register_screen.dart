import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'otp_verification_screen.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialPhoneNumber;

  const RegisterScreen({super.key, this.initialPhoneNumber});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _profilePicFile;
  bool _isLoading = false;

  // Toggle: 'phone' or 'email'
  String _contactType = 'phone';

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      final val = widget.initialPhoneNumber!;
      if (val.contains('@')) {
        _emailController.text = val;
        _contactType = 'email';
      } else {
        _phoneController.text = val;
        _contactType = 'phone';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Show bottom sheet to pick source ───────────────────────────
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Profile Photo',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how you want to add your photo',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Divider(
              color: Colors.white.withValues(alpha: 0.07),
              height: 1,
              indent: 20,
              endIndent: 20,
            ),
            const SizedBox(height: 8),
            // Camera option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFFF7A00),
                  size: 20,
                ),
              ),
              title: Text(
                'Camera',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'Take a new photo',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            // Gallery option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFFFF7A00),
                  size: 20,
                ),
              ),
              title: Text(
                'Gallery',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'Choose from your photos',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _profilePicFile = File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _profilePicFile = File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar('Gallery error: $e');
    }
  }

  // ── Register ──────────────────────────────────────────────────────────
  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }

    String contact;
    if (_contactType == 'phone') {
      if (phone.isEmpty) {
        _showSnackBar('Please enter your phone number');
        return;
      }
      if (phone.length != 10) {
        _showSnackBar('Phone number must be exactly 10 digits');
        return;
      }
      contact = phone;
    } else {
      if (email.isEmpty || !email.contains('@')) {
        _showSnackBar('Please enter a valid email address');
        return;
      }
      contact = email;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.registerUser(
        name: name,
        contact: contact,
        profilePicFile: _profilePicFile,
      );
      final otp = response['Data']?['dev_mode_otp']?.toString();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            _contactType == 'phone'
                ? 'OTP sent successfully on your mobile number.'
                : 'OTP sent successfully on your email.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF7A00),
        ));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: contact,
              initialOtp: otp,
            ),
          ),
        );
      }
    } catch (error) {
      _showSnackBar(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: Colors.redAccent,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF1E102F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
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

            // Glassmorphic form
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
                            top: 36, left: 28, right: 28, bottom: 32),
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
                            // Title
                            Center(
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Profile picture picker
                            Center(
                              child: GestureDetector(
                                onTap: _showImageSourcePicker,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.08),
                                      backgroundImage: _profilePicFile != null
                                          ? FileImage(_profilePicFile!)
                                          : null,
                                      child: _profilePicFile == null
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 40,
                                              color:
                                                  Colors.white.withValues(alpha: 0.4),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF7A00),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Phone / Email toggle ──────────────────
                            Container(
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleBtn(
                                    label: 'Phone Number',
                                    icon: Icons.phone_iphone_rounded,
                                    selected: _contactType == 'phone',
                                    onTap: () => setState(() => _contactType = 'phone'),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildToggleBtn(
                                    label: 'Email',
                                    icon: Icons.alternate_email_rounded,
                                    selected: _contactType == 'email',
                                    onTap: () => setState(() => _contactType = 'email'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Full Name field
                            _fieldLabel('Full Name'),
                            const SizedBox(height: 8),
                            _inputField(
                              controller: _nameController,
                              hint: 'Enter your full name',
                              icon: Icons.person_outline_rounded,
                              iconColor: Colors.white.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),

                            // Phone OR Email field (conditional)
                            if (_contactType == 'phone') ...[
                              _fieldLabel('Phone Number'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _phoneController,
                                hint: 'Enter 10-digit number',
                                icon: Icons.phone_iphone_rounded,
                                iconColor: const Color(0xFFFF7A00),
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ] else ...[
                              _fieldLabel('Email Address'),
                              const SizedBox(height: 8),
                              _inputField(
                                controller: _emailController,
                                hint: 'name@example.com',
                                icon: Icons.mail_outline_rounded,
                                iconColor: const Color(0xFFFF7A00),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                            const SizedBox(height: 28),

                            // Register button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7A00),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                onPressed:
                                    _isLoading ? null : _registerUser,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0))
                                    : Text(
                                        'Register',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            // Already have account
                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an account? ',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Login',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF7A00),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
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

  // ── Helper widgets ────────────────────────────────────────────────────

  Widget _buildToggleBtn({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFF7A00)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
