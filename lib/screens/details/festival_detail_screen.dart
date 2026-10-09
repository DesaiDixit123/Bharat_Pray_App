import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/utsav_service.dart';
import 'mandal_registration_screen.dart';
import 'mandal_status_tab_content.dart';
import 'mandal_profile_screen.dart';

class FestivalDetailScreen extends StatefulWidget {
  final String festivalName;
  final String imageUrl;
  final bool isMandal;
  final Map<String, dynamic>? festivalData;

  const FestivalDetailScreen({
    super.key,
    required this.festivalName,
    required this.imageUrl,
    this.isMandal = false,
    this.festivalData,
  });

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  Map<String, dynamic>? _festivalData;
  Map<String, dynamic>? _myRegistration;

  // Checklist states (original view)
  final Map<String, bool> _checklist = {
    "Clay Diyas (मिट्टी के दीये)": false,
    "Marigold Flowers (गेंदे के फूल)": false,
    "Gangajal & Ghee (गंगाजल और घी)": false,
    "Sweet Offerings (नैवेद्य/मिठाई)": false,
    "Incense & Camphor (धूप और कपूर)": false,
  };

  bool _isDiyaLit = false;

  final List<String> _vidhiSteps = [
    "Step 1: Clean the prayer altar and place a red cloth on it.",
    "Step 2: Install the idols/photos of Lord Ganesha and Goddess Lakshmi.",
    "Step 3: Light the central Ghee Diya and apply vermilion tilak to the deities.",
    "Step 4: Offer fresh marigold flowers, sweets (laddoos), and fruits.",
    "Step 5: Perform the Aarti together with your family and distribute prasad.",
  ];

  @override
  void initState() {
    super.initState();
    _festivalData = widget.festivalData;
    _loadFestivalDetails();
    _loadMyRegistration();
  }

  Future<void> _loadMyRegistration() async {
    final reg = await UtsavService.getMyMandalRegistration();
    if (mounted) {
      setState(() {
        _myRegistration = reg;
      });
    }
  }

  Future<void> _loadFestivalDetails() async {
    final fest = await UtsavService.getFestivalByName(widget.festivalName);
    if (fest != null && mounted) {
      setState(() {
        _festivalData = fest;
      });
    }
  }

  String _getFestivalTiming() {
    if (_festivalData?['timing'] != null && _festivalData!['timing'].toString().trim().isNotEmpty) {
      return _festivalData!['timing'].toString();
    }
    if (_festivalData?['timings'] != null && _festivalData!['timings'].toString().trim().isNotEmpty) {
      return _festivalData!['timings'].toString();
    }
    final name = widget.festivalName.toLowerCase();
    if (name.contains('navratri') || name.contains('garba')) {
      return 'Daily Raas Garba & Aarti: 7:00 PM - 12:00 AM';
    } else if (name.contains('diwali') || name.contains('deepotsav')) {
      return 'Deepotsav & Lakshmi Aarti: 6:00 PM - 11:00 PM';
    }
    return 'Daily Darshan & Aarti: 6:00 AM - 11:30 PM';
  }

  Map<String, String> _getMandalDates() {
    final regDate = _festivalData?['formattedRegDate'] ??
        (_festivalData?['regStartDate'] != null && _festivalData?['regEndDate'] != null
            ? '${_festivalData!['regStartDate']} - ${_festivalData!['regEndDate']}'
            : '-');
    final festDate = _festivalData?['formattedDate'] ??
        (_festivalData?['startDate'] != null && _festivalData?['endDate'] != null
            ? '${_festivalData!['startDate']} - ${_festivalData!['endDate']}'
            : '-');
    final status = _festivalData?['status'] ?? 'Upcoming';
    final participants = '${_festivalData?['participantCount'] ?? 0} Mandals';
    final votes = '${_festivalData?['totalVotes'] ?? 0} Devotees';

    return {
      'Registration Window': regDate.toString(),
      'Mahotsav Dates': festDate.toString(),
      'Daily Event Timing': _getFestivalTiming(),
      'Current Stage': status.toString(),
      'Participants': participants,
      'Total Votes': votes,
    };
  }

  String _getMandalDatesText() {
    if (_festivalData != null && _festivalData!['formattedDate'] != null) {
      return _festivalData!['formattedDate'].toString();
    }
    if (_festivalData != null && _festivalData!['startDate'] != null) {
      final start = _festivalData!['startDate'];
      final end = _festivalData!['endDate'];
      return end != null ? '$start - $end' : '$start';
    }
    return '';
  }

