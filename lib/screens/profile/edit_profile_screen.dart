import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  String _gender = 'Male';
  String _profilePic = '';
  String? _localImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _bioController.text = prefs.getString('user_bio') ?? 'Devoted to daily Darshan & Spiritual Journey 🙏';
      _gender = prefs.getString('user_gender') ?? 'Male';
      _profilePic = prefs.getString('profile_pic') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _localImagePath = picked.path);
    }
  }

  String _getProfilePicUrl() {
    if (_localImagePath != null) return _localImagePath!;
    if (_profilePic.isEmpty) {
      return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=60';
    }
    if (_profilePic.startsWith('http')) return _profilePic;
    final baseDomain = ApiService.baseUrl.replaceAll('/user', '');
    return '$baseDomain/uploads/$_profilePic';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();

      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_bio', bio);
      await prefs.setString('user_gender', _gender);

      if (_localImagePath != null) {
        await prefs.setString('profile_pic', _localImagePath!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFFF7700),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Edit Profile',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Save',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF7700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Picker
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF7700), width: 3.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.2),
                          blurRadius: 16,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundImage: _localImagePath != null
                          ? FileImage(File(_localImagePath!)) as ImageProvider
                          : NetworkImage(_getProfilePicUrl()),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap camera icon to change picture',
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF2E2A36).withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 28),

              // Full Name
              _buildInputField(
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              _buildInputField(
                label: 'Mobile Number',
                hint: 'Enter your mobile number',
                icon: Icons.phone_android_rounded,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Mobile Number is required' : null,
              ),
              const SizedBox(height: 16),

              // Email Address
              _buildInputField(
                label: 'Email Address',
                hint: 'Enter your email address',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Gender Selector
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Gender', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gender,
                    isExpanded: true,
                    style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontSize: 14, fontWeight: FontWeight.w600),
                    items: ['Male', 'Female', 'Other'].map((g) {
                      return DropdownMenuItem(value: g, child: Text(g));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _gender = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Spiritual Bio
              _buildInputField(
                label: 'Spiritual Bio / Guidance Quote',
                hint: 'Share your spiritual devotion or favorite mantra...',
                icon: Icons.auto_awesome_rounded,
                controller: _bioController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Update Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFFFF7700), size: 20),
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
