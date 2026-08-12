import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MandalProfileScreen extends StatefulWidget {
  final String mandalName;
  final String location;
  final String avatarUrl;
  final String coverUrl;

  const MandalProfileScreen({
    super.key,
    this.mandalName = "Shree Ganesh Yuva Mandal",
    this.location = "Ahmedabad, Gujarat",
    this.avatarUrl = "assets/images/new_year_card.png",
    this.coverUrl = "assets/images/new_year_card.png",
  });

  @override
  State<MandalProfileScreen> createState() => _MandalProfileScreenState();
}

class _MandalProfileScreenState extends State<MandalProfileScreen> {
  // Tabs: Posts, Reels, Live, Images, Videos
  int _activeTab = 0;
  final List<String> _tabs = ["Posts", "Reels", "Live", "Images", "Videos"];

  // SVG back arrow
  static const String _backArrowSvg =
      '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cover Banner & Avatar Header (tight spacing)
                    _buildProfileHeader(context),
                    const SizedBox(height: 8),

                    // 2. Mandal Details (Name, location, bio)
                    _buildMandalInfoSection(),
                    const SizedBox(height: 10),

                    // 3. Stats & Share Button Row
                    _buildStatsAndShareRow(),
                    const SizedBox(height: 6),

                    // 4. Tab Bar (Posts, Reels, Live, Images, Videos)
                    _buildTabBar(),
                    const SizedBox(height: 6),

