import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'add_member_screen.dart'; // To access ContactItem
import 'start_yatra_overview_screen.dart';

class LocationBadgeStyle {
  final Color backgroundColor;
  final Color textColor;
  LocationBadgeStyle(this.backgroundColor, this.textColor);
}

class SetStartLocationScreen extends StatefulWidget {
  final List<ContactItem> selectedContacts;
  final String selectedYatra;
  final String groupName;
  final String distance;
  final String steps;
  final String duration;
  final String imageAsset;
  final bool isFromCreateGroup;

  const SetStartLocationScreen({
    super.key,
    required this.selectedContacts,
    this.selectedYatra = 'Somnath Temple',
    this.groupName = 'Somnath Yatra Group',
    this.distance = '450 KM',
    this.steps = '1,08,000 Steps',
    this.duration = '5 Days',
    this.imageAsset = 'assets/images/somnath_temple_new.png',
    this.isFromCreateGroup = false,
  });

  @override
  State<SetStartLocationScreen> createState() => _SetStartLocationScreenState();
}

class _SetStartLocationScreenState extends State<SetStartLocationScreen> {
  static const String _backSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''';

  // Info SVG provided by the user
  static const String _infoSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 0C5.37281 0 0 5.37281 0 12C0 18.6272 5.37281 24 12 24C18.6272 24 24 18.6272 24 12C24 5.37281 18.6272 0 12 0ZM12.4509 5.80641C13.2877 5.80641 13.9762 6.49453 13.9762 7.33172C13.9762 8.16891 13.2881 8.87531 12.4509 8.87531C11.6137 8.87531 10.9073 8.18719 10.9073 7.33172C10.9073 6.47625 11.5955 5.80641 12.4509 5.80641ZM14.4042 12.8742C13.9763 15.0506 13.493 18.1936 11.8744 18.1936C8.86125 18.1936 9.43781 11.4047 10.2005 9.7125C10.6655 8.68969 12.9717 9.00562 13.1578 10.1962C12.3394 11.2008 11.9114 14.8458 12.6745 15.0136C12.9722 15.0694 13.4372 14.1023 13.6791 12.7261C13.7348 12.4284 14.4787 12.503 14.4047 12.8747L14.4042 12.8742Z" fill="#C8A882"/>
</svg>''';

  // Get location badge style based on city name
  LocationBadgeStyle _getBadgeStyle(String location) {
    switch (location) {
      case 'Surat, Gujarat':
        return LocationBadgeStyle(const Color(0xFFE8E5F7), const Color(0xFF7A68D6)); // Pastel Purple
      case 'Vapi, Gujarat':
        return LocationBadgeStyle(const Color(0xFFE5F1FD), const Color(0xFF4A90E2)); // Pastel Blue
      case 'Bharuch, Gujarat':
        return LocationBadgeStyle(const Color(0xFFE0F7FA), const Color(0xFF00ACC1)); // Pastel Cyan
      case 'Ahemdabad, Gujarat':
        return LocationBadgeStyle(const Color(0xFFFCE4EC), const Color(0xFFD81B60)); // Pastel Pink
      case 'Amareli, Gujarat':
        return LocationBadgeStyle(const Color(0xFFE8F5E9), const Color(0xFF43A047)); // Pastel Green
      case 'Vadodara, Gujarat':
        return LocationBadgeStyle(const Color(0xFFFFEBEE), const Color(0xFFE53935)); // Pastel Red
      case 'Rajkot, Gujarat':
        return LocationBadgeStyle(const Color(0xFFE0F2F1), const Color(0xFF00897B)); // Pastel Teal
      case 'Jamnagar, Gujarat':
        return LocationBadgeStyle(const Color(0xFFFFF8E1), const Color(0xFFFFB300)); // Pastel Amber
      case 'Bhavnagar, Gujarat':
        return LocationBadgeStyle(const Color(0xFFE8EAF6), const Color(0xFF3949AB)); // Pastel Indigo
      case 'Anand, Gujarat':
        return LocationBadgeStyle(const Color(0xFFF3E5F5), const Color(0xFF8E24AA)); // Pastel Violet
      case 'Nadiad, Gujarat':
        return LocationBadgeStyle(const Color(0xFFF1F8E9), const Color(0xFF7CB342)); // Pastel Lime
      default:
        return LocationBadgeStyle(const Color(0xFFFFF3E0), const Color(0xFFFB8C00)); // Fallback
    }
  }

  // Map member names to locations to match mockup
  String _getContactLocation(String name) {
    if (name.contains('Mehul')) return 'Surat, Gujarat';
    if (name.contains('Amit')) return 'Vapi, Gujarat';
    if (name.contains('Ketan')) return 'Bharuch, Gujarat';
    if (name.contains('Pooja')) return 'Ahemdabad, Gujarat';
    if (name.contains('Hitakshi')) return 'Amareli, Gujarat';
    if (name.contains('Pratiksha')) return 'Vadodara, Gujarat';
    if (name.contains('Rahul')) return 'Rajkot, Gujarat';
    if (name.contains('Neha')) return 'Jamnagar, Gujarat';
    if (name.contains('Omik')) return 'Bhavnagar, Gujarat';
    if (name.contains('Ankit')) return 'Anand, Gujarat';
    if (name.contains('Daval')) return 'Nadiad, Gujarat';
    return 'Surat, Gujarat'; // Fallback
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left back arrow button
          Positioned(
            left: 20,
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
          // Screen Title & Subtitle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Set Start Location',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Distance: 450KM',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A6C58),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      width: 293,
      height: 71,
      margin: const EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Tan rounded box (38x38) with border-radius 10px holding the SVG info icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E2), // Soft cream/tan background matching mockup
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.string(
                _infoSvg,
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Each member starts from their own location. Steps & distance will be tracked separately.',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: const Color(0xFF8A6C58),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ContactItem contact, int index) {
    final String location = _getContactLocation(contact.name);
    final LocationBadgeStyle badgeStyle = _getBadgeStyle(location);
    
    // Toggles stats between 450KM / 1,08,000 steps and 750KM / 2,00,000 steps
    final String distance = index % 2 == 0 ? '450KM' : '750KM';
    final String steps = index % 2 == 0 ? '1,08,000' : '2,00,000';

    return Container(
      width: 353,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Symmetrical rounded corners
        border: Border.all(color: const Color(0xFFC8A882), width: 1.0), // Gold border matching notice box
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Avatar image exactly 50x50
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                contact.avatarUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Row 1: Name and Location Badge (badge is aligned to the right edge)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        contact.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF7A00),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeStyle.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          location,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: badgeStyle.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Row 2: Distance and Steps Column alignment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Distance Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distance to Destination',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFC8A882),
                            ),
                          ),
                          Text(
                            distance,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF7A00),
                            ),
                          ),
                        ],
                      ),
                      // Est. Steps Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Est. Steps',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFC8A882),
                            ),
                          ),
                          Text(
                            steps,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF7A00),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGroupButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StartYatraOverviewScreen(
                title: widget.selectedYatra,
                distance: widget.distance,
                steps: widget.steps,
                duration: widget.duration,
                sangha: widget.groupName,
                imageAsset: widget.imageAsset,
                isFromCreateGroup: widget.isFromCreateGroup,
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
          'Create Group',
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 15),
            _buildNoticeBox(),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.selectedContacts.length,
                itemBuilder: (context, index) {
                  return _buildMemberCard(widget.selectedContacts[index], index);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: _buildCreateGroupButton(),
            ),
          ],
        ),
      ),
    );
  }
}
