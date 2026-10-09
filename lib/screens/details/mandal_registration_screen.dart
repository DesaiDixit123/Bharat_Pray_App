import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_success_screen.dart';
import '../../services/utsav_service.dart';
import '../../services/api_service.dart';

class MandalMemberEntry {
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final bool isBharatPrayUser;

  MandalMemberEntry({
    required this.nameController,
    required this.mobileController,
    this.isBharatPrayUser = true,
  });

  void dispose() {
    nameController.dispose();
    mobileController.dispose();
  }
}

class MandalRegistrationScreen extends StatefulWidget {
  final String? initialFestival;

  const MandalRegistrationScreen({
    super.key,
    this.initialFestival,
  });

  @override
  State<MandalRegistrationScreen> createState() => _MandalRegistrationScreenState();
}

class _MandalRegistrationScreenState extends State<MandalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mandalNameController = TextEditingController();
  final TextEditingController _leaderNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final List<MandalMemberEntry> _memberEntries = [];

  final ImagePicker _picker = ImagePicker();
  File? _logoImage;
  File? _coverImage;

  String _festivalName = "Maha Navratri Garba Utsav 2026";

  @override
  void initState() {
    super.initState();
    if (widget.initialFestival != null && widget.initialFestival!.trim().isNotEmpty) {
      _festivalName = widget.initialFestival!.trim();
    } else {
      _loadUpcomingFestival();
    }
  }

  @override
  void dispose() {
    _mandalNameController.dispose();
    _leaderNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    for (final m in _memberEntries) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMemberFromContact({required String name, required String mobile}) {
    // Check if already added
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final exists = _memberEntries.any((m) {
      final existingClean = m.mobileController.text.replaceAll(RegExp(r'\D'), '');
      return existingClean == clean;
    });

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$name is already added to members list"),
          backgroundColor: const Color(0xFFE67E22),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _memberEntries.add(
        MandalMemberEntry(
          nameController: TextEditingController(text: name),
          mobileController: TextEditingController(text: mobile),
          isBharatPrayUser: true,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added $name as Mandal Committee Member"),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeMember(int index) {
    setState(() {
      final removed = _memberEntries.removeAt(index);
      removed.dispose();
    });
  }

  void _openContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MandalContactPickerSheet(
        festivalName: _festivalName,
        alreadyAddedMobiles: _memberEntries.map((m) => m.mobileController.text.trim()).toList(),
        onMemberSelected: (name, phone) {
          _addMemberFromContact(name: name, mobile: phone);
        },
      ),
    );
  }

  Future<void> _loadUpcomingFestival() async {
    final fest = await UtsavService.getUpcomingRegistrationFestivalName();
    if (mounted) {
      setState(() {
        _festivalName = fest;
      });
    }
  }


  // ─── SVG back arrow ────────────────────────────────────────────────────────

  static const String _backArrowSvg =
      '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: Center(
                child: SvgPicture.string(
                  _backArrowSvg,
                  width: 15,
                  height: 15,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Mandal Registration',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // 1. Mandal Logo Upload Section
                  _buildUploadSection(
                    label: "Mandal Logo",
                    buttonText: "Upload Logo",
                    isLogo: true,
                    selectedImage: _logoImage,
                  ),
                  const SizedBox(height: 16),

                  // 2. Cover Image Upload Section
                  _buildUploadSection(
                    label: "Cover Image",
                    buttonText: "Upload Cover",
                    isLogo: false,
                    selectedImage: _coverImage,
                  ),
                  const SizedBox(height: 16),

                  // 3. Form Input Fields
                  _buildLabel("Mandal Name*"),
                  _buildTextField(
                    controller: _mandalNameController,
                    hint: "Enter mandal name",
                  ),
                  const SizedBox(height: 14),

                  _buildLabel("Leader Name*"),
                  _buildTextField(
                    controller: _leaderNameController,
                    hint: "Enter leader name",
                  ),
                  const SizedBox(height: 14),

                  _buildLabel("Mobile Number*"),
                  _buildTextField(
                    controller: _mobileController,
                    hint: "Enter 10 digit mobile number",
                    keyboardType: TextInputType.phone,
                    isMobile: true,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel("Address*"),
                  _buildTextField(
                    controller: _addressController,
                    hint: "Enter address",
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel("Mandal Bio / Description"),
                  _buildTextField(
                    controller: _bioController,
                    hint: "Enter mandal bio or details (Aarti timings, seva, activities)",
                    maxLines: 3,
                    isRequired: false,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel("Festival"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration_rounded, color: Color(0xFFFF7700), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _festivalName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Committee Members Section (Dynamic Add Member)
                  _buildMembersSection(),
                  const SizedBox(height: 24),

                  // 5. Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Component Helpers ─────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2E2A36),
        ),
      ),
    );
  }

  Future<void> _showImagePickerPopup({required bool isLogo}) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFE6DB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8A882).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isLogo ? 'Upload Mandal Logo' : 'Upload Cover Image',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Take a photo or choose from gallery',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF7700), size: 20),
              ),
              title: Text(
                'Take Photo with Camera',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Color(0xFFEFE6DB), height: 1),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF7700), size: 20),
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source != null && mounted) {
      try {
        final XFile? picked = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (picked != null && mounted) {
          setState(() {
            if (isLogo) {
              _logoImage = File(picked.path);
            } else {
              _coverImage = File(picked.path);
            }
          });
        }
      } catch (e) {
        debugPrint("Error picking image: $e");
      }
    }
  }

  Widget _buildUploadSection({
    required String label,
    required String buttonText,
    required bool isLogo,
    required File? selectedImage,
  }) {
    final bool hasImage = selectedImage != null && selectedImage.existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Row(
          children: [
            // Thumbnail container — empty placeholder OR selected image preview
            GestureDetector(
              onTap: () => _showImagePickerPopup(isLogo: isLogo),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage ? const Color(0xFFFF7700) : const Color(0xFFC8A882),
                    width: 1.2,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFC8A882), size: 26),
              ),
            ),
            const SizedBox(width: 14),

            // Upload button
            Expanded(
              child: GestureDetector(
                onTap: () => _showImagePickerPopup(isLogo: isLogo),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasImage ? const Color(0xFFFF7700) : const Color(0xFFC8A882),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasImage ? Icons.check_circle_rounded : Icons.upload_rounded,
                          size: 18,
                          color: hasImage ? const Color(0xFFFF7700) : const Color(0xFF8E5A2A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasImage ? (isLogo ? "Change Logo" : "Change Cover") : buttonText,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasImage ? const Color(0xFFFF7700) : const Color(0xFF8E5A2A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    bool isMobile = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isMobile ? TextInputType.number : keyboardType,
      maxLines: maxLines,
      inputFormatters: isMobile
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF2E2A36),
      ),
      validator: (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return "This field is required";
        }
        if (isMobile && val != null && val.trim().length != 10) {
          return "Enter minimum 10 digit mobile number";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFFC8A882).withValues(alpha: 0.6),
        ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8A882), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7700),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          FocusScope.of(context).unfocus();
          if (_formKey.currentState!.validate()) {
            final List<Map<String, String>> membersList = [];
            for (final m in _memberEntries) {
              final name = m.nameController.text.trim();
              final mobile = m.mobileController.text.trim();
              if (name.isNotEmpty || mobile.isNotEmpty) {
                membersList.add({
                  'name': name,
                  'mobile': mobile,
                  'role': 'Committee Member',
                });
              }
            }

            await UtsavService.saveMandalRegistration(
              mandalName: _mandalNameController.text.trim(),
              leaderName: _leaderNameController.text.trim(),
              mobile: _mobileController.text.trim(),
              address: _addressController.text.trim(),
              category: _festivalName,
              festival: _festivalName,
              bio: _bioController.text.trim(),
              members: membersList,
              logoPath: _logoImage?.path,
              coverPath: _coverImage?.path,
              status: 'Pending',
            );

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistrationSuccessScreen(),
                ),
              );
            }
          }
        },
        child: Text(
          'Submit for Approval',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Dynamic Committee Members Section ─────────────────────────────────────

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Committee Members",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                Text(
                  "Add devotees who use BharatPray app",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: _openContactPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF7700), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contacts_rounded, size: 15, color: Color(0xFFFF7700)),
                    const SizedBox(width: 5),
                    Text(
                      "Add Member",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF7700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_memberEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.4), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add_rounded, color: Color(0xFFFF7700), size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  "No Members Added Yet",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Select devotee committee members from your contacts who use BharatPray app",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7700),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.contacts_rounded, size: 15),
                    label: Text(
                      "Select from Contacts",
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _openContactPicker,
                  ),
                ),
              ],
            ),
          )
        else
          ..._memberEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.7), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7700),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Member #${index + 1}",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF27AE60)),
                                const SizedBox(width: 3),
                                Text(
                                  "BharatPray User",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF27AE60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _removeMember(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name is editable by Leader
                  TextFormField(
                    controller: item.nameController,
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36)),
                    decoration: InputDecoration(
                      hintText: "Member Name (Editable)",
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFF9E9E9E), fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFFC8A882)),
                      helperText: "Leader can edit member name",
                      helperStyle: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.5), fontSize: 11),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5D5C5), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mobile number is locked/readOnly (verified from BharatPray)
                  TextFormField(
                    controller: item.mobileController,
                    readOnly: true,
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Member Mobile Number",
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFF9E9E9E), fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFFF7700)),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Locked",
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF7700)),
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      helperText: "Verified BharatPray number (cannot be changed)",
                      helperStyle: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.5), fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFFFBF6EF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5D5C5), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC8A882), width: 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─── Contact Picker Sheet for BharatPray Members & Invites ─────────────────────

