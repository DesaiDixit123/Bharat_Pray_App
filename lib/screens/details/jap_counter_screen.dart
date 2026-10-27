import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/jap_models.dart';
import '../../services/api_service.dart';
import '../../services/jap_offline_repository.dart';
import 'upload_god_photo_screen.dart';
import 'notification_screen.dart';
import 'messages_screen.dart';
import '../../services/yatra_personal_chat_service.dart';
import '../../widgets/user_avatar.dart';
import '../../models/jap_theme_config.dart';
import '../../widgets/cinematic_jap/effects/jap_effect_selector_sheet.dart';
import 'jap_detail_screen.dart';
import 'cinematic_jap_screen.dart';
export 'jap_detail_screen.dart';
export 'cinematic_jap_screen.dart';

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

    // 3. Load user's custom Japs from backend and offline cache
    List<JapConfig> customJaps = [];
    try {
      if (_token.isNotEmpty) {
        final serverCustoms = await ApiService.getMyCustomJaps(_token);
        final serverIds = <String>{};
        for (final sc in serverCustoms) {
          final cfg = JapConfig.fromJson(sc);
          customJaps.add(cfg);
          serverIds.add(cfg.id);
        }

        // If a custom jap was deleted on server (by Admin or user), prune it locally so it disappears from user app too
        final localCustomsRaw = await JapOfflineRepository.getCustomJaps();
        for (final raw in localCustomsRaw) {
          final localId = (raw['id'] ?? raw['_id'] ?? '').toString();
          if (localId.length == 24 && !serverIds.contains(localId)) {
            await JapOfflineRepository.removeCustomJap(localId);
          }
        }
      }
      final localCustoms = await JapOfflineRepository.getCustomJaps();
      for (final raw in localCustoms) {
        final cfg = JapConfig.fromJson(raw);
        if (!customJaps.any((c) => c.id == cfg.id)) {
          customJaps.add(cfg);
        }
      }
    } catch (e) {
      debugPrint('[JapCounterScreen] Error loading custom japs: $e');
    }

    // 4. Combine remote admin japs and user custom japs
    List<JapConfig> combined = [
      ...remoteJaps,
      ...customJaps.where((c) => !remoteJaps.any((r) => r.id == c.id)),
    ];
    if (combined.isEmpty) {
      combined = _getDefaultPresets();
    } else {
      final hasRadha = combined.any((j) => j.name.toLowerCase().contains('radha'));
      if (!hasRadha) {
        combined.insert(0, _createRadhaPreset());
      }
      final hasRam = combined.any((j) => j.name.toLowerCase().contains('ram'));
      if (!hasRam) {
        combined.insert(0, _createRamPreset());
      }
    }
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

  static JapConfig _createRadhaPreset() {
    return JapConfig(
      id: JapThemeConfig.radha.id,
      name: JapThemeConfig.radha.name,
      thumbnailUrl: JapThemeConfig.radha.imageAsset,
      darshanImageUrl: JapThemeConfig.radha.imageAsset,
      shlokText: JapThemeConfig.radha.mantraText,
      shlokAudioUrl: JapThemeConfig.radha.audioAsset,
      targetCount: 108,
      progress: 0,
      effectPack: EffectPack.resolve(name: 'Shri Radha'),
    );
  }

  static JapConfig _createRamPreset() {
    return JapConfig(
      id: JapThemeConfig.ram.id,
      name: JapThemeConfig.ram.name,
      thumbnailUrl: JapThemeConfig.ram.imageAsset,
      darshanImageUrl: JapThemeConfig.ram.imageAsset,
      shlokText: JapThemeConfig.ram.mantraText,
      shlokAudioUrl: JapThemeConfig.ram.audioAsset,
      targetCount: 108,
      progress: 0,
      effectPack: EffectPack.resolve(name: 'Lord Ram'),
    );
  }

  static List<JapConfig> _getDefaultPresets() {
    return JapThemeConfig.allThemes.map((theme) {
      return JapConfig(
        id: theme.id,
        name: theme.name,
        thumbnailUrl: theme.imageAsset,
        darshanImageUrl: theme.imageAsset,
        shlokText: theme.mantraText,
        shlokAudioUrl: theme.audioAsset,
        targetCount: 108,
        progress: 0,
        effectPack: EffectPack.resolve(name: theme.name),
      );
    }).toList();
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
    final bool isRam = entry.name.toLowerCase().contains('ram') ||
        entry.shlokText.toLowerCase().contains('राम');

    final Widget destination = isRam
        ? CinematicJapScreen(entry: entry)
        : JapDetailScreen(entry: entry);

    final updatedProgress = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => destination),
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
      if (_token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      }
      if (_token.isNotEmpty && entry.id.isNotEmpty && entry.id.length == 24) {
        try {
          await ApiService.syncJapProgress(
            _token,
            entry.id,
            updatedProgress % entry.targetCount,
            completedMalas: updatedProgress ~/ entry.targetCount,
          );
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
      String assignedId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      String resolvedThumbnail = result.coverImagePath;
      String resolvedDarshan = result.godImagePath;
      String resolvedAudio = result.audioFilePath;
      if (_token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      }

      if (_token.isNotEmpty) {
        if (!mounted || !context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF7700),
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Saving custom Jap...',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2E2A36),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        try {
          final serverRes = await ApiService.createCustomJap(
            _token,
            name: result.name,
            coverImageFile: File(result.coverImagePath),
            godImageFile: File(result.godImagePath),
            audioFile: result.audioFilePath.isNotEmpty && File(result.audioFilePath).existsSync()
                ? File(result.audioFilePath)
                : null,
            targetCount: result.chantCount,
            particleShape: result.particleEffect,
            godCategory: result.category,
          );

          final serverId = (serverRes['_id'] ?? serverRes['id'])?.toString();
          if (serverId != null && serverId.length == 24) {
            assignedId = serverId;
            if (serverRes['thumbnail'] != null && serverRes['thumbnail'].toString().isNotEmpty) {
              resolvedThumbnail = serverRes['thumbnail'].toString();
            }
            if (serverRes['darshanImage'] != null && serverRes['darshanImage'].toString().isNotEmpty) {
              resolvedDarshan = serverRes['darshanImage'].toString();
            }
            if (serverRes['shlokAudio'] != null && serverRes['shlokAudio'].toString().isNotEmpty) {
              resolvedAudio = serverRes['shlokAudio'].toString();
            }
          }
        } catch (e) {
          debugPrint('[JapCounterScreen] Server createCustomJap failed, saved offline: $e');
        } finally {
          if (mounted && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      }

      final newCustomConfig = JapConfig(
        id: assignedId,
        name: result.name,
        thumbnailUrl: resolvedThumbnail,
        darshanImageUrl: resolvedDarshan,
        shlokText: '',
        shlokAudioUrl: resolvedAudio,
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
        'id': newCustomConfig.id,
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
                  UserAvatar(
                    profilePic: _profilePic,
                    userName: _profileName,
                    size: 48,
                    borderColor: const Color(0xFFFF7700).withValues(alpha: 0.2),
                    borderWidth: 1.5,
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

                    // Actions: [Effects ✨] (if Ram) & [Chant 📿]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.name.toLowerCase().contains('ram') ||
                            entry.shlokText.toLowerCase().contains('राम')) ...[
                          GestureDetector(
                            onTap: () async {
                              final currentEffect = await JapEffectSelectorSheet.loadSelectedEffect();
                              if (!context.mounted) return;
                              JapEffectSelectorSheet.show(
                                context,
                                currentEffect: currentEffect,
                                onEffectSelected: (newEffect) {},
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF9900),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: Color(0xFFFF7700),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Effects',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF7700),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // Chant CTA Button (Always Orange)
                        Container(
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
                      ],
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
