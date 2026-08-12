import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'festival_detail_screen.dart';
import 'mandal_status_tab_content.dart';
import 'live_darshan_dashboard_screen.dart';
import 'mandal_leaderboard_tab_content.dart';

// ─── Static fallback festival data ────────────────────────────────────────────

const List<Map<String, dynamic>> _kActiveFestivals = [
  {
    'name': 'Ganesh Chaturthi 2026',
    'startDate': '15 Sep 2026',
    'endDate': '25 Sep 2026',
    'imageUrl': 'assets/images/new_year_card.png',
    'description': "Let's celebrate the arrival of Bappa together.",
    'registrationStatus': 'open',
  },
  {
    'name': 'Navratri 2026',
    'startDate': '03 Oct 2026',
    'endDate': '12 Oct 2026',
    'imageUrl': 'assets/images/diwali_card.png',
    'description': 'Nine nights of devotion to Maa Durga.',
    'registrationStatus': 'open',
  },
];

const List<Map<String, dynamic>> _kUpcomingFestivals = [
  {
    'name': 'Krishna Janmashtami 2026',
    'startDate': '16 Aug 2026',
    'endDate': '17 Aug 2026',
    'imageUrl': 'assets/images/dhanteras_card.png',
    'description': 'Celebrate the birth of Lord Krishna.',
    'registrationStatus': 'coming_soon',
  },
  {
    'name': 'Diwali 2026',
    'startDate': '08 Nov 2026',
    'endDate': '08 Nov 2026',
    'imageUrl': 'assets/images/bhaiduj_card.png',
    'description': 'Festival of lights across India.',
    'registrationStatus': 'coming_soon',
  },
  {
    'name': 'Holi 2027',
    'startDate': '01 Mar 2027',
    'endDate': '02 Mar 2027',
    'imageUrl': 'assets/images/new_year_card.png',
    'description': 'The festival of colours and joy.',
    'registrationStatus': 'coming_soon',
  },
];

// Cover banners for the horizontal carousel
const List<Map<String, String>> _kCoverBanners = [
  {
    'title': 'Celebrate Festivals',
    'subtitle': 'Connect. Devotion. Win.',
    'tag': '1. Utsav',
    'imageUrl': 'assets/images/new_year_card.png',
  },
  {
    'title': 'Navratri 2026',
    'subtitle': 'Nine nights of divine devotion.',
    'tag': '2. Utsav',
    'imageUrl': 'assets/images/diwali_card.png',
  },
  {
    'title': 'Diwali 2026',
    'subtitle': 'Festival of lights & prosperity.',
    'tag': '3. Utsav',
    'imageUrl': 'assets/images/dhanteras_card.png',
  },
];

const String _kBackArrowSvg =
    '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
    '</svg>';


class FestivalsHomeTabContent extends StatefulWidget {
  const FestivalsHomeTabContent({super.key});

  @override
  State<FestivalsHomeTabContent> createState() =>
      _FestivalsHomeTabContentState();
}

class _FestivalsHomeTabContentState extends State<FestivalsHomeTabContent> {
  late final PageController _bannerController;
  int _bannerPage = 0;
  Timer? _bannerTimer;

  int _segment = 0;

  int _currentBottomTab = 0;

