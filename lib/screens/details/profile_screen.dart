import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/utsav_service.dart';
import '../login_screen.dart';
import '../profile/change_password_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/help_support_screen.dart';
import '../profile/privacy_policy_screen.dart';
import '../profile/saved_items_screen.dart';
import '../profile/terms_conditions_screen.dart';
import 'create_mandal_post_screen.dart';
import 'create_mandal_reel_screen.dart';
import 'go_live_studio_screen.dart';
import 'favourite_bhajans_screen.dart';
import 'mandal_profile_screen.dart';
import 'mandal_registration_screen.dart';
import 'mandal_status_tab_content.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  bool _soundEffects = true;
  String _selectedLanguage = "English";

  String _userName = 'Guest User';
  String _userEmail = 'no-email@example.com';
  String _userPhone = '';
  String _profilePic = '';

  Map<String, dynamic>? _myMandalRegistration;
  bool _isMandalEventValid = false;
  Timer? _statusPollTimer;
  bool _deletedDialogShown = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      if (_myMandalRegistration != null) {
        final reg = await UtsavService.getMyMandalRegistration();
        if (mounted && reg != null) {
          final newStatus = reg['status']?.toString();
          if (newStatus != _myMandalRegistration?['status']) {
            final isRegValid = await UtsavService.isRegistrationActive(reg);
            setState(() {
              _myMandalRegistration = reg;
              _isMandalEventValid = isRegValid;
            });
            if (newStatus?.toLowerCase() == 'deleted' && !_deletedDialogShown) {
              _deletedDialogShown = true;
              _showAccountDeletedDialog(context, reg);
            }
          } else if (newStatus?.toLowerCase() == 'deleted' && !_deletedDialogShown) {
            _deletedDialogShown = true;
            _showAccountDeletedDialog(context, reg);
          }
        }
      }
    });
  }

  Widget _buildMandalCardLogo(String? path) {
    if (path == null || path.trim().isEmpty) {
      return const Center(child: Text("🛕", style: TextStyle(fontSize: 24)));
    }
    final clean = path.trim();
    if (clean.startsWith('data:image')) {
      try {
        final commaIdx = clean.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(clean.substring(commaIdx + 1));
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(child: Text("🛕", style: TextStyle(fontSize: 24))),
          );
        }
      } catch (_) {}
    }
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Text("🛕", style: TextStyle(fontSize: 24))),
      );
    }
    if (clean.startsWith('/uploads/') || clean.startsWith('uploads/')) {
      return Image.network(
        UtsavService.resolveImageUrl(clean),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Text("🛕", style: TextStyle(fontSize: 24))),
      );
    }
    if (clean.startsWith('assets/')) {
      return Image.asset(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Text("🛕", style: TextStyle(fontSize: 24))),
      );
    }
    try {
      final file = File(clean);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Text("🛕", style: TextStyle(fontSize: 24))),
        );
      }
    } catch (_) {}
    return const Center(child: Text("🛕", style: TextStyle(fontSize: 24)));
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final reg = await UtsavService.getMyMandalRegistration();
    final isRegValid = await UtsavService.isRegistrationActive(reg);

    if (mounted) {
      setState(() {
        _myMandalRegistration = reg;
        _isMandalEventValid = isRegValid;
        _userName = prefs.getString('user_name') ?? 'Ayush Kyada';
        _userEmail = prefs.getString('user_email') ?? 'ayush@example.com';
        _profilePic = prefs.getString('profile_pic') ?? '';
        String phoneRaw = prefs.getString('user_phone') ?? '8128753230';
        if (phoneRaw.isEmpty) {
          _userPhone = 'No phone number';
        } else if (phoneRaw.startsWith('+91')) {
          _userPhone = phoneRaw;
        } else {
          if (phoneRaw.length == 10) {
            _userPhone = '+91 ${phoneRaw.substring(0, 5)} ${phoneRaw.substring(5)}';
          } else {
            _userPhone = '+91 $phoneRaw';
          }
        }
      });
      if (reg != null && reg['status']?.toString().toLowerCase() == 'deleted' && !_deletedDialogShown) {
        _deletedDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAccountDeletedDialog(context, reg);
        });
      }
    }
  }

  void _showAccountDeletedDialog(BuildContext context, Map<String, dynamic> reg) {
    final mandalName = (reg['mandalName'] ?? 'Your Mandal').toString();
    final reason = (reg['deletionReason'] ?? reg['rejectionReason'] ?? 'Account deleted by Bharat Pray Admin').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Mandal Account Deleted ❌",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Your Mandal account '$mandalName' has been deleted by Bharat Pray Admin.",
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.red.shade800, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Reason for Deletion:",
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason.isNotEmpty ? reason : "Account deleted by administrator.",
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "You can now submit a fresh registration directly.",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await UtsavService.clearMyMandalRegistration();
                      if (mounted) {
                        setState(() {
                          _myMandalRegistration = null;
                          _isMandalEventValid = false;
                        });
                        _loadProfileData();
                      }
                    },
                    child: Text("Dismiss", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7700),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final festName = (reg['festival'] ?? reg['festivalName'] ?? 'Maha Navratri Garba Utsav 2026').toString();
                      await UtsavService.clearMyMandalRegistration();
                      if (mounted) {
                        setState(() {
                          _myMandalRegistration = null;
                          _isMandalEventValid = false;
                        });
                        _loadProfileData();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MandalRegistrationScreen(
                              initialFestival: festName,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text("Register Again", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getProfilePicUrl(String storedPath) {
    if (storedPath.isEmpty) {
      return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=60';
    }
    if (storedPath.startsWith('http') || storedPath.startsWith('/')) {
      return storedPath;
    }
    final baseDomain = ApiService.baseUrl.replaceAll('/user', '');
    return '$baseDomain/uploads/$storedPath';
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFF7700), width: 1.0),
        ),
        title: Text(
          "Logout",
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to log out of Bharat Pray?",
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.6), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              await prefs.remove('auth_token');
              await prefs.remove('user_name');
              await prefs.remove('user_email');
              await prefs.remove('user_phone');
              await prefs.remove('profile_pic');

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              "Logout",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = widget.isTab;
    final double bottomPad = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Black icons for Android
        statusBarBrightness: Brightness.light,    // Black icons for iOS
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Black time, wifi, battery on Android
            statusBarBrightness: Brightness.light,    // Black time, wifi, battery on iOS
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        automaticallyImplyLeading: !isTab,
        leading: isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFFF7700), size: 28),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              if (updated == true) _loadProfileData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: const Color(0xFFFF7700),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Profile Avatar Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF7700), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7700).withValues(alpha: 0.15),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundImage: NetworkImage(_getProfilePicUrl(_profilePic)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                            if (updated == true) _loadProfileData();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7700),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_userName ☀️',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_userPhone • $_userEmail',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Devotional Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("1,296", "Total Jap", "📿"),
                  _buildStatItem("14", "Bhajans", "🎵"),
                  _buildStatItem("7 Days", "Streak", "🔥"),
                  _buildStatItem("1 Tour", "Yatras", "⛰️"),
                ],
              ),

              const SizedBox(height: 16),

              // MANDAL PROFILE HIGHLIGHT CARD (Only shown if registered for an active/upcoming event)
              if (_myMandalRegistration != null &&
                  _isMandalEventValid &&
                  (_myMandalRegistration!['mandalName']?.toString().trim().isNotEmpty ?? false)) ...[
                Builder(
                  builder: (context) {
                    final mandalName = _myMandalRegistration!['mandalName']?.toString() ?? 'My Mandal';
                    final status = _myMandalRegistration!['status']?.toString() ?? 'Pending';
                    final isApproved = status.toLowerCase() == 'approved';
                    final mandalLogo = (_myMandalRegistration!['logo'] ?? _myMandalRegistration!['avatar'] ?? _myMandalRegistration!['logoUrl'])?.toString();
                    final mandalCover = (_myMandalRegistration!['cover'] ?? _myMandalRegistration!['coverUrl'] ?? _myMandalRegistration!['imageUrl'])?.toString();

                    return GestureDetector(
                      onTap: () async {
                        if (isApproved) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MandalProfileScreen(
                                mandalName: mandalName,
                                isOwnProfile: true,
                                avatarUrl: mandalLogo,
                                coverUrl: mandalCover,
                              ),
                            ),
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MandalStatusTabContent(isStandalone: true),
                            ),
                          );
                        }
                        _loadProfileData();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFEFE6DB)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0E6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFFD8B3)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: _buildMandalCardLogo(mandalLogo),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Mandal Profile",
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2E2A36),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isApproved ? const Color(0xFFA5D6A7) : const Color(0xFFFFB74D),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isApproved ? Icons.check_circle_rounded : Icons.pending_rounded,
                                                  color: isApproved ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  status,
                                                  style: GoogleFonts.outfit(
                                                    color: isApproved ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "$mandalName 🚩",
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF7700),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E9E9E), size: 18),
                              ],
                            ),
                            if (isApproved) ...[
                              const SizedBox(height: 14),
                              const Divider(color: Color(0xFFF0E8DF), height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMandalChip(
                                    Icons.add_photo_alternate_rounded,
                                    "Add Posts",
                                    onTap: () async {
                                      final check = await UtsavService.checkFestivalStartedForMandal(mandalName: mandalName);
                                      if (check['isStarted'] != true) {
                                        _showFestivalNotStartedDialog(context, check, action: "Post");
                                        return;
                                      }
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateMandalPostScreen(mandalName: mandalName),
                                        ),
                                      );
                                      if (result != null && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("🎉 Post published to Mandal Profile!"),
                                            backgroundColor: Color(0xFFFF7700),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  _buildMandalChip(
                                    Icons.video_library_rounded,
                                    "Add Reels",
                                    onTap: () async {
                                      final check = await UtsavService.checkFestivalStartedForMandal(mandalName: mandalName);
                                      if (check['isStarted'] != true) {
                                        _showFestivalNotStartedDialog(context, check, action: "Reel");
                                        return;
                                      }
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateMandalReelScreen(mandalName: mandalName),
                                        ),
                                      );
                                      if (result != null && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("🎬 Reel published successfully!"),
                                            backgroundColor: Color(0xFFFF7700),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  _buildMandalChip(
                                    Icons.sensors_rounded,
                                    "Go Live",
                                    onTap: () async {
                                      final check = await UtsavService.checkFestivalStartedForMandal(mandalName: mandalName);
                                      if (check['isStarted'] != true) {
                                        _showFestivalNotStartedDialog(context, check, action: "Live Darshan");
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GoLiveStudioScreen(mandalName: mandalName),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // 1. Account Settings
              _buildSectionHeader("Account Settings"),
              const SizedBox(height: 10),
              Container(
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildNavTile(
                      icon: Icons.person_outline_rounded,
                      title: "Edit Profile",
                      subtitle: "Update name, photo & spiritual bio",
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                        if (updated == true) _loadProfileData();
                      },
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildNavTile(
                      icon: Icons.favorite_rounded,
                      title: "Favourite Bhajans",
                      subtitle: "View liked & saved devotional bhajans",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FavouriteBhajansScreen()),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildNavTile(
                      icon: Icons.bookmark_outline_rounded,
                      title: "Saved Library & Items",
                      subtitle: "View bookmarked Granths & Chapters",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SavedItemsScreen()),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildNavTile(
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Security & login credentials",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. App Preferences
              _buildSectionHeader("App Preferences"),
              const SizedBox(height: 10),
              Container(
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: "Push Notifications",
                      subtitle: "Alerts for daily darshan & live aartis",
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildSwitchTile(
                      title: "Daily Jap Reminder",
                      subtitle: "Reminds you to complete 108 counts",
                      value: _dailyReminder,
                      onChanged: (val) => setState(() => _dailyReminder = val),
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildSwitchTile(
                      title: "Beads Sound Effects",
                      subtitle: "Plays haptic click sound on Jap tap",
                      value: _soundEffects,
                      onChanged: (val) => setState(() => _soundEffects = val),
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text(
                        "Spiritual Language",
                        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        "Currently set to $_selectedLanguage",
                        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.5), fontSize: 12),
                      ),
                      trailing: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: Colors.white,
                        underline: const SizedBox(),
                        style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontWeight: FontWeight.bold, fontSize: 14),
                        items: ["English", "Hindi", "Gujarati"].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLanguage = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Legal & Support
              _buildSectionHeader("Legal & Help"),
              const SizedBox(height: 10),
              Container(
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildNavTile(
                      icon: Icons.description_outlined,
                      title: "Terms & Conditions",
                      subtitle: "App rules & spiritual guidelines",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildNavTile(
                      icon: Icons.shield_outlined,
                      title: "Privacy Policy",
                      subtitle: "Data protection & privacy details",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 1),
                    _buildNavTile(
                      icon: Icons.help_outline_rounded,
                      title: "Help & Support",
                      subtitle: "FAQs, contact support & app info",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF3333),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFFFCCCC), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    "Log Out from Account",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _showLogoutConfirmDialog,
                ),
              ),
              SizedBox(height: isTab ? 140 + bottomPad : 40.0),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEFE6DB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2E2A36),
        ),
      ),
    );
  }

  void _showFestivalNotStartedDialog(BuildContext context, Map<String, dynamic> check, {required String action}) {
    final festName = (check['festivalName'] ?? 'Festival').toString();
    final fStart = (check['formattedDate'] ?? check['startDate'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7700).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFFF7700),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Festival Not Started Yet ⏳",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Text(
                  festName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Posts, Reels and Live streaming will unlock once $festName begins on $fStart.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Understood",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMandalChip(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE0CC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFF7700), size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, String emoji) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEFE6DB)),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF2E2A36).withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF7700), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.5), fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.5), fontSize: 12),
      ),
      value: value,
      activeThumbColor: const Color(0xFFFF7700),
      activeTrackColor: const Color(0xFFFF7700).withValues(alpha: 0.2),
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.grey.withValues(alpha: 0.15),
      onChanged: onChanged,
    );
  }
}
