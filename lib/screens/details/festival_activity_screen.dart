import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mandal_profile_screen.dart';

// ─── Mock data for search (mandals + reels) ────────────────────────────────

const List<Map<String, dynamic>> _kSearchMandals = [
  {
    'name': 'Lalbaugcha Raja Yuva Mandal',
    'location': 'Mumbai, Maharashtra',
    'area': 'mumbai',
    'avatarUrl': 'assets/images/new_year_card.png',
    'coverUrl': 'assets/images/diwali_card.png',
    'followers': '12.4k',
    'type': 'mandal',
  },
  {
    'name': 'Shree Ganesh Yuvak Mandal',
    'location': 'Ahmedabad, Gujarat',
    'area': 'ahmedabad',
    'avatarUrl': 'assets/images/diwali_card.png',
    'coverUrl': 'assets/images/new_year_card.png',
    'followers': '9.8k',
    'type': 'mandal',
  },
  {
    'name': 'Surat Sarvajanik Garba Mandal',
    'location': 'Surat, Gujarat',
    'area': 'surat',
    'avatarUrl': 'assets/images/dhanteras_card.png',
    'coverUrl': 'assets/images/bhaiduj_card.png',
    'followers': '8.6k',
    'type': 'mandal',
  },
  {
    'name': 'Maa Durga Mahotsav Samiti',
    'location': 'Vadodara, Gujarat',
    'area': 'vadodara',
    'avatarUrl': 'assets/images/bhaiduj_card.png',
    'coverUrl': 'assets/images/dhanteras_card.png',
    'followers': '7.1k',
    'type': 'mandal',
  },
  {
    'name': 'Kashi Vishwanath Bhakta Mandal',
    'location': 'Varanasi, Uttar Pradesh',
    'area': 'varanasi',
    'avatarUrl': 'assets/images/new_year_card.png',
    'coverUrl': 'assets/images/diwali_card.png',
    'followers': '6.4k',
    'type': 'mandal',
  },
  {
    'name': 'Pune Ganesh Utsav Mandal',
    'location': 'Pune, Maharashtra',
    'area': 'pune',
    'avatarUrl': 'assets/images/diwali_card.png',
    'coverUrl': 'assets/images/new_year_card.png',
    'followers': '5.9k',
    'type': 'mandal',
  },
  {
    'name': 'Rajkot Shree Ram Mandal',
    'location': 'Rajkot, Gujarat',
    'area': 'rajkot',
    'avatarUrl': 'assets/images/dhanteras_card.png',
    'coverUrl': 'assets/images/bhaiduj_card.png',
    'followers': '4.2k',
    'type': 'mandal',
  },
];

const List<Map<String, String>> _kPopularReels = [
  {
    'mandalName': 'Lalbaugcha Raja Yuva Mandal',
    'area': 'mumbai',
    'image': 'assets/images/new_year_card.png',
    'caption': 'Bappa Aagman 2026 🙏 #BappaMorya',
    'likes': '12.4k',
  },
  {
    'mandalName': 'Shree Ganesh Yuvak Mandal',
    'area': 'ahmedabad',
    'image': 'assets/images/diwali_card.png',
    'caption': 'Navratri Garba Night ✨ #NavratriVibes',
    'likes': '9.8k',
  },
  {
    'mandalName': 'Surat Sarvajanik Garba Mandal',
    'area': 'surat',
    'image': 'assets/images/dhanteras_card.png',
    'caption': 'Incredible setup this year 🎉 #Utsav2026',
    'likes': '8.1k',
  },
  {
    'mandalName': 'Maa Durga Mahotsav Samiti',
    'area': 'vadodara',
    'image': 'assets/images/bhaiduj_card.png',
    'caption': 'Maa ki Aarti 🪔 #MaaDurga #DeviBhakti',
    'likes': '7.3k',
  },
  {
    'mandalName': 'Pune Ganesh Utsav Mandal',
    'area': 'pune',
    'image': 'assets/images/new_year_card.png',
    'caption': 'Grand procession 2026 🥁 #PuneGanesh',
    'likes': '5.9k',
  },
];

