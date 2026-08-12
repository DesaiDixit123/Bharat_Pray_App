import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/jap_models.dart';
import '../../models/particles.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import '../../services/jap_session_controller.dart';
import 'darshan_runtime_screen.dart';
import 'upload_god_photo_screen.dart';

// ─────────────────────────────────────────────
// Main Jap List Screen
// ─────────────────────────────────────────────
class JapCounterScreen extends StatefulWidget {
  final bool isTab;
  const JapCounterScreen({super.key, this.isTab = false});

  @override
  State<JapCounterScreen> createState() => _JapCounterScreenState();
}

class _JapCounterScreenState extends State<JapCounterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  String _token = '';
  List<JapConfig> _allJaps = [];

  // Dynamic user profile fields matching HomeScreen
  String _profileName = 'Devotee';
  String _profilePic = '';
  int _notificationCount = 2;
  int _messageCount = 1;

  @override
  void initState() {
    super.initState();
    _fetchJaps();
  }

  Future<void> _fetchJaps() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';

    // Load local SharedPreferences profile cache first
    _profileName = prefs.getString('user_name') ?? 'Ayush Kyada';
    _profilePic = prefs.getString('profile_pic') ?? '';

    // 1. Fetch dynamic user info (non-blocking)
    if (_token.isNotEmpty) {
      try {
        final homeData = await ApiService.getDarshanHome(_token);
        if (homeData['user'] != null) {
          _profileName = homeData['user']['name'] ?? _profileName;
          _profilePic = homeData['user']['profile_pic'] ?? _profilePic;
          _notificationCount = homeData['notificationCount'] ?? 2;
          _messageCount = homeData['messageCount'] ?? 1;
        }
      } catch (e) {
        debugPrint('[JapCounterScreen] Error fetching user profile: $e');
      }
    }

    // 2. Fetch remote japs (isolated try-catch so failures don't block offline japs)
    List<JapConfig> remoteJaps = [];
    if (_token.isNotEmpty) {
      try {
        final data = await ApiService.getJapList(_token);
        remoteJaps = data.map((e) => JapConfig.fromJson(e)).toList();
      } catch (e) {
        debugPrint('[JapCounterScreen] Error fetching remote japs: $e');
      }
    }

    // 3. Load custom user Japs from local offline storage (always runs)
    List<JapConfig> customJaps = [];
    try {
      final customJapsRaw = await JapOfflineRepository.getCustomJaps();
      customJaps = customJapsRaw
          .map((e) => JapConfig.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('[JapCounterScreen] Error loading local custom japs: $e');
    }

    // 4. Combine and overlay local cached progress
    final combined = [...customJaps, ...remoteJaps];
    try {
      for (final jap in combined) {
        final cached = await JapOfflineRepository.getProgress(
          jap.id,
          defaultTarget: jap.targetCount,
        );
        if (cached['count']! > 0 || cached['completedMalas']! > 0) {
          final totalCached =
              (cached['completedMalas']! * jap.targetCount) + cached['count']!;
          if (totalCached > jap.progress) {
            jap.progress = totalCached;
          }
        }
      }
    } catch (e) {
      debugPrint('[JapCounterScreen] Error overlaying progress: $e');
    }

    if (mounted) {
      setState(() {
        _allJaps = combined;
        _isLoading = false;
      });
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

  void _showMailNotificationSheet(
    BuildContext context,
    String title,
    String content,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0E6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    icon: const Icon(Icons.close, color: Color(0xFF2E2A36)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                ),
                child: Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  List<JapConfig> get _filteredJaps {
    if (_searchQuery.isEmpty) return _allJaps;
    final q = _searchQuery.toLowerCase();
    return _allJaps
        .where(
          (j) =>
              j.name.toLowerCase().contains(q) ||
              j.shlokText.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openJapDetail(JapConfig entry) async {
    final updatedProgress = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => JapDetailScreen(entry: entry)),
    );

    if (updatedProgress != null) {
      setState(() {
        entry.progress = updatedProgress;
      });

      // Save locally
      await JapOfflineRepository.saveProgress(
        japId: entry.id,
        count: updatedProgress % entry.targetCount,
        completedMalas: updatedProgress ~/ entry.targetCount,
      );

      // Trigger cloud sync if remote
      if (_token.isNotEmpty && entry.id.isNotEmpty && entry.id.length == 24) {
        try {
          await ApiService.syncJapProgress(_token, entry.id, updatedProgress);
          await JapOfflineRepository.markSynced(entry.id);
        } catch (e) {
          debugPrint('[JapCounterScreen] Background sync error: $e');
        }
      }
    }
  }

  Future<void> _onAddPhotoTap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadGodPhotoScreen()),
    );
    if (result == null || !mounted) return;

    if (result is CustomJapDetails) {
      final newCustomConfig = JapConfig(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: result.name,
        thumbnailUrl: result.coverImagePath,
        darshanImageUrl: result.godImagePath,
        shlokText: '',
        shlokAudioUrl: result.audioFilePath,
        targetCount: result.chantCount,
        progress: 0,
        effectPack: EffectPack.resolve(
          name: result.name,
          particleShape: result.particleEffect,
        ),
      );

      await JapOfflineRepository.saveCustomJap({
        '_id': newCustomConfig.id,
        'name': newCustomConfig.name,
        'thumbnail': newCustomConfig.thumbnailUrl,
        'darshanImage': newCustomConfig.darshanImageUrl,
        'shlokText': newCustomConfig.shlokText,
        'shlokAudio': newCustomConfig.shlokAudioUrl,
        'targetCount': newCustomConfig.targetCount,
        'progress': 0,
      });

      if (!mounted) return;
      setState(() {
        _allJaps.insert(0, newCustomConfig);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF7700),
          content: Text(
            'Added "${result.name}" successfully!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredJaps;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E6),
      body: SafeArea(
        child: Column(
          children: [
            // ── Dynamic Header Matching HomeScreen ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFE6D5),
                      border: Border.all(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: _profilePic.isNotEmpty
                          ? Image.network(
                              _resolveProfilePic(_profilePic),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    _profileName.isNotEmpty
                                        ? _profileName[0].toUpperCase()
                                        : 'U',
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
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF7700),
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                _profileName.isNotEmpty
                                    ? _profileName[0].toUpperCase()
                                    : 'U',
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          '${_getGreeting()}, $_profileName ${_getGreetingIcon()}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showMailNotificationSheet(
                      context,
                      "Messages",
                      "You have a new message from the Somnath Temple Trust: 'The morning Aarti timings have been adjusted to 06:00 AM due to the summer season.'",
                    ),
                    child: SvgPicture.string(
                      _getMailSvg(_messageCount),
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showMailNotificationSheet(
                      context,
                      "Notifications",
                      "📿 Daily Chant Reminder: You have not completed your Jap goals for today. Tap the center bead button to start chanting.",
                    ),
                    child: SvgPicture.string(
                      _getBellSvg(_notificationCount),
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search Bar & Go Back Row ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC8A882),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.string(
                          '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''',
                          width: 15,
                          height: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(89),
                        border: Border.all(
                          color: const Color(0xFFC8A882),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFFC8A882),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search gods, temples, mantras...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(
                              0xFFC8A882,
                            ).withValues(alpha: 0.6),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.string(
                              '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z" stroke="#C8A882" stroke-width="1.33333"/>
<path d="M21 20.9999L16.65 16.6499" stroke="#C8A882" stroke-width="1.33333"/>
</svg>''',
                              width: 18,
                              height: 18,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFC8A882),
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Add Photo Button ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _onAddPhotoTap,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                    ),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add Photo',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Card List ────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF7700),
                onRefresh: _fetchJaps,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF7700),
                        ),
                      )
                    : filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                'No results found',
                                style: GoogleFonts.outfit(
                                  color: const Color(
                                    0xFF2E2A36,
                                  ).withValues(alpha: 0.4),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          widget.isTab
                              ? 140 + MediaQuery.of(context).padding.bottom
                              : 20,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final jap = filtered[index];
                          return _JapCard(
                            entry: jap,
                            onTap: () => _openJapDetail(jap),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

// ─────────────────────────────────────────────
// Individual Jap Card
// ─────────────────────────────────────────────
class _JapCard extends StatelessWidget {
  final JapConfig entry;
  final VoidCallback onTap;

  const _JapCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = entry.progress;
    final target = entry.targetCount;
    final progressRatio = (progress / target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFFC8A882).withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E2A36).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                bottomLeft: Radius.circular(32),
              ),
              child: SizedBox(
                width: 140,
                height: double.infinity,
                child: _buildImage(entry.thumbnailUrl),
              ),
            ),

            // Right Info Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.shlokText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerifDevanagari(
                        fontSize: 12,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),

                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              backgroundColor: const Color(0xFFFFF0E6),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                entry.effectPack.primaryColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progress / $target',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: entry.effectPack.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chant CTA Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              entry.effectPack.primaryColor,
                              entry.effectPack.secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Chant 📿',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: const Color(0xFFFFF0E6),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFFC8A882),
          size: 36,
        ),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        // Downsample to thumbnail dimensions to avoid decoding full-res images into memory
        cacheWidth: 280,
        cacheHeight: 360,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFFFF0E6),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFC8A882),
            size: 36,
          ),
        ),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFFFF0E6),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFC8A882),
            size: 36,
          ),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFFFF0E6),
        child: const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFFC8A882),
          size: 36,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail / Counting Screen – Image Reveal Engine
// ─────────────────────────────────────────────
class JapDetailScreen extends StatefulWidget {
  final JapConfig entry;
  const JapDetailScreen({super.key, required this.entry});

  @override
  State<JapDetailScreen> createState() => _JapDetailScreenState();
}

class _JapDetailScreenState extends State<JapDetailScreen>
    with TickerProviderStateMixin {
  late int _count;
  late int _target;
  int _completedMalas = 0;
  JapLifecycle _lifecycle = JapLifecycle.idle;

  JapLifecycle get lifecycle => _lifecycle;

  late List<int> _shuffledIndices;
  late List<Offset> _jitteredPoints;

  late final AudioPlayer _audioPlayer;
  late final AnimationController _revealController;
  late final AnimationController _completionController;
  late final AnimationController _ambientController;

  int? _revealingTile;
  bool _canTap = true;
  bool _isAudioPlaying = false;
  bool _isRevealAnimating = false;
  bool _showContinueButton = false;
  double _buttonScale = 1.0;

  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _debounceDuration = Duration(milliseconds: 80);

  ImageProvider? _imageProvider;

  final List<EmberParticle> _embers = [];
  final List<GlowRing> _glowRings = [];
  final List<PetalParticle> _petals = [];
  final List<TapSparkParticle> _tapSparks = [];
  final List<SpiralSparkParticle> _spiralSparks = [];
  final List<FloatingOmText> _floatingOms = [];
  final List<MistParticle> _mistParticles = [];
  final List<DivineSymbolParticle> _divineSymbolParticles = [];
  final List<SmokeParticle> _smokePuffs = [];
  final List<PetalParticle> _tapPetals = [];
  bool _autoRepeat = false;
  DateTime _lastMistTime = DateTime.now();

  int get _totalProgress => (_completedMalas * _target) + _count;


  List<int> _buildShuffled(int malaSeed) {
    final rng = math.Random(widget.entry.name.hashCode ^ malaSeed);
    return List.generate(_target, (i) => i)..shuffle(rng);
  }

  List<Offset> _generateJitteredPoints(int malaSeed) {
    final rng = math.Random(widget.entry.name.hashCode ^ (malaSeed + 123));
    List<Offset> points = [];

    final int cols = math.max(1, math.sqrt(_target / 1.875).round());
    final int rows = (_target / cols).ceil();

    final double cellWidth = 353.0 / cols;
    final double cellHeight = 650.0 / rows;

    for (int i = 0; i < _target; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final cellCenterX = col * cellWidth + (cellWidth / 2.0);
      final cellCenterY = row * cellHeight + (cellHeight / 2.0);

      final dx = (rng.nextDouble() * (cellWidth * 0.4)) - (cellWidth * 0.2);
      final dy = (rng.nextDouble() * (cellHeight * 0.4)) - (cellHeight * 0.2);

      points.add(
        Offset(
          (cellCenterX + dx).clamp(10.0, 343.0),
          (cellCenterY + dy).clamp(10.0, 640.0),
        ),
      );
    }
    return points;
  }

  @override
  void initState() {
    super.initState();

    _target = widget.entry.targetCount;
    final totalProgress = widget.entry.progress;
    _completedMalas = totalProgress ~/ _target;
    _count = totalProgress % _target;

    _shuffledIndices = _buildShuffled(_completedMalas);
    _jitteredPoints = _generateJitteredPoints(_completedMalas);

    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isAudioPlaying = false);
        _tryUnlockTap();
      }
    });

    _ambientController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            _updateParticlesNoSetState();
          });
    _ambientController.repeat();

    _initEmbers();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (_completedMalas > 0) {
      _completionController.value = 1.0;
      _showContinueButton = true;
      _lifecycle = JapLifecycle.darshanActive;
    } else if (_count > 0) {
      _lifecycle = JapLifecycle.inProgress;
    } else {
      _lifecycle = JapLifecycle.started;
    }


  }

  void _tryUnlockTap() {
    if (!_isRevealAnimating && !_isAudioPlaying && _count < _target) {
      if (mounted) {
        setState(() => _canTap = true);
      }
    }
  }

  void _resetMala() {
    if (mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _count = 0;
        _completedMalas = 0;
        _canTap = true;
        _isAudioPlaying = false;
        _isRevealAnimating = false;
        _showContinueButton = false;
        _lifecycle = JapLifecycle.started;
        _shuffledIndices = _buildShuffled(0);
        _jitteredPoints = _generateJitteredPoints(0);
        _embers.clear();
        _petals.clear();
        _glowRings.clear();
        _tapSparks.clear();
        _spiralSparks.clear();
        _floatingOms.clear();
        _mistParticles.clear();
        _divineSymbolParticles.clear();
        _smokePuffs.clear();
        _tapPetals.clear();
      });
      _completionController.reset();
      _revealController.reset();
      JapOfflineRepository.saveProgress(
        japId: widget.entry.id,
        count: 0,
        completedMalas: 0,
      );
    }
  }

  void _initEmbers() {
    final rng = math.Random();
    _embers.clear();
    for (int i = 0; i < 25; i++) {
      _embers.add(
        EmberParticle(
          x: rng.nextDouble() * 393,
          y: rng.nextDouble() * 1010,
          vx: (rng.nextDouble() * 0.5) - 0.25,
          vy: rng.nextDouble() * 0.6 + 0.4,
          size: rng.nextDouble() * 2.8 + 1.2,
          alpha: rng.nextDouble() * 0.45 + 0.15,
          speedMultiplier: rng.nextDouble() * 0.5 + 0.8,
        ),
      );
    }
  }

  void _initPetals() {
    final rng = math.Random();
    final pack = widget.entry.effectPack;
    _petals.clear();
    for (int i = 0; i < 30; i++) {
      final color = pack.particleColors[i % pack.particleColors.length];
      _petals.add(
        PetalParticle(
          x: rng.nextDouble() * 393,
          y: rng.nextDouble() * 1010 - 1010,
          vy: (rng.nextDouble() * 1.2 + 0.9) * pack.particleVelocity,
          angle: rng.nextDouble() * 2 * math.pi,
          rotationSpeed: (rng.nextDouble() * 0.035) - 0.0175,
          size: rng.nextDouble() * 8.0 + 8.0,
          windFreq: rng.nextDouble() * 1.3 + 0.7,
          windAmp: rng.nextDouble() * 1.2 + 0.6,
          color: color,
          shape: pack.shape,
        ),
      );
    }
  }

  void _updateParticlesNoSetState() {
    final bool isCompleted = _completedMalas > 0 || _count >= _target;

    for (final ember in _embers) {
      ember.update(393, 1010);
    }

    _glowRings.removeWhere((ring) => !ring.update());
    _tapSparks.removeWhere((spark) => !spark.update());
    _spiralSparks.removeWhere((spark) => !spark.update());
    _floatingOms.removeWhere((om) => !om.update());
    _mistParticles.removeWhere((mist) => !mist.update());
    _divineSymbolParticles.removeWhere((sym) => !sym.update());
    _smokePuffs.removeWhere((p) => !p.update());
    for (final petal in _tapPetals) {
      petal.update(353, 520);
    }
    _tapPetals.removeWhere((p) => p.y > 540);

    // Emit atmospheric mist periodically
    final now = DateTime.now();
    if (now.difference(_lastMistTime).inMilliseconds > 400 && _mistParticles.length < 12) {
      _lastMistTime = now;
      final rng = math.Random();
      final pack = widget.entry.effectPack;
      _mistParticles.add(
        MistParticle(
          x: rng.nextDouble() * 353,
          y: 650.0 + rng.nextDouble() * 20,
          vx: (rng.nextDouble() - 0.5) * 0.8,
          vy: -(rng.nextDouble() * 1.2 + 0.6),
          size: rng.nextDouble() * 50 + 40,
          maxAlpha: rng.nextDouble() * 0.12 + 0.05,
          maxLife: rng.nextDouble() * 3.0 + 2.5,
          color: pack.haloGlowColor,
        ),
      );
    }



    if (isCompleted) {
      if (_petals.isEmpty) {
        _initPetals();
      }
      for (final petal in _petals) {
        petal.update(393, 1010);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageProvider == null) {
      final path = widget.entry.darshanImageUrl.isNotEmpty
          ? widget.entry.darshanImageUrl
          : widget.entry.thumbnailUrl;
      if (path.startsWith('http')) {
        _imageProvider = NetworkImage(path);
      } else if (path.startsWith('assets/')) {
        _imageProvider = AssetImage(path);
      } else {
        _imageProvider = FileImage(File(path));
      }
      precacheImage(_imageProvider!, context);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _revealController.dispose();
    _completionController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  // ── Tap handler with Double-Tap Protection & Boundary Validation ──────
  void _increment() async {
    // 1. Hardware Debounce Guard
    final now = DateTime.now();
    if (now.difference(_lastTapTime) < _debounceDuration) {
      return;
    }
    _lastTapTime = now;

    if (!_canTap) return;
    if (_completedMalas > 0 || _count >= _target) {
      _startNextMala();
      return;
    }

    // 2. Devotion Milestones Haptics
    final int halfTarget = _target ~/ 2;
    final int nearCompletion = (_target * 0.9).round();
    if ((_count + 1) == halfTarget) {
      HapticFeedback.mediumImpact();
    } else if ((_count + 1) == nearCompletion) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }

    // 3. Coordinate calculation
    final revealPos = _count % _target;
    final tileIdx = _shuffledIndices[revealPos];
    final revealPt = _jitteredPoints[tileIdx];

    setState(() {
      _canTap = false;
      _isRevealAnimating = true;
      _isAudioPlaying = true;
      _buttonScale = 0.82;
      _revealingTile = tileIdx;

      _count = math.min(_count + 1, _target);
      _lifecycle = _count >= _target
          ? JapLifecycle.completed
          : JapLifecycle.inProgress;

      if (_count >= _target) {
        final rng = math.Random();
        for (int i = 0; i < 12; i++) {
          final angle =
              (i / 12.0) * 2 * math.pi + (rng.nextDouble() * 0.4 - 0.2);
          final speed = rng.nextDouble() * 5.0 + 3.5;
          final sparkColors = [
            const Color(0xFFFFD700),
            const Color(0xFFFF9100),
            const Color(0xFFFFFFFF),
            widget.entry.effectPack.primaryColor,
          ];
          _tapSparks.add(
            TapSparkParticle(
              position: revealPt,
              vx: math.cos(angle) * speed,
              vy: math.sin(angle) * speed,
              maxLife: rng.nextDouble() * 0.35 + 0.35,
              size: rng.nextDouble() * 4.0 + 3.0,
              color: sparkColors[i % sparkColors.length],
            ),
          );
        }

        for (int i = 0; i < 8; i++) {
          final startAngle = (i / 8.0) * 2 * math.pi;
          _spiralSparks.add(
            SpiralSparkParticle(
              center: revealPt,
              angle: startAngle,
              speed:
                  (i % 2 == 0 ? 1.0 : -1.0) * (rng.nextDouble() * 0.18 + 0.12),
              radialSpeed: rng.nextDouble() * 2.8 + 2.2,
              maxLife: rng.nextDouble() * 0.35 + 0.40,
              size: rng.nextDouble() * 3.5 + 2.5,
              color: i % 2 == 0
                  ? const Color(0xFFFFD700)
                  : widget.entry.effectPack.primaryColor,
            ),
          );
        }

        final omTexts = ['ॐ', 'राम', 'जय', 'ॐ', 'हरि', 'नमः'];
        _floatingOms.add(
          FloatingOmText(
            position: revealPt,
            maxLife: 0.65,
            text: omTexts[(_count - 1) % omTexts.length],
          ),
        );

        _glowRings.add(
          GlowRing(
            position: revealPt,
            maxRadius: 180.0,
            maxLife: 1.1,
            color: widget.entry.effectPack.primaryColor,
          ),
        );
      }
    });

  /// Spawn god-category specific particle burst using effectPack.shape (reliable enum)
  void spawnCategoryParticles(Offset center) {
    final rng = math.Random();
    final pack = widget.entry.effectPack;
    final primary = pack.primaryColor;
    final secondary = pack.secondaryColor;
    final accent = pack.accentColor;

    switch (pack.shape) {
      case ParticleShapeType.flame:
        // Shiva / fire — blue-white lightning arc sparks
        final colors = [const Color(0xFF64B5F6), const Color(0xFFB3E5FC), primary, Colors.white];
        for (int i = 0; i < 12; i++) {
          final angle = (i / 12.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 6 + 4),
            vy: math.sin(angle) * (rng.nextDouble() * 6 + 4),
            maxLife: rng.nextDouble() * 0.4 + 0.3,
            size: rng.nextDouble() * 5 + 2,
            color: colors[i % colors.length],
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 95, maxLife: 0.65, color: primary));
        break;

      case ParticleShapeType.feather:
        // Ganesha / Krishna — scallop: spiral peacock sparks
        final colors = [primary, secondary, accent, const Color(0xFF81C784)];
        for (int i = 0; i < 10; i++) {
          final startAngle = (i / 10.0) * 2 * math.pi;
          _spiralSparks.add(SpiralSparkParticle(
            center: center,
            angle: startAngle,
            speed: (i % 2 == 0 ? 1.2 : -1.2) * (rng.nextDouble() * 0.2 + 0.1),
            radialSpeed: rng.nextDouble() * 3.5 + 2.5,
            maxLife: rng.nextDouble() * 0.5 + 0.35,
            size: rng.nextDouble() * 4.5 + 2,
            color: colors[i % colors.length],
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 80, maxLife: 0.7, color: primary));
        break;

      case ParticleShapeType.spark:
        // Hanuman / Durga — fire burst — fast outward sparks
        final colors = [primary, secondary, accent, const Color(0xFFFFFFFF)];
        for (int i = 0; i < 16; i++) {
          final angle = (i / 16.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 9 + 5),
            vy: math.sin(angle) * (rng.nextDouble() * 9 + 5),
            maxLife: rng.nextDouble() * 0.3 + 0.2,
            size: rng.nextDouble() * 6 + 3,
            color: colors[i % colors.length],
          ));
        }
        // Chakra spin
        for (int i = 0; i < 6; i++) {
          _spiralSparks.add(SpiralSparkParticle(
            center: center,
            angle: (i / 6.0) * 2 * math.pi,
            speed: (i.isEven ? 1.8 : -1.8) * (rng.nextDouble() * 0.12 + 0.08),
            radialSpeed: rng.nextDouble() * 4 + 3,
            maxLife: rng.nextDouble() * 0.35 + 0.3,
            size: rng.nextDouble() * 5 + 3,
            color: i.isEven ? primary : accent,
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 110, maxLife: 0.55, color: primary));
        break;

      case ParticleShapeType.leaf:
        // Vishnu / nature — blue-gold Sudarshana chakra spin
        final colors = [primary, secondary, accent];
        for (int i = 0; i < 8; i++) {
          _spiralSparks.add(SpiralSparkParticle(
            center: center,
            angle: (i / 8.0) * 2 * math.pi,
            speed: (i.isEven ? 1.0 : -1.0) * (rng.nextDouble() * 0.18 + 0.1),
            radialSpeed: rng.nextDouble() * 3.5 + 2.5,
            maxLife: rng.nextDouble() * 0.4 + 0.35,
            size: rng.nextDouble() * 4 + 2.5,
            color: colors[i % colors.length],
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 95, maxLife: 0.65, color: primary));
        break;

      case ParticleShapeType.ash:
        // Subtle — gentle floating sparkle shower
        final colors = [primary, secondary, accent];
        for (int i = 0; i < 10; i++) {
          final angle = rng.nextDouble() * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center + Offset((rng.nextDouble() - 0.5) * 24, (rng.nextDouble() - 0.5) * 24),
            vx: math.cos(angle) * (rng.nextDouble() * 3 + 1),
            vy: math.sin(angle) * (rng.nextDouble() * 3 + 1) - 2,
            maxLife: rng.nextDouble() * 0.6 + 0.4,
            size: rng.nextDouble() * 5 + 3,
            color: colors[i % colors.length],
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 70, maxLife: 0.75, color: primary));
        break;

      case ParticleShapeType.petal:
      case ParticleShapeType.custom:
        // Lakshmi / default — golden lotus bloom
        final colors = [primary, secondary, accent, Colors.white];
        for (int i = 0; i < 10; i++) {
          final angle = (i / 10.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 5 + 3),
            vy: math.sin(angle) * (rng.nextDouble() * 5 + 3) - 1,
            maxLife: rng.nextDouble() * 0.45 + 0.3,
            size: rng.nextDouble() * 5 + 2,
            color: colors[i % colors.length],
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 80, maxLife: 0.65, color: primary));
        break;
    }

    // Floating God-Specific Mantra Text on every tap
    final mantras = pack.tapMantras.isNotEmpty ? pack.tapMantras : ['ॐ', 'जय', 'हरि', 'नमः'];
    _floatingOms.add(FloatingOmText(
      position: center,
      maxLife: 0.85,
      text: mantras[_count % mantras.length],
    ));

    // Spawn Divine Symbol (Trishul, Shankh, Flute, Bow, Lotus, Chakra, ॐ)
    _divineSymbolParticles.add(DivineSymbolParticle(
      position: center,
      symbol: pack.divineSymbol,
      color: pack.primaryColor,
      maxLife: 0.95,
      vy: -2.0,
    ));

    // 10 Random Natural Element Effects (Leaf, Water Ripple, Yajna Fire, Rose Petals, Golden Lotus, Lightning, Star Dust, Cloud Smoke, Peacock Aura, Sunbeams)
    final naturalEffectType = rng.nextInt(10);
    switch (naturalEffectType) {
      case 0:
        // 🍃 1. Leaf Drift (Tulsi / Bilva Leaves)
        for (int i = 0; i < 6; i++) {
          _tapPetals.add(PetalParticle(
            x: center.dx + (rng.nextDouble() - 0.5) * 30,
            y: center.dy + (rng.nextDouble() - 0.5) * 30,
            vy: rng.nextDouble() * 1.5 + 0.8,
            angle: rng.nextDouble() * 2 * math.pi,
            rotationSpeed: (rng.nextDouble() * 0.1) - 0.05,
            size: rng.nextDouble() * 8 + 8,
            windFreq: rng.nextDouble() * 2 + 1,
            windAmp: rng.nextDouble() * 3 + 1,
            color: const Color(0xFF4CAF50), // Bilva leaf green
            shape: ParticleShapeType.leaf,
          ));
        }
        break;

      case 1:
        // 💧 2. Water Ripple & Drop
        for (int i = 0; i < 3; i++) {
          _glowRings.add(GlowRing(
            position: center,
            maxRadius: 60.0 + (i * 35.0),
            maxLife: 0.8 + (i * 0.2),
            color: const Color(0xFF29B6F6), // Ganga jal blue
          ));
        }
        break;

      case 2:
        // 🔥 3. Yajna Fire Embers
        for (int i = 0; i < 8; i++) {
          final angle = (i / 8.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 4 + 2),
            vy: math.sin(angle) * (rng.nextDouble() * 4 + 2) - 3,
            maxLife: rng.nextDouble() * 0.5 + 0.3,
            size: rng.nextDouble() * 6 + 3,
            color: i.isEven ? const Color(0xFFFF5722) : const Color(0xFFFFC107),
          ));
        }
        break;

      case 3:
        // 🌸 4. Rose Petal Shower
        for (int i = 0; i < 6; i++) {
          _tapPetals.add(PetalParticle(
            x: center.dx + (rng.nextDouble() - 0.5) * 30,
            y: center.dy + (rng.nextDouble() - 0.5) * 30,
            vy: rng.nextDouble() * 1.6 + 0.9,
            angle: rng.nextDouble() * 2 * math.pi,
            rotationSpeed: (rng.nextDouble() * 0.08) - 0.04,
            size: rng.nextDouble() * 9 + 8,
            windFreq: rng.nextDouble() * 2 + 1,
            windAmp: rng.nextDouble() * 2 + 1,
            color: const Color(0xFFFF1744), // Crimson rose red
            shape: ParticleShapeType.petal,
          ));
        }
        break;

      case 4:
        // 🪷 5. Golden Lotus Bloom
        for (int i = 0; i < 8; i++) {
          final angle = (i / 8.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 5 + 3),
            vy: math.sin(angle) * (rng.nextDouble() * 5 + 3),
            maxLife: rng.nextDouble() * 0.45 + 0.3,
            size: rng.nextDouble() * 6 + 3,
            color: const Color(0xFFFFD700), // Gold
          ));
        }
        break;

      case 5:
        // ⚡ 6. Divine Lightning Sparks
        for (int i = 0; i < 10; i++) {
          final angle = (i / 10.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 8 + 4),
            vy: math.sin(angle) * (rng.nextDouble() * 8 + 4),
            maxLife: rng.nextDouble() * 0.3 + 0.2,
            size: rng.nextDouble() * 5 + 2,
            color: i.isEven ? Colors.white : const Color(0xFF80DEEA),
          ));
        }
        break;

      case 6:
        // ✨ 7. Star Dust Shower
        for (int i = 0; i < 10; i++) {
          final angle = rng.nextDouble() * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center + Offset((rng.nextDouble() - 0.5) * 30, (rng.nextDouble() - 0.5) * 30),
            vx: math.cos(angle) * (rng.nextDouble() * 3 + 1),
            vy: math.sin(angle) * (rng.nextDouble() * 3 + 1) - 1.5,
            maxLife: rng.nextDouble() * 0.6 + 0.4,
            size: rng.nextDouble() * 4 + 2,
            color: const Color(0xFFFFE082),
          ));
        }
        break;

      case 7:
        // 🌼 8. Marigold Flower Petals (ગલગોટા પંખુડી)
        for (int i = 0; i < 6; i++) {
          _tapPetals.add(PetalParticle(
            x: center.dx + (rng.nextDouble() - 0.5) * 30,
            y: center.dy + (rng.nextDouble() - 0.5) * 30,
            vy: rng.nextDouble() * 1.5 + 0.8,
            angle: rng.nextDouble() * 2 * math.pi,
            rotationSpeed: (rng.nextDouble() * 0.1) - 0.05,
            size: rng.nextDouble() * 9 + 7,
            windFreq: rng.nextDouble() * 2 + 1,
            windAmp: rng.nextDouble() * 2.5 + 1,
            color: i.isEven ? const Color(0xFFFF9800) : const Color(0xFFFFC107), // Marigold gold & orange
            shape: ParticleShapeType.petal,
          ));
        }
        break;

      case 8:
        // 🦚 9. Peacock Feather Swirl
        for (int i = 0; i < 8; i++) {
          _spiralSparks.add(SpiralSparkParticle(
            center: center,
            angle: (i / 8.0) * 2 * math.pi,
            speed: (i % 2 == 0 ? 1.5 : -1.5) * (rng.nextDouble() * 0.15 + 0.1),
            radialSpeed: rng.nextDouble() * 3.5 + 2.5,
            maxLife: rng.nextDouble() * 0.45 + 0.35,
            size: rng.nextDouble() * 5 + 2.5,
            color: i.isEven ? const Color(0xFF00E676) : const Color(0xFF29B6F6),
          ));
        }
        break;

      case 9:
        // ☀️ 10. Surya Sunbeam Burst
        for (int i = 0; i < 12; i++) {
          final angle = (i / 12.0) * 2 * math.pi;
          _tapSparks.add(TapSparkParticle(
            position: center,
            vx: math.cos(angle) * (rng.nextDouble() * 7 + 4),
            vy: math.sin(angle) * (rng.nextDouble() * 7 + 4),
            maxLife: rng.nextDouble() * 0.4 + 0.25,
            size: rng.nextDouble() * 5 + 3,
            color: const Color(0xFFFFB300),
          ));
        }
        _glowRings.add(GlowRing(position: center, maxRadius: 100, maxLife: 0.6, color: const Color(0xFFFF9933)));
        break;
    }
  }

    // 3b. Call category particles after function defined
    spawnCategoryParticles(revealPt);

    // 4. Persistence to local cache
    JapOfflineRepository.saveProgress(
      japId: widget.entry.id,
      count: _count,
      completedMalas: _completedMalas,
    );

    // 5. Milestone background cloud sync (at 27, 54, 81, 108)
    if (_count % 27 == 0 || _count >= _target) {
      _triggerBackgroundSync();
    }

    // 6. Tactile Button spring animation
    Future.delayed(const Duration(milliseconds: 70), () {
      if (mounted) setState(() => _buttonScale = 1.12);
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _buttonScale = 1.0);
    });

    // 7. Unmasking animation
    _revealController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _revealingTile = null;
        _isRevealAnimating = false;
      });
      _tryUnlockTap();
    });

    // 8. Audio playback
    final audioUrl = widget.entry.shlokAudioUrl;
    if (audioUrl != null && audioUrl.isNotEmpty) {
      setState(() => _isAudioPlaying = true);
      try {
        await _audioPlayer.stop();
        if (audioUrl.startsWith('http')) {
          await _audioPlayer.play(UrlSource(audioUrl));
        } else if (audioUrl.startsWith('assets/')) {
          await _audioPlayer.play(
            AssetSource(audioUrl.replaceFirst('assets/', '')),
          );
        } else {
          // Strip file:// prefix if present — DeviceFileSource needs raw path
          final rawPath = audioUrl.startsWith('file://')
              ? audioUrl.replaceFirst('file://', '')
              : audioUrl;
          await _audioPlayer.play(DeviceFileSource(rawPath));
        }

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isAudioPlaying) {
            setState(() => _isAudioPlaying = false);
            _tryUnlockTap();
          }
        });
      } catch (e) {
        debugPrint("[JapAudio] Error playing audio: $e");
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => _isAudioPlaying = false);
          _tryUnlockTap();
        }
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isAudioPlaying = false);
        _tryUnlockTap();
      }
    }

    // 9. 108 Completion & Darshan Reveal
    if (_count >= _target) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() => _lifecycle = JapLifecycle.darshanReveal);
      }
      _completionController.forward(from: 0.0);
      if (_autoRepeat) {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) {
          _startNextMala();
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 5000));
        if (mounted) {
          HapticFeedback.heavyImpact();
          setState(() {
            _showContinueButton = true;
            _lifecycle = JapLifecycle.darshanActive;
          });
        }
      }
    }
  }

  void _triggerBackgroundSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty && widget.entry.id.length == 24) {
        await ApiService.syncJapProgress(
          token,
          widget.entry.id,
          _totalProgress,
        );
        await JapOfflineRepository.markSynced(widget.entry.id);
      }
    } catch (e) {
      debugPrint('[JapDetailScreen] Background sync error: $e');
    }
  }

  void _startNextMala() {
    HapticFeedback.mediumImpact();
    setState(() {
      _completedMalas++;
      _count = 0;
      _showContinueButton = false;
      _isRevealAnimating = false;
      _canTap = true;
      _revealingTile = null;
      _lifecycle = JapLifecycle.started;
      _glowRings.clear();
      _tapSparks.clear();
      _spiralSparks.clear();
      _floatingOms.clear();
      _mistParticles.clear();
      _divineSymbolParticles.clear();
      _petals.clear();
      // Rebuild grid with new seed so shape positions shuffle for the new mala
      _shuffledIndices = _buildShuffled(_completedMalas);
      _jitteredPoints = _generateJitteredPoints(_completedMalas);
    });
    _completionController.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.entry.effectPack;
    final isCompleted = _completedMalas > 0 || _count >= _target;
    final bool isBusy = _isAudioPlaying || !_canTap;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _totalProgress);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0E6),
        body: Stack(
          children: [
            // Background Divine Painter
            AnimatedBuilder(
              animation: _ambientController,
              builder: (ctx, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: DivineBackgroundPainter(
                    timeSeconds: _ambientController.value * 10.0,
                    isCompleted: isCompleted,
                    progressPct: _count / _target,
                  ),
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context, _totalProgress),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC8A882),
                                width: 1.0,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFFC8A882),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ),
                        // Top Bar: Only Reset Button
                        GestureDetector(
                          onTap: _resetMala,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: pack.primaryColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 15,
                                  color: pack.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reset',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: pack.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Darshan Card with Unmasking Canvas
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 353,
                        height: 520,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: pack.primaryColor.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Unmasked Darshan Image
                              if (_imageProvider != null)
                                Image(
                                  image: _imageProvider!,
                                  fit: BoxFit.cover,
                                ),

                              // Interactive Mask & Smoke Painter
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _revealController,
                                  _completionController,
                                  _ambientController,
                                ]),
                                builder: (ctx, _) {
                                  return CustomPaint(
                                    painter: DivineCardPainter(
                                      jitteredPoints: _jitteredPoints,
                                      shuffledIndices: _shuffledIndices,
                                      count: _count,
                                      target: _target,
                                      revealingTileIndex: _revealingTile,
                                      currentRevealProgress:
                                          _revealController.value,
                                      completionFadeProgress:
                                          _completionController.value,
                                      glowRings: _glowRings,
                                      tapSparks: _tapSparks,
                                      spiralSparks: _spiralSparks,
                                      floatingOms: _floatingOms,
                                      mistParticles: _mistParticles,
                                      smokePuffs: _smokePuffs,
                                      tapPetals: _tapPetals,
                                      divineSymbolParticles: _divineSymbolParticles,
                                      timeSeconds:
                                          _ambientController.value * 10.0,
                                      isCompleted: isCompleted,
                                      effectPack: widget.entry.effectPack,
                                    ),
                                  );
                                },
                              ),

                              // Completion Blessing Banner Overlay
                              if (_showContinueButton)
                                Positioned(
                                  bottom: 24,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: pack.primaryColor,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: pack.primaryColor.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pack.blessingTitle,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: pack.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pack.blessingSubtitle,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: const Color(
                                              0xFF2E2A36,
                                            ).withValues(alpha: 0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DarshanRuntimeScreen(
                                                      config: widget.entry,
                                                      sessionController:
                                                          JapSessionController(
                                                            config:
                                                                widget.entry,
                                                            initialCount: widget
                                                                .entry
                                                                .targetCount,
                                                          ),
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  pack.primaryColor,
                                                  pack.secondaryColor,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: pack.primaryColor
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'View Divine Darshan 🙏',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Chant Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.entry.shlokText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerifDevanagari(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Center Chant Bead Button with Count & Audio Playing Disabled State
                        Transform.scale(
                          scale: _buttonScale,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _increment,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: isBusy
                                      ? [
                                          pack.primaryColor.withValues(alpha: 0.7),
                                          pack.accentColor.withValues(alpha: 0.85),
                                        ]
                                      : [
                                          pack.secondaryColor,
                                          pack.primaryColor,
                                        ],
                                  center: const Alignment(-0.2, -0.3),
                                ),
                                border: isBusy
                                    ? Border.all(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        width: 2.5,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: pack.primaryColor.withValues(
                                      alpha: isBusy ? 0.65 : 0.45,
                                    ),
                                    blurRadius: isBusy ? 24 : 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isBusy)
                                    const Icon(
                                      Icons.graphic_eq_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    )
                                  else
                                    SvgPicture.string(
                                      '''<svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20Z" fill="white"/>
<circle cx="12" cy="12" r="5" fill="white"/>
</svg>''',
                                      width: 24,
                                      height: 24,
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_count / $_target',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        const Shadow(
                                          color: Colors.black38,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _increment,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                isBusy
                                    ? '🔊 Chanting Shlok...'
                                    : isCompleted
                                        ? 'Mala Complete! Tap for Next Mala'
                                        : 'Tap to Chant Mantra',
                                key: ValueKey<String>(
                                  isBusy ? 'busy' : (isCompleted ? 'comp' : 'tap'),
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isBusy ? FontWeight.bold : FontWeight.w600,
                                  color: isBusy
                                      ? pack.primaryColor
                                      : const Color(0xFF2E2A36).withValues(alpha: 0.7),
                                ),
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

            // Top Overlay Flower Petals / Bilva / Feathers Shower (Ignored from Pointer/Touch Events)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (ctx, _) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: DivineOverlayPainter(
                      embers: _embers,
                      petals: _petals,
                      isCompleted: isCompleted,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────
class DivineBackgroundPainter extends CustomPainter {
  final double timeSeconds;
  final bool isCompleted;
  final double progressPct;

  DivineBackgroundPainter({
    required this.timeSeconds,
    required this.isCompleted,
    this.progressPct = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double effectiveProgress = isCompleted ? 1.0 : progressPct;
    if (effectiveProgress <= 0.02) return;

    final center = Offset(size.width / 2, size.height * 0.4);

    final double pulse =
        (0.08 + 0.14 * effectiveProgress) +
        (math.sin(timeSeconds * 2.5) * 0.04);
    final auraPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFF9900).withValues(alpha: pulse.clamp(0.0, 0.35)),
              const Color(0xFFFF5500).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: 350 * (0.6 + 0.4 * effectiveProgress),
            ),
          );
    canvas.drawCircle(center, 350 * (0.6 + 0.4 * effectiveProgress), auraPaint);
  }

  @override
  bool shouldRepaint(covariant DivineBackgroundPainter oldDelegate) =>
      oldDelegate.timeSeconds != timeSeconds ||
      oldDelegate.isCompleted != isCompleted ||
      oldDelegate.progressPct != progressPct;
}


class MistParticle {
  double x, y;
  double vx, vy;
  double size;
  double alpha;
  double maxAlpha;
  double life;
  double maxLife;
  Color color;

  MistParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxAlpha,
    required this.maxLife,
    required this.color,
  })  : alpha = 0.0,
        life = maxLife;

  bool update() {
    life -= 0.016;
    if (life <= 0) return false;
    x += vx;
    y += vy;
    final progress = 1.0 - (life / maxLife);
    if (progress < 0.3) {
      alpha = maxAlpha * (progress / 0.3);
    } else {
      alpha = maxAlpha * (1.0 - ((progress - 0.3) / 0.7));
    }
    return true;
  }
}

class DivineSymbolParticle {
  Offset position;
  double vy;
  double alpha;
  double life;
  double maxLife;
  DivineSymbolType symbol;
  Color color;
  double rotation;

  DivineSymbolParticle({
    required this.position,
    required this.symbol,
    required this.color,
    this.maxLife = 1.0,
    this.vy = -1.5,
  })  : alpha = 1.0,
        life = maxLife,
        rotation = 0.0;

  bool update() {
    life -= 0.016;
    if (life <= 0) return false;
    position = position + Offset(0, vy);
    alpha = (life / maxLife).clamp(0.0, 1.0);
    rotation += 0.02;
    return true;
  }
}

class DivineCardPainter extends CustomPainter {
  final List<Offset> jitteredPoints;
  final List<int> shuffledIndices;
  final int count;
  final int target;
  final int? revealingTileIndex;
  final double currentRevealProgress;
  final double completionFadeProgress;
  final List<GlowRing> glowRings;
  final List<TapSparkParticle> tapSparks;
  final List<SpiralSparkParticle> spiralSparks;
  final List<FloatingOmText> floatingOms;
  final List<MistParticle> mistParticles;
  final List<DivineSymbolParticle> divineSymbolParticles;
  final List<SmokeParticle> smokePuffs;
  final List<PetalParticle> tapPetals;
  final double timeSeconds;
  final bool isCompleted;
  final EffectPack effectPack;

  DivineCardPainter({
    required this.jitteredPoints,
    required this.shuffledIndices,
    required this.count,
    required this.target,
    required this.revealingTileIndex,
    required this.currentRevealProgress,
    required this.completionFadeProgress,
    required this.glowRings,
    required this.tapSparks,
    required this.spiralSparks,
    required this.floatingOms,
    required this.mistParticles,
    required this.divineSymbolParticles,
    required this.smokePuffs,
    required this.tapPetals,
    required this.timeSeconds,
    required this.isCompleted,
    required this.effectPack,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final cardRRect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final double defaultEraseRadius = 26.0;

    // Clip everything to the card's rounded corners so reveals don't leak outside
    canvas.clipRRect(cardRRect);

    // 1. Draw Divine Veil Overlay using SaveLayer & BlendMode.dstOut
    final veilPaint = Paint()
      ..color = const Color(0xFF1A1025).withValues(
        alpha: ((1.0 - completionFadeProgress) * 0.92).clamp(0.0, 0.92),
      );

    if (completionFadeProgress < 1.0) {
      canvas.saveLayer(rect, Paint());
      canvas.drawRect(rect, veilPaint);

      final erasePaint = Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      for (int i = 0; i < count && i < target; i++) {
        final tileIdx = shuffledIndices[i];
        final pt = jitteredPoints[tileIdx];

        double scale = 1.0;
        if (tileIdx == revealingTileIndex) {
          scale = Curves.easeOutBack.transform(
            currentRevealProgress.clamp(0.0, 1.0),
          );
        }
        final r = defaultEraseRadius * scale;
        _drawRevealShape(canvas, pt, r, erasePaint, i);
      }

      canvas.restore();
    }

    // 2. Draw Incense Smoke Puffs
    for (final smoke in smokePuffs) {
      final alpha = (smoke.life / smoke.maxLife).clamp(0.0, 1.0) * smoke.alpha;
      final smokePaint = Paint()
        ..color = effectPack.secondaryColor.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.drawCircle(Offset(smoke.x, smoke.y), smoke.size, smokePaint);
    }

    // 3. Draw Fluttering Tap Flower Petals
    for (final petal in tapPetals) {
      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.angle);
      final petalPaint = Paint()
        ..color = petal.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      final pPath = Path();
      pPath.moveTo(0, -petal.size);
      pPath.quadraticBezierTo(petal.size * 0.5, -petal.size * 0.2, 0, petal.size * 0.6);
      pPath.quadraticBezierTo(-petal.size * 0.5, -petal.size * 0.2, 0, -petal.size);
      canvas.drawPath(pPath, petalPaint);
      canvas.restore();
    }

    // 4. Draw Lotus Mandala Bloom Glow Rings
    for (final ring in glowRings) {
      final progress = 1.0 - (ring.life / ring.maxLife);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..color = ring.color.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(ring.position, ring.maxRadius * progress, ringPaint);
    }

    // 5. Draw Tap Sparks
    for (final spark in tapSparks) {
      final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);
      final sparkPaint = Paint()..color = spark.color.withValues(alpha: alpha);
      canvas.drawCircle(spark.position, spark.size, sparkPaint);
    }

    // 6. Draw Floating Om Glyphs & Mantras
    for (final om in floatingOms) {
      final alpha = (om.life / om.maxLife).clamp(0.0, 1.0);
      final tp = _getOmPainter(om.text);
      final paint = tp.text!.style!.copyWith(
        color: effectPack.primaryColor.withValues(alpha: alpha),
      );
      final blended = TextPainter(
        text: TextSpan(text: om.text, style: paint),
        textDirection: TextDirection.ltr,
      )..layout();
      blended.paint(
        canvas,
        om.position - Offset(blended.width / 2, blended.height / 2),
      );
    }

    // 7. Draw Atmospheric Mist Particles
    for (final mist in mistParticles) {
      final mistPaint = Paint()
        ..color = mist.color.withValues(alpha: mist.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.drawCircle(Offset(mist.x, mist.y), mist.size, mistPaint);
    }

    // 8. Draw Divine Symbols (Trishul, Shankh, Flute, Bow, Lotus, Chakra, ॐ)
    for (final sym in divineSymbolParticles) {
      _drawDivineSymbol(canvas, sym);
    }
  }

  /// Cache of baseline TextPainters (opaque) for each Om glyph string.
  static final Map<String, TextPainter> _omPainterCache = {};

  static TextPainter _getOmPainter(String text) {
    return _omPainterCache.putIfAbsent(text, () {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.outfit(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }


  void _drawDivineSymbol(Canvas canvas, DivineSymbolParticle particle) {
    canvas.save();
    canvas.translate(particle.position.dx, particle.position.dy);
    canvas.scale(0.8 + (1.0 - particle.life / particle.maxLife) * 0.4);

    final paint = Paint()
      ..color = particle.color.withValues(alpha: particle.alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = particle.color.withValues(alpha: particle.alpha * 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (particle.symbol) {
      case DivineSymbolType.trishul:
        // Trishul: center rod + outer curved prongs
        path.moveTo(0, 15);
        path.lineTo(0, -20); // Center spear
        path.moveTo(-12, 0);
        path.quadraticBezierTo(-12, -18, -12, -18);
        path.moveTo(12, 0);
        path.quadraticBezierTo(12, -18, 12, -18);
        path.moveTo(-15, 0);
        path.quadraticBezierTo(0, 10, 15, 0);
        canvas.drawPath(path, paint);
        break;

      case DivineSymbolType.shankh:
        // Shankh: Spiral conch shell outline
        final rect = Rect.fromCenter(center: Offset.zero, width: 22, height: 30);
        canvas.drawOval(rect, paint);
        path.moveTo(0, -15);
        path.quadraticBezierTo(8, 0, 0, 15);
        canvas.drawPath(path, paint);
        break;

      case DivineSymbolType.flute:
        // Flute: Diagonal flute with peacock feather dot
        canvas.rotate(0.3);
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 36, height: 8),
          const Radius.circular(4),
        );
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, paint);
        for (int i = -10; i <= 10; i += 6) {
          canvas.drawCircle(Offset(i.toDouble(), 0), 1.2, Paint()..color = Colors.white.withValues(alpha: particle.alpha));
        }
        break;

      case DivineSymbolType.bowArrow:
        // Bow & Arrow: Arc + Arrow line
        path.addArc(Rect.fromCenter(center: Offset.zero, width: 26, height: 32), -1.5, 3.0);
        path.moveTo(-12, 0);
        path.lineTo(16, 0); // Arrow shaft
        path.moveTo(10, -5);
        path.lineTo(16, 0);
        path.lineTo(10, 5); // Arrowhead
        canvas.drawPath(path, paint);
        break;

      case DivineSymbolType.lotus:
        // Lotus: 3 overlapping petals
        for (int i = -1; i <= 1; i++) {
          final p = Path();
          p.moveTo(0, 10);
          p.quadraticBezierTo(i * 15.0 + 8, -5, 0, -16);
          p.quadraticBezierTo(i * 15.0 - 8, -5, 0, 10);
          canvas.drawPath(p, fillPaint);
          canvas.drawPath(p, paint);
        }
        break;

      case DivineSymbolType.chakra:
        // Sudarshana Chakra: Spinning circle with spokes
        canvas.rotate(particle.rotation);
        canvas.drawCircle(Offset.zero, 14, paint);
        for (int i = 0; i < 8; i++) {
          final ang = (i / 8.0) * 2 * math.pi;
          canvas.drawLine(Offset.zero, Offset(math.cos(ang) * 14, math.sin(ang) * 14), paint);
        }
        break;

      case DivineSymbolType.om:
      case DivineSymbolType.none:
        final tp = _getOmPainter('ॐ');
        tp.paint(canvas, const Offset(-10, -10));
        break;
    }

    canvas.restore();
  }

  /// Draw reveal hole using smooth organic round blobs (no sharp eye shapes)
  void _drawRevealShape(
    Canvas canvas,
    Offset center,
    double radius,
    Paint erasePaint,
    int index,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = Path();
    _buildOrganicRoundPath(path, radius, index);

    canvas.drawPath(path, erasePaint);
    canvas.restore();
  }

  /// Smooth organic rounded blob with subtle random radius jitter per tile
  void _buildOrganicRoundPath(Path path, double r, int index) {
    final rng = math.Random(index * 7919);
    const int points = 6;
    final List<Offset> pts = [];
    for (int k = 0; k < points; k++) {
      final angle = (k * 2 * math.pi / points);
      final jitterR = r * (0.92 + (rng.nextDouble() * 0.18));
      pts.add(Offset(jitterR * math.cos(angle), jitterR * math.sin(angle)));
    }
    path.moveTo((pts[0].dx + pts[points - 1].dx) / 2, (pts[0].dy + pts[points - 1].dy) / 2);
    for (int k = 0; k < points; k++) {
      final p1 = pts[k];
      final p2 = pts[(k + 1) % points];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.close();
  }




  @override
  bool shouldRepaint(covariant DivineCardPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.currentRevealProgress != currentRevealProgress ||
        oldDelegate.completionFadeProgress != completionFadeProgress ||
        oldDelegate.tapSparks.length != tapSparks.length ||
        oldDelegate.floatingOms.length != floatingOms.length ||
        oldDelegate.glowRings.length != glowRings.length ||
        (oldDelegate.timeSeconds - timeSeconds).abs() > 0.008;
  }
}

class DivineOverlayPainter extends CustomPainter {
  final List<EmberParticle> embers;
  final List<PetalParticle> petals;
  final bool isCompleted;

  DivineOverlayPainter({
    required this.embers,
    required this.petals,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isCompleted) {
      final emberPaint = Paint()..style = PaintingStyle.fill;
      for (final ember in embers) {
        emberPaint.color = const Color(
          0xFFFFB300,
        ).withValues(alpha: ember.alpha);
        canvas.drawCircle(Offset(ember.x, ember.y), ember.size, emberPaint);
      }

      for (final particle in petals) {
        _drawParticle(
          canvas,
          Offset(particle.x, particle.y),
          particle.size,
          particle.angle,
          particle.color,
          particle.shape,
        );
      }
    }
  }

  void _drawParticle(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Color color,
    ParticleShapeType shape,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    switch (shape) {
      case ParticleShapeType.leaf:
        path.moveTo(0, -size);
        path.quadraticBezierTo(size * 0.6, -size * 0.3, 0, size * 0.5);
        path.quadraticBezierTo(-size * 0.6, -size * 0.3, 0, -size);
        canvas.drawPath(path, paint);
        break;

      case ParticleShapeType.feather:
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size * 0.8,
          height: size * 1.5,
        );
        canvas.drawOval(rect, paint);
        canvas.drawCircle(
          Offset.zero,
          size * 0.25,
          Paint()..color = const Color(0xFFFFD700),
        );
        break;

      case ParticleShapeType.spark:
      case ParticleShapeType.flame:
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(Offset.zero, size * 0.6, glowPaint);
        canvas.drawCircle(Offset.zero, size * 0.3, paint);
        break;

      case ParticleShapeType.petal:
      case ParticleShapeType.ash:
      case ParticleShapeType.custom:
        path.moveTo(0, -size / 2);
        path.quadraticBezierTo(size / 2.5, -size / 4, 0, size / 2);
        path.quadraticBezierTo(-size / 2.5, -size / 4, 0, -size / 2);
        path.close();
        canvas.drawPath(path, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DivineOverlayPainter oldDelegate) {
    // Repaint only when completion state or petal count changes
    return oldDelegate.isCompleted != isCompleted ||
        oldDelegate.petals.length != petals.length;
  }
}
