import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  String _gender = 'Male';
  String _profilePic = '';
  String? _localImagePath;
  bool _removedPhoto = false;
  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadInitialData();
    _recoverLostCameraImage();
  }

  Future<String?> _copyToPersistentFile(String srcPath) async {
    try {
      final src = File(srcPath);
      if (!await src.exists()) return null;
      final dir = await getApplicationDocumentsDirectory();
      final outPath = '${dir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final copied = await src.copy(outPath);
      return copied.path;
    } catch (_) {
      return srcPath;
    }
  }

  Future<void> _recoverLostCameraImage() async {
    try {
      final picker = ImagePicker();
      final response = await picker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file != null) {
        final safePath = await _copyToPersistentFile(file.path);
        if (safePath != null && mounted) {
          setState(() {
            _localImagePath = safePath;
            _removedPhoto = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGender = prefs.getString('user_gender') ?? 'Male';
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _gender = ['Male', 'Female', 'Other'].contains(savedGender) ? savedGender : 'Male';
      _profilePic = prefs.getString('profile_pic') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      // Wait for bottom sheet dismissal & free Flutter image cache before opening Android Camera
      await Future.delayed(const Duration(milliseconds: 180));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 72,
        preferredCameraDevice: CameraDevice.front,
        requestFullMetadata: false,
      );
      if (picked != null) {
        final safePath = await _copyToPersistentFile(picked.path);
        if (safePath != null && mounted) {
          setState(() {
            _localImagePath = safePath;
            _removedPhoto = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to pick image: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _showImageSourcePopup() {
    final hasPhoto = _getProfilePicProvider() != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D5C8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Update Profile Photo',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImageFromSource(ImageSource.camera);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE2BC)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF7700), size: 30),
                            const SizedBox(height: 8),
                            Text(
                              'Camera',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImageFromSource(ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE2BC)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_rounded, color: Color(0xFFFF7700), size: 30),
                            const SizedBox(height: 8),
                            Text(
                              'Browse Gallery',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _localImagePath = null;
                        _profilePic = '';
                        _removedPhoto = true;
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    label: Text(
                      'Remove Photo',
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfilePicProvider() {
    if (_removedPhoto) return null;
    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      return FileImage(File(_localImagePath!));
    }
    if (_profilePic.trim().isEmpty) return null;
    if (_profilePic.startsWith('/') || _profilePic.startsWith('file://')) {
      final local = _profilePic.replaceFirst('file://', '');
      if (File(local).existsSync()) {
        return FileImage(File(local));
      }
      return null;
    }
    final url = ApiService.resolveImageUrl(_profilePic);
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      String savedProfilePic = _removedPhoto ? '' : _profilePic;

      if (token.isNotEmpty) {
        try {
          final serverRes = await ApiService.updateProfile(
            token,
            name: name,
            email: email,
            phone: phone,
            bio: '',
            gender: _gender,
            profilePicFile: _localImagePath != null ? File(_localImagePath!) : null,
          );
          if (!_removedPhoto &&
              serverRes['profile_pic'] != null &&
              serverRes['profile_pic'].toString().isNotEmpty) {
            savedProfilePic = serverRes['profile_pic'].toString();
          }
        } catch (apiErr) {
          debugPrint('[EditProfile] Server update error: $apiErr');
        }
      }

      if (_localImagePath != null && savedProfilePic == _profilePic) {
        savedProfilePic = _localImagePath!;
      }

      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_gender', _gender);
      await prefs.setString('profile_pic', savedProfilePic);

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
    final avatarProvider = _getProfilePicProvider();

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
              // Avatar Picker with Default User Icon (NO stock photo!)
              GestureDetector(
                onTap: _showImageSourcePopup,
                child: Stack(
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
                      child: ClipOval(
                        child: Container(
                          width: 108,
                          height: 108,
                          color: Colors.white,
                          child: _buildSafeAvatarWidget(avatarProvider),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
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
                isRequired: true,
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
                isRequired: true,
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

              // Gender Selector (Clean White Dropdown!)
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: 'Gender',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
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
                    dropdownColor: Colors.white,
                    iconEnabledColor: const Color(0xFFFF7700),
                    borderRadius: BorderRadius.circular(16),
                    style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontSize: 14, fontWeight: FontWeight.w600),
                    items: ['Male', 'Female', 'Other'].map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text(
                          g,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2E2A36),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _gender = val);
                    },
                  ),
                ),
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

  Widget _buildSafeAvatarWidget(ImageProvider? provider) {
    const defaultIcon = Center(
      child: Icon(
        Icons.person_rounded,
        size: 54,
        color: Color(0xFFFF7700),
      ),
    );
    if (_removedPhoto) return defaultIcon;
    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      return Image.file(
        File(_localImagePath!),
        width: 108,
        height: 108,
        fit: BoxFit.cover,
        cacheWidth: 360,
        errorBuilder: (_, __, ___) => defaultIcon,
      );
    }
    if (provider is NetworkImage) {
      return Image.network(
        provider.url,
        width: 108,
        height: 108,
        fit: BoxFit.cover,
        cacheWidth: 360,
        errorBuilder: (_, __, ___) => defaultIcon,
      );
    }
    if (provider is FileImage) {
      return Image.file(
        provider.file,
        width: 108,
        height: 108,
        fit: BoxFit.cover,
        cacheWidth: 360,
        errorBuilder: (_, __, ___) => defaultIcon,
      );
    }
    return defaultIcon;
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : const [],
          ),
        ),
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