const List<Map<String, dynamic>> _kPopularPosts = [
  {
    'mandalName': 'Lalbaugcha Raja Yuva Mandal',
    'area': 'mumbai',
    'avatarUrl': 'assets/images/new_year_card.png',
    'image': 'assets/images/diwali_card.png',
    'caption': 'Bappa is here! 🙏 Join us in the celebration.\n#GaneshChaturthi2026 #BappaMorya',
    'likes': 1240,
    'time': '2h ago',
  },
  {
    'mandalName': 'Shree Ganesh Yuvak Mandal',
    'area': 'ahmedabad',
    'avatarUrl': 'assets/images/diwali_card.png',
    'image': 'assets/images/dhanteras_card.png',
    'caption': 'Decoration in progress ✨ Stay tuned!\n#Navratri2026 #GarbaVibes',
    'likes': 890,
    'time': '5h ago',
  },
  {
    'mandalName': 'Surat Sarvajanik Garba Mandal',
    'area': 'surat',
    'avatarUrl': 'assets/images/dhanteras_card.png',
    'image': 'assets/images/bhaiduj_card.png',
    'caption': 'Our theme this year is divine & spectacular 🌟\n#SuratGarba #Utsav2026',
    'likes': 670,
    'time': '1d ago',
  },
  {
    'mandalName': 'Maa Durga Mahotsav Samiti',
    'area': 'vadodara',
    'avatarUrl': 'assets/images/bhaiduj_card.png',
    'image': 'assets/images/new_year_card.png',
    'caption': 'Maa Durga pandal setup complete 🪔🙏\n#MaaDurga #DeviBhakti',
    'likes': 540,
    'time': '2d ago',
  },
];

// ─── Festival Activity Screen ──────────────────────────────────────────────────

class FestivalActivityScreen extends StatefulWidget {
  final String festivalName;
  final String imageUrl;

  const FestivalActivityScreen({
    super.key,
    required this.festivalName,
    required this.imageUrl,
  });

  @override
  State<FestivalActivityScreen> createState() => _FestivalActivityScreenState();
}

class _FestivalActivityScreenState extends State<FestivalActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearchFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isSearchFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMandals {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return _kSearchMandals.where((m) {
      final name = (m['name'] as String).toLowerCase();
      final area = (m['area'] as String).toLowerCase();
      final location = (m['location'] as String).toLowerCase();
      return name.contains(q) || area.contains(q) || location.contains(q);
    }).toList();
  }

  List<Map<String, String>> get _filteredReels {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return _kPopularReels.where((r) {
      final mn = (r['mandalName'] ?? '').toLowerCase();
      final area = (r['area'] ?? '').toLowerCase();
      return mn.contains(q) || area.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return _kPopularPosts.where((p) {
      final mn = (p['mandalName'] as String).toLowerCase();
      final area = (p['area'] as String).toLowerCase();
      return mn.contains(q) || area.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
    );
  }

  // ── Default Feed: Popular Reels + Popular Posts ────────────────────────────

  Widget _buildDefaultFeed() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // Section: Popular Reels
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            '🎬  Popular Reels',
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
            itemCount: _kPopularReels.length,
            itemBuilder: (context, index) => _buildReelThumbnail(_kPopularReels[index]),
          ),
        ),

        const SizedBox(height: 22),

        // Section: Popular Posts
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            '📸  Popular Posts',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ),
        ...List.generate(
          _kPopularPosts.length,
          (i) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildPostCard(_kPopularPosts[i]),
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
          _buildSectionHeader('🏛  Mandals', mandals.length),
          const SizedBox(height: 8),
          ...mandals.map((m) => _buildMandalSearchCard(m)),
          const SizedBox(height: 16),
        ],

        // ── Reel results
        if (reels.isNotEmpty) ...[
          _buildSectionHeader('🎬  Reels', reels.length),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: reels.length,
              itemBuilder: (context, index) => _buildReelThumbnail(reels[index]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Post results
        if (posts.isNotEmpty) ...[
          _buildSectionHeader('📸  Posts', posts.length),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF7700),
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

  Widget _buildReelThumbnail(Map<String, String> reel) {
    return GestureDetector(
      onTap: () {
        // find matching mandal
        final mandal = _kSearchMandals.firstWhere(
          (m) => m['name'] == reel['mandalName'],
          orElse: () => _kSearchMandals.first,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullscreenReelViewer(
              startIndex: 0,
              mandalName: reel['mandalName'] ?? '',
              avatarUrl: mandal['avatarUrl'] as String,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final mandal = _kSearchMandals.firstWhere(
            (m) => m['name'] == post['mandalName'],
            orElse: () => _kSearchMandals.first,
          );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      post['avatarUrl'] as String,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['mandalName'] as String,
                          style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          post['time'] as String,
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF2E2A36).withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Caption
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                post['caption'] as String,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Image
            ClipRRect(
              child: Image.asset(
                post['image'] as String,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: const Color(0xFFFFF1E5),
                  child: const Icon(Icons.image_rounded, color: Color(0xFFFF8C1A), size: 48),
                ),
              ),
            ),
            // Engagement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 20, color: Color(0xFF2E2A36)),
                  const SizedBox(width: 6),
                  Text(
                    '${post['likes']}',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                  ),
                  const SizedBox(width: 18),
                  const Icon(Icons.share_rounded, size: 18, color: Color(0xFF2E2A36)),
                  const SizedBox(width: 6),
                  Text(
                    'Share',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36)),
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
