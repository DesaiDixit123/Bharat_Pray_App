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
import '../../services/saved_items_service.dart';
import '../../widgets/user_avatar.dart';
import '../../models/jap_theme_config.dart';
import '../../models/jap_animation_effect.dart';
import '../../widgets/cinematic_jap/effects/jap_effect_selector_sheet.dart';
import 'jap_detail_screen.dart';
import 'cinematic_jap_screen.dart';
import 'dhup_jap_screen.dart';
import 'jal_jap_screen.dart';
import 'prakash_jap_screen.dart';
import 'pushp_varsha_jap_screen.dart';
export 'jap_detail_screen.dart';
export 'cinematic_jap_screen.dart';
export 'dhup_jap_screen.dart';
export 'jal_jap_screen.dart';
export 'prakash_jap_screen.dart';
export 'pushp_varsha_jap_screen.dart';

// ─────────────────────────────────────────────
// Main Jap List Screen
// ─────────────────────────────────────────────
class JapCounterScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;
  const JapCounterScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<JapCounterScreen> createState() => _JapCounterScreenState();
}

class _JapCounterScreenState extends State<JapCounterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  String _token = '';
  List<JapConfig> _allJaps = [];
  int _selectedTab = 0; // 0 = Admin Jap, 1 = Your Custom Jap

  int get _adminJapCount => _allJaps.where((j) => !j.isCustom).length;
  int get _customJapCount => _allJaps.where((j) => j.isCustom).length;

  // Dynamic user profile fields matching HomeScreen
  String _profileName = 'Devotee';
  String _profilePic = '';
  int _notificationCount = 2;
  int _messageCount = 0;
  Set<String> _favJapIds = {};
  Set<String> _savedJapIds = {};

  Future<void> _loadJapFavAndSaved() async {
    final favs = await SavedItemsService.getFavouriteJaps();
    final saved = await SavedItemsService.getSavedJaps();
    if (mounted) {
      setState(() {
        _favJapIds = favs.map((e) => (e['id'] ?? '').toString()).toSet();
        _savedJapIds = saved.map((e) => (e['id'] ?? '').toString()).toSet();
      });
    }
  }

  Future<void> _toggleCardFav(JapConfig jap) async {
    final nowFav = await SavedItemsService.toggleFavouriteJap({
      'id': jap.id,
      'title': jap.name.isNotEmpty ? jap.name : jap.displayName,
      'subtitle': jap.mantraText.isNotEmpty ? jap.mantraText : jap.shlokText,
      'image': jap.thumbnailUrl.isNotEmpty ? jap.thumbnailUrl : jap.darshanImageUrl,
      'targetCount': jap.targetCount,
    });
    if (!mounted) return;
    setState(() {
      if (nowFav) {
        _favJapIds.add(jap.id);
      } else {
        _favJapIds.remove(jap.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFav ? 'Added to Your Favourites ❤️' : 'Removed from Your Favourites'),
        backgroundColor: const Color(0xFFFF7700),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleCardSaved(JapConfig jap) async {
    final nowSaved = await SavedItemsService.toggleSaveJap({
      'id': jap.id,
      'title': jap.name.isNotEmpty ? jap.name : jap.displayName,
      'subtitle': jap.mantraText.isNotEmpty ? jap.mantraText : jap.shlokText,
      'image': jap.thumbnailUrl.isNotEmpty ? jap.thumbnailUrl : jap.darshanImageUrl,
      'targetCount': jap.targetCount,
    });
    if (!mounted) return;
    setState(() {
      if (nowSaved) {
        _savedJapIds.add(jap.id);
      } else {
        _savedJapIds.remove(jap.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowSaved ? 'Saved to Saved Library 🔖' : 'Removed from Saved Library'),
        backgroundColor: const Color(0xFFFF7700),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _messageCount = YatraPersonalChatService().unreadMessageCount.value;
    YatraPersonalChatService().unreadMessageCount.addListener(_onUnreadMessagesChanged);
    YatraPersonalChatService().refreshUnreadCount();
    _loadJapFavAndSaved();
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
      // Clean up any stale custom test japs like 'dixit'
      final localCustomsRaw = await JapOfflineRepository.getCustomJaps();
      for (final raw in localCustomsRaw) {
        final localName = (raw['name'] ?? '').toString().toLowerCase();
        final localId = (raw['id'] ?? raw['_id'] ?? '').toString();
        if (localName == 'dixit' || localName.contains('bike') || localName.contains('shivji')) {
          await JapOfflineRepository.removeCustomJap(localId);
        }
      }

      if (_token.isNotEmpty) {
        final serverCustoms = await ApiService.getMyCustomJaps(_token);
        final serverIds = <String>{};
        for (final sc in serverCustoms) {
          final cfg = JapConfig.fromJson(sc);
          if (cfg.name.toLowerCase() != 'dixit' && !cfg.name.toLowerCase().contains('bike')) {
            customJaps.add(cfg);
            serverIds.add(cfg.id);
          }
        }
      }
      final localCustoms = await JapOfflineRepository.getCustomJaps();
      for (final raw in localCustoms) {
        final cfg = JapConfig.fromJson(raw);
        if (cfg.name.toLowerCase() != 'dixit' && !cfg.name.toLowerCase().contains('bike')) {
          if (!customJaps.any((c) => c.id == cfg.id)) {
            customJaps.add(cfg);
          }
        }
      }
    } catch (e) {
      debugPrint('[JapCounterScreen] Error loading custom japs: $e');
    }

    // Filter out test entries (dixit, shivji's jap, bike)
    remoteJaps.removeWhere((j) {
      final n = j.name.toLowerCase();
      return n == 'dixit' ||
          n.contains('bike') ||
          n == "shivji's jap" ||
          j.id == '6ad31b0a015c2a40cb3c584a' ||
          j.id == '6a56119e039eb816c106f3b0' ||
          j.id == '6aca2e1cfd3149164af9088f';
    });

    // Dynamic Admin Japs directly from Database / Admin Panel (with offline presets fallback)
    final List<JapConfig> adminJaps;
    if (remoteJaps.isNotEmpty) {
      remoteJaps.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      adminJaps = remoteJaps;
    } else {
      adminJaps = _getDefaultPresets();
    }

    List<JapConfig> combined = [
      ...adminJaps,
      ...customJaps,
    ];
    try {
      await JapOfflineRepository.ensureDailyReset();
      final prefs = await SharedPreferences.getInstance();
      final hasResetRamV6 = prefs.getBool('has_reset_ram_v6') ?? false;
      if (!hasResetRamV6) {
        for (final jap in combined) {
          if (jap.name.toLowerCase().contains('ram') || jap.id.toLowerCase().contains('ram')) {
            jap.progress = 0;
            await JapOfflineRepository.saveProgress(
              japId: jap.id,
              count: 0,
              completedMalas: 0,
              targetCount: jap.targetCount,
            );
            await JapOfflineRepository.saveProgress(
              japId: '${jap.id}_jal',
              count: 0,
              completedMalas: 0,
              targetCount: jap.targetCount,
            );
            await JapOfflineRepository.saveProgress(
              japId: '${jap.id}_dhup',
              count: 0,
              completedMalas: 0,
              targetCount: jap.targetCount,
            );
            await JapOfflineRepository.saveProgress(
              japId: '${jap.id}_prakash',
              count: 0,
              completedMalas: 0,
              targetCount: jap.targetCount,
            );
            await JapOfflineRepository.saveProgress(
              japId: '${jap.id}_pushp',
              count: 0,
              completedMalas: 0,
              targetCount: jap.targetCount,
            );
          }
        }
        await prefs.setBool('has_reset_ram_v6', true);
      }

      for (final jap in combined) {
        if (!hasResetRamV6 &&
            (jap.name.toLowerCase().contains('ram') ||
                jap.id.toLowerCase().contains('ram'))) {
          jap.progress = 0;
          continue;
        }
        final cached = await JapOfflineRepository.getProgress(
          jap.id,
          defaultTarget: jap.targetCount,
        );
        final int safeTarget = jap.targetCount > 0 ? jap.targetCount : 108;
        final int cachedCount = (cached['count'] ?? 0).clamp(0, safeTarget);
        jap.progress = jap.progress.clamp(0, safeTarget);
        if (cachedCount > jap.progress) {
          jap.progress = cachedCount;
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
        name: theme.displayName,
        displayName: theme.displayName,
        fullName: theme.fullName,
        mantraText: theme.mantraText,
        voiceText: theme.voiceText,
        thumbnailUrl: theme.thumbnailAsset,
        darshanImageUrl: theme.coverAsset,
        backgroundMusic: theme.backgroundMusicAsset,
        shlokText: theme.mantraText,
        shlokAudioUrl: theme.audioAsset,
        targetCount: 108,
        progress: 0,
        effectPack: EffectPack.resolve(name: theme.fullName),
        isCustom: false,
        displayOrder: theme.displayOrder,
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
    final baseList = _allJaps.where((j) {
      if (_selectedTab == 0) {
        return !j.isCustom;
      } else {
        return j.isCustom;
      }
    }).toList();

    if (_searchQuery.isEmpty) return baseList;
    final q = _searchQuery.toLowerCase();
    return baseList
        .where(
          (j) =>
              j.displayName.toLowerCase().contains(q) ||
              j.fullName.toLowerCase().contains(q) ||
              j.name.toLowerCase().contains(q) ||
              j.mantraText.toLowerCase().contains(q) ||
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

  Future<void> _performJapReset(JapConfig entry) async {
    final int safeTarget = entry.targetCount > 0 ? entry.targetCount : 108;
    setState(() {
      entry.progress = 0;
    });

    await JapOfflineRepository.resetProgress(entry.id);
    await JapOfflineRepository.resetProgress('${entry.id}_jal');
    await JapOfflineRepository.resetProgress('${entry.id}_dhup');
    await JapOfflineRepository.resetProgress('${entry.id}_prakash');
    await JapOfflineRepository.resetProgress('${entry.id}_pushp');

    if (_token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    }
    if (_token.isNotEmpty && entry.id.isNotEmpty && entry.id.length == 24) {
      try {
        await ApiService.resetJapProgress(_token, entry.id);
      } catch (e) {
        debugPrint('[JapCounterScreen] Remote reset error: $e');
      }
    }

    if (mounted) {
      final label = entry.displayName.isNotEmpty ? entry.displayName : entry.name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label Jap reset to 0 / $safeTarget',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFFF7700),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showResetJapDialog(JapConfig entry) async {
    final int safeTarget = entry.targetCount > 0 ? entry.targetCount : 108;
    final int currentCount = entry.progress.clamp(0, safeTarget);
    final String label = entry.displayName.isNotEmpty ? entry.displayName : entry.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFFBF5),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: Color(0xFFFF7700),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Reset Today's Jap?",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Do you want to reset $label progress ($currentCount / $safeTarget) back to 0 so you can chant again?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF6B5B4D),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: const Color(0xFF8C6239),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reset',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performJapReset(entry);
    }
  }

  void _openJapDetail(JapConfig entry) async {
    final int safeTarget = entry.targetCount > 0 ? entry.targetCount : 108;
    if (entry.progress >= safeTarget) {
      final String label = entry.displayName.isNotEmpty ? entry.displayName : entry.name;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFFFFBF5),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Today's Jap Completed!",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You have completed $safeTarget / $safeTarget chants of $label today. Would you like to reset and chant again?',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF6B5B4D),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'view'),
              child: Text(
                'View Darshan Video',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C6239),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx, 'reset'),
              child: Text(
                'Reset & Chant',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (action == null) return;
      if (action == 'reset') {
        await _performJapReset(entry);
      }
    }

    try {
      await JapOfflineRepository.ensureDailyReset();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_jap_id', entry.id);
      await prefs.setString('last_jap_id', entry.id);
      await prefs.setString('last_jap_title', entry.name);
      await prefs.setString(
        'last_jap_image',
        entry.thumbnailUrl.isNotEmpty ? entry.thumbnailUrl : entry.darshanImageUrl,
      );
      await prefs.setString('last_jap_shlok', entry.shlokText);
      await prefs.setString('last_jap_audio', entry.shlokAudioUrl ?? '');
      await prefs.setInt('last_jap_target', entry.targetCount);
      await prefs.setString('last_jap_shape', entry.particleShape ?? '');
      await prefs.setBool('last_jap_custom', entry.isCustom);
    } catch (_) {}

    final Widget destination;
    final selectedShape = (entry.particleShape ?? '').toLowerCase();
    if (selectedShape == 'dhup' || selectedShape == 'dhoop_smoke_reveal') {
      destination = DhupJapScreen(entry: entry);
    } else if (selectedShape == 'jal') {
      destination = JalJapScreen(entry: entry);
    } else if (selectedShape == 'prakash') {
      destination = PrakashJapScreen(entry: entry);
    } else if (selectedShape == 'pushp') {
      destination = PushpVarshaJapScreen(entry: entry);
    } else {
      destination = CinematicJapScreen(entry: entry);
    }

    final updatedProgress = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );

    // Sync Favourite & Saved icons immediately on return from Jap detail screen
    await _loadJapFavAndSaved();

    // Always resolve latest progress (even when user exited via system back gesture)
    int resolvedCount;
    if (updatedProgress != null) {
      resolvedCount = updatedProgress.clamp(0, safeTarget);
    } else {
      final cached = await JapOfflineRepository.getProgress(
        entry.id,
        defaultTarget: safeTarget,
      );
      resolvedCount = (cached['count'] ?? entry.progress).clamp(0, safeTarget);
    }

    if (mounted) {
      setState(() {
        entry.progress = resolvedCount;
      });
    }

    final int malas = resolvedCount >= safeTarget ? 1 : 0;

    // Save locally
    await JapOfflineRepository.saveProgress(
      japId: entry.id,
      count: resolvedCount,
      completedMalas: malas,
      targetCount: safeTarget,
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
          resolvedCount,
          completedMalas: malas,
        );
        await JapOfflineRepository.markSynced(entry.id);
      } catch (e) {
        debugPrint('[JapCounterScreen] Background sync error: $e');
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
            displayName: result.displayName,
            coverImageFile: File(result.coverImagePath),
            godImageFile: File(result.godImagePath),
            audioFile: result.audioFilePath.isNotEmpty && File(result.audioFilePath).existsSync()
                ? File(result.audioFilePath)
                : null,
            targetCount: result.chantCount,
            particleShape: result.particleEffect,
            revealEffect: result.particleEffect,
            godCategory: result.category,
            shlokText: result.mantraText,
            voiceText: result.voiceText,
            backgroundMusic: result.backgroundMusic,
            voiceEnabled: result.voiceEnabled,
            musicEnabled: result.musicEnabled,
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
        displayName: result.displayName.isNotEmpty ? result.displayName : result.name,
        fullName: result.name,
        mantraText: result.mantraText,
        voiceText: result.voiceText,
        backgroundMusic: result.backgroundMusic,
        voiceEnabled: result.voiceEnabled,
        musicEnabled: result.musicEnabled,
        thumbnailUrl: resolvedThumbnail,
        darshanImageUrl: resolvedDarshan,
        shlokText: result.mantraText,
        shlokAudioUrl: resolvedAudio,
        targetCount: result.chantCount,
        progress: 0,
        particleShape: result.particleEffect,
        isCustom: true,
        effectPack: EffectPack.resolve(
          name: result.name,
          particleShape: result.particleEffect,
        ),
      );

      await JapOfflineRepository.saveCustomJap({
        '_id': newCustomConfig.id,
        'id': newCustomConfig.id,
        'name': newCustomConfig.name,
        'displayName': newCustomConfig.displayName,
        'fullName': newCustomConfig.fullName,
        'thumbnail': newCustomConfig.thumbnailUrl,
        'darshanImage': newCustomConfig.darshanImageUrl,
        'shlokText': newCustomConfig.shlokText,
        'voiceText': newCustomConfig.voiceText,
        'backgroundMusic': newCustomConfig.backgroundMusic ?? '',
        'voiceEnabled': newCustomConfig.voiceEnabled,
        'musicEnabled': newCustomConfig.musicEnabled,
        'shlokAudio': newCustomConfig.shlokAudioUrl,
        'targetCount': newCustomConfig.targetCount,
        'particleShape': result.particleEffect,
        'isCustom': true,
        'progress': 0,
      });

      if (!mounted) return;
      setState(() {
        _allJaps.insert(0, newCustomConfig);
        _selectedTab = 1; // Auto switch to Your Custom Jap tab
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
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.canPop(context)) {
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

            // ── Create Custom Jap Button ─────────────
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
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                        'Create Custom Jap',
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

            const SizedBox(height: 12),

            // ── 2 Toggle Buttons: Admin Jap & Your Custom Jap ─────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFE0B2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9933).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Button 1: Admin Jap
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedTab != 0) {
                            setState(() => _selectedTab = 0);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 0
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                                  )
                                : null,
                            color: _selectedTab == 0 ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF6600).withValues(alpha: 0.28),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 16,
                                color: _selectedTab == 0 ? Colors.white : const Color(0xFF8C6239),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Admin Jap ($_adminJapCount)',
                                style: GoogleFonts.outfit(
                                  color: _selectedTab == 0 ? Colors.white : const Color(0xFF6B4226),
                                  fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Button 2: Your Custom Jap
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedTab != 1) {
                            setState(() => _selectedTab = 1);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 1
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                                  )
                                : null,
                            color: _selectedTab == 1 ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF6600).withValues(alpha: 0.28),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: _selectedTab == 1 ? Colors.white : const Color(0xFF8C6239),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Your Custom Jap ($_customJapCount)',
                                style: GoogleFonts.outfit(
                                  color: _selectedTab == 1 ? Colors.white : const Color(0xFF6B4226),
                                  fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _selectedTab == 1 ? Icons.person_rounded : Icons.search_off_rounded,
                                    size: 32,
                                    color: const Color(0xFFFF7700),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedTab == 1
                                      ? 'No Custom Jap Yet'
                                      : (_searchQuery.isEmpty ? 'No Admin Jap Available' : 'No matching results'),
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2E2A36),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedTab == 1
                                      ? 'Tap "Create Custom Jap" above to add your own deity photo, mantra & chanting target.'
                                      : 'No chanting entries found matching your query.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF7A6451),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
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
                          final int safeTarget = jap.targetCount > 0 ? jap.targetCount : 108;
                          return _JapCard(
                            entry: jap,
                            onTap: () => _openJapDetail(jap),
                            isFavourite: _favJapIds.contains(jap.id),
                            isSaved: _savedJapIds.contains(jap.id),
                            onFavouriteTap: () => _toggleCardFav(jap),
                            onSavedTap: () => _toggleCardSaved(jap),
                            onResetTap: () => _showResetJapDialog(jap),
                            onDhupTap: () async {
                              final updated = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DhupJapScreen(entry: jap),
                                ),
                              );
                              int resolvedCount;
                              if (updated != null) {
                                resolvedCount = updated.clamp(0, safeTarget);
                              } else {
                                final cached = await JapOfflineRepository.getProgress(
                                  '${jap.id}_dhup',
                                  defaultTarget: safeTarget,
                                );
                                final cachedBase = await JapOfflineRepository.getProgress(
                                  jap.id,
                                  defaultTarget: safeTarget,
                                );
                                resolvedCount = [
                                  cached['count'] ?? 0,
                                  cachedBase['count'] ?? 0,
                                  jap.progress,
                                ].reduce((a, b) => a > b ? a : b).clamp(0, safeTarget);
                              }
                              if (mounted) {
                                setState(() => jap.progress = resolvedCount);
                              }
                              final int malas = resolvedCount >= safeTarget ? 1 : 0;
                              await JapOfflineRepository.saveProgress(
                                japId: jap.id,
                                count: resolvedCount,
                                completedMalas: malas,
                                targetCount: safeTarget,
                              );
                              if (_token.isEmpty) {
                                final prefs = await SharedPreferences.getInstance();
                                _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
                              }
                              if (_token.isNotEmpty && jap.id.isNotEmpty && jap.id.length == 24) {
                                try {
                                  await ApiService.syncJapProgress(
                                    _token,
                                    jap.id,
                                    resolvedCount,
                                    completedMalas: malas,
                                  );
                                } catch (_) {}
                              }
                            },
                            onJalTap: () async {
                              final updated = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JalJapScreen(entry: jap),
                                ),
                              );
                              if (updated != null && mounted) {
                                final clamped = updated.clamp(0, safeTarget);
                                setState(() => jap.progress = clamped);
                                await JapOfflineRepository.saveProgress(
                                  japId: jap.id,
                                  count: clamped,
                                  completedMalas: clamped >= safeTarget ? 1 : 0,
                                  targetCount: safeTarget,
                                );
                              }
                            },
                            onPrakashTap: () async {
                              final updated = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PrakashJapScreen(entry: jap),
                                ),
                              );
                              if (updated != null && mounted) {
                                final clamped = updated.clamp(0, safeTarget);
                                setState(() => jap.progress = clamped);
                                await JapOfflineRepository.saveProgress(
                                  japId: jap.id,
                                  count: clamped,
                                  completedMalas: clamped >= safeTarget ? 1 : 0,
                                  targetCount: safeTarget,
                                );
                              }
                            },
                            onPushpTap: () async {
                              final updated = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PushpVarshaJapScreen(entry: jap),
                                ),
                              );
                              if (updated != null && mounted) {
                                final clamped = updated.clamp(0, safeTarget);
                                setState(() => jap.progress = clamped);
                                await JapOfflineRepository.saveProgress(
                                  japId: jap.id,
                                  count: clamped,
                                  completedMalas: clamped >= safeTarget ? 1 : 0,
                                  targetCount: safeTarget,
                                );
                              }
                            },
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
  final VoidCallback? onResetTap;
  final VoidCallback? onDhupTap;
  final VoidCallback? onJalTap;
  final VoidCallback? onPrakashTap;
  final VoidCallback? onPushpTap;
  final bool isFavourite;
  final bool isSaved;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onSavedTap;

  const _JapCard({
    required this.entry,
    required this.onTap,
    this.onResetTap,
    this.onDhupTap,
    this.onJalTap,
    this.onPrakashTap,
    this.onPushpTap,
    this.isFavourite = false,
    this.isSaved = false,
    this.onFavouriteTap,
    this.onSavedTap,
  });

  @override
  Widget build(BuildContext context) {
    final int target = entry.targetCount > 0 ? entry.targetCount : 108;
    final int currentCount = entry.progress.clamp(0, target);
    final bool isCompletedToday = currentCount >= target;
    final double progressRatio = (currentCount / target).clamp(0.0, 1.0);

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            entry.name.isNotEmpty
                                ? entry.name
                                : (entry.fullName.isNotEmpty ? entry.fullName : entry.displayName),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              height: 1.15,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ),
                        if (onSavedTap != null)
                          InkWell(
                            onTap: onSavedTap,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 19,
                                color: isSaved ? const Color(0xFFFF7700) : const Color(0xFF9E8A78),
                              ),
                            ),
                          ),
                        if (onFavouriteTap != null)
                          InkWell(
                            onTap: onFavouriteTap,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 19,
                                color: isFavourite ? const Color(0xFFE53935) : const Color(0xFF9E8A78),
                              ),
                            ),
                          ),
                        if (currentCount > 0 && onResetTap != null) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: isCompletedToday
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF8C6239),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              color: const Color(0xFFFFFBF5),
                              onSelected: (value) {
                                if (value == 'reset') {
                                  onResetTap?.call();
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem<String>(
                                  value: 'reset',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.restart_alt_rounded,
                                        size: 18,
                                        color: Color(0xFFFF7700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Reset Today's Jap",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                          color: const Color(0xFF2E2A36),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.mantraText.isNotEmpty ? entry.mantraText : entry.shlokText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerifGujarati(
                        fontSize: 12,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.75),
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),

                    // Proper Daily Progress Bar (Orange in-progress, Green when completed)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              backgroundColor: isCompletedToday
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF0E6),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompletedToday
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFFF7700),
                              ),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCompletedToday) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              '$currentCount / $target',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: isCompletedToday
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFFF7700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Actions: ONLY [Chant 📿] and [✨ Effect]
                    Row(
                      children: [
                        // Chant CTA Button (Always Orange)
                        GestureDetector(
                          onTap: onTap,
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
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Effect Picker Button
                        GestureDetector(
                          onTap: () => _showEffectPickerSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                                  'Effect',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF7700),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
    );
  }

  void _showEffectPickerSheet(BuildContext context) {
    final String deityLabel = entry.displayName.isNotEmpty ? entry.displayName : entry.name;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        Widget buildEffectTile({
          required IconData icon,
          required Color iconColor,
          required Color bgColor,
          required String title,
          required String subtitle,
          required VoidCallback? onSelect,
        }) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(sheetCtx);
              onSelect?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFC8A882).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF7B6B5D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFFFF7700),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9C5B2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFF7700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Jap Effect',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          Text(
                            'Choose an effect to begin $deityLabel Jap',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: const Color(0xFF8C6239),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8C6239)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                buildEffectTile(
                  icon: Icons.waves_rounded,
                  iconColor: const Color(0xFFFFB300),
                  bgColor: const Color(0xFF1E140F),
                  title: 'Dhoop Smoke Reveal 🪔',
                  subtitle: 'With every chant, incense smoke rises from the dhoop and unveils the deity',
                  onSelect: onDhupTap,
                ),
                const SizedBox(height: 10),
                buildEffectTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFFFF7700),
                  bgColor: const Color(0xFFFFF3E0),
                  title: 'Divine Reveal 🕉️',
                  subtitle: 'Classic cinematic progressive darshan',
                  onSelect: () async {
                    await JapEffectSelectorSheet.saveSelectedEffect(
                      JapRevealEffectType.divineVerticalReveal,
                    );
                    onTap();
                  },
                ),
              ],
            ),
          ),
        );
      },
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
