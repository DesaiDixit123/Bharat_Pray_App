import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/localization_constants.dart';
import '../../core/localization/localized_api_helper.dart';
import '../../models/bhajan_track_item.dart';
import '../../services/api_service.dart';
import '../../services/bhajan_audio_service.dart';
import '../../services/bhajan_library_service.dart';
import '../../widgets/bhajan/bhajan_mini_player_widget.dart';
import 'bhajan_category_screen.dart';
import 'bhajan_library_hub_screen.dart';
import 'bhajan_list_by_category_screen.dart';
import 'bhajan_now_playing_screen.dart';

class BhajanDashboardScreen extends StatefulWidget {
  const BhajanDashboardScreen({super.key});

  @override
  State<BhajanDashboardScreen> createState() => _BhajanDashboardScreenState();
}

class _BhajanDashboardScreenState extends State<BhajanDashboardScreen> {
  String _token = '';
  bool _isLoading = true;
  String _error = '';

  List<BhajanTrackItem> _featuredTracks = [];
  List<BhajanTrackItem> _trendingTracks = [];
  List<BhajanTrackItem> _recommendedTracks = [];
  List<_DashboardCategoryItem> _categories = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentBannerIndex = 0;
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_featuredTracks.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerPageController.hasClients && _featuredTracks.isNotEmpty) {
        final next = (_currentBannerIndex + 1) % _featuredTracks.length;
        _bannerPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

    await BhajanLibraryService.instance.init(token: _token);

    try {
      // 1. Fetch categories
      final catRaw = await ApiService.getBhajanGodCategories(_token);
      final List<_DashboardCategoryItem> parsedCats = [];
      for (final item in catRaw) {
        if (item is Map<String, dynamic>) {
          final id = (item['_id'] ?? item['id'] ?? '').toString();
          final title = LocalizedApiHelper.parse(item['name'] ?? item['title']);
          final img = (item['image'] ?? item['imageUrl'] ?? '').toString();
          final count = item['bhajanCount'] ?? item['totalBhajans'] ?? item['count'] ?? 0;
          if (id.isNotEmpty && title.isNotEmpty) {
            parsedCats.add(_DashboardCategoryItem(
              id: id,
              title: title,
              imageUrl: img,
              count: count is int ? count : int.tryParse(count.toString()) ?? 0,
            ));
          }
        }
      }

      // 2. Fetch Bhajan Home Data (trending, popular, recommended)
      Map<String, dynamic> homeData = {};
      try {
        homeData = await ApiService.getBhajanHome(_token);
      } catch (_) {}

      final popularList = homeData['popular'] is List ? (homeData['popular'] as List) : [];
      final recommendedList = homeData['recommended'] is List ? (homeData['recommended'] as List) : [];
      final latestList = homeData['latest'] is List ? (homeData['latest'] as List) : [];

      List<BhajanTrackItem> trending = [];
      for (final item in popularList) {
        final t = _parseTrack(item);
        if (t != null) trending.add(t);
      }

      List<BhajanTrackItem> recommended = [];
      for (final item in (recommendedList.isNotEmpty ? recommendedList : latestList)) {
        final t = _parseTrack(item);
        if (t != null) recommended.add(t);
      }

      // Gather a rich pool of 20-30 bhajans across categories so Recent Plays "View All" has 20-30 tracks
      final List<BhajanTrackItem> recentPool = [...recommended, ...trending];
      if (parsedCats.isNotEmpty && recentPool.length < 25) {
        for (var i = 0; i < parsedCats.length && recentPool.length < 30; i++) {
          final cat = parsedCats[i];
          try {
            final catData = await ApiService.getBhajansByCategory(_token, cat.id, limit: 10);
            final items = catData['docs'] ?? catData['items'] ?? catData['bhajans'] ?? [];
            if (items is List) {
              if (cat.count == 0 && items.isNotEmpty) {
                parsedCats[i] = cat.copyWith(count: items.length);
              }
              for (final raw in items) {
                final t = _parseTrack(raw);
                if (t != null) {
                  if (trending.length < 8 && !trending.any((e) => e.id == t.id)) {
                    trending.add(t);
                  }
                  if (!recentPool.any((e) => e.id == t.id) && recentPool.length < 30) {
                    recentPool.add(t);
                  }
                }
              }
            }
          } catch (_) {}
        }
      }

      // Sync any server-marked liked tracks & seed 20-30 recent plays pool
      // (User's actual last played tracks ALWAYS remain at index 0, 1, 2...)
      BhajanLibraryService.instance.syncLikedFromTracks(recentPool);
      BhajanLibraryService.instance.seedRecentPlaysPool(recentPool);

      // Featured tracks for Hero Banner
      final List<BhajanTrackItem> featured = [];
      if (trending.isNotEmpty) {
        featured.addAll(trending.take(4));
      } else if (recommended.isNotEmpty) {
        featured.addAll(recommended.take(4));
      }

      if (!mounted) return;
      setState(() {
        _categories = parsedCats;
        _trendingTracks = trending;
        _recommendedTracks = recommended;
        _featuredTracks = featured;
        _isLoading = false;
      });

      _startBannerAutoScroll();
    } catch (e) {
      if (!mounted) return;
      final lib = BhajanLibraryService.instance;
      final offlinePool = <BhajanTrackItem>[
        ...lib.downloadedTracks,
        ...lib.recentTracks,
        ...lib.likedTracks,
      ];
      final uniqueOffline = <String, BhajanTrackItem>{};
      for (final t in offlinePool) {
        uniqueOffline.putIfAbsent(t.id, () => t);
      }
      final fallbackTracks = uniqueOffline.values.toList();
      setState(() {
        _isLoading = false;
        if (fallbackTracks.isNotEmpty) {
          _error = '';
          _trendingTracks = fallbackTracks;
          _recommendedTracks = fallbackTracks;
          _featuredTracks = fallbackTracks.take(4).toList();
        } else {
          _error = '';
        }
      });
    }
  }

  BhajanTrackItem? _parseTrack(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return BhajanTrackItem.fromJson(raw);
  }

  void _playTrack(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    BhajanLibraryService.instance.recordRecentPlay(track);
    BhajanAudioService.instance.playTrack(track, queue: queue, token: _token);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BhajanNowPlayingScreen(
          currentTrack: track,
          queue: queue,
        ),
      ),
    );
  }

  Future<void> _toggleLike(BhajanTrackItem track) async {
    HapticFeedback.selectionClick();
    final nowLiked = await BhajanLibraryService.instance.toggleLike(track, token: _token);
    if (mounted) {
      BhajanLibraryService.showLightSnackBar(
        context,
        nowLiked
            ? '${LocalizedApiHelper.parse("Added to Liked Bhajans")} ❤️'
            : LocalizedApiHelper.parse('Removed from Liked Bhajans'),
        icon: nowLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      );
    }
  }

  void _onTrackMenuSelected(String action, BhajanTrackItem track) async {
    switch (action) {
      case 'download':
        final lib = BhajanLibraryService.instance;
        if (lib.isDownloaded(track.id) || lib.isDownloading(track.id)) return;
        HapticFeedback.lightImpact();
        final completed = await lib.downloadTrack(track, token: _token);
        if (completed && mounted) {
          BhajanLibraryService.showLightSnackBar(
            context,
            '${LocalizedApiHelper.parse("Saved to Offline Downloads")}: "${track.title}"',
            icon: Icons.download_done_rounded,
          );
        }
        break;
      case 'share':
        final shareText =
            '🙏 Listen to divine bhajan "${track.title}" by ${track.singer} on Bharat Pray app!\nhttps://bharatpray.com/bhajan/${track.id}';
        await Share.share(shareText, subject: track.title);
        break;
      case 'playlist':
        BhajanLibraryService.showAddToPlaylistSheet(context, track);
        break;
    }
  }

  void _openCategory(_DashboardCategoryItem category) {
    final resolvedImage = _resolveDeityAsset(category.title, category.imageUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanListByCategoryScreen(
          categoryId: category.id,
          categoryTitle: category.title,
          categoryImagePath: resolvedImage,
        ),
      ),
    );
  }

  void _openAllCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BhajanCategoryScreen(),
      ),
    );
  }

  void _openLibraryHub({int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanLibraryHubScreen(initialTabIndex: initialTab),
      ),
    );
  }

  String _resolveDeityAsset(String title, String remoteUrl) {
    if (remoteUrl.startsWith('http://') || remoteUrl.startsWith('https://')) {
      return remoteUrl;
    }
    final lower = title.toLowerCase();
    if (lower.contains('hanuman') || lower.contains('bajrang') || lower.contains('હનુમાન') || lower.contains('हनुमान')) {
      return 'assets/images/deity_hanuman.png';
    }
    if (lower.contains('shiva') || lower.contains('shiv') || lower.contains('mahadev') || lower.contains('bholenath') || lower.contains('શિવ') || lower.contains('शिव')) {
      return 'assets/images/deity_shiva.png';
    }
    if (lower.contains('krishna') || lower.contains('shyam') || lower.contains('kanha') || lower.contains('radhe') || lower.contains('કૃષ્ણ') || lower.contains('कृष्ण')) {
      return 'assets/images/deity_krishna.png';
    }
    if (lower.contains('ram') || lower.contains('sita') || lower.contains('raghunath') || lower.contains('રામ') || lower.contains('राम')) {
      return 'assets/images/deity_ram.png';
    }
    if (lower.contains('amba') || lower.contains('durga') || lower.contains('mataji') || lower.contains('jagadamba') || lower.contains('દુર્ગા') || lower.contains('અંબા') || lower.contains('दुर्गा')) {
      return 'assets/images/deity_amba.png';
    }
    if (lower.contains('ganesh') || lower.contains('ganpati') || lower.contains('vinayak') || lower.contains('gajanand') || lower.contains('ગણેશ') || lower.contains('गणेश')) {
      return 'assets/images/deity_ganesha.png';
    }
    if (lower.contains('khodiyar') || lower.contains('khodal') || lower.contains('ખોડિયાર')) {
      return 'assets/images/deity_khodiyar.png';
    }
    if (lower.contains('vishnu') || lower.contains('narayan') || lower.contains('dwarka') || lower.contains('વિષ્ણુ')) {
      return 'assets/images/deity_vishnu.png';
    }
    if (lower.contains('brahma') || lower.contains('બ્રહ્મા') || lower.contains('ब्रह्मा')) {
      return 'assets/images/deity_brahma.png';
    }
    if (lower.contains('surya') || lower.contains('sun') || lower.contains('aditya') || lower.contains('bhaskar') || lower.contains('સૂર્ય')) {
      return 'assets/images/deity_surya.png';
    }
    if (lower.contains('ayyappa') || lower.contains('swamy') || lower.contains('shabarimala') || lower.contains('manikandan') || lower.contains('અય્યપ્પા')) {
      return 'assets/images/deity_ayyappa.png';
    }
    return 'assets/images/deity_shiva.png';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        body: SafeArea(
          top: true,
          child: AnimatedBuilder(
            animation: BhajanLibraryService.instance,
            builder: (context, _) {
              return Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: _buildHeader(),
                  ),

                  // Main Scrollable Dashboard
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFFFF7700),
                      backgroundColor: Colors.white,
                      onRefresh: _loadDashboardData,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7700)),
                              ),
                            )
                          : _error.isNotEmpty
                              ? _buildErrorView()
                              : _buildDashboardContent(),
                    ),
                  ),

                  // Persistent Mini-Player
                  const BhajanMiniPlayerWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
            ),
            child: const Center(
              child: Icon(Icons.arrow_back_rounded, color: Color(0xFFC8A882), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizedApiHelper.parse('Divine Bhajans'),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              Text(
                LocalizedApiHelper.parse('Spiritual melodies & sacred hymns'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF8C7B6E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Profile Icon Button matching the exact Back Arrow color combination
        GestureDetector(
          onTap: () => _openLibraryHub(initialTab: 0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFFC8A882),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchBar(),
        ),
        const SizedBox(height: 18),

        // 1. Hero Banner Carousel (Featured Bhajan)
        if (_featuredTracks.isNotEmpty) ...[
          _buildHeroBannerSection(),
          const SizedBox(height: 24),
        ],

        // 2. Divine Categories Section
        if (_categories.isNotEmpty) ...[
          _buildCategoriesSection(),
          const SizedBox(height: 24),
        ],

        // 3. Trending Bhajans (Horizontal Cards)
        if (_trendingTracks.isNotEmpty) ...[
          _buildTrendingSection(),
          const SizedBox(height: 24),
        ],

        // 4. Recent Plays (Vertical List)
        if (_recommendedTracks.isNotEmpty || _trendingTracks.isNotEmpty) ...[
          _buildPopularListSection(),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DFCE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(
          fontSize: 14.5,
          color: const Color(0xFF2E2A36),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: LocalizedApiHelper.parse('Search bhajans, deities, singers...'),
          hintStyle: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFB56E28),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(Icons.close_rounded, color: Color(0xFF999999), size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  /// 1. Hero Banner Carousel featuring devotional highlight
  Widget _buildHeroBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 184,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: _featuredTracks.length,
            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
            itemBuilder: (context, index) {
              final track = _featuredTracks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => _playTrack(track, _featuredTracks),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7700), Color(0xFFFF9533), Color(0xFFE65100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: _buildNetworkOrFallbackImage(track.imagePath, width: 105, height: 105),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '⭐ ${LocalizedApiHelper.parse("FEATURED BHAJAN")}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      track.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      track.singer,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.12),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF7700), size: 18),
                                              const SizedBox(width: 4),
                                              Text(
                                                LocalizedApiHelper.parse('Listen Now'),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFFFF7700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (track.duration != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            track.duration!,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11.5,
                                              color: Colors.white.withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
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
            },
          ),
        ),
        if (_featuredTracks.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_featuredTracks.length, (i) {
              final isCurrent = i == _currentBannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isCurrent ? const Color(0xFFFF7700) : const Color(0xFFD8C4AF),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  /// 2. Categories in a unique divine circular avatar style
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SpiritualTerms.get('categories'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              GestureDetector(
                onTap: _openAllCategories,
                child: Row(
                  children: [
                    Text(
                      SpiritualTerms.get('view_all'),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7700),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFFF7700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final deityAsset = _resolveDeityAsset(cat.title, cat.imageUrl);

              return GestureDetector(
                onTap: () => _openCategory(cat),
                child: Container(
                  width: 82,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFFF7700), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7700).withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildNetworkOrFallbackImage(deityAsset, width: 66, height: 66),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      Text(
                        cat.count > 0
                            ? '${cat.count} ${LocalizedApiHelper.parse("Bhajans")}'
                            : LocalizedApiHelper.parse('Bhajans'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          color: const Color(0xFF8C7B6E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 3. Trending Bhajans (Horizontal Cards)
  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 18)),
              Text(
                SpiritualTerms.get('trending_bhajans'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const Spacer(),
              Text(
                LocalizedApiHelper.parse('Most Played'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF8C7B6E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 208,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trendingTracks.length,
            itemBuilder: (context, index) {
              final track = _trendingTracks[index];

              return GestureDetector(
                onTap: () => _playTrack(track, _trendingTracks),
                child: Container(
                  width: 146,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                            child: _buildNetworkOrFallbackImage(track.imagePath, width: 146, height: 122),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF7700),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.singer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF8C7B6E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openAllRecentPlays() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BhajanRecentPlaysAllScreen(
          token: _token,
          fallbackTracks: [..._recommendedTracks, ..._trendingTracks],
        ),
      ),
    );
  }

  /// 4. Recent Plays (Vertical List — Last played ALWAYS first + View All for 20-30 tracks)
  Widget _buildPopularListSection() {
    final lib = BhajanLibraryService.instance;
    final recents = lib.recentTracks.isNotEmpty
        ? lib.recentTracks
        : (_recommendedTracks.isNotEmpty ? _recommendedTracks : _trendingTracks);
    final previewList = recents.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFF7700),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocalizedApiHelper.parse('Recent Plays'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openAllRecentPlays,
                child: Row(
                  children: [
                    Text(
                      SpiritualTerms.get('view_all'),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7700),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFFF7700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...previewList.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            final isFirst = index == 0;
            final isLiked = lib.isLiked(track.id);
            final isDownloaded = lib.isDownloaded(track.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFirst
                      ? const Color(0xFFFF7700).withValues(alpha: 0.45)
                      : const Color(0xFFF3E4D6),
                  width: isFirst ? 1.3 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                onTap: () => _playTrack(track, recents),
                leading: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildNetworkOrFallbackImage(track.imagePath, width: 52, height: 52),
                    ),
                    if (isFirst)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7700),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 11),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          LocalizedApiHelper.parse('Last Played'),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF7700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Row(
                  children: [
                    if (lib.isDownloading(track.id)) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            value: (lib.getDownloadPercentage(track.id) / 100.0).clamp(0.02, 1.0),
                            strokeWidth: 1.8,
                            backgroundColor: const Color(0xFFEBD7C2),
                            color: const Color(0xFFFF7700),
                          ),
                        ),
                      ),
                      Text(
                        '${lib.getDownloadPercentage(track.id)}% ',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF7700),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        '${track.singer}${track.duration != null ? " • ${track.duration}" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? const Color(0xFFE53935) : const Color(0xFF8C7B6E),
                        size: 22,
                      ),
                      onPressed: () => _toggleLike(track),
                    ),
                    // Light-Themed PopupMenuButton (No Dark BG!)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A3A2C), size: 22),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFF0DFCE)),
                      ),
                      elevation: 6,
                      onSelected: (action) => _onTrackMenuSelected(action, track),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'playlist',
                          child: Row(
                            children: [
                              const Icon(Icons.playlist_add_rounded, size: 20, color: Color(0xFFFF7700)),
                              const SizedBox(width: 10),
                              Text(
                                LocalizedApiHelper.parse('Add to Playlist'),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'download',
                          enabled: !isDownloaded && !lib.isDownloading(track.id),
                          child: Row(
                            children: [
                              Icon(
                                isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                size: 20,
                                color: isDownloaded ? const Color(0xFF4CAF50) : const Color(0xFFFF7700),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                lib.isDownloading(track.id)
                                    ? 'Downloading ${lib.getDownloadPercentage(track.id)}%...'
                                    : (isDownloaded
                                        ? LocalizedApiHelper.parse('Downloaded')
                                        : LocalizedApiHelper.parse('Download')),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDownloaded
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF2E2A36),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              const Icon(Icons.share_rounded, size: 20, color: Color(0xFFFF7700)),
                              const SizedBox(width: 10),
                              Text(
                                LocalizedApiHelper.parse('Share'),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Search Results View
  Widget _buildSearchResults() {
    final allTracks = <BhajanTrackItem>{..._trendingTracks, ..._recommendedTracks, ..._featuredTracks}.toList();
    final matchingTracks = allTracks.where((t) {
      return t.title.toLowerCase().contains(_searchQuery) ||
          t.singer.toLowerCase().contains(_searchQuery);
    }).toList();

    final matchingCats = _categories.where((c) {
      return c.title.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        if (matchingCats.isNotEmpty) ...[
          Text(
            LocalizedApiHelper.parse('Categories'),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matchingCats.map((c) {
              return ActionChip(
                backgroundColor: Colors.white,
                label: Text(c.title, style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.w600)),
                avatar: const Icon(Icons.category_rounded, size: 16, color: Color(0xFFFF7700)),
                onPressed: () => _openCategory(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '${LocalizedApiHelper.parse("Bhajans")} (${matchingTracks.length})',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
        ),
        const SizedBox(height: 10),
        if (matchingTracks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'No bhajans found for "$_searchQuery"',
                style: GoogleFonts.outfit(color: const Color(0xFF8C7B6E)),
              ),
            ),
          )
        else
          ...matchingTracks.map((track) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3E4D6)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                onTap: () => _playTrack(track, matchingTracks),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildNetworkOrFallbackImage(track.imagePath, width: 48, height: 48),
                ),
                title: Text(
                  track.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
                ),
                subtitle: Text(
                  track.singer,
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8C7B6E)),
                ),
                trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF7700), size: 30),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF7700), size: 48),
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOrFallbackImage(String path, {required double width, required double height}) {
    if (path.isNotEmpty && !path.startsWith('http') && !path.startsWith('assets/')) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          return Image.file(
            f,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackImage(width, height),
          );
        }
      } catch (_) {}
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    }
    return _fallbackImage(width, height);
  }

  Widget _fallbackImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF6E8DC),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 24),
      ),
    );
  }
}

class _DashboardCategoryItem {
  const _DashboardCategoryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.count,
  });

  final String id;
  final String title;
  final String imageUrl;
  final int count;

  _DashboardCategoryItem copyWith({
    String? id,
    String? title,
    String? imageUrl,
    int? count,
  }) {
    return _DashboardCategoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      count: count ?? this.count,
    );
  }
}

/// Full-Screen "View All" Recent Plays (Last 20–30 Played Bhajans, Most Recent First)
class _BhajanRecentPlaysAllScreen extends StatefulWidget {
  final String token;
  final List<BhajanTrackItem> fallbackTracks;

  const _BhajanRecentPlaysAllScreen({
    required this.token,
    required this.fallbackTracks,
  });

  @override
  State<_BhajanRecentPlaysAllScreen> createState() => _BhajanRecentPlaysAllScreenState();
}

class _BhajanRecentPlaysAllScreenState extends State<_BhajanRecentPlaysAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _playTrack(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    BhajanLibraryService.instance.recordRecentPlay(track);
    BhajanAudioService.instance.playTrack(track, queue: queue, token: widget.token);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BhajanNowPlayingScreen(
          currentTrack: track,
          queue: queue,
        ),
      ),
    );
  }

  Future<void> _toggleLike(BhajanTrackItem track) async {
    HapticFeedback.selectionClick();
    final nowLiked = await BhajanLibraryService.instance.toggleLike(track, token: widget.token);
    if (mounted) {
      BhajanLibraryService.showLightSnackBar(
        context,
        nowLiked
            ? '${LocalizedApiHelper.parse("Added to Liked Bhajans")} ❤️'
            : LocalizedApiHelper.parse('Removed from Liked Bhajans'),
        icon: nowLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      );
    }
  }

  void _onMenuSelected(String action, BhajanTrackItem track) async {
    switch (action) {
      case 'playlist':
        BhajanLibraryService.showAddToPlaylistSheet(context, track);
        break;
      case 'download':
        final lib = BhajanLibraryService.instance;
        if (lib.isDownloaded(track.id) || lib.isDownloading(track.id)) return;
        HapticFeedback.lightImpact();
        final completed = await lib.downloadTrack(track, token: widget.token);
        if (completed && mounted) {
          BhajanLibraryService.showLightSnackBar(
            context,
            '${LocalizedApiHelper.parse("Saved to Offline Downloads")}: "${track.title}"',
            icon: Icons.download_done_rounded,
          );
        }
        break;
      case 'share':
        final shareText =
            '🙏 Listen to divine bhajan "${track.title}" by ${track.singer} on Bharat Pray app!\nhttps://bharatpray.com/bhajan/${track.id}';
        await Share.share(shareText, subject: track.title);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = BhajanLibraryService.instance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        body: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
            animation: lib,
            builder: (context, _) {
              final allRecent = lib.recentTracks.isNotEmpty
                  ? lib.recentTracks.take(30).toList()
                  : widget.fallbackTracks.take(30).toList();

              final filtered = _query.isEmpty
                  ? allRecent
                  : allRecent.where((t) {
                      return t.title.toLowerCase().contains(_query) ||
                          t.singer.toLowerCase().contains(_query);
                    }).toList();

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFC8A882), size: 20),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizedApiHelper.parse('Recent Plays'),
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            Text(
                              '${allRecent.length} ${LocalizedApiHelper.parse("Bhajans")} • ${LocalizedApiHelper.parse("Last Played")}',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: const Color(0xFF8C7B6E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allRecent.isNotEmpty)
                        GestureDetector(
                          onTap: () => _playTrack(allRecent.first, allRecent),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7700), Color(0xFFFF9838)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  LocalizedApiHelper.parse('Play All'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Search inside Recent Plays
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEAD9C9)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                      decoration: InputDecoration(
                        hintText: LocalizedApiHelper.parse('Search bhajans, deities, singers...'),
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB56E28), size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(Icons.close_rounded, color: Color(0xFF8C7B6E), size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),

                // List of 20-30 Recent Plays
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final track = filtered[index];
                      final isFirst = index == 0 && _query.isEmpty;
                      final isLiked = lib.isLiked(track.id);
                      final isDownloaded = lib.isDownloaded(track.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFirst
                                ? const Color(0xFFFF7700).withValues(alpha: 0.5)
                                : const Color(0xFFF3E4D6),
                            width: isFirst ? 1.4 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          onTap: () => _playTrack(track, allRecent),
                          leading: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildImage(track.imagePath),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFirst ? const Color(0xFFFF7700) : const Color(0xFF2E2A36).withValues(alpha: 0.72),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                ),
                              ),
                              if (isFirst) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0E0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    LocalizedApiHelper.parse('Last Played'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF7700),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${track.singer}${track.duration != null ? " • ${track.duration}" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isLiked ? const Color(0xFFE53935) : const Color(0xFF8C7B6E),
                                  size: 22,
                                ),
                                onPressed: () => _toggleLike(track),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A3A2C), size: 22),
                                color: Colors.white,
                                surfaceTintColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFF0DFCE)),
                                ),
                                elevation: 6,
                                onSelected: (action) => _onMenuSelected(action, track),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'playlist',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.playlist_add_rounded, size: 20, color: Color(0xFFFF7700)),
                                        const SizedBox(width: 10),
                                        Text(
                                          LocalizedApiHelper.parse('Add to Playlist'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF2E2A36),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'download',
                                    enabled: !isDownloaded && !lib.isDownloading(track.id),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                          size: 20,
                                          color: isDownloaded ? const Color(0xFF4CAF50) : const Color(0xFFFF7700),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          lib.isDownloading(track.id)
                                              ? 'Downloading ${lib.getDownloadPercentage(track.id)}%...'
                                              : (isDownloaded
                                                  ? LocalizedApiHelper.parse('Downloaded')
                                                  : LocalizedApiHelper.parse('Download')),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDownloaded
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFF2E2A36),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.share_rounded, size: 20, color: Color(0xFFFF7700)),
                                        const SizedBox(width: 10),
                                        Text(
                                          LocalizedApiHelper.parse('Share'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF2E2A36),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const BhajanMiniPlayerWidget(),
              ],
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isNotEmpty && !path.startsWith('http') && !path.startsWith('assets/')) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          return Image.file(
            f,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          );
        }
      } catch (_) {}
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFF6E8DC),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 22),
      ),
    );
  }
}
