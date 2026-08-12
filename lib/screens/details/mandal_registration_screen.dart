import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'registration_success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final TextEditingController _mandalNameController = TextEditingController(text: "Shree Ganesh Yuva Mandal");
  final TextEditingController _leaderNameController = TextEditingController(text: "Rohit Sharma");
  final TextEditingController _mobileController = TextEditingController(text: "+91 98765 43210");
  final TextEditingController _addressController = TextEditingController(text: "123, Swaminarayan Nagar, Nikol, Ahmedabad");

  String? _selectedCategory = "Ganesh";
  String? _selectedFestival;

  final List<String> _categories = ["Ganesh", "Devi", "Krishna", "Shiv", "Hanuman"];
  final List<String> _festivals = [
    "Ganesh Chaturthi 2026",
    "Navratri 2026",
    "Krishna Janmashtami 2026",
    "Diwali 2026",
  ];

  @override
  void initState() {
    super.initState();
    // Match initial festival if provided and valid
    if (widget.initialFestival != null) {
      final matched = _festivals.firstWhere(
        (f) => f.toLowerCase().contains(widget.initialFestival!.toLowerCase()) ||
               widget.initialFestival!.toLowerCase().contains(f.toLowerCase()),
        orElse: () => "",
      );
      if (matched.isNotEmpty) {
        _selectedFestival = matched;
      }
    }
    _selectedFestival ??= _festivals.first;
  }

  @override
  void dispose() {
    _mandalNameController.dispose();
    _leaderNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
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
                        imageAsset: "assets/images/new_year_card.png",
                        buttonText: "Upload Logo",
                      ),
                      const SizedBox(height: 16),

                      // 2. Cover Image Upload Section
                      _buildUploadSection(
                        label: "Cover Image",
                        imageAsset: "assets/images/diwali_card.png",
                        buttonText: "Upload Cover",
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
                        hint: "Enter mobile number",
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Address*"),
                      _buildTextField(
                        controller: _addressController,
                        hint: "Enter address",
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Select God Category*"),
                      _buildDropdownField(
                        value: _selectedCategory,
                        hint: "Select Category",
                        items: _categories,
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Select Festival*"),
                      _buildDropdownField(
                        value: _selectedFestival,
                        hint: "Select Festival",
                        items: _festivals,
                        onChanged: (val) => setState(() => _selectedFestival = val),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Sticky Submit Button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildSubmitButton(),
              ),
            ],
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

  Widget _buildUploadSection({
    required String label,
    required String imageAsset,
    required String buttonText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Row(
          children: [
            // Thumbnail container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFFFF1E5),
                    child: const Icon(Icons.image_rounded, color: Color(0xFFB56E28)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Upload button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Upload feature coming soon!", style: GoogleFonts.outfit()),
                      backgroundColor: const Color(0xFF2E2A36),
                    ),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E5A2A),
                      ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF2E2A36),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return "This field is required";
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

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: Colors.white,
      hint: Text(
        hint,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFFC8A882).withValues(alpha: 0.6),
        ),
      ),
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF2E2A36),
      ),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8A882), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFC8A882)),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
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
          if (_formKey.currentState!.validate()) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_mandal_leader', true);

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
}
