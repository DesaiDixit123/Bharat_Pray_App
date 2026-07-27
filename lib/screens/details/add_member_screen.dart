import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/door_open_page_route.dart';
import 'set_start_location_screen.dart';

class ContactItem {
  final String name;
  final String phone;
  final String avatarUrl;
  bool isSelected;

  ContactItem({
    required this.name,
    required this.phone,
    required this.avatarUrl,
    this.isSelected = false,
  });
}

class AddMemberScreen extends StatefulWidget {
  final String selectedYatra;
  final String groupName;
  final String distance;
  final String steps;
  final String duration;
  final String imageAsset;

  const AddMemberScreen({
    super.key,
    this.selectedYatra = 'Somnath Temple',
    this.groupName = 'Somnath Yatra Group',
    this.distance = '450 KM',
    this.steps = '1,08,000 Steps',
    this.duration = '5 Days',
    this.imageAsset = 'assets/images/somnath_temple_new.png',
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Master contact list matching mockup exactly
  late final List<ContactItem> _contacts;

  // List to maintain selected contacts in selection order
  List<ContactItem> _selectedContacts = [];

  static const String _backSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''';

  static const String _searchSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z" stroke="#C8A882" stroke-width="1.33333"/>
<path d="M21 20.9999L16.65 16.6499" stroke="#C8A882" stroke-width="1.33333"/>
</svg>''';

  // Green tick SVG provided by the user
  static const String _tickSvg = '''<svg width="12" height="9" viewBox="0 0 12 9" fill="none" xmlns="http://www.w3.org/2000/svg">
<mask id="path-1-inside-1_283_2424" fill="white">
<path fill-rule="evenodd" clip-rule="evenodd" d="M3.42628 7.94622L0.304899 4.60536C0.0998236 4.38448 -0.00954859 4.09145 0.000654866 3.79022C0.0108583 3.48899 0.139809 3.20402 0.35936 2.99753C0.580279 2.7922 0.873493 2.68267 1.17492 2.69288C1.47635 2.70308 1.76148 2.83219 1.96801 3.05199L4.3757 5.62876L8.18721 2.06843C8.22135 2.03591 8.25711 2.00665 8.2945 1.97901L10.0869 0.30452C10.3078 0.0995478 10.6009 -0.00968126 10.9022 0.000674541C11.2034 0.0110303 11.4883 0.14013 11.6947 0.359794C11.9 0.580714 12.0096 0.873927 11.9993 1.17536C11.9891 1.47678 11.86 1.76192 11.6402 1.96844L6.16644 7.08296L6.16075 7.07646L4.26678 8.84606L3.42628 7.94622Z"/>
</mask>
<path fill-rule="evenodd" clip-rule="evenodd" d="M3.42628 7.94622L0.304899 4.60536C0.0998236 4.38448 -0.00954859 4.09145 0.000654866 3.79022C0.0108583 3.48899 0.139809 3.20402 0.35936 2.99753C0.580279 2.7922 0.873493 2.68267 1.17492 2.69288C1.47635 2.70308 1.76148 2.83219 1.96801 3.05199L4.3757 5.62876L8.18721 2.06843C8.22135 2.03591 8.25711 2.00665 8.2945 1.97901L10.0869 0.30452C10.3078 0.0995478 10.6009 -0.00968126 10.9022 0.000674541C11.2034 0.0110303 11.4883 0.14013 11.6947 0.359794C11.9 0.580714 12.0096 0.873927 11.9993 1.17536C11.9891 1.47678 11.86 1.76192 11.6402 1.96844L6.16644 7.08296L6.16075 7.07646L4.26678 8.84606L3.42628 7.94622Z" fill="#2E7D32"/>
<path d="M3.42628 7.94622L21.2437 -8.69623L21.2415 -8.69862L3.42628 7.94622ZM0.304899 4.60536L-17.5624 21.1942L-17.5364 21.2222L-17.5103 21.2502L0.304899 4.60536ZM0.35936 2.99753L-16.2387 -14.8612L-16.2918 -14.8119L-16.3445 -14.7623L0.35936 2.99753ZM1.96801 3.05199L19.7825 -13.5936L19.7593 -13.6185L19.7359 -13.6433L1.96801 3.05199ZM4.3757 5.62876L-13.4388 22.2743L3.20428 40.0861L21.0186 23.4458L4.3757 5.62876ZM8.18721 2.06843L24.8301 19.8854L24.9163 19.8049L25.0017 19.7236L8.18721 2.06843ZM8.2945 1.97901L22.7863 21.5856L23.914 20.7521L24.9387 19.7948L8.2945 1.97901ZM10.0869 0.30452L-6.49324 -17.5709L-6.52535 -17.5411L-6.55734 -17.5112L10.0869 0.30452ZM11.6947 0.359794L29.5534 -16.2383L29.5085 -16.2867L29.4633 -16.3348L11.6947 0.359794ZM11.6402 1.96844L28.2856 19.7831L28.3106 19.7598L28.3355 19.7364L11.6402 1.96844ZM6.16644 7.08296L-12.1816 23.1386L4.40641 42.0949L22.8118 24.8976L6.16644 7.08296ZM6.16075 7.07646L24.5087 -8.97913L7.92102 -27.9352L-10.4844 -10.7385L6.16075 7.07646ZM4.26678 8.84606L-13.5506 25.4885L3.09431 43.3085L20.9119 26.661L4.26678 8.84606ZM3.42628 7.94622L21.2415 -8.69862L18.1201 -12.0395L0.304899 4.60536L-17.5103 21.2502L-14.3889 24.5911L3.42628 7.94622ZM0.304899 4.60536L18.1722 -11.9835C22.3482 -7.48561 24.5754 -1.51844 24.3676 4.61559L0.000654866 3.79022L-24.3663 2.96484C-24.5945 9.70133 -22.1486 16.2546 -17.5624 21.1942L0.304899 4.60536ZM0.000654866 3.79022L24.3676 4.61559C24.1599 10.7496 21.534 16.5524 17.0632 20.7574L0.35936 2.99753L-16.3445 -14.7623C-21.2544 -10.1444 -24.1381 -3.77165 -24.3663 2.96484L0.000654866 3.79022ZM0.35936 2.99753L16.9575 20.8563C12.4588 25.0373 6.48804 27.2677 0.349965 27.0599L1.17492 2.69288L1.99988 -21.6741C-4.74105 -21.9023 -11.2983 -19.4529 -16.2387 -14.8612L0.35936 2.99753ZM1.17492 2.69288L0.349965 27.0599C-5.78812 26.8521 -11.5944 24.223 -15.7999 19.7472L1.96801 3.05199L19.7359 -13.6433C15.1173 -18.5586 8.74082 -21.4459 1.99988 -21.6741L1.17492 2.69288ZM1.96801 3.05199L-15.8465 19.6976L-13.4388 22.2743L4.3757 5.62876L22.1902 -11.0168L19.7825 -13.5936L1.96801 3.05199ZM4.3757 5.62876L21.0186 23.4458L24.8301 19.8854L8.18721 2.06843L-8.45567 -15.7486L-12.2672 -12.1882L4.3757 5.62876ZM8.18721 2.06843L25.0017 19.7236C24.1625 20.5228 23.3906 21.139 22.7863 21.5856L8.2945 1.97901L-6.19732 -17.6276C-6.87636 -17.1257 -7.71983 -16.4509 -8.62724 -15.5867L8.18721 2.06843ZM8.2945 1.97901L24.9387 19.7948L26.7311 18.1203L10.0869 0.30452L-6.55734 -17.5112L-8.3497 -15.8367L8.2945 1.97901ZM10.0869 0.30452L26.667 18.1799C22.167 22.3539 16.1985 24.5781 10.0645 24.3672L10.9022 0.000674541L11.7399 -24.3659C5.00335 -24.5975 -1.55127 -22.1548 -6.49324 -17.5709L10.0869 0.30452ZM10.9022 0.000674541L10.0645 24.3672C3.93041 24.1564 -1.87116 21.5274 -6.07386 17.0544L11.6947 0.359794L29.4633 -16.3348C24.8478 -21.2472 18.4764 -24.1343 11.7399 -24.3659L10.9022 0.000674541ZM11.6947 0.359794L-6.16403 16.9579C-10.3451 12.4593 -12.5755 6.48847 -12.3676 0.350399L11.9993 1.17536L36.3663 2.00031C36.5946 -4.74062 34.1452 -11.2978 29.5534 -16.2383L11.6947 0.359794ZM11.9993 1.17536L-12.3676 0.350399C-12.1598 -5.78765 -9.53079 -11.5939 -5.05501 -15.7995L11.6402 1.96844L28.3355 19.7364C33.2509 15.1178 36.1381 8.74122 36.3663 2.00031L11.9993 1.17536ZM11.6402 1.96844L-5.00513 -15.8462L-10.4789 -10.7317L6.16644 7.08296L22.8118 24.8976L28.2856 19.7831L11.6402 1.96844ZM6.16644 7.08296L24.5144 -8.97263L24.5087 -8.97913L6.16075 7.07646L-12.1872 23.132L-12.1816 23.1386L6.16644 7.08296ZM6.16075 7.07646L-10.4844 -10.7385L-12.3783 -8.96887L4.26678 8.84606L20.9119 26.661L22.8058 24.8914L6.16075 7.07646ZM4.26678 8.84606L22.0842 -7.7964L21.2437 -8.69623L3.42628 7.94622L-14.3911 24.5887L-13.5506 25.4885L4.26678 8.84606ZM3.42628 7.94622L21.2415 -8.69862L18.1201 -12.0395L0.304899 4.60536L-17.5103 21.2502L-14.3889 24.5911L3.42628 7.94622ZM0.304899 4.60536L18.1722 -11.9835C22.3482 -7.48561 24.5754 -1.51844 24.3676 4.61559L0.000654866 3.79022L-24.3663 2.96484C-24.5945 9.70133 -22.1486 16.2546 -17.5624 21.1942L0.304899 4.60536ZM0.000654866 3.79022L24.3676 4.61559C24.1599 10.7496 21.534 16.5524 17.0632 20.7574L0.35936 2.99753L-16.3445 -14.7623C-21.2544 -10.1444 -24.1381 -3.77165 -24.3663 2.96484L0.000654866 3.79022ZM0.35936 2.99753L16.9575 20.8563C12.4588 25.0373 6.48804 27.2677 0.349965 27.0599L1.17492 2.69288L1.99988 -21.6741C-4.74105 -21.9023 -11.2983 -19.4529 -16.2387 -14.8612L0.35936 2.99753ZM1.17492 2.69288L0.349965 27.0599C-5.78812 26.8521 -11.5944 24.223 -15.7999 19.7472L1.96801 3.05199L19.7359 -13.6433C15.1173 -18.5586 8.74082 -21.4459 1.99988 -21.6741L1.17492 2.69288ZM1.96801 3.05199L-15.8465 19.6976L-13.4388 22.2743L4.3757 5.62876L22.1902 -11.0168L19.7825 -13.5936L1.96801 3.05199ZM4.3757 5.62876L21.0186 23.4458L24.8301 19.8854L8.18721 2.06843L-8.45567 -15.7486L-12.2672 -12.1882L4.3757 5.62876ZM8.18721 2.06843L25.0017 19.7236C24.1625 20.5228 23.3906 21.139 22.7863 21.5856L8.2945 1.97901L-6.19732 -17.6276C-6.87636 -17.1257 -7.71983 -16.4509 -8.62724 -15.5867L8.18721 2.06843ZM8.2945 1.97901L24.9387 19.7948L26.7311 18.1203L10.0869 0.30452L-6.55734 -17.5112L-8.3497 -15.8367L8.2945 1.97901ZM10.0869 0.30452L26.667 18.1799C22.167 22.3539 16.1985 24.5781 10.0645 24.3672L10.9022 0.000674541L11.7399 -24.3659C5.00335 -24.5975 -1.55127 -22.1548 -6.49324 -17.5709L10.0869 0.30452ZM10.9022 0.000674541L10.0645 24.3672C3.93041 24.1564 -1.87116 21.5274 -6.07386 17.0544L11.6947 0.359794L29.4633 -16.3348C24.8478 -21.2472 18.4764 -24.1343 11.7399 -24.3659L10.9022 0.000674541ZM11.6947 0.359794L-6.16403 16.9579C-10.3451 12.4593 -12.5755 6.48847 -12.3676 0.350399L11.9993 1.17536L36.3663 2.00031C36.5946 -4.74062 34.1452 -11.2978 29.5534 -16.2383L11.6947 0.359794ZM11.9993 1.17536L-12.3676 0.350399C-12.1598 -5.78765 -9.53079 -11.5939 -5.05501 -15.7995L11.6402 1.96844L28.3355 19.7364C33.2509 15.1178 36.1381 8.74122 36.3663 2.00031L11.9993 1.17536ZM11.6402 1.96844L-5.00513 -15.8462L-10.4789 -10.7317L6.16644 7.08296L22.8118 24.8976L28.2856 19.7831L11.6402 1.96844ZM6.16644 7.08296L24.5144 -8.97263L24.5087 -8.97913L6.16075 7.07646L-12.1872 23.132L-12.1816 23.1386L6.16644 7.08296ZM6.16075 7.07646L-10.4844 -10.7385L-12.3783 -8.96887L4.26678 8.84606L20.9119 26.661L22.8058 24.8914L6.16075 7.07646ZM4.26678 8.84606L22.0842 -7.7964L21.2437 -8.69623L3.42628 7.94622L-14.3911 24.5887L-13.5506 25.4885L4.26678 8.84606Z" fill="#2E7D32" mask="url(#path-1-inside-1_283_2424)"/>
</svg>''';

  static const String _plusSvg = '''<svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6 0V12M0 6H12" stroke="#FF7A00" stroke-width="2" stroke-linecap="round"/>
</svg>''';

  static const String _crossSvg = '''<svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11 1L1 11M1 1L11 11" stroke="#2E2A36" stroke-width="1.5" stroke-linecap="round"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    // Setup initial data based on screenshots
    _contacts = [
      // Suggested items (first 6)
      ContactItem(
        name: 'Rahul J.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=60',
      ),
      ContactItem(
        name: 'Ketan P.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=60',
        isSelected: true, // Selected by default in suggested
      ),
      ContactItem(
        name: 'Neha P.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=60',
      ),
      ContactItem(
        name: 'Omik N.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=60',
      ),
      ContactItem(
        name: 'Ankit S.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop&q=60',
      ),
      ContactItem(
        name: 'Daval S.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100&auto=format&fit=crop&q=60',
      ),
      // Bottom Selected list items (pre-selected but not visible in suggested initially)
      ContactItem(
        name: 'Mehul R.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=100&auto=format&fit=crop&q=60',
        isSelected: false,
      ),
      ContactItem(
        name: 'Amit K.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&auto=format&fit=crop&q=60',
        isSelected: false,
      ),
      ContactItem(
        name: 'Pooja H.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=60',
        isSelected: false,
      ),
      ContactItem(
        name: 'Hitakshi J.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&auto=format&fit=crop&q=60',
        isSelected: false,
      ),
      ContactItem(
        name: 'Pratiksha S.',
        phone: '+91 9876543210',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop&q=60',
        isSelected: false, // Make it false to match "Selected (5)" exactly
      ),
    ];

    // Initialize the selected contacts list based on the isSelected flag from the master list.
    // This ensures the initial state is correct.
    _selectedContacts = _contacts.where((c) => c.isSelected).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                width: 40,
                height: 40,
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
            'Add Member',
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

  Widget _buildSearchBar() {
    return Container(
      height: 43,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(89),
        border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
      ),
      child: TextField(
        controller: _searchController,
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFF2E2A36),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by name or Phone number',
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFFC8A882).withValues(alpha: 0.6),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: SvgPicture.string(
              _searchSvg,
              width: 18,
              height: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF994700),
      ),
    );
  }

  // Helper widget to build the exact 30x30 green checkmark circular button
  Widget _buildGreenTickButton() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
      ),
      child: Center(
        child: SvgPicture.string(
          _tickSvg,
          width: 12,
          height: 9,
        ),
      ),
    );
  }

  // Helper widget to build the exact 30x30 orange plus circular button
  Widget _buildOrangePlusButton() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
      ),
      child: Center(
        child: SvgPicture.string(
          _plusSvg,
          width: 12,
          height: 12,
        ),
      ),
    );
  }

  // Helper widget to build the exact cross button with size 16.7x16.7
  Widget _buildCrossButton() {
    return SvgPicture.string(
      _crossSvg,
      width: 16.7,
      height: 16.7,
    );
  }

  // A single list item widget for contact row (50px height)
  Widget _buildContactRow(ContactItem contact, {required bool isSuggested}) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Row(
        children: [
          // User Avatar (CircleAvatar)
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF3E5D7),
            child: ClipOval(
              child: Image.network(
                contact.avatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF994700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contact.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF7A00),
                  ),
                ),
                Text(
                  contact.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Action Button on the right
          GestureDetector(
            onTap: () {
              setState(() {
                // Toggle selection state
                contact.isSelected = !contact.isSelected;

                // Sync the _selectedContacts list
                if (contact.isSelected) {
                  // Add if not already in the list to avoid duplicates
                  if (!_selectedContacts.any((c) => c.name == contact.name)) {
                    _selectedContacts.add(contact);
                  }
                } else {
                  // Remove from selected list
                  _selectedContacts.removeWhere((c) => c.name == contact.name);
                }
              });
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: isSuggested // The button appearance depends on whether it's in the suggested list
                  ? (contact.isSelected ? _buildGreenTickButton() : _buildOrangePlusButton())
                  : _buildCrossButton(),
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
          Navigator.of(context).push(
            DoorOpenPageRoute(
              page: SetStartLocationScreen(
                  selectedContacts: _selectedContacts,
                  selectedYatra: widget.selectedYatra,
                  groupName: widget.groupName,
                  distance: widget.distance,
                  steps: widget.steps,
                  duration: widget.duration,
                  imageAsset: widget.imageAsset,
                  isFromCreateGroup: true,
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
    // Filter contacts based on search query. If empty, show first 6 suggested.
    // If search query is entered, search all contacts in the master list.
    List<ContactItem> suggestedList = _searchQuery.isEmpty
        ? _contacts.sublist(0, 6)
        : _contacts.where((c) =>
            c.name.toLowerCase().contains(_searchQuery) ||
            c.phone.contains(_searchQuery)).toList();

    // Ensure the isSelected state is always correct by checking against the _selectedContacts list
    for (var contact in _contacts) {
      contact.isSelected = _selectedContacts.any((c) => c.name == contact.name);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false, // Let the Column handle padding at the bottom
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      // 1. Header (Back button + Title)
                      _buildHeader(),

                      const SizedBox(height: 15),

                      // 2. Search Bar
                      _buildSearchBar(),

                      const SizedBox(height: 20),

                      // 3. Suggested Section Header
                      _buildSectionHeader('Suggested'),

                      const SizedBox(height: 12),

                      // 4. Suggested List Column
                      ...suggestedList.map((contact) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildContactRow(contact, isSuggested: true),
                      )),

                      const SizedBox(height: 15),

                      // 5. Selected Section Header
                      _buildSectionHeader('Selected (${_selectedContacts.length})'),

                      const SizedBox(height: 12),

                      // 6. Selected List Column
                      if (_selectedContacts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No members selected yet',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                            ),
                          ),
                        )
                      else
                        // Use ListView.builder for dynamic lists for better performance
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedContacts.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildContactRow(_selectedContacts[index], isSuggested: false),
                            );
                          },
                        ),

                      const SizedBox(height: 20),

                      // 7. Next Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: _buildNextButton(),
                      ),
                    ],
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
