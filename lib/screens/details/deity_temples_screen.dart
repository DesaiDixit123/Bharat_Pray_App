import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'live_darshan_screen.dart';

class DeityTemplesScreen extends StatefulWidget {
  final String deityName;
  final String imageUrl;

  const DeityTemplesScreen({
    super.key,
    required this.deityName,
    required this.imageUrl,
  });

  @override
  State<DeityTemplesScreen> createState() => _DeityTemplesScreenState();
}

class _DeityTemplesScreenState extends State<DeityTemplesScreen> {
  String _profileName = 'User';
  String _profilePic = '';
  String _token = '';
  int _notificationCount = 2;
  int _messageCount = 1;

  List<dynamic> _templeDarshans = [];
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    final fullName = prefs.getString('user_name') ?? 'User';
    final pic = prefs.getString('profile_pic') ?? '';
    setState(() {
      _profileName = fullName.isNotEmpty ? fullName : 'User';
      _profilePic = pic;
    });
    _fetchDashboardAndTemples();
  }

  Future<void> _fetchDashboardAndTemples() async {
    if (_token.isEmpty) return;
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      // 1. Fetch dashboard data (message/notification count)
      final homeData = await ApiService.getDarshanHome(_token);
      if (mounted) {
        setState(() {
          _profileName = homeData['user']['name'] ?? 'User';
          _profilePic = homeData['user']['profile_pic'] ?? '';
          _notificationCount = homeData['notificationCount'] ?? 2;
          _messageCount = homeData['messageCount'] ?? 1;
        });
      }

      // 2. Fetch all active darshans matching the deity name or category
      final data = await ApiService.getDarshansList(
        token: _token,
        search: widget.deityName,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _templeDarshans = data['docs'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching temples: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 17) return '☀️';
    return '🌙';
  }

  String _resolveProfilePic(String pic) {
    return ApiService.resolveImageUrl(pic);
  }

  String _resolveImageUrl(String? url) {
    return ApiService.resolveImageUrl(url);
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
                          color: const Color(0xFF2E2A36).withOpacity(0.6),
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

  String _getHeaderTitle(String name) {
    if (name.contains("Krishna")) return "Krishna's Darshan";
    if (name.contains("Shiva") || name.contains("Shiv")) return "Shiva's Darshan";
    if (name.contains("Hanuman")) return "Hanuman's Darshan";
    if (name.contains("Amba")) return "Amba Mata's Darshan";
    if (name.contains("Ram")) return "Ram's Darshan";
    if (name.contains("Ganesha")) return "Ganesha's Darshan";
    return "$name's Darshan";
  }

  Widget _buildPlaceholderImage(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF7A00).withOpacity(0.05),
            const Color(0xFFFF7A00).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.temple_hindu_outlined,
                color: Color(0xFFFF7A00),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFFFF7A00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
              content,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF2E2A36).withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String iconAsset,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFFFF7A00);
    final inactiveColor = const Color(0xFF2E2A36).withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              isActive ? activeColor : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isActive ? activeColor : inactiveColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SizedBox(
      width: 353,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
              isActive: false,
              onTap: () => Navigator.pop(context, 0),
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
              isActive: true,
              onTap: () => Navigator.pop(context, 1),
            ),
          ),
          // Jap
          Positioned(
            left: 147,
            top: -2,
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, 2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFAB5E),
                      Color(0xFFFF7A00),
                    ],
                    center: Alignment.center,
                    radius: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 13),
                    SvgPicture.asset(
                      'assets/images/nav_jap.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 1),
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
              isActive: false,
              onTap: () => Navigator.pop(context, 3),
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
              isActive: false,
              onTap: () => Navigator.pop(context, 4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - 40 - 12) / 2;
    final double childAspectRatio = cardWidth / 233;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        body: Stack(
          children: [
            // Main Scrollable Content
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header (User Profile row matching normal Darshan page)
                    _buildDynamicHeader(),

                    // 2. Action row below profile (back, title, filter)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEFE6DB), width: 1.0),
                              ),
                              child: const Center(
                                child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36), size: 16),
                              ),
                            ),
                          ),
                          // Title
                          Text(
                            _getHeaderTitle(widget.deityName),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2E2A36),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          // Circular Filter Button
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFEFE6DB), width: 1.0),
                            ),
                            child: const Center(
                              child: Icon(Icons.tune_rounded, color: Color(0xFF2E2A36), size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Grid of Temples (Dynamic)
                    Expanded(
                      child: _isError
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Failed to load temples.',
                                    style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF2E2A36)),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF7A00),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: _fetchDashboardAndTemples,
                                    child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                                  )
                                ],
                              ),
                            )
                          : _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
                                )
                              : _templeDarshans.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No temples found for this deity.',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          color: const Color(0xFF2E2A36).withOpacity(0.5),
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(20, 10, 20, 140 + MediaQuery.of(context).padding.bottom),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: childAspectRatio,
                                      ),
                                      itemCount: _templeDarshans.length,
                                      itemBuilder: (context, index) {
                                        final item = _templeDarshans[index];
                                        return _buildTempleCard(context, item);
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom blocker container for system navigation bar (3-button/gesture area)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).padding.bottom,
              child: Container(
                color: const Color(0xFFFFE8D6),
              ),
            ),

            // Custom Floating Arched Bottom Navigation Bar
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

  Widget _buildTempleCard(BuildContext context, dynamic deity) {
    final imagePath = _resolveImageUrl(deity['image']);
    final String deityName = deity['name'] ?? widget.deityName;
    final String templeName = (deity['temple'] != null) ? (deity['temple']['name'] ?? '') : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE6DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area at the top
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: imagePath.isNotEmpty
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildPlaceholderImage(deityName),
                      )
                    : _buildPlaceholderImage(deityName),
              ),
            ),
            // Details area at the bottom
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    templeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF2E2A36).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Start Darshan button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF7A00), width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveDarshanScreen(
                              darshanId: deity['_id']?.toString() ?? '',
                              templeName: templeName.isNotEmpty ? templeName : deityName,
                              imageUrl: imagePath,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Start Darshan',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF7A00),
                          fontSize: 11,
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
      ..color = const Color(0x59B46414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final hostRect = Rect.fromLTWH(0.5, 30.5, size.width - 1.0, 49);
    final guestRect = Rect.fromLTWH(147 - 5.5, -2 - 5.5, 60 + 11, 60 + 11);

    final notchedPath = CircularNotchedRectangle().getOuterPath(hostRect, guestRect);

    const radius = 12.0;
    final rrect = RRect.fromRectAndRadius(hostRect, const Radius.circular(radius));
    final roundedPath = Path()..addRRect(rrect);

    final finalPath = Path.combine(PathOperation.intersect, notchedPath, roundedPath);

    canvas.drawPath(finalPath.shift(const Offset(0, 4)), shadowPaint);
    canvas.drawPath(finalPath, paint);
    canvas.drawPath(finalPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
