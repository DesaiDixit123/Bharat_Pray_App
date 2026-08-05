import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password updated successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFF7700),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Preferences',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your password regularly to protect your account and devotional progress.',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),

              // Current Password
              _buildPasswordField(
                label: 'Current Password',
                hint: 'Enter current password',
                controller: _currentPasswordController,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Current password is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password
              _buildPasswordField(
                label: 'New Password',
                hint: 'Enter new password (min. 6 chars)',
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (val) {
                  if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm New Password
              _buildPasswordField(
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Update Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF7700), size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade600, size: 20),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
