import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, bool> _prefs = {
    'japReminders': true,
    'liveDarshan': true,
    'yatraUpdates': true,
    'festivalsAndMandal': true,
    'granthAndBhajan': true,
    'socialAndChat': true,
    'panchangDaily': true,
    'quietHoursEnabled': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? sp.getString('token') ?? '';
      if (token.isNotEmpty) {
        final serverPrefs = await ApiService.getNotificationPreferences(token);
        if (mounted && serverPrefs.isNotEmpty) {
          setState(() {
            _prefs = {..._prefs, ...serverPrefs};
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load notification preferences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    final prev = _prefs[key] ?? true;
    setState(() {
      _prefs[key] = value;
      _isSaving = true;
    });

    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? sp.getString('token') ?? '';
      if (token.isNotEmpty) {
        await ApiService.updateNotificationPreferences(token, {key: value});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _prefs[key] = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF7700),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7700)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _buildSectionHeader('SPIRITUAL & DAILY ALERTS'),
                _buildToggleCard(
                  icon: Icons.self_improvement_rounded,
                  title: 'Jap & Streak Reminders',
                  subtitle: 'Morning/Evening Jap, Streak Saver & Milestones',
                  prefKey: 'japReminders',
                ),
                _buildToggleCard(
                  icon: Icons.live_tv_rounded,
                  title: 'Live Darshan & Aarti',
                  subtitle: 'Temple Live alerts, Mangala & Sandhya Aarti',
                  prefKey: 'liveDarshan',
                ),
                _buildToggleCard(
                  icon: Icons.wb_sunny_rounded,
                  title: 'Daily Panchang & Weekly Report',
                  subtitle: 'Weekday deity blessings, Tithi & weekly summary',
                  prefKey: 'panchangDaily',
                ),
                const SizedBox(height: 14),
                _buildSectionHeader('COMMUNITY & LIBRARY'),
                _buildToggleCard(
                  icon: Icons.explore_rounded,
                  title: 'Yatra & Sangha Groups',
                  subtitle: 'Group invites, live streams & temple milestones',
                  prefKey: 'yatraUpdates',
                ),
                _buildToggleCard(
                  icon: Icons.celebration_rounded,
                  title: 'Utsav & Mandal Updates',
                  subtitle: 'Festival countdowns, Mandal posts & events',
                  prefKey: 'festivalsAndMandal',
                ),
                _buildToggleCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Granth, Shloka & Bhajan',
                  subtitle: 'Daily Gita Shloka, new chapters & bhajans',
                  prefKey: 'granthAndBhajan',
                ),
                _buildToggleCard(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Social & Chat Messages',
                  subtitle: 'Follow requests, personal & group chat alerts',
                  prefKey: 'socialAndChat',
                ),
                const SizedBox(height: 14),
                _buildSectionHeader('DO NOT DISTURB'),
                _buildToggleCard(
                  icon: Icons.bedtime_rounded,
                  title: 'Quiet Hours (10:30 PM – 5:30 AM IST)',
                  subtitle:
                      'Silence non-urgent reminders at night (chat & security still arrive)',
                  prefKey: 'quietHoursEnabled',
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: const Color(0xFF9E8A78),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String prefKey,
  }) {
    final enabled = _prefs[prefKey] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: SwitchListTile(
        value: enabled,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFFFF7700),
        onChanged: (val) => _togglePref(prefKey, val),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFF7700), size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E2A36),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF7B7066),
          ),
        ),
      ),
    );
  }
}