                    // 5. Grid/Feed Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildTabContent(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Component Helpers ─────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image banner
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image.asset(
              widget.coverUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Back arrow (size matches standard 40x40 circle back button)
        Positioned(
          top: 48,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: Center(
                child: SvgPicture.string(
                  _backArrowSvg,
                  width: 15,
                  height: 15,
                ),
              ),
            ),
          ),
        ),

        // Overlapping Profile Avatar (reduced height overlap spacing)
        Positioned(
          bottom: -32,
          left: 20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE8D6),
              border: Border.all(color: const Color(0xFFFFE8D6), width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(
                widget.avatarUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMandalInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Verified Badge
          Row(
            children: [
              Text(
                widget.mandalName,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFFFF7700),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFC8A882),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                widget.location,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bio description
          Text(
            "We are here to spread devotion and celebrate festivals with enthusiasm. Join us in worship and celebrations.",
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndShareRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildStatColumn("125", "Posts"),
          const SizedBox(width: 24),
          _buildStatColumn("12", "Live"),
          const Spacer(),

          // Share Mandal Button (orange button container)
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Mandal link copied to clipboard!",
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF2E2A36),
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 15),
              label: Text(
                'Share',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final active = _activeTab == i;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFF7700) : const Color(0xFFFFEAD8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.outfit(
                    color: active ? Colors.white : const Color(0xFF8E5A2A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 1: // Reels
        return _buildReelsGrid();
      case 2: // Live
        return _buildLiveContent();
      case 3: // Images
        return _buildImagesGrid();
      case 4: // Videos
        return _buildVideosGrid();
      case 0: // Posts Grid (like Instagram)
      default:
        return _buildPostsGrid();
    }
  }

  // ─── Tab Content Views ─────────────────────────────────────────────────────

  Widget _buildPostsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: 2,
      itemBuilder: (context, i) {
        final imageAsset = i == 0 ? "assets/images/new_year_card.png" : "assets/images/diwali_card.png";
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MandalPostsFeedScreen(
                  startIndex: i,
                  mandalName: widget.mandalName,
                  avatarUrl: widget.avatarUrl,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullscreenReelViewer(
                  startIndex: i,
                  mandalName: widget.mandalName,
                  avatarUrl: widget.avatarUrl,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF3E4D6)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/new_year_card.png',
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        Text(
                          "1.2K",
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildLiveContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3E4D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                "Mandal Live Broadcasts",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "There are no active live broadcasts at this time. Live streams will start during the festival dates.",
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: 9,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MandalImagesFeedScreen(
                  startIndex: i,
                  mandalName: widget.mandalName,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/diwali_card.png',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: 3,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MandalVideosFeedScreen(
                  startIndex: i,
                  mandalName: widget.mandalName,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF3E4D6)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/new_year_card.png',
                    fit: BoxFit.cover,
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Fullscreen Reel Viewer ──────────────────────────────────────────────────

class FullscreenReelViewer extends StatefulWidget {
  final int startIndex;
  final String mandalName;
  final String avatarUrl;

  const FullscreenReelViewer({
    super.key,
    required this.startIndex,
    required this.mandalName,
    required this.avatarUrl,
  });

  @override
  State<FullscreenReelViewer> createState() => _FullscreenReelViewerState();
}

class _FullscreenReelViewerState extends State<FullscreenReelViewer> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Reel background (different image per index for a visual scroll indication)
              Image.asset(
                [
                  'assets/images/new_year_card.png',
                  'assets/images/diwali_card.png',
                  'assets/images/dhanteras_card.png',
                  'assets/images/bhaiduj_card.png',
                  'assets/images/new_year_card.png',
                  'assets/images/diwali_card.png',
                ][index % 6],
                fit: BoxFit.cover,
              ),

              // Overlay
              Container(color: Colors.black.withValues(alpha: 0.3)),

              // Top Header
              Positioned(
                top: 50,
                left: 20,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Reels",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Interaction options (Like, Share, Save)
              Positioned(
                bottom: 60,
                right: 16,
                child: Column(
                  children: [
                    _buildReelInteraction(Icons.favorite_rounded, "1.2K"),
                    const SizedBox(height: 20),
                    _buildReelInteraction(Icons.share_rounded, "120"),
                    const SizedBox(height: 20),
                    _buildReelInteraction(Icons.bookmark_border_rounded, "Save"),
                  ],
                ),
              ),

              // Info caption
              Positioned(
                bottom: 40,
                left: 20,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(widget.avatarUrl, width: 30, height: 30, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.mandalName,
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Bappa Aagman 2026 🙏 Reel #$index #BappaMorya",
                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReelInteraction(IconData icon, String count) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

// ─── Mandal Posts Scrollable Feed Screen (Instagram-like) ───────────────────

class MandalPostsFeedScreen extends StatefulWidget {
  final int startIndex;
  final String mandalName;
  final String avatarUrl;

  const MandalPostsFeedScreen({
    super.key,
    required this.startIndex,
    required this.mandalName,
    required this.avatarUrl,
  });

  @override
  State<MandalPostsFeedScreen> createState() => _MandalPostsFeedScreenState();
}

class _MandalPostsFeedScreenState extends State<MandalPostsFeedScreen> {
  late final ScrollController _scrollController;

  final List<Map<String, dynamic>> _posts = [
    {
      'time': '2h ago',
      'content': 'Bappa is here! 🙏\nJoin us in the celebration.\n#GaneshChaturthi2026 #BappaMorya',
      'image': 'assets/images/new_year_card.png',
      'likes': 128,
      'shares': 56,
      'isLiked': false,
    },
    {
      'time': '1 day ago',
      'content': 'Decoration in progress ✨ Stay tuned for updates!',
      'image': 'assets/images/diwali_card.png',
      'likes': 94,
      'shares': 38,
      'isLiked': false,
    }
  ];

  // SVG back arrow
  static const String _backArrowSvg =
      '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to clicked index after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startIndex > 0 && widget.startIndex < _posts.length) {
        // Approximate height per post card is around 380-420 pixels
        _scrollController.animateTo(
          widget.startIndex * 410.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: Center(
                child: SvgPicture.string(
                  _backArrowSvg,
                  width: 15,
                  height: 15,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Posts',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        itemCount: _posts.length,
        itemBuilder: (context, i) {
          final post = _posts[i];
          final liked = post['isLiked'] as bool;
          final likesCount = post['likes'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3E4D6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top user info
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(widget.avatarUrl, width: 36, height: 36, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mandalName,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            Text(
                              post['time'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Caption text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
                  child: Text(
                    post['content'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF2E2A36),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Post Image content
                ClipRRect(
                  child: Image.asset(
                    post['image'] as String,
                    width: double.infinity,
                    height: 230,
                    fit: BoxFit.cover,
                  ),
                ),

                // Engagement Row (Removed comments option completely)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      // Like
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            post['isLiked'] = !liked;
                            post['likes'] = likesCount + (liked ? -1 : 1);
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: liked ? Colors.red : const Color(0xFF2E2A36),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${post['likes']}",
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Share
                      Row(
                        children: [
                          const Icon(Icons.share_outlined, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${post['shares']}",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Mandal Images Feed Screen (Instagram-like scrollable viewer) ───────────

class MandalImagesFeedScreen extends StatelessWidget {
  final int startIndex;
  final String mandalName;

  const MandalImagesFeedScreen({
    super.key,
    required this.startIndex,
    required this.mandalName,
  });

  @override
  Widget build(BuildContext context) {
    // Show scrollable image viewer
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
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
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC8A882), size: 16),
              ),
            ),
          ),
        ),
        title: Text(
          'Images',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/diwali_card.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mandal Videos Feed Screen (Instagram-like scrollable video viewer) ─────

class MandalVideosFeedScreen extends StatelessWidget {
  final int startIndex;
  final String mandalName;

  const MandalVideosFeedScreen({
    super.key,
    required this.startIndex,
    required this.mandalName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
        title: Text(
          'Videos',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/new_year_card.png',
              fit: BoxFit.contain,
            ),
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 64,
            ),
          ],
        ),
      ),
    );
  }
}
