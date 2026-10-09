import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/saved_items_service.dart';
import '../../services/utsav_service.dart';
import 'mandal_profile_screen.dart';

// ─── Festival Activity Screen ──────────────────────────────────────────────────

class FestivalActivityScreen extends StatefulWidget {
  final String festivalName;
  final String imageUrl;
  final Map<String, dynamic>? festivalData;

  const FestivalActivityScreen({
    super.key,
    required this.festivalName,
    required this.imageUrl,
    this.festivalData,
  });

  @override
  State<FestivalActivityScreen> createState() => _FestivalActivityScreenState();
}

class _FestivalActivityScreenState extends State<FestivalActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearchFocused = false;
  final FocusNode _focusNode = FocusNode();

  final Map<String, bool> _likedPosts = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _savedPosts = {};
  String? _heartAnimatedPostId;

  List<Map<String, dynamic>> _mandals = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, String>> _reels = [];
  bool _isLoading = true;

  void _triggerHeartAnimation(String postId, Map<String, dynamic> post) {
    setState(() {
      _heartAnimatedPostId = postId;
      if (!(_likedPosts[postId] ?? false)) {
        _likedPosts[postId] = true;
        _likeCounts[postId] = (_likeCounts[postId] ?? (post['likes'] as int? ?? 0)) + 1;
      }
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _heartAnimatedPostId = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isSearchFocused = _focusNode.hasFocus);
    });
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    try {
      final festId = widget.festivalData?['_id'] ?? widget.festivalData?['customId'];
      final list = await UtsavService.getMandals(festivalId: festId?.toString());
      final List<Map<String, dynamic>> allPosts = [];
      final List<Map<String, String>> allReels = [];

      for (final m in list) {
        final mName = (m['name'] ?? '').toString();
        final pList = await UtsavService.getMandalPosts(mName);
        for (final p in pList) {
          allPosts.add({
            ...p,
            'mandalName': mName,
            'logo': m['logo'] ?? m['imageUrl'],
            'area': m['city'] ?? '',
          });
        }
        final rList = await UtsavService.getMandalReels(mName);
        for (final r in rList) {
          allReels.add({
            'id': r['id']?.toString() ?? '',
            'title': r['title']?.toString() ?? '',
            'mandalName': mName,
            'thumbnailUrl': (r['thumbnailUrl'] ?? r['imageUrl'] ?? 'assets/images/devotional/navratri_garba_festival.jpg').toString(),
            'videoUrl': r['videoUrl']?.toString() ?? '',
            'area': m['city']?.toString() ?? '',
            'views': r['views']?.toString() ?? '1.2K',
          });
        }
      }

      if (mounted) {
        setState(() {
          _mandals = list;
          _reels = allReels;
          _posts = allPosts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentMandals => _mandals;
  List<Map<String, String>> get _currentReels => _reels;
  List<Map<String, dynamic>> get _currentPosts => _posts;

  List<Map<String, dynamic>> get _filteredMandals {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return _currentMandals.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final area = (m['city'] ?? m['area'] ?? '').toString().toLowerCase();
      final location = (m['location'] ?? '').toString().toLowerCase();
      return name.contains(q) || area.contains(q) || location.contains(q);
    }).toList();
  }

  List<Map<String, String>> get _filteredReels {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return _currentReels.where((r) {
      final mn = (r['mandalName'] ?? '').toLowerCase();
      final area = (r['area'] ?? '').toLowerCase();
      return mn.contains(q) || area.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return _currentPosts.where((p) {
      final mn = (p['mandalName'] ?? '').toString().toLowerCase();
      final area = (p['area'] ?? '').toString().toLowerCase();
      return mn.contains(q) || area.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasQuery = _query.trim().isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8A882), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF8E5A2A)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.festivalName,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSearchFocused ? const Color(0xFFFF7700) : const Color(0xFFF0E0CF),
                    width: _isSearchFocused ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7700).withValues(alpha: _isSearchFocused ? 0.08 : 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.outfit(fontSize: 14.5, color: const Color(0xFF2E2A36)),
                  decoration: InputDecoration(
                    hintText: 'Search mandals, areas, cities...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8C1A), size: 22),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFC8A882)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: hasQuery ? _buildSearchResults() : _buildDefaultFeed(),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDefaultFeed() {
    final reels = _currentReels;
    final posts = _currentPosts;

    if (reels.isEmpty && posts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAD8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.25), width: 2),
                ),
                child: const Icon(Icons.video_library_outlined, size: 44, color: Color(0xFFFF7700)),
              ),
              const SizedBox(height: 20),
              Text(
                'No Reels or Posts Yet',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Devotees and Mandals can share their Reels and Posts once the festival begins.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // Section: Popular Reels
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            'Popular Reels',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reels.length,
            itemBuilder: (context, index) => _buildReelThumbnail(reels[index], index, reels),
          ),
        ),

        const SizedBox(height: 22),

        // Section: Popular Posts
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'Popular Posts',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ),
        ...List.generate(
          posts.length,
          (i) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildPostCard(posts[i]),
          ),
        ),
      ],
    );
  }

  // ── Search Results ─────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    final mandals = _filteredMandals;
    final reels = _filteredReels;
    final posts = _filteredPosts;
    final totalResults = mandals.length + reels.length + posts.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFFD9B89C)),
            const SizedBox(height: 12),
            Text(
              'No results for "$_query"',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching by mandal name or city.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // ── Mandal results
        if (mandals.isNotEmpty) ...[
          _buildSectionHeader('Mandals', mandals.length),
          const SizedBox(height: 8),
          ...mandals.map((m) => _buildMandalSearchCard(m)),
          const SizedBox(height: 16),
        ],

        // ── Reel results
        if (reels.isNotEmpty) ...[
          _buildSectionHeader('Reels', reels.length),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: reels.length,
              itemBuilder: (context, index) => _buildReelThumbnail(reels[index], index, reels),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Post results
        if (posts.isNotEmpty) ...[
          _buildSectionHeader('Posts', posts.length),
          const SizedBox(height: 8),
          ...posts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildPostCard(p),
              )),
        ],
      ],
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7700),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.35),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMandalSearchCard(Map<String, dynamic> mandal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MandalProfileScreen(
              mandalName: mandal['name'] as String,
              location: mandal['location'] as String,
              avatarUrl: mandal['avatarUrl'] as String,
              coverUrl: mandal['coverUrl'] as String,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3E4D6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                mandal['avatarUrl'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFFFFF1E5),
                  child: const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF8C1A)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mandal['name'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFFF8C1A)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          mandal['location'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mandal['followers'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF7700),
                  ),
                ),
                Text(
                  'followers',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFFF8C1A)),
          ],
        ),
      ),
    );
  }

  Widget _buildReelThumbnail(Map<String, String> reel, [int index = 0, List<Map<String, String>>? sourceList]) {
    final list = sourceList ?? _reels;
    return GestureDetector(
      onTap: () {
        // find matching mandal
        final mandal = _mandals.firstWhere(
          (m) => m['name'] == reel['mandalName'],
          orElse: () => <String, dynamic>{},
        );

        final videoAssets = [
          'assets/images/1st_Scene.mp4',
          'assets/images/2nd_Scene.mp4',
          'assets/images/3rd_Scene.mp4',
        ];

        final convertedReels = list.asMap().entries.map((entry) {
          final r = entry.value;
          final i = entry.key;
          return ReelItem(
            id: 'reel_${r['mandalName']}_$i',
            thumbnailUrl: r['image'] ?? 'assets/images/ram_bhajan.png',
            videoUrl: videoAssets[i % videoAssets.length],
            title: r['caption'] ?? 'Divine Mandal Aarti Clip',
            audioTrack: 'Original Mandal Audio • Sacred Chants',
            views: r['likes'] ?? '0',
            likes: int.tryParse(r['likes']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0,
          );
        }).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullscreenReelViewer(
              startIndex: index,
              reels: convertedReels,
              mandalName: reel['mandalName'] ?? 'Mandal',
              avatarUrl: (mandal['avatarUrl'] ?? mandal['imageUrl'] ?? 'assets/images/ram_bhajan.png').toString(),
            ),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                reel['image'] ?? 'assets/images/new_year_card.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFFFFEAD8)),
              ),
              // Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
              // Play icon
              const Center(
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
              ),
              // Caption + likes
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel['mandalName'] ?? '',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          reel['likes'] ?? '',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
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

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = '${post['mandalName']}_${post['time']}';
    final isLiked = _likedPosts[postId] ?? false;
    final currentLikes = _likeCounts[postId] ?? (post['likes'] as int? ?? 0);
    final isSaved = _savedPosts[postId] ?? false;

    // find matching mandal
    final mandal = _mandals.firstWhere(
      (m) => m['name'] == post['mandalName'],
      orElse: () => {
        'name': post['mandalName'] as String? ?? 'Mandal',
        'location': 'Gujarat, India',
        'avatarUrl': post['avatarUrl'] as String? ?? 'assets/images/new_year_card.png',
        'coverUrl': 'assets/images/somnath_hero.png',
      },
    );
    final mandalLocation = (mandal['location'] as String?) ?? 'Gujarat, India';
    final avatarUrl = (post['avatarUrl'] ?? mandal['avatarUrl'] ?? 'assets/images/new_year_card.png') as String;
    final postImage = (post['image'] ?? 'assets/images/diwali_card.png') as String;
    final caption = (post['caption'] ?? '') as String;
    final timeAgo = (post['time'] ?? 'Recently') as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE6DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header - Click to Open Mandal Profile Directly
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MandalProfileScreen(
                      mandalName: mandal['name'] as String,
                      location: mandal['location'] as String,
                      avatarUrl: mandal['avatarUrl'] as String,
                      coverUrl: (mandal['coverUrl'] as String?) ?? 'assets/images/somnath_hero.png',
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9500), Color(0xFFFF5500)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: avatarUrl.startsWith('http')
                          ? NetworkImage(avatarUrl) as ImageProvider
                          : AssetImage(avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post['mandalName'] as String,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: const Color(0xFF2E2A36),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 15),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFFFF7700)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                "$mandalLocation • ",
                                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF7A757F)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF7A757F)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Post Image (Clean, Full-width, Double-tap to Like)
          GestureDetector(
            onDoubleTap: () => _triggerHeartAnimation(postId, post),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 220, maxHeight: 420),
                  color: const Color(0xFFF7F2EB),
                  child: buildSmartImage(postImage, fit: BoxFit.cover),
                ),
                if (_heartAnimatedPostId == postId)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween(begin: 0.4, end: 1.2),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 90,
                          shadows: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // 3. Action Buttons Row (Like, Share, Save)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.redAccent : const Color(0xFF2E2A36),
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      final nowLiked = !isLiked;
                      _likedPosts[postId] = nowLiked;
                      _likeCounts[postId] = currentLikes + (nowLiked ? 1 : -1);
                    });
                  },
                ),
                Text(
                  "$currentLikes",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: const Color(0xFF2E2A36)),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF2E2A36), size: 22),
                  onPressed: () {
                    Share.share(
                      "🚩 Check out this post by ${post['mandalName']} on Bharat Pray!\n\n$caption\n\nDownload App: https://bharatpray.app",
                      subject: "Bharat Pray Mandal Post",
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isSaved ? const Color(0xFFFF7700) : const Color(0xFF2E2A36),
                    size: 24,
                  ),
                  onPressed: () async {
                    final isNowSaved = await SavedItemsService.toggleSavePost(
                      {
                        'id': postId,
                        'content': caption,
                        'image': postImage,
                        'likes': currentLikes,
                        'time': timeAgo,
                        'location': mandalLocation,
                      },
                      post['mandalName'] as String,
                      avatarUrl,
                    );
                    setState(() {
                      _savedPosts[postId] = isNowSaved;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isNowSaved ? "Saved to Library! 🔖" : "Removed from Saved Items"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // 4. Festival Tag Chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF7700).withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🛕", style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 5),
                  Text(
                    widget.festivalName,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF7700),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Post Caption (Clear, Dark Text, High Contrast)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF2E2A36),
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: "${post['mandalName']} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
