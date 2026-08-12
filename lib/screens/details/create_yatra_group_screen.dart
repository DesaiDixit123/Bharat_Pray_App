import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'add_member_screen.dart';

class CreateYatraGroupScreen extends StatefulWidget {
  const CreateYatraGroupScreen({super.key});

  @override
  State<CreateYatraGroupScreen> createState() => _CreateYatraGroupScreenState();
}

class _CreateYatraGroupScreenState extends State<CreateYatraGroupScreen> {
  String? _selectedYatra;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  static const String _backSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''';

  static const String _groupLogoSvg = '''<svg width="90" height="90" viewBox="0 0 90 90" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M77.008 48.0443H70.0478C70.7572 49.9867 71.1448 52.0829 71.1448 54.2677V80.5734C71.1448 81.4843 70.9863 82.3586 70.6978 83.1718H82.2046C86.503 83.1718 89.9998 79.6748 89.9998 75.3766V61.0362C90 53.8725 84.1718 48.0443 77.008 48.0443ZM18.8552 54.2679C18.8552 52.0829 19.2428 49.9869 19.9522 48.0445H12.992C5.8282 48.0445 0 53.8727 0 61.0365V75.3769C0 79.6751 3.49682 83.1721 7.79519 83.1721H19.3022C19.006 82.3378 18.8548 81.4589 18.8552 80.5735V54.2679ZM52.956 41.2759H37.044C29.8802 41.2759 24.052 47.1041 24.052 54.2679V80.5735C24.052 82.0084 25.2153 83.1719 26.6504 83.1719H63.3496C64.7847 83.1719 65.948 82.0086 65.948 80.5735V54.2679C65.948 47.1041 60.1198 41.2759 52.956 41.2759ZM45 6.82715C36.3846 6.82715 29.3755 13.8362 29.3755 22.4518C29.3755 28.2957 32.6009 33.3995 37.3642 36.0791C39.6236 37.35 42.2283 38.0763 45 38.0763C47.7717 38.0763 50.3764 37.35 52.6358 36.0791C57.3992 33.3995 60.6245 28.2955 60.6245 22.4518C60.6245 13.8364 53.6154 6.82715 45 6.82715ZM17.5637 21.3905C11.1204 21.3905 5.87865 26.6322 5.87865 33.0755C5.87865 39.5188 11.1204 44.7606 17.5637 44.7606C19.1471 44.7619 20.714 44.4396 22.1683 43.8135C24.6127 42.7611 26.6282 40.8981 27.8754 38.5646C28.7789 36.8762 29.2507 34.9905 29.2488 33.0755C29.2488 26.6324 24.007 21.3905 17.5637 21.3905ZM72.4363 21.3905C65.993 21.3905 60.7512 26.6322 60.7512 33.0755C60.7493 34.9905 61.2211 36.8762 62.1246 38.5646C63.3718 40.8983 65.3873 42.7612 67.8317 43.8135C69.286 44.4396 70.8529 44.7619 72.4363 44.7606C78.8795 44.7606 84.1213 39.5188 84.1213 33.0755C84.1213 26.6322 78.8795 21.3905 72.4363 21.3905Z" fill="#FF7A00"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    _groupNameController.text = 'Somnath Yatra Group';
    _descriptionController.text = 'Let’s walk together towards Somnath🙏';
    _selectedYatra = 'Somnath Temple';
    _distanceController.text = '450 KM';
    _stepsController.text = '1,08,000 Steps';
  }

  String _resolveImageAsset(String? yatraName) {
    switch (yatraName) {
      case 'Dwarkadhish Temple':
        return 'assets/images/dwarka_temple.jpg';
      case 'Somnath Temple':
      default:
        return 'assets/images/somnath_temple_new.png';
    }
  }

  String _resolveDuration(String? yatraName) {
    switch (yatraName) {
      case 'Dwarkadhish Temple':
        return '4 Days';
      case 'Somnath Temple':
      default:
        return '5 Days';
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _distanceController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left back arrow button
          Positioned(
            left: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
              width: 48,
              height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                ),
                child: Center(
                  child: SvgPicture.string(
                    _backSvg,
                    width: 15,
                    height: 15,
                  ),
                ),
              ),
            ),
          ),
          // Screen Title
          Text(
            'Create Yatra Group',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupIcon() {
    return Center(
      child: Container(
        width: 158,
        height: 158,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
        ),
        child: Center(
          child: SvgPicture.string(
            _groupLogoSvg,
            width: 90,
            height: 90,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required Widget labelWidget,
    required Widget fieldWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        labelWidget,
        const SizedBox(height: 8),
        fieldWidget, // Render naturally to prevent overflows
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF2E2A36),
      ),
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
      dropdownColor: Colors.white, // Style dropdown menu background to solid white
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

  Widget _buildDescriptionField() {
    return SizedBox(
      width: double.infinity,
      height: 130, // Compact height to fit perfectly on a single screen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Description (Optional)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: const Color(0xFF994700),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _descriptionController,
              maxLines: null,
              minLines: 3,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF2E2A36),
              ),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFFC8A882).withValues(alpha: 0.6),
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8A882), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          final selectedYatra = _selectedYatra ?? 'Somnath Temple';
          final groupName = _groupNameController.text.trim();
          final distance = _distanceController.text.trim();
          final steps = _stepsController.text.trim();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddMemberScreen(
                selectedYatra: selectedYatra,
                groupName: groupName.isEmpty ? 'Somnath Yatra Group' : groupName,
                distance: distance.isEmpty ? '450 KM' : distance,
                steps: steps.isEmpty ? '1,08,000 Steps' : steps,
                duration: _resolveDuration(selectedYatra),
                imageAsset: _resolveImageAsset(selectedYatra),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A00),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.5),
        ),
        child: Text(
          'Next',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Allow scrolling when keyboard is open or content overflows
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        // 1. Header (Back button + Title)
                        _buildHeader(),
                        
                        const SizedBox(height: 10),
                        
                        // 2. Group Icon Circle
                        _buildGroupIcon(),
                        
                        const SizedBox(height: 25),
                        
                        // 3. Group Name Text Box
                        _buildInputField(
                          labelWidget: Text(
                            'Group Name',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: const Color(0xFF994700),
                            ),
                          ),
                          fieldWidget: _buildTextField(
                            controller: _groupNameController,
                            hint: 'Name',
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 4. Select Yatra / Temple Dropdown
                        _buildInputField(
                          labelWidget: Text(
                            'Select Yatra / Temple',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: const Color(0xFF994700),
                            ),
                          ),
                          fieldWidget: _buildDropdownField(
                            value: _selectedYatra,
                            hint: 'Select Yatra',
                            items: const ['Somnath Temple', 'Dwarkadhish Temple'],
                            onChanged: (val) {
                              setState(() {
                                _selectedYatra = val;
                                if (val == 'Somnath Temple') {
                                  _distanceController.text = '450 KM';
                                  _stepsController.text = '1,08,000 Steps';
                                } else if (val == 'Dwarkadhish Temple') {
                                  _distanceController.text = '220 KM';
                                  _stepsController.text = '80,000 Steps';
                                }
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 5. Total Distance Row (Now editable text field)
                        _buildInputField(
                          labelWidget: Text(
                            'Total Distance',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: const Color(0xFF994700),
                            ),
                          ),
                          fieldWidget: _buildTextField(
                            controller: _distanceController,
                            hint: 'Enter distance (e.g. 000 KM)',
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 6. Total Steps (approx) Row (Now editable text field)
                        _buildInputField(
                          labelWidget: Text.rich(
                            TextSpan(
                              text: 'Total Steps ',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                color: const Color(0xFF994700),
                              ),
                              children: [
                                TextSpan(
                                  text: '(approx)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    height: 2.4,
                                    color: const Color(0xFF994700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          fieldWidget: _buildTextField(
                            controller: _stepsController,
                            hint: 'Enter steps (e.g. 000 Steps)',
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 7. Group Description Field
                        _buildDescriptionField(),
                        
                        // Spacer pushes Next button to bottom of screen
                        const Spacer(),
                        
                        const SizedBox(height: 15),
                        
                        // 8. Next Button
                        _buildNextButton(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