class _MandalContactPickerSheet extends StatefulWidget {
  final String festivalName;
  final List<String> alreadyAddedMobiles;
  final Function(String name, String phone) onMemberSelected;

  const _MandalContactPickerSheet({
    required this.festivalName,
    required this.alreadyAddedMobiles,
    required this.onMemberSelected,
  });

  @override
  State<_MandalContactPickerSheet> createState() => _MandalContactPickerSheetState();
}

class _MandalContactPickerSheetState extends State<_MandalContactPickerSheet> {
  bool _isLoading = true;
  String _searchQuery = '';
  int _tabIndex = 0; // 0 = BharatPray Users, 1 = Invite Contacts

  List<Map<String, dynamic>> _registeredUsers = [];
  List<Map<String, dynamic>> _nonRegisteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadContactsAndSync();
  }

  Future<void> _loadContactsAndSync() async {
    setState(() => _isLoading = true);

    List<Map<String, String>> phoneContacts = [];
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final deviceContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        for (final c in deviceContacts) {
          final name = c.displayName.isNotEmpty
              ? c.displayName
              : '${c.name.first} ${c.name.last}'.trim();
          for (final p in c.phones) {
            final num = p.number.replaceAll(RegExp(r'\D'), '');
            if (num.isNotEmpty) {
              phoneContacts.add({
                'name': name.isNotEmpty ? name : 'Devotee',
                'phone': p.number.trim(),
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting contacts: $e');
    }

    // Default sample/fallback contacts for smooth user testing
    if (phoneContacts.isEmpty) {
      phoneContacts = [
        {'name': 'Ramesh Kumar (Committee)', 'phone': '9876543210'},
        {'name': 'Pooja Patel (Garba Lead)', 'phone': '9876543213'},
        {'name': 'Suresh Sharma', 'phone': '9876543211'},
        {'name': 'Anita Verma', 'phone': '9876543212'},
        {'name': 'Vikram Singh', 'phone': '9876543214'},
        {'name': 'Hardik Shah', 'phone': '9825012345'},
      ];
    }

    List<dynamic> regList = [];
    List<dynamic> nonRegList = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final res = await ApiService.syncContacts(token, contacts: phoneContacts);
      if (res['registeredUsers'] is List) regList = res['registeredUsers'];
      if (res['nonRegisteredUsers'] is List) nonRegList = res['nonRegisteredUsers'];
    } catch (_) {}

    if (regList.isNotEmpty || nonRegList.isNotEmpty) {
      _registeredUsers = regList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _nonRegisteredUsers = nonRegList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      // Graceful fallback for offline testing
      _registeredUsers = phoneContacts.take((phoneContacts.length / 2).ceil()).map((c) => {
        'name': c['name'] ?? 'Devotee',
        'phone': c['phone'] ?? '',
        'mobile': c['phone'] ?? '',
        'is_registered': true,
      }).toList();

      _nonRegisteredUsers = phoneContacts.skip((phoneContacts.length / 2).ceil()).map((c) => {
        'name': c['name'] ?? 'Devotee',
        'phone': c['phone'] ?? '',
        'mobile': c['phone'] ?? '',
        'is_registered': false,
      }).toList();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _inviteContact(Map<String, dynamic> contact) {
    final name = (contact['name'] ?? 'Devotee').toString();
    Share.share(
      "Namaste $name! 🙏 Join BharatPray app to participate with our Mandal in ${widget.festivalName}. Download BharatPray app now: https://bharatpray.com/download",
      subject: "Join our Mandal on BharatPray",
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    final filteredRegistered = _registeredUsers.where((u) {
      final n = (u['name'] ?? '').toString().toLowerCase();
      final p = (u['mobile'] ?? u['phone'] ?? '').toString().toLowerCase();
      return n.contains(query) || p.contains(query);
    }).toList();

    final filteredNonRegistered = _nonRegisteredUsers.where((u) {
      final n = (u['name'] ?? '').toString().toLowerCase();
      final p = (u['mobile'] ?? u['phone'] ?? '').toString().toLowerCase();
      return n.contains(query) || p.contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Committee Member",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    Text(
                      "Only registered BharatPray users can be added",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Search name or phone number...",
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFFF7700)),
                filled: true,
                fillColor: const Color(0xFFF9F5F0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tab Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EDE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _tabIndex == 0
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: _tabIndex == 0 ? const Color(0xFFFF7700) : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "BharatPray Users (${filteredRegistered.length})",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _tabIndex == 0 ? const Color(0xFFFF7700) : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tabIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _tabIndex == 1
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share_rounded,
                              size: 14,
                              color: _tabIndex == 1 ? const Color(0xFFFF7700) : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Invite Contacts (${filteredNonRegistered.length})",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _tabIndex == 1 ? const Color(0xFFFF7700) : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
                : _tabIndex == 0
                    ? _buildRegisteredTab(filteredRegistered)
                    : _buildInviteTab(filteredNonRegistered),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredTab(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                "No BharatPray Users Found",
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              ),
              const SizedBox(height: 6),
              Text(
                "Switch to 'Invite Contacts' tab to invite your devotee friends to download BharatPray!",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0E5D8)),
      itemBuilder: (context, index) {
        final u = users[index];
        final name = (u['name'] ?? 'Devotee').toString();
        final mobile = (u['mobile'] ?? u['phone'] ?? '').toString();
        final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');

        final isAdded = widget.alreadyAddedMobiles.any((m) {
          final existingClean = m.replaceAll(RegExp(r'\D'), '');
          return existingClean == cleanMobile;
        });

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBD6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF7700),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF27AE60)),
            ],
          ),
          subtitle: Text(
            mobile,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: isAdded
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Added ✓",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onMemberSelected(name, mobile);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "+ Add",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInviteTab(List<Map<String, dynamic>> contacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.contacts_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                "No Other Contacts",
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0E5D8)),
      itemBuilder: (context, index) {
        final c = contacts[index];
        final name = (c['name'] ?? 'Contact').toString();
        final mobile = (c['mobile'] ?? c['phone'] ?? '').toString();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E2A36),
            ),
          ),
          subtitle: Text(
            mobile,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF7700),
              side: const BorderSide(color: Color(0xFFFF7700)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.share_rounded, size: 13),
            label: Text(
              "Invite",
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _inviteContact(c),
          ),
        );
      },
    );
  }
}
