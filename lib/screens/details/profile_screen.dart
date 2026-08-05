import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/change_password_screen.dart';
import '../profile/terms_conditions_screen.dart';
import '../profile/privacy_policy_screen.dart';
import '../profile/help_support_screen.dart';
import '../../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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

              const SizedBox(height: 28),

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
