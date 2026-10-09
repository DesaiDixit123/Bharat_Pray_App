import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'festival_detail_screen.dart';
import 'festival_activity_screen.dart';
import 'mandal_status_tab_content.dart';
import 'live_darshan_dashboard_screen.dart';
import 'mandal_leaderboard_tab_content.dart';
import 'mandal_profile_screen.dart';
import '../../services/utsav_service.dart';


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
  bool _hasRegisteredMandal = false;
  Map<String, dynamic>? _myRegistration;

  List<Map<String, dynamic>> _activeFestivals = [];
  List<Map<String, dynamic>> _upcomingFestivals = [];
  List<Map<String, dynamic>> _topMandals = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get _currentList {
    if (_segment == 0) return _activeFestivals;
    if (_segment == 1) return _upcomingFestivals;
    // Segment 2: Top Mandals — If no active festival, top mandals should be empty!
    if (_activeFestivals.isEmpty) return [];
    return _topMandals;
  }

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.92);
    _startBannerTimer();
    _loadUtsavData();
  }

  Future<void> _loadUtsavData() async {
    try {
      final all = await UtsavService.getFestivals(status: 'ALL');
      final active = all.where((f) => (f['status'] ?? '').toString().toLowerCase() == 'active').toList();
      final upcoming = all.where((f) => (f['status'] ?? '').toString().toLowerCase() == 'upcoming').toList();
      final mandals = await UtsavService.getMandals();
      
      Map<String, dynamic>? myReg;
      bool hasRegistered = false;
      try {
        myReg = await UtsavService.getMyMandalRegistration();
        final isRegActive = await UtsavService.isRegistrationActive(myReg);
        hasRegistered = myReg != null && isRegActive && (myReg['mandalName']?.toString().trim().isNotEmpty ?? false);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _activeFestivals = active;
          _upcomingFestivals = upcoming;
          _topMandals = mandals;
          _myRegistration = myReg;
          _hasRegisteredMandal = hasRegistered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[UtsavHome] Error loading utsav data: $e');
      final fallbackFestivals = await UtsavService.getFestivals(status: 'ALL');
      final fallbackMandals = await UtsavService.getMandals();
      if (mounted) {
        setState(() {
          _activeFestivals = fallbackFestivals.where((f) => (f['status'] ?? '').toString().toLowerCase() == 'active').toList();
          _upcomingFestivals = fallbackFestivals.where((f) => (f['status'] ?? '').toString().toLowerCase() == 'upcoming').toList();
          _topMandals = fallbackMandals;
          _isLoading = false;
        });
      }
    }
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
        final total = _bannerItems.length;
        if (total > 0) {
          final next = (_bannerPage + 1) % total;
          _bannerController.animateToPage(
            next,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
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
    if (_hasRegisteredMandal) {
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
    } else {
      switch (_currentBottomTab) {
        case 1:
          return const LiveDarshanDashboardScreen();
        case 2:
          return const MandalLeaderboardTabContent();
        case 0:
        default:
          return _buildHomeTabBody(context);
      }
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

        // ── Festival / Top Mandals list ──────────────────────────────────
        Expanded(
          child: _isLoading
              ? Padding(
                  padding: EdgeInsets.only(bottom: 90.0 + MediaQuery.of(context).padding.bottom),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7700)),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF7700),
                  onRefresh: _loadUtsavData,
                  child: _segment == 2
                      ? (_currentList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                              itemCount: _currentList.length,
                              itemBuilder: (context, index) =>
                                  _buildTopMandalCard(_currentList[index]),
                            ))
                      : (_currentList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                              itemCount: _currentList.length,
                              itemBuilder: (context, index) =>
                                  _buildFestivalCard(_currentList[index]),
                            )),
                ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    String title = 'Utsav Vibes';
    if (_hasRegisteredMandal) {
      if (_currentBottomTab == 1) {
        title = 'Live Darshan';
      } else if (_currentBottomTab == 2) {
        title = 'Registration Status';
      } else if (_currentBottomTab == 3) {
        title = 'Leaderboard';
      }
    } else {
      if (_currentBottomTab == 1) {
        title = 'Live Darshan';
      } else if (_currentBottomTab == 2) {
        title = 'Leaderboard';
      }
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

  List<Map<String, dynamic>> get _bannerItems {
    final list = [..._activeFestivals, ..._upcomingFestivals];
    return list.map((f) => {
      'title': (f['name'] ?? 'Festival').toString(),
      'subtitle': (f['slogan'] ?? f['description'] ?? 'Connect. Devotion. Win.').toString(),
      'tag': '${f['status'] ?? 'Active'} Utsav',
      'imageUrl': (f['banner'] ?? f['imageUrl'] ?? 'assets/images/devotional/navratri_garba_festival.jpg').toString(),
      'rawFestival': f,
    }).toList();
  }

  // ── Banner Carousel ─────────────────────────────────────────────────────────

  Widget _buildBannerCarousel() {
    final items = _bannerItems;
    final total = items.length;
    if (total == 0) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: total,
            onPageChanged: (i) {
              setState(() => _bannerPage = i);
              _startBannerTimer();
            },
            itemBuilder: (_, i) => _buildBannerCard(items[i % total]),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
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

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final title = (banner['title'] ?? '').toString();
    final imageUrl = (banner['imageUrl'] ?? 'assets/images/new_year_card.png').toString();
    final rawFest = banner['rawFestival'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FestivalDetailScreen(
              festivalName: title,
              imageUrl: imageUrl,
              isMandal: true,
              festivalData: rawFest,
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildSegmentTab('Active', 0),
              const SizedBox(width: 8),
              _buildSegmentTab('Upcoming', 1),
              const SizedBox(width: 8),
              _buildSegmentTab('Top Mandals', 2),
            ],
          ),
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
    final name = (festival['name'] ?? '').toString();
    final startDate = (festival['formattedDate'] ?? festival['startDate'] ?? '').toString();
    final endDate = (festival['formattedDate'] != null ? '' : (festival['endDate'] ?? '')).toString();
    final imageUrl = (festival['banner'] ?? festival['imageUrl'] ?? 'assets/images/new_year_card.png').toString();
    String regStatus = (festival['registrationStatus'] ?? '').toString();
    if (regStatus.isEmpty) {
      regStatus = UtsavService.computeRegistrationStatus(
        festival['regStartDate']?.toString(),
        festival['regEndDate']?.toString(),
        festival['status'] == 'Active' ? 'open' : 'coming_soon',
        festivalName: name,
      );
    }
    final isOpen = regStatus == 'open';

    final isClickable = _segment == 0 || isOpen;

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
              ? () async {
                  // Check if this festival has user's registration
                  final regFest = (_myRegistration?['festival'] ?? _myRegistration?['festivalName'] ?? _myRegistration?['category'])?.toString().toLowerCase() ?? '';
                  final currFest = name.toLowerCase();
                  final bool isRegisteredForThis = _myRegistration != null && regFest.isNotEmpty && currFest.isNotEmpty &&
                      (currFest.contains(regFest) || regFest.contains(currFest) ||
                       (currFest.contains('navratri') && regFest.contains('navratri')) ||
                       (currFest.contains('diwali') && regFest.contains('diwali')));

                  if (isRegisteredForThis) {
                    final st = (_myRegistration!['status'] ?? 'Pending').toString().toLowerCase();
                    if (st == 'pending' || st == 'rejected') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MandalStatusTabContent(isStandalone: true),
                        ),
                      );
                      _loadUtsavData();
                      return;
                    }
                  }

                  if (_segment == 0) {
                    // Active → Popular Reels + Posts + Search
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FestivalActivityScreen(
                          festivalName: name,
                          imageUrl: imageUrl,
                          festivalData: festival,
                        ),
                      ),
                    );
                    _loadUtsavData();
                  } else {
                    // Upcoming → Register flow
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FestivalDetailScreen(
                          festivalName: name,
                          imageUrl: imageUrl,
                          isMandal: true,
                          festivalData: festival,
                        ),
                      ),
                    );
                    _loadUtsavData();
                  }
                }
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
                      _buildStatusText(regStatus, festivalName: name),
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

  Widget _buildTopMandalCard(Map<String, dynamic> mandal) {
    final name = (mandal['name'] ?? 'Mandal').toString();
    final location = (mandal['city'] ?? mandal['location'] ?? '').toString();
    final votesVal = mandal['votes'];
    final votes = votesVal is num ? '$votesVal Devotees' : (mandal['votes'] ?? '').toString();
    final rankVal = mandal['rank'];
    final badge = (mandal['badge'] ?? (rankVal != null ? '🏆 #$rankVal' : '🏆')).toString();
    final imageUrl = (mandal['imageUrl'] ?? mandal['banner'] ?? 'assets/images/new_year_card.png').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MandalProfileScreen(
                mandalName: name,
                location: location,
                avatarUrl: imageUrl,
                coverUrl: imageUrl,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFFFF1E5),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFFFF7700), size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF7700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$location • $votes',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFFFF7700),
              ),
            ],
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

  Widget _buildStatusText(String regStatus, {String? festivalName}) {
    // 1. If user has registered for this festival, show their real Mandal registration status!
    if (_myRegistration != null) {
      final regFest = (_myRegistration!['festival'] ?? _myRegistration!['festivalName'] ?? _myRegistration!['category'])?.toString().toLowerCase() ?? '';
      final currFest = (festivalName ?? '').toLowerCase();
      final bool isMatch = regFest.isNotEmpty && currFest.isNotEmpty &&
          (currFest.contains(regFest) || regFest.contains(currFest) ||
           (currFest.contains('navratri') && regFest.contains('navratri')) ||
           (currFest.contains('diwali') && regFest.contains('diwali')));

      if (isMatch) {
        final st = (_myRegistration!['status'] ?? 'Pending').toString().toLowerCase();
        if (st == 'approved') {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF27AE60)),
              const SizedBox(width: 4),
              Text(
                'Mandal Approved',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          );
        } else if (st == 'rejected') {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFE74C3C)),
              const SizedBox(width: 4),
              Text(
                'Registration Rejected',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE74C3C),
                ),
              ),
            ],
          );
        } else {
          // Pending status
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFE67E22)),
              const SizedBox(width: 4),
              Text(
                'Verification in Progress ⏳',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE67E22),
                ),
              ),
            ],
          );
        }
      }
    }

    // 2. Default Festival Status
    final isActive = _segment == 0;
    final isOpen = regStatus == 'open';
    final isClosed = regStatus == 'closed';

    String text = 'Coming Soon';
    Color color = const Color(0xFF2E2A36).withValues(alpha: 0.45);

    if (isActive) {
      text = 'Active';
      color = const Color(0xFF27AE60);
    } else if (isOpen) {
      text = 'Registrations Open';
      color = const Color(0xFF27AE60);
    } else if (isClosed) {
      text = 'Registrations Closed';
      color = const Color(0xFFE74C3C);
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
    Widget content;
    if (_segment == 0) {
      content = _buildActiveEmptyContent();
    } else if (_segment == 2) {
      content = _buildTopMandalsEmptyContent();
    } else {
      content = _buildUpcomingEmptyContent();
    }

    final bottomInset = 90.0 + MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset, left: 24.0, right: 24.0),
              child: Center(
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveEmptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.celebration_outlined, color: Color(0xFFFF7700), size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'No Active Festivals Today',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Maha Navratri Garba Utsav starts on 11 Oct 2026.\nRegistrations are open now in Upcoming!',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => _segment = 1);
          },
          icon: const Icon(Icons.app_registration_rounded, size: 18, color: Colors.white),
          label: Text(
            'View Upcoming & Register Mandal',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7700),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEmptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_note_rounded, color: Color(0xFFFF7700), size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'No Upcoming Festivals',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'New festival schedules and registration dates will appear here soon.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTopMandalsEmptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.groups_rounded, color: Color(0xFFFF7700), size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'No Top Mandals Yet',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Top mandals will be featured when an active festival begins.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
      ],
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
          if (_hasRegisteredMandal) ...[
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
          ] else ...[
            _buildBottomNavItem(
              iconData: Icons.leaderboard_rounded,
              label: 'Leaderboard',
              isActive: _currentBottomTab == 2,
              onTap: () => setState(() => _currentBottomTab = 2),
            ),
          ],
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
