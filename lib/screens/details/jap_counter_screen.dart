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
import 'notification_screen.dart';
import 'messages_screen.dart';
import '../../services/yatra_personal_chat_service.dart';
import '../../widgets/devotional_chant_overlay.dart';

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
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _messageCount = YatraPersonalChatService().unreadMessageCount.value;
    YatraPersonalChatService().unreadMessageCount.addListener(_onUnreadMessagesChanged);
    YatraPersonalChatService().refreshUnreadCount();
    _fetchJaps();
  }

  void _onUnreadMessagesChanged() {
    if (mounted) {
      setState(() {
        _messageCount = YatraPersonalChatService().unreadMessageCount.value;
      });
    }
  }

  Future<void> _fetchJaps() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

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
          _messageCount = YatraPersonalChatService().unreadMessageCount.value;
        }
      } catch (e) {
        debugPrint('[JapCounterScreen] Error fetching user profile: $e');
      }
    }

    // 2. Fetch remote japs (always runs, backend supports guest token)
    List<JapConfig> remoteJaps = [];
    try {
      final data = await ApiService.getJapList(_token);
      remoteJaps = data.map((e) => JapConfig.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[JapCounterScreen] Error fetching remote japs: $e');
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

    // 4. Combine and overlay local cached progress (prioritize remote/admin japs)
    final combined = [
      ...remoteJaps,
      ...customJaps.where((c) => !remoteJaps.any((r) => r.id == c.id)),
    ];
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
    YatraPersonalChatService().unreadMessageCount.removeListener(_onUnreadMessagesChanged);
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
        particleShape: result.particleEffect,
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
        'particleShape': result.particleEffect,
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessagesScreen(),
                        ),
                      ).then((_) {
                        YatraPersonalChatService().refreshUnreadCount();
                      });
                    },
                    child: SvgPicture.string(
                      _getMailSvg(_messageCount),
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
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
                child: _buildImage(entry.thumbnailUrl, deityName: entry.name),
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

                    // Progress Bar (Always Orange)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              backgroundColor: const Color(0xFFFFF0E6),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7700),
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
                            color: const Color(0xFFFF7700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chant CTA Button (Always Orange)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF9933),
                              Color(0xFFFF6600),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7700).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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

  Widget _buildImage(String path, {String deityName = ''}) {
    final fallbackAsset = JapConfig.defaultDeityImage(deityName);
    if (path.isEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        cacheWidth: 280,
        cacheHeight: 360,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
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

  DevotionalAnimationMode _devotionalMode = DevotionalAnimationMode.pushpanjaliPetals;
  bool _showDevotionalOverlay = false;

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

    final int cols = math.max(1, math.sqrt(_target / 1.47).round());
    final int rows = (_target / cols).ceil();

    final double cellWidth = 353.0 / cols;
    final double cellHeight = 520.0 / rows;

    for (int i = 0; i < _target; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final cellCenterX = col * cellWidth + (cellWidth / 2.0);
      final cellCenterY = row * cellHeight + (cellHeight / 2.0);

      final dx = (rng.nextDouble() * (cellWidth * 0.5)) - (cellWidth * 0.25);
      final dy = (rng.nextDouble() * (cellHeight * 0.5)) - (cellHeight * 0.25);

      points.add(
        Offset(
          (cellCenterX + dx).clamp(25.0, 328.0),
          (cellCenterY + dy).clamp(30.0, 490.0),
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

    final n = widget.entry.name.toLowerCase();
    if (n.contains('ram') || n.contains('raghav') || n.contains('sita')) {
      _devotionalMode = DevotionalAnimationMode.ramNaamVandana;
    } else if (n.contains('radha') || n.contains('krishna') || n.contains('kanha')) {
      _devotionalMode = DevotionalAnimationMode.radhaMorPankh108;
    } else if (n.contains('shiva') || n.contains('mahadev') || n.contains('shankar')) {
      _devotionalMode = DevotionalAnimationMode.dhoopSmoke;
    } else if (n.contains('aarti') || n.contains('diya') || n.contains('temple')) {
      _devotionalMode = DevotionalAnimationMode.mahaAartiBells;
    } else {
      _devotionalMode = DevotionalAnimationMode.pushpanjaliPetals;
    }
  }

  void _openDevotionalModePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1428),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'દિવ્ય એનિમેશન સ્ટાઇલ પસંદ કરો',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...DevotionalAnimationMode.values.map((mode) {
                final isSelected = mode == _devotionalMode;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF9933).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF9933)
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFFF9933)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        mode.icon,
                        color: isSelected ? Colors.white : const Color(0xFFFFB74D),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      mode.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      mode.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9933), size: 22)
                        : null,
                    onTap: () {
                      setState(() {
                        _devotionalMode = mode;
                        _showDevotionalOverlay = true;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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
        _showDevotionalOverlay = false;
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



    if (_petals.isEmpty) {
      _initPetals();
    }
    for (final petal in _petals) {
      petal.update(393, 1010);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageProvider == null) {
      final defaultAsset = JapConfig.defaultDeityImage(widget.entry.name);
      final path = widget.entry.darshanImageUrl.isNotEmpty
          ? widget.entry.darshanImageUrl
          : (widget.entry.thumbnailUrl.isNotEmpty
              ? widget.entry.thumbnailUrl
              : defaultAsset);
      if (path.startsWith('http')) {
        _imageProvider = NetworkImage(path);
      } else if (path.startsWith('assets/')) {
        _imageProvider = AssetImage(path);
      } else {
        final f = File(path);
        _imageProvider = f.existsSync() ? FileImage(f) : AssetImage(defaultAsset);
      }
      try {
        precacheImage(_imageProvider!, context);
      } catch (_) {}
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
      _showDevotionalOverlay = true;

      _count = math.min(_count + 1, _target);
      _lifecycle = _count >= _target
          ? JapLifecycle.completed
          : JapLifecycle.inProgress;

    });

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
                        // Top Bar: Animation Style & Reset Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _openDevotionalModePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF9933),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: Color(0xFFFF7700),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'એનિમેશન',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: const Color(0xFFFF7700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _resetMala,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                      size: 14,
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
                      ],
                    ),
                  ),

                  // Center Darshan Card with Unmasking Canvas & Divine Chant Typography Overlay
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _increment,
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
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      JapConfig.defaultDeityImage(widget.entry.name),
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                // Interactive Mask & Reveal Painter (Reveals tile-by-tile)
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

                                // Photorealistic Devotional Chant Overlay
                                if (_showDevotionalOverlay)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DevotionalChantOverlay(
                                        key: ValueKey('dev_${_devotionalMode}_$_count'),
                                        mode: _devotionalMode,
                                        tapCount: _count,
                                        onCompleted: () {
                                          if (mounted) {
                                            setState(() => _showDevotionalOverlay = false);
                                          }
                                        },
                                      ),
                                    ),
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
                                        color: const Color(0xFFFF7700),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF7700).withValues(
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
                                            color: const Color(0xFFFF7700),
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
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF9933),
                                                  Color(0xFFFF6600),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF7700)
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
                                          const Color(0xFFFF7700).withValues(alpha: 0.7),
                                          const Color(0xFFFF9933).withValues(alpha: 0.85),
                                        ]
                                      : const [
                                          Color(0xFFFF9933),
                                          Color(0xFFFF6600),
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
                                    color: const Color(0xFFFF7700).withValues(
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
                                      ? const Color(0xFFFF7700)
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
    // Clip everything to the card's rounded corners so reveals don't leak outside
    canvas.clipRRect(cardRRect);

    // 1. Draw Divine Veil Overlay strictly proportional to completed chant count
    final veilAlpha = ((1.0 - completionFadeProgress) * 0.94).clamp(0.0, 0.94);

    final veilPaint = Paint()
      ..color = const Color(0xFF140D1F).withValues(alpha: veilAlpha);

    if (completionFadeProgress < 1.0 && veilAlpha > 0.01) {
      canvas.saveLayer(rect, Paint());
      canvas.drawRect(rect, veilPaint);

      final erasePaint = Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

      // Proportional radius mathematically sized so target chants reveal exactly 100%
      final double targetSafe = math.max(1, target).toDouble();
      final double cellRadius =
          (math.sqrt((size.width * size.height) / (targetSafe * math.pi)) *
                  1.35)
              .clamp(24.0, 38.0);

      for (int i = 0; i < count && i < target; i++) {
        final tileIdx = shuffledIndices[i];
        final pt = jitteredPoints[tileIdx];

        // Organic varied radius around the exact cell size (no premature full unmasking)
        final tileRng = math.Random((tileIdx + 1) * 7919);
        final baseRadius = cellRadius * (0.92 + tileRng.nextDouble() * 0.22);

        double scale = 1.0;
        if (tileIdx == revealingTileIndex) {
          scale = 0.35 +
              Curves.easeOutCubic.transform(
                    currentRevealProgress.clamp(0.0, 1.0),
                  ) *
                  0.65;
        }
        final r = baseRadius * scale;
        _drawRevealShape(canvas, pt, r, erasePaint, tileIdx);
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
      case DivineSymbolType.lotus:
        // Lotus: 3 overlapping petals
        for (int i = -1; i <= 1; i++) {
          final p = Path();
          p.moveTo(0, 10);
          p.quadraticBezierTo(i * 12.0, -5, i * 6.0, -18);
          p.quadraticBezierTo(0, -10, 0, 10);
          canvas.drawPath(p, fillPaint);
          canvas.drawPath(p, paint);
        }
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

      case DivineSymbolType.trishul:
        // Sacred Golden Trishul with Mahadev's crescent halo
        final haloPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: (particle.alpha * 0.4).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(const Offset(0, -5), 14.0, haloPaint);

        final goldTrishulPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: particle.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;

        path.moveTo(0, 16);
        path.lineTo(0, -22); // Central spear tip
        path.moveTo(-11, 2);
        path.cubicTo(-13, -12, -7, -18, -10, -20);
        path.moveTo(11, 2);
        path.cubicTo(13, -12, 7, -18, 10, -20);
        path.moveTo(-11, 2);
        path.quadraticBezierTo(0, 8, 11, 2);
        canvas.drawPath(path, goldTrishulPaint);
        // Damru knot
        canvas.drawCircle(const Offset(0, 4), 2.5, Paint()..color = const Color(0xFFFF3D00));
        break;

      case DivineSymbolType.chakra:
        // Luminous Sudarshana Chakra with radiant flaming teeth
        canvas.rotate(particle.rotation);
        final aura = Paint()
          ..color = const Color(0xFFFFB300).withValues(alpha: (particle.alpha * 0.45).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(Offset.zero, 16.0, aura);

        final rimPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: particle.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset.zero, 13, rimPaint);
        canvas.drawCircle(Offset.zero, 6, rimPaint);

        final spokePaint = Paint()
          ..color = const Color(0xFFFFF9C4).withValues(alpha: particle.alpha)
          ..strokeWidth = 1.6;
        for (int i = 0; i < 8; i++) {
          final ang = (i / 8.0) * 2 * math.pi;
          canvas.drawLine(
            Offset(math.cos(ang) * 6, math.sin(ang) * 6),
            Offset(math.cos(ang) * 15, math.sin(ang) * 15),
            spokePaint,
          );
        }
        break;

      case DivineSymbolType.shankh:
        // Sacred Panchajanya Conch Shell with golden spiral
        final shankhPaint = Paint()
          ..color = const Color(0xFFFFFDE7).withValues(alpha: particle.alpha)
          ..style = PaintingStyle.fill;
        final shankhRim = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: particle.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        final sRect = Rect.fromCenter(center: Offset.zero, width: 22, height: 28);
        canvas.drawOval(sRect, shankhPaint);
        canvas.drawOval(sRect, shankhRim);
        path.moveTo(0, -14);
        path.cubicTo(10, -4, 4, 10, -2, 14);
        canvas.drawPath(path, shankhRim);
        break;

      case DivineSymbolType.bowArrow:
        // Divine Kodanda Bow with golden arrowhead
        final bowPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: particle.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        path.addArc(Rect.fromCenter(center: Offset.zero, width: 28, height: 34), -1.5, 3.0);
        path.moveTo(-14, 0);
        path.lineTo(18, 0); // Arrow
        path.moveTo(11, -5);
        path.lineTo(18, 0);
        path.lineTo(11, 5);
        canvas.drawPath(path, bowPaint);
        // Glowing arrow tip
        canvas.drawCircle(
          const Offset(18, 0),
          3.0,
          Paint()
            ..color = const Color(0xFFFFEA00).withValues(alpha: particle.alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
        );
        break;

      case DivineSymbolType.om:
      case DivineSymbolType.none:
        final tp = _getOmPainter('ॐ');
        tp.paint(canvas, const Offset(-10, -10));
        break;
    }

    canvas.restore();
  }

  /// Draw reveal hole using smooth organic cloud shapes (no box, no circle, random sizes & contours)
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
    _buildOrganicCloudPath(path, radius, index);

    canvas.drawPath(path, erasePaint);
    canvas.restore();
  }

  /// Organic asymmetrical cloud silhouette with 9 Bézier lobes and random variation
  void _buildOrganicCloudPath(Path path, double r, int index) {
    final rng = math.Random((index + 1) * 7919);
    const int points = 9;
    final List<Offset> pts = [];
    for (int k = 0; k < points; k++) {
      final baseAngle = (k * 2 * math.pi / points);
      final angleJitter = (rng.nextDouble() - 0.5) * 0.35;
      final angle = baseAngle + angleJitter;
      final lobeFactor = 0.70 + (rng.nextDouble() * 0.60);
      final curR = r * lobeFactor;
      pts.add(Offset(curR * math.cos(angle), curR * math.sin(angle)));
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
  bool shouldRepaint(covariant DivineOverlayPainter oldDelegate) => true;
}
