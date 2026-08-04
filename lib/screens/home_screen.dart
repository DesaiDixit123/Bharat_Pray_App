import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'details/live_darshan_screen.dart';
import 'details/jap_counter_screen.dart';
import 'details/yatra_screen.dart';
import 'details/profile_screen.dart';
import 'details/bhajan_category_screen.dart';
import 'details/granth_screen.dart';
import 'details/utsav_screen.dart';
import 'details/deity_detail_screen.dart';
import 'details/festival_detail_screen.dart';
import 'details/darshan_tab_content.dart';
import 'details/deity_temples_screen.dart';
import 'prayer_detail_screen.dart';
import '../models/prayer.dart';
import '../services/api_service.dart';
import '../services/yatra_group_socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Carousel state
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;

  String _profileName = 'User';
  String _profilePic = '';
  int _currentTab = 0;
  int _notificationCount = 2;
  int _messageCount = 1;

  final List<Map<String, String>> _heroBanners = [
    {
      'title': 'Somnath Jyotirlinga',
      'desc': 'Start your divine darshan and get blessings from the temple of the Moon God.',
      'views': '100K',
      'image': 'assets/images/somnath_hero.png',
    },
    {
      'title': 'Kedarnath Dham',
      'desc': 'Experience the spiritual essence of the mighty Himalayas and Lord Shiva.',
      'views': '250K',
      'image': 'assets/images/somnath_hero.png',
    },
    {
      'title': 'Kashi Vishwanath',
      'desc': 'Connect to Kashi Live Aarti and feel the vibration of eternal chants.',
      'views': '85K',
      'image': 'assets/images/somnath_hero.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startCarouselTimer();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('user_name') ?? '';
    final pic = prefs.getString('profile_pic') ?? '';
    setState(() {
      _profileName = fullName.isNotEmpty ? fullName : 'User';
      _profilePic = pic;
    });
    // Fetch live dashboard data from backend
    _fetchDashboardData();
    _initYatraGroupSocket();
  }

  Future<void> _initYatraGroupSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        YatraGroupSocketService().init(token);
      }
    } catch (e) {
      debugPrint('YatraGroupSocket init error: $e');
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      debugPrint('🔑 Retrieved Auth Token from storage: $token');
      if (token.isNotEmpty) {
        final homeData = await ApiService.getDarshanHome(token);
        if (mounted) {
          debugPrint('👤 Home Screen User Data (ID): ${homeData['user']}');
          setState(() {
            _profileName = homeData['user']['name'] ?? 'User';
            _profilePic = homeData['user']['profile_pic'] ?? '';
            _notificationCount = homeData['notificationCount'] ?? 2;
            _messageCount = homeData['messageCount'] ?? 1;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 17) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  String _resolveProfilePic(String pic) {
    return ApiService.resolveImageUrl(pic);
  }

  String _getMailSvg(int count) {
    final fill = count > 0 ? '#FF0000' : 'none';
    return '''<svg width="26" height="24" viewBox="0 0 26 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.01417 3.9978C3.80516 3.9978 2.01416 5.7888 2.01416 7.9978V15.9978C2.01416 18.2068 3.80516 19.9978 6.01417 19.9978H18.0142C20.2232 19.9978 22.0142 18.2068 22.0142 15.9978V7.9978C22.0142 5.7888 20.2232 3.9978 18.0142 3.9978H6.01417ZM6.01417 5.9978H18.0142C19.0222 5.9978 19.8552 6.73781 19.9932 7.70781C19.0352 8.60081 17.6112 9.6968 16.6702 10.3728C14.5052 11.9278 12.6002 12.9978 12.0142 12.9978C11.4282 12.9978 9.52317 11.9288 7.35816 10.3728C6.41716 9.6968 5.49217 8.9658 4.79517 8.3728C4.49817 8.1198 4.27816 7.9158 4.10816 7.7478C4.24616 6.7778 5.00616 5.9978 6.01417 5.9978ZM4.02417 10.3518C6.56218 12.4048 10.2812 14.9858 12.0142 14.9978C13.1432 15.0058 15.0742 13.9278 17.0442 12.5668C18.0632 11.8618 19.1972 11.0248 20.0152 10.3378L20.0142 15.9978C20.0142 17.1028 19.1192 17.9978 18.0142 17.9978H6.01417C4.90916 17.9978 4.01416 17.1028 4.01416 15.9978L4.02417 10.3518Z" fill="#6B4226"/>
<circle cx="22" cy="4.5" r="4" fill="$fill"/>
</svg>''';
  }

  String _getBellSvg(int count) {
    final fill = count > 0 ? '#FF0000' : 'none';
    return '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 6.43994V9.76994" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M12.02 2C8.34002 2 5.36002 4.98 5.36002 8.66V10.76C5.36002 11.44 5.08002 12.46 4.73002 13.04L3.46002 15.16C2.68002 16.47 3.22002 17.93 4.66002 18.41C9.44002 20 14.61 20 19.39 18.41C20.74 17.96 21.32 16.38 20.59 15.16L19.32 13.04C18.97 12.46 18.69 11.43 18.69 10.76V8.66C18.68 5 15.68 2 12.02 2Z" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M15.33 18.8199C15.33 20.6499 13.83 22.1499 12 22.1499C11.09 22.1499 10.25 21.7699 9.65004 21.1699C9.05004 20.5699 8.67004 19.7299 8.67004 18.8199" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10"/>
<circle cx="18" cy="4.5" r="4" fill="$fill"/>
</svg>''';
  }

  Widget _buildDynamicHeader() {
    final greeting = _getGreeting();
    final icon = _getGreetingIcon();
    final profilePicUrl = _resolveProfilePic(_profilePic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Stack(
          children: [
            // Left side: User Avatar & Info
            Positioned(
              left: 20,
              top: 0,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF7700).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profilePicUrl.isNotEmpty
                          ? Image.network(
                              profilePicUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    _profileName.isNotEmpty ? _profileName[0].toUpperCase() : 'U',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF7700),
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700), strokeWidth: 2));
                              },
                            )
                          : Center(
                              child: Text(
                                _profileName.isNotEmpty ? _profileName[0].toUpperCase() : 'U',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF7700),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Jai Shree Ram',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🙏', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$greeting, $_profileName $icon',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Mail Action Button
            Positioned(
              left: 317,
              top: 12,
              width: 24,
              height: 24,
              child: GestureDetector(
                onTap: () => _showMailNotificationSheet(context, "Messages", "You have a new message from the Somnath Temple Trust: 'The morning Aarti timings have been adjusted to 06:00 AM due to the summer season.'"),
                child: SvgPicture.string(
                  _getMailSvg(_messageCount),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            
            // Notification Bell Action Button
            Positioned(
              left: 349,
              top: 12,
              width: 24,
              height: 24,
              child: GestureDetector(
                onTap: () => _showMailNotificationSheet(context, "Notifications", "📿 Daily Chant Reminder: You have not completed your Jap goals for today. Tap the center bead button to start chanting."),
                child: SvgPicture.string(
                  _getBellSvg(_notificationCount),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _heroBanners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHomeTabBody() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDynamicHeader(),

            // 2. Search gods, temples row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFEFE6DB),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
                        decoration: InputDecoration(
                          hintText: 'Search gods, temples, bhajans...',
                          hintStyle: GoogleFonts.outfit( // Corrected from withValues to withOpacity
                            color: const Color(0xFF2E2A36).withOpacity(0.4),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF2E2A36).withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Orange Tune Filter Button
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: SizedBox(
                height: 353,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _startCarouselTimer(); // Reset timer on manual swipe
                  },
                  itemCount: _heroBanners.length,
                  itemBuilder: (context, index) {
                    final banner = _heroBanners[index];
                    return _buildHeroCard(banner);
                  },
                ),
              ),
            ),

            // 4. Categories Section (Bhajan, Granth, Utsav Vibes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSvgCategoryCard(
                      svgAsset: 'assets/images/cat_bhajan.svg',
                      label: 'Bhajan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BhajanScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSvgCategoryCard(
                      svgAsset: 'assets/images/cat_granth.svg',
                      label: 'Granth',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GranthScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSvgCategoryCard(
                      svgAsset: 'assets/images/cat_utsav.svg',
                      label: 'Utsav Vibes',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UtsavScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Deities Horizontal Slider
            SizedBox(
              height: 208,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Card 1: Somnath Temple
                  SizedBox(
                    width: 178,
                    child: _buildDeityCard(
                      imageUrl: 'assets/images/somnath_temple.png',
                      height: 208,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeityDetailScreen(
                            title: "Somnath Temple",
                            imageUrl: "assets/images/somnath_temple.png",
                            description: "Somnath Temple is one of the most sacred pilgrimage sites in India, housing the first of the twelve holy Jyotirlinga shrines of Lord Shiva. Located on the western coast of Gujarat, it stands as a symbol of eternal devotion and architectural grandeur, rebuilt beautifully over history.",
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Card 2: Shree Krishna
                  SizedBox(
                    width: 178,
                    child: _buildDeityCard(
                      imageUrl: 'assets/images/krishna.png',
                      height: 208,
                      onTap: () async {
                        final tabIndex = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeityTemplesScreen(
                              deityName: "Shree Krishna",
                              imageUrl: "assets/images/krishna.png",
                            ),
                          ),
                        );
                        if (tabIndex is int) {
                          setState(() {
                            _currentTab = tabIndex;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Card 3: Ram Bhajan
                  SizedBox(
                    width: 178,
                    child: _buildDeityCard(
                      imageUrl: 'assets/images/ram_bhajan.png',
                      height: 208,
                      onTap: () {
                        final ramBhajan = Prayer.defaultPrayers.firstWhere(
                          (p) => p.title.contains("Ram") || p.title.contains("Ghar"),
                          orElse: () => Prayer.defaultPrayers[0],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrayerDetailScreen(prayer: ramBhajan),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Card 4: Bhagavad Gita
                  SizedBox(
                    width: 178,
                    child: _buildDeityCard(
                      imageUrl: 'assets/images/bhagavad_gita.png',
                      height: 208,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GranthScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. Festivals Horizontal Slider (showing last 4 cards)
            SizedBox(
              height: 300,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Dhanterash',
                      dateText: 'Nov 07\nSAT',
                      imageUrl: 'assets/images/new_year_card.png',
                      height: 300,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FestivalDetailScreen(
                            festivalName: "Dhanterash",
                            imageUrl: "assets/images/new_year_card.png",
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Diwali',
                      dateText: 'Nov 08\nSUN',
                      imageUrl: 'assets/images/diwali_card.png',
                      height: 300,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FestivalDetailScreen(
                            festivalName: "Diwali",
                            imageUrl: "assets/images/diwali_card.png",
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Gujarati New Year',
                      dateText: 'Nov 10\nTUE',
                      imageUrl: 'assets/images/dhanteras_card.png',
                      height: 300,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FestivalDetailScreen(
                            festivalName: "Gujarati New Year",
                            imageUrl: "assets/images/dhanteras_card.png",
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Bhaibeej',
                      dateText: 'Nov 11\nWED',
                      imageUrl: 'assets/images/bhaiduj_card.png',
                      height: 300,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FestivalDetailScreen(
                            festivalName: "Bhaibeej",
                            imageUrl: "assets/images/bhaiduj_card.png",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 140 + MediaQuery.of(context).padding.bottom), // Extra clearance for floating Jap button
          ],
        ),
      ),
    );
  }

  Widget _buildDarshanTabBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDynamicHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: DarshanTabContent(
              onTabChanged: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tabBody;
    switch (_currentTab) {
      case 0:
        tabBody = _buildHomeTabBody();
        break;
      case 1:
        tabBody = _buildDarshanTabBody();
        break;
      case 2:
        tabBody = const JapCounterScreen(isTab: true);
        break;
      case 3:
        tabBody = const YatraScreen(isTab: true);
        break;
      case 4:
        tabBody = const ProfileScreen(isTab: true);
        break;
      default:
        tabBody = _buildHomeTabBody();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6), // Warm peach cream theme background matched to mockup
        body: Stack(
          children: [
            tabBody,
            // Solid opaque blocker background container for system navigation bar (3 buttons/gesture area)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).padding.bottom,
              child: Container(
                color: const Color(0xFFFFE8D6),
              ),
            ),
            // 7. Custom Floating Arched Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: _buildBottomNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Header IconButton with red badge dot
  Widget _buildHeaderIconButton({required IconData icon, bool hasBadge = false, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFEFE6DB),
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon, color: const Color(0xFF2E2A36), size: 20),
            onPressed: onTap,
          ),
          if (hasBadge)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                height: 7,
                width: 7,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper: Swipable Hero Card for PageView
  Widget _buildHeroCard(Map<String, String> banner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: 353,
        height: 353,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    banner['image']!,
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient shader to darken bottom for text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),

                // 1. LIVE Overlay Badge (Figma: width 80, height 40, top 15, left 161, radius 9999)
                Positioned(
                  top: 15,
                  left: 161,
                  width: 80,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B42),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Radio signal SVG icon: top:13.33, left:14, width:20, height:13.33
                        Positioned(
                          top: 13.33,
                          left: 14,
                          width: 20,
                          height: 13.33,
                          child: SvgPicture.string(
                            '''<svg width="20" height="14" viewBox="0 0 20 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M13.5399 10.9905C13.3432 10.9899 13.1511 10.9341 12.9875 10.83C12.824 10.726 12.6963 10.5784 12.6204 10.4056C12.5446 10.2328 12.5239 10.0425 12.5609 9.85856C12.598 9.67462 12.6912 9.50517 12.8289 9.37142C13.5789 8.65361 13.9999 7.68217 13.9999 6.66952C13.9999 5.65688 13.5789 4.68544 12.8289 3.96763C12.6475 3.78708 12.5479 3.54588 12.5515 3.29603C12.5551 3.04617 12.6617 2.80769 12.8483 2.63201C13.0349 2.45632 13.2865 2.35751 13.5488 2.35687C13.8112 2.35623 14.0633 2.45382 14.2509 2.62859C15.3712 3.70283 15.9999 5.15545 15.9999 6.66952C15.9999 8.18359 15.3712 9.63622 14.2509 10.7105C14.1576 10.7995 14.0468 10.8701 13.9248 10.9182C13.8027 10.9662 13.6719 10.9908 13.5399 10.9905ZM7.16288 10.7152C7.35142 10.5376 7.45818 10.296 7.45968 10.0435C7.46118 9.79093 7.3573 9.54816 7.17088 9.36856C6.42088 8.65076 5.99984 7.67931 5.99984 6.66667C5.99984 5.65402 6.42088 4.68258 7.17088 3.96478C7.26573 3.87638 7.34114 3.77088 7.39274 3.65444C7.44434 3.538 7.47109 3.41295 7.47143 3.28656C7.47177 3.16018 7.4457 3.03499 7.39472 2.9183C7.34375 2.80162 7.2689 2.69576 7.17453 2.60689C7.08017 2.51803 6.96817 2.44795 6.84508 2.40073C6.72199 2.3535 6.59026 2.33009 6.45757 2.33184C6.32488 2.33359 6.19388 2.36048 6.07221 2.41094C5.95054 2.4614 5.84063 2.53441 5.74889 2.62573C4.62858 3.69997 3.99983 5.1526 3.99983 6.66667C3.99983 8.18074 4.62858 9.63336 5.74889 10.7076C5.93536 10.8872 6.18907 10.9888 6.45423 10.9903C6.7194 10.9917 6.9743 10.8928 7.16288 10.7152ZM17.4318 13.02C19.0847 11.2783 19.9997 9.01428 19.9997 6.66667C19.9997 4.31906 19.0847 2.05504 17.4318 0.313363C17.2539 0.126071 17.0051 0.0137769 16.7402 0.00118524C16.4753 -0.0114064 16.216 0.0767356 16.0193 0.246221C15.8227 0.415706 15.7048 0.652651 15.6916 0.904931C15.6783 1.15721 15.7709 1.40416 15.9488 1.59145C17.2689 2.98289 17.9997 4.79141 17.9997 6.66667C17.9997 8.54192 17.2689 10.3504 15.9488 11.7419C15.7709 11.9292 15.6783 12.1761 15.6916 12.4284C15.7048 12.6807 15.8227 12.9176 16.0193 13.0871C16.216 13.2566 16.4753 13.3447 16.7402 13.3321C17.0051 13.3196 17.2539 13.2073 17.4318 13.02ZM3.9799 13.0866C4.17648 12.9172 4.29439 12.6804 4.30771 12.4283C4.32102 12.1761 4.22865 11.9292 4.0509 11.7419C2.73087 10.3504 2.00008 8.54192 2.00008 6.66667C2.00008 4.79141 2.73087 2.98289 4.0509 1.59145C4.13902 1.49871 4.20709 1.39036 4.25124 1.27256C4.29538 1.15477 4.31473 1.02985 4.30819 0.904931C4.30164 0.780015 4.26932 0.657549 4.21308 0.544528C4.15684 0.431506 4.07777 0.330141 3.9804 0.246221C3.88303 0.1623 3.76925 0.0974673 3.64556 0.0554241C3.52188 0.0133808 3.39071 -0.00504952 3.25955 0.00118524C2.99466 0.0137769 2.74587 0.126071 2.56791 0.313363C0.915082 2.05504 0 4.31906 0 6.66667C0 9.01428 0.915082 11.2783 2.56791 13.02C2.74591 13.2071 2.99464 13.3192 3.25941 13.3317C3.52419 13.3442 3.78334 13.256 3.9799 13.0866ZM9.99987 5.2381C9.7032 5.2381 9.41319 5.32189 9.16652 5.47886C8.91985 5.63583 8.72759 5.85894 8.61406 6.11998C8.50053 6.38102 8.47082 6.66825 8.5287 6.94537C8.58658 7.22248 8.72944 7.47703 8.93922 7.67681C9.14899 7.8766 9.41627 8.01266 9.70724 8.06778C9.99821 8.1229 10.2998 8.09461 10.5739 7.98649C10.848 7.87836 11.0822 7.69526 11.2471 7.46033C11.4119 7.22541 11.4999 6.94921 11.4999 6.66667C11.4999 6.28779 11.3418 5.92443 11.0605 5.65652C10.7792 5.38861 10.3977 5.2381 9.99987 5.2381Z" fill="white"/>
</svg>''',
                            width: 20,
                            height: 13.33,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // "Live" text: positioned after icon (left: 14+20+4=38)
                        Positioned(
                          top: 12,
                          left: 38,
                          child: Text(
                            'Live',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 2. Active Viewers Badge (Figma: dark gray pill, width 87, height 40, top 15, left 251, radius 47)
                Positioned(
                  top: 15,
                  left: 251,
                  width: 87,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(47),
                    child: BackdropFilter(
                      // backdrop-filter: blur(4.599999904632568px) as per Figma
                      filter: ImageFilter.blur(sigmaX: 4.6, sigmaY: 4.6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(47),
                          border: Border.all(
                            color: const Color(0x66FFFFFF), // #FFFFFF66
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Eye SVG icon: top:13.33, left:14, width:22, height:13.33
                            Positioned(
                              top: 13.33,
                              left: 14,
                              width: 22,
                              height: 13.33,
                              child: SvgPicture.string(
                                '''<svg width="22" height="14" viewBox="0 0 22 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21.8602 6.25978C21.6637 6.00412 16.9808 0 10.9999 0C5.01902 0 0.335926 6.00413 0.139602 6.25953C0.0488853 6.37771 0 6.52023 0 6.66654C0 6.81285 0.0488853 6.95538 0.139602 7.07356C0.335926 7.32921 5.01902 13.3333 10.9999 13.3333C16.9808 13.3333 21.6637 7.32917 21.8602 7.07376C21.951 6.95564 22 6.8131 22 6.66677C22 6.52044 21.951 6.3779 21.8602 6.25978ZM10.9999 11.954C6.59434 11.954 2.77866 7.96897 1.64914 6.6662C2.7772 5.36228 6.58489 1.3793 10.9999 1.3793C15.4052 1.3793 19.2207 5.36367 20.3507 6.66714C19.2226 7.97101 15.4149 11.954 10.9999 11.954Z" fill="white"/>
<path d="M10.9997 2.52869C8.60028 2.52869 6.64807 4.38501 6.64807 6.66664C6.64807 8.94826 8.60028 10.8046 10.9997 10.8046C13.3992 10.8046 15.3514 8.94826 15.3514 6.66664C15.3514 4.38501 13.3992 2.52869 10.9997 2.52869ZM10.9997 9.42524C9.40001 9.42524 8.09866 8.18776 8.09866 6.66664C8.09866 5.14551 9.40006 3.90803 10.9997 3.90803C12.5994 3.90803 13.9008 5.14551 13.9008 6.66664C13.9008 8.18776 12.5995 9.42524 10.9997 9.42524Z" fill="white"/>
</svg>''',
                                width: 22,
                                height: 13.33,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Views text: positioned after icon (left: 14+22+4=40)
                            Positioned(
                              top: 12,
                              left: 40,
                              child: Text(
                                banner['views']!,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Text & Button details (Bottom)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner['title']!,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banner['desc']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,             
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.5), // blur/faded look
                          height: 16 / 14,          // line-height: 16px → height ratio = 16/14
                          letterSpacing: 0,         // letter-spacing: 0px
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Start Darshan Button
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveDarshanScreen(
                                  darshanId: '',
                                  templeName: banner['title']!,
                                  imageUrl: banner['image']!,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Start Darshan',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  // Helper: Category Pill Card
  Widget _buildCategoryCard({
    String? imageAsset,
    IconData? icon,
    String? title,
    required double width,
    required double height,
    double scale = 1.15,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Figma: radius = 12px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFEFE6DB),
            width: 1.0, // Figma: border = 1px
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageAsset != null
              ? Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) Icon(icon, color: const Color(0xFFFF7700), size: 24),
                    const SizedBox(height: 8),
                    if (title != null)
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF7700),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // Helper: SVG Category Card — icon 42x42 at top:21 centered, label below (Figma spec)
  Widget _buildSvgCategoryCard({
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 111,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFC8A882),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 21), // top: 21px as per Figma
            SvgPicture.asset(
              svgAsset,
              width: 42,
              height: 42,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF7A00),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Deity Card for Raw Downloaded Images
  Widget _buildDeityCard({
    required String imageUrl,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Transform.scale(
          scale: 1.45, // Increased size even further to fill the space
          child: Image.asset(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Helper: Devotional Temple Card (Two-Column)
  Widget _buildTempleCard({
    required String title,
    required String imageUrl,
    required String badgeEmoji,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Dark gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                left: 14,
                bottom: progress > 0 ? 24 : 14,
                right: 44,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Progress Bar (only if progress > 0)
              if (progress > 0)
                Positioned(
                  left: 14,
                  right: 52,
                  bottom: 10,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white24,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: const Color(0xFFFF7700),
                        ),
                      ),
                    ),
                  ),
                ),
              // Bottom Right Saffron Button with Emoji
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7700),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badgeEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Festival Card
  Widget _buildFestivalCard({
    required String title,
    required String dateText,
    required String imageUrl,
    required VoidCallback onTap,
    double height = 130,
  }) {
    final dateParts = dateText.split(RegExp(r'[\s\n]+'));
    final month = dateParts.isNotEmpty ? dateParts[0] : 'Nov';
    final date = dateParts.length > 1 ? dateParts[1] : '07';
    final day = dateParts.length > 2 ? dateParts[2] : 'SAT';

    final String titleLower = title.toLowerCase();
    final Color themeColor;
    if (titleLower.contains('dhanteras')) {
      themeColor = const Color(0xFFA22E85); // Berry Magenta
    } else if (titleLower.contains('diwali')) {
      themeColor = const Color(0xFF4C45A5); // Indigo Purple
    } else if (titleLower.contains('new') || titleLower.contains('year') || titleLower.contains('gujarati')) {
      themeColor = const Color(0xFF1E539E); // Dark Royal Blue
    } else if (titleLower.contains('bhai') || titleLower.contains('beej') || titleLower.contains('duj')) {
      themeColor = const Color(0xFF439CA3); // Teal Light Blue
    } else {
      themeColor = const Color(0xFFFF7700); // Saffron Orange fallback
    }

    final Color badgeHeaderColor = themeColor;

    final calendarBadge = Container(
      width: 21,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            // Top Month Header
            Container(
              width: double.infinity,
              height: 12,
              color: themeColor,
              alignment: Alignment.center,
              child: Text(
                month, // e.g. "Nov"
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            // Bottom Date/Day Body
            Expanded(
              child: Container(
                width: double.infinity,
                color: themeColor.withValues(alpha: 0.12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date, // e.g. "07"
                      style: GoogleFonts.outfit(
                        color: themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 0.5),
                    Text(
                      day.toUpperCase(), // e.g. "SAT"
                      style: GoogleFonts.outfit(
                        color: themeColor.withValues(alpha: 0.5),
                        fontSize: 5.5,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEFE6DB),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Colored bottom overlay gradient matching design
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeColor.withOpacity(0.0),
                        themeColor.withOpacity(0.9), // Rich solid color fade at the bottom
                      ],
                    ),
                  ),
                ),
              ),
              // Date stamp & title Row – anchored to bottom of card
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    calendarBadge,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Custom Floating Arched Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return SizedBox(
      width: 353,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none, // Allows Jap button to float above bar
        children: [
          // Arched background container with shadow and beige border
          Positioned.fill(
            child: CustomPaint(
              painter: ArchedNavBarPainter(),
            ),
          ),
          
          // Home
          Positioned(
            left: 8,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_home.svg',
              label: 'Home',
              isActive: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          
          // Darshan
          Positioned(
            left: 76,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_darshan.svg',
              label: 'Darshan',
              isActive: _currentTab == 1,
              onTap: () => setState(() => _currentTab = 1),
            ),
          ),
          
          // Jap (Floating Orange Circle with Highlighted Radial Gradient)
          Positioned(
            left: 147,
            top: -2,
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = 2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFAB5E), // Inner highlighted light orange
                      Color(0xFFFF7A00), // Outer deep orange
                    ],
                    center: Alignment.center,
                    radius: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 13), // Logo top: 13px as per Figma
                    SvgPicture.asset(
                      'assets/images/nav_jap.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 1), // Tightly aligned spacer
                    Text(
                      'Jap',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Yatra
          Positioned(
            left: 218,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_yatra.svg',
              label: 'Yatra',
              isActive: _currentTab == 3,
              onTap: () => setState(() => _currentTab = 3),
            ),
          ),
          
          // Profile
          Positioned(
            left: 285,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_profile.svg',
              label: 'Profile',
              isActive: _currentTab == 4,
              onTap: () => setState(() => _currentTab = 4),
            ),
          ),
        ],
      ),
    );
  }

  // Nav Item helper
  Widget _buildNavItem({
    required String iconAsset,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFFFF7A00);
    final inactiveColor = const Color(0xFFB59E83);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconAsset.endsWith('.svg')
              ? SvgPicture.asset(
                  iconAsset,
                  colorFilter: ColorFilter.mode(
                      isActive ? activeColor : inactiveColor,
                      BlendMode.srcIn),
                  width: 20, // Reduced from 24 to 20 for more vertical breathing room
                  height: 20,
                )
              : Image.asset(
                  iconAsset,
                  color: isActive ? activeColor : inactiveColor,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
          const SizedBox(height: 2),
          Text(
            label,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: GoogleFonts.outfit(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 10, // Reduced from 11 to 10 for better space matching
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showMailNotificationSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFE8D6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFEFE6DB), height: 20),
            const SizedBox(height: 8),
            Text(
              content, style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF2E2A36).withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Mark as Read",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArchedNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0x59B46414) // Figma border: #B46414 with 59 (35%) opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Host rect (the white bar from y=30.5 to y=79.5)
    final hostRect = Rect.fromLTWH(0.5, 30.5, size.width - 1.0, 49);
    
    // Guest rect (the Jap circle from x=147, y=-2 with size 60x60)
    // We add a gap of 5.5px on all sides to create the perfect circular gap
    final guestRect = Rect.fromLTWH(147 - 5.5, -2 - 5.5, 60 + 11, 60 + 11);

    // Get the notched path using Flutter's built-in Material design notched path generator
    final notchedPath = CircularNotchedRectangle().getOuterPath(hostRect, guestRect);

    // Create the rounded rectangle path for the outer corners (radius 12.0)
    const radius = 12.0;
    final rrect = RRect.fromRectAndRadius(hostRect, const Radius.circular(radius));
    final roundedPath = Path()..addRRect(rrect);

    // Intersect the two paths to get the rounded outer corners with the smooth circular notch
    final finalPath = Path.combine(PathOperation.intersect, notchedPath, roundedPath);

    // Draw shadow first
    canvas.drawPath(finalPath.shift(const Offset(0, 4)), shadowPaint);

    // Draw white background
    canvas.drawPath(finalPath, paint);

    // Draw border
    canvas.drawPath(finalPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