  List<Map<String, dynamic>> get _currentList =>
      _segment == 0 ? _kActiveFestivals : _kUpcomingFestivals;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.92);
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _bannerController.hasClients) {
        final next = (_bannerPage + 1) % _kCoverBanners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      body: Stack(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header with back button (size matches yatra flow) ────────
                _buildHeader(context),

                // ── Switch between Home, Live & Status tabs ───────────────────
                Expanded(
                  child: _buildTabBody(context),
                ),
              ],
            ),
          ),
          
          // ── Bottom Navigation Bar (Home & Live) ──────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }
  Widget _buildTabBody(BuildContext context) {
    switch (_currentBottomTab) {
      case 1:
        return const LiveDarshanDashboardScreen();
      case 2:
        return const MandalStatusTabContent();
      case 3:
        return const MandalLeaderboardTabContent();
      case 0:
      default:
        return _buildHomeTabBody(context);
    }
  }
  Widget _buildHomeTabBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Horizontal banner carousel ───────────────────────────────────
        const SizedBox(height: 14),
        _buildBannerCarousel(),
        const SizedBox(height: 16),

        // ── Segment control ──────────────────────────────────────────────
        _buildSegmentControl(),
        const SizedBox(height: 12),

        // ── Festival list ────────────────────────────────────────────────
        Expanded(
          child: _currentList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: _currentList.length,
                  itemBuilder: (context, index) =>
                      _buildFestivalCard(_currentList[index]),
                ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    String title = 'Utsav Vibes';
    if (_currentBottomTab == 1) {
      title = 'Live Darshan';
    } else if (_currentBottomTab == 2) {
      title = 'Registration Status';
    } else if (_currentBottomTab == 3) {
      title = 'Leaderboard';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back button — matching yatra flow size (40x40)
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
                    border: Border.all(
                        color: const Color(0xFFC8A882), width: 1.0),
                  ),
                  child: Center(
                    child: SvgPicture.string(
                      _kBackArrowSvg,
                      width: 15,
                      height: 15,
                    ),
                  ),
                ),
              ),
            ),
            // Title
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner Carousel ─────────────────────────────────────────────────────────

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _kCoverBanners.length,
            onPageChanged: (i) {
              setState(() => _bannerPage = i);
              _startBannerTimer();
            },
            itemBuilder: (_, i) => _buildBannerCard(_kCoverBanners[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_kCoverBanners.length, (i) {
            final active = i == _bannerPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF7700)
                    : const Color(0xFFFF7700).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBannerCard(Map<String, String> banner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FestivalDetailScreen(
              festivalName: banner['title']!,
              imageUrl: banner['imageUrl']!,
              isMandal: true,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(banner['imageUrl']!, fit: BoxFit.cover),
                // Gradient — same as bhajan banner
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xC31A1209), Color(0x8A5B2F0A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                // Tag pill
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      banner['tag']!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Title + subtitle
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner['title']!,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner['subtitle']!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Segment Control — same style as bhajan filter tabs ──────────────────────

  Widget _buildSegmentControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            _buildSegmentTab('Active', 0),
            const SizedBox(width: 8),
            _buildSegmentTab('Upcoming', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String label, int index) {
    final selected = _segment == index;
    return GestureDetector(
      onTap: () => setState(() => _segment = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7700) : const Color(0xFFFFEAD8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF8E5A2A),
            ),
          ),
        ),
      ),
    );
  }

  // ── Festival List Card — same style as bhajan _buildTrackCard ────────────────

  Widget _buildFestivalCard(Map<String, dynamic> festival) {
    final name = (festival['name'] ?? '') as String;
    final startDate = (festival['startDate'] ?? '') as String;
    final endDate = (festival['endDate'] ?? '') as String;
    final imageUrl = (festival['imageUrl'] ?? '') as String;
    final regStatus = (festival['registrationStatus'] ?? 'coming_soon') as String;
    final isOpen = regStatus == 'open';

    final isClickable = isOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isClickable
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FestivalDetailScreen(
                        festivalName: name,
                        imageUrl: imageUrl,
                        isMandal: true,
                      ),
                    ),
                  )
              : null,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildFestivalImage(imageUrl),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        endDate.isNotEmpty
                            ? '$startDate - $endDate'
                            : startDate,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF2E2A36)
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildStatusText(regStatus),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Arrow (Only visible if clickable)
                isClickable
                    ? const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFFFF8A1E),
                      )
                    : const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFestivalImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackThumb(),
      );
    }
    return _fallbackThumb();
  }

  Widget _fallbackThumb() {
    return Container(
      width: 54,
      height: 54,
      color: const Color(0xFFFFF1E5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.celebration_rounded,
        size: 22,
        color: Color(0xFFB56E28),
      ),
    );
  }

  Widget _buildStatusText(String regStatus) {
    final isActive = _segment == 0;
    final isOpen = regStatus == 'open';

    String text = 'Coming Soon';
    Color color = const Color(0xFF2E2A36).withValues(alpha: 0.45);

    if (isActive) {
      text = 'Active';
      color = const Color(0xFF27AE60);
    } else if (isOpen) {
      text = 'Registrations Open';
      color = const Color(0xFF27AE60);
    }

    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration_outlined,
              color: Color(0xFFFF7700), size: 48),
          const SizedBox(height: 16),
          Text(
            _segment == 0
                ? 'No active festivals right now.'
                : 'No upcoming festivals yet.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ──────────────────────────────────────────────────

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFC8A882).withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            iconAsset: 'assets/images/nav_home.svg',
            label: 'Home',
            isActive: _currentBottomTab == 0,
            onTap: () => setState(() => _currentBottomTab = 0),
          ),
          _buildBottomNavItem(
            iconData: Icons.sensors_rounded,
            label: 'Live',
            isActive: _currentBottomTab == 1,
            onTap: () => setState(() => _currentBottomTab = 1),
          ),
          _buildBottomNavItem(
            iconData: Icons.assignment_turned_in_rounded,
            label: 'Status',
            isActive: _currentBottomTab == 2,
            onTap: () => setState(() => _currentBottomTab = 2),
          ),
          _buildBottomNavItem(
            iconData: Icons.leaderboard_rounded,
            label: 'Leaderboard',
            isActive: _currentBottomTab == 3,
            onTap: () => setState(() => _currentBottomTab = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    String? iconAsset,
    IconData? iconData,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFFFF7A00);
    final inactiveColor = const Color(0xFFB59E83);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              SvgPicture.asset(
                iconAsset,
                colorFilter: ColorFilter.mode(
                  isActive ? activeColor : inactiveColor,
                  BlendMode.srcIn,
                ),
                width: 20,
                height: 20,
              )
            else if (iconData != null)
              Icon(
                iconData,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