  String _getMandalDesc() {
    if (_festivalData != null && _festivalData!['description'] != null) {
      return _festivalData!['description'].toString();
    }
    if (_festivalData != null && _festivalData!['slogan'] != null) {
      return _festivalData!['slogan'].toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMandal) {
      return _buildMandalLayout(context);
    }
    return _buildOriginalLayout(context);
  }

  // ── Mandal Registration Layout ─────────────────────────────────────────────

  Widget _buildMandalLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: _FestivalBackButton(
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Festival Details',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // 1. Cover Card
                      _buildMandalCoverCard(),
                      const SizedBox(height: 20),

                      // 2. Dates Subtitle
                      Text(
                        _getMandalDatesText(),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. Status Badge
                      _buildMandalBadge(),
                      const SizedBox(height: 10),

                      // Timing Info
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFFF7700)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getFestivalTiming(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8E5A2A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Description
                      Text(
                        _getMandalDesc(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Rewards section if available
                      if (_festivalData?['rewards'] != null) ...[
                        _buildRewardsSection(),
                        const SizedBox(height: 25),
                      ],

                      // 5. Divider
                      Container(
                        height: 1,
                        color: const Color(0xFFEFE6DB),
                      ),
                      const SizedBox(height: 25),

                      // 6. Important Dates
                      _buildImportantDatesSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // 7. Register Mandal Button (Bottom Sticky Layout)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildRegisterButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMandalCoverCard() {
    final displayName = widget.festivalName;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Text(
                displayName.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandalBadge() {
    if (_myRegistration != null) {
      final regFest = (_myRegistration!['festival'] ?? _myRegistration!['festivalName'] ?? _myRegistration!['category'])?.toString().toLowerCase() ?? '';
      final currFest = widget.festivalName.toLowerCase();
      final bool isMatch = regFest.isNotEmpty && currFest.isNotEmpty &&
          (currFest.contains(regFest) || regFest.contains(currFest) ||
           (currFest.contains('navratri') && regFest.contains('navratri')) ||
           (currFest.contains('diwali') && regFest.contains('diwali')));

      if (isMatch) {
        final st = (_myRegistration!['status'] ?? 'Pending').toString().toLowerCase();
        if (st == 'approved') {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF27AE60)),
                const SizedBox(width: 4),
                Text(
                  'Mandal Approved',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF27AE60),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        } else if (st == 'rejected') {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFC62828)),
                const SizedBox(width: 4),
                Text(
                  'Registration Rejected',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFE65100)),
                const SizedBox(width: 4),
                Text(
                  'Verification in Progress ⏳',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    final status = _festivalData?['registrationStatus']?.toString() ??
        UtsavService.computeRegistrationStatus(
          _festivalData?['regStartDate']?.toString(),
          _festivalData?['regEndDate']?.toString(),
          'coming_soon',
          festivalName: widget.festivalName,
        );
    final isOpen = status == 'open';
    final isClosed = status == 'closed';

    String text = 'Coming Soon';
    Color bgColor = const Color(0xFFFFF3E0);
    Color textColor = const Color(0xFFE65100);

    if (isOpen) {
      text = 'Registrations Open';
      bgColor = const Color(0xFFE8F8EE);
      textColor = const Color(0xFF27AE60);
    } else if (isClosed) {
      text = 'Registrations Closed';
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildImportantDatesSection() {
    final dates = _getMandalDates();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important Dates',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 16),
        ...dates.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      e.value,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF2E2A36),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRewardsSection() {
    final rewards = _festivalData?['rewards'] as Map<String, dynamic>? ?? {};
    final first = _cleanReward(rewards['first']?.toString() ?? 'Grand Winner Trophy & Golden Certificate');
    final second = _cleanReward(rewards['second']?.toString() ?? 'Silver Shield & Runner-up Certificate');
    final third = _cleanReward(rewards['third']?.toString() ?? 'Bronze Medal & Excellence Certificate');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF7700), size: 22),
            const SizedBox(width: 8),
            Text(
              'Honors & Certificates',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Official recognition & certified awards for participating mandals.',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 14),
        _buildRewardRow("🏆 1st Winner", first, const Color(0xFFFFA000)),
        _buildRewardRow("🥈 2nd Runner-up", second, const Color(0xFF78909C)),
        _buildRewardRow("🥉 3rd Place", third, const Color(0xFF8D6E63)),
        _buildRewardRow("📜 All Mandals", "Official Digital Certificate of Participation", const Color(0xFF2E7D32)),
      ],
    );
  }

  String _cleanReward(String text) {
    // Strip any cash or rupee amounts like ₹1,50,000 or Rs. 1000
    final cleaned = text.replaceAll(RegExp(r'(?:₹|Rs\.?)\s*[\d,]+\s*'), '').trim();
    return cleaned.isNotEmpty ? cleaned : text;
  }

  Widget _buildRewardRow(String title, String desc, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    // 1. If user already has a registration
    if (_myRegistration != null) {
      final regStatus = (_myRegistration!['status'] ?? 'Pending').toString().toLowerCase();
      final mandalName = (_myRegistration!['mandalName'] ?? 'Your Mandal').toString();
      final logo = _myRegistration!['logo']?.toString();
      final cover = _myRegistration!['cover']?.toString();

      if (regStatus == 'approved') {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.verified_rounded, size: 20),
            label: Text(
              'Go to Mandal Profile',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MandalProfileScreen(
                    mandalName: mandalName,
                    isOwnProfile: true,
                    avatarUrl: logo,
                    coverUrl: cover,
                  ),
                ),
              );
            },
          ),
        );
      } else if (regStatus == 'rejected') {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.error_outline_rounded, size: 20),
            label: Text(
              'Application Rejected • View Status',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MandalStatusTabContent(isStandalone: true),
                ),
              );
              _loadMyRegistration();
            },
          ),
        );
      } else {
        // Pending approval!
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.hourglass_top_rounded, size: 20),
            label: Text(
              'Application Pending Approval',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MandalStatusTabContent(isStandalone: true),
                ),
              );
              _loadMyRegistration();
            },
          ),
        );
      }
    }

    // 2. Default registration flow when no registration exists
    final status = _festivalData?['registrationStatus']?.toString() ??
        UtsavService.computeRegistrationStatus(
          _festivalData?['regStartDate']?.toString(),
          _festivalData?['regEndDate']?.toString(),
          'coming_soon',
          festivalName: widget.festivalName,
        );
    final isOpen = status == 'open';
    final isClosed = status == 'closed';

    String btnText = 'Register Mandal';
    if (isClosed) {
      btnText = 'Registrations Closed';
    } else if (!isOpen) {
      btnText = 'Registration Starts Soon';
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isOpen ? const Color(0xFFFF7700) : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: isOpen
            ? () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MandalRegistrationScreen(
                      initialFestival: widget.festivalName,
                    ),
                  ),
                );
                _loadMyRegistration();
              }
            : null,
        child: Text(
          btnText,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Original Puja Prep/Lit Diya Layout ──────────────────────────────────────

  Widget _buildOriginalLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image header banner
              Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: Image.asset(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            const Color(0xFFFFE8D6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 16,
                    child: _FestivalBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      widget.festivalName,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. Virtual Diya widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFEFE6DB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Lit Virtual Diya (दीप प्रज्वलन)",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDiyaLit = !_isDiyaLit;
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/diya.png',
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                            if (_isDiyaLit)
                              Positioned(
                                top: 18,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.2),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [Colors.white, Colors.yellow, Colors.orangeAccent, Colors.transparent],
                                        stops: [0.1, 0.4, 0.8, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withValues(alpha: 0.8),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isDiyaLit ? "May the light of wisdom guide you! 🌟" : "Click to Light Diya",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isDiyaLit ? const Color(0xFFFF7700) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 2. Puja Preparation Checklist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Puja Preparation Checklist (सामग्री)",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEFE6DB)),
                      ),
                      child: Column(
                        children: _checklist.keys.map((item) {
                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              item,
                              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                            ),
                            value: _checklist[item],
                            activeColor: const Color(0xFFFF7700),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _checklist[item] = val;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3. Step-by-Step Puja Vidhi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Puja Vidhi Steps (पूजा विधि)",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._vidhiSteps.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEFE6DB)),
                            ),
                            child: Text(
                              step,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Back Button ─────────────────────────────────────────────────────────────

class _FestivalBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FestivalBackButton({required this.onTap});

  static const String _backArrowSvg =
      '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
