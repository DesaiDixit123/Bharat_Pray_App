import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/saved_items_service.dart';
import '../details/granth_chapter_list_screen.dart';
import '../details/granth_chapter_reader_screen.dart';
import '../details/mandal_profile_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  final int initialTabIndex;
  const SavedItemsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _savedGranths = [];
  List<Map<String, dynamic>> _savedChapters = [];
  List<Map<String, dynamic>> _savedPosts = [];
  List<Map<String, dynamic>> _savedReels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);
    final granths = await SavedItemsService.getSavedGranths();
    final chapters = await SavedItemsService.getSavedChapters();
    final posts = await SavedItemsService.getSavedPosts();
    final reels = await SavedItemsService.getSavedReels();

    if (mounted) {
      setState(() {
        _savedGranths = granths;
        _savedChapters = chapters;
        _savedPosts = posts;
        _savedReels = reels;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: Text(
            'Saved Library & Items',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFFFF7700),
            indicatorWeight: 3,
            labelColor: const Color(0xFFFF7700),
            unselectedLabelColor: const Color(0xFF2E2A36).withValues(alpha: 0.6),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Granths (${_savedGranths.length})'),
              Tab(text: 'Chapters (${_savedChapters.length})'),
              Tab(text: 'Posts (${_savedPosts.length})'),
              Tab(text: 'Reels (${_savedReels.length})'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGranthsTab(),
                    _buildChaptersTab(),
                    _buildPostsTab(),
                    _buildReelsTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGranthsTab() {
    if (_savedGranths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_rounded, size: 54, color: Color(0xFFD9B89C)),
            const SizedBox(height: 12),
            Text(
              'No saved Granths yet.',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 6),
            Text(
              'Bookmark your favorite Granths to read them anytime.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _savedGranths.length,
      itemBuilder: (context, index) {
        final granth = _savedGranths[index];
        final rawGranth = Map<String, dynamic>.from(granth['rawGranth'] ?? granth);
        final name = (granth['name'] ?? granth['title'] ?? 'Sacred Granth').toString();
        final author = (granth['author'] ?? 'Maharishi Ved Vyas').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3E4D6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GranthChapterListScreen(
                    category: const {'name': 'Saved'},
                    granth: rawGranth,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/images/bhagavad_gita.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.menu_book_rounded, color: Color(0xFFFF8C1A)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          author,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.52)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF8C1A), size: 24),
                    onPressed: () async {
                      await SavedItemsService.toggleSaveGranth(rawGranth);
                      _loadSavedData();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChaptersTab() {
    if (_savedChapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_rounded, size: 54, color: Color(0xFFD9B89C)),
            const SizedBox(height: 12),
            Text(
              'No saved Chapters yet.',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 6),
            Text(
              'Save individual chapters to quick-read them anytime.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _savedChapters.length,
      itemBuilder: (context, index) {
        final item = _savedChapters[index];
        final chapter = Map<String, dynamic>.from(item['chapter'] ?? item);
        final granth = Map<String, dynamic>.from(item['granth'] ?? {'name': item['granthName'] ?? 'Granth'});
        final title = (item['title'] ?? item['name'] ?? 'Chapter').toString();
        final granthName = (item['granthName'] ?? granth['name'] ?? 'Granth').toString();
        final sanskritName = (item['sanskritName'] ?? chapter['sanskritName'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3E4D6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GranthChapterReaderScreen(
                    granth: granth,
                    chapter: chapter,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFFF8C1A), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                        ),
                        if (sanskritName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sanskritName,
                            style: GoogleFonts.notoSerifDevanagari(fontSize: 12, color: const Color(0xFF7A4518)),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          granthName,
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF2E2A36).withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF8C1A), size: 24),
                    onPressed: () async {
                      await SavedItemsService.toggleSaveChapter(chapter, granth);
                      _loadSavedData();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostsTab() {
    if (_savedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_rounded, size: 54, color: Color(0xFFD9B89C)),
            const SizedBox(height: 12),
            Text(
              'No saved Posts yet.',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 6),
            Text(
              'Save posts from Mandal feeds to view them here.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _savedPosts.length,
      itemBuilder: (context, index) {
        final post = _savedPosts[index];
        final mandalName = (post['mandalName'] ?? 'Mandal').toString();
        final content = (post['content'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3E4D6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MandalPostsFeedScreen(
                    startIndex: 0,
                    mandalName: mandalName,
                    avatarUrl: (post['avatarUrl'] ?? 'assets/images/new_year_card.png').toString(),
                    posts: [
                      PostItem(
                        id: (post['id'] ?? 'saved_post').toString(),
                        imageUrl: (post['image'] ?? 'assets/images/new_year_card.png').toString(),
                        caption: (post['content'] ?? post['title'] ?? '').toString(),
                        festivalName: (post['festivalName'] ?? 'Bharat Pray Post').toString(),
                        location: (post['location'] ?? 'Gujarat, India').toString(),
                        timeAgo: (post['time'] ?? 'Saved').toString(),
                        likes: (post['likes'] as int?) ?? 108,
                        isSaved: true,
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      (post['image'] ?? 'assets/images/new_year_card.png').toString(),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFFFFF1E5),
                        child: const Icon(Icons.article_rounded, color: Color(0xFFFF8C1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mandalName,
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.65)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF8C1A), size: 24),
                    onPressed: () async {
                      await SavedItemsService.toggleSavePost(post, mandalName, (post['avatarUrl'] ?? '').toString());
                      _loadSavedData();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelsTab() {
    if (_savedReels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_rounded, size: 54, color: Color(0xFFD9B89C)),
            const SizedBox(height: 12),
            Text(
              'No saved Reels yet.',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 6),
            Text(
              'Save Reels from Mandal profiles to view them anytime.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _savedReels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final reel = _savedReels[index];
        final mandalName = (reel['mandalName'] ?? 'Mandal').toString();
        final title = (reel['title'] ?? 'Reel').toString();
        final thumb = _resolveReelThumbnail(reel);
        final likes = (reel['likes'] ?? '5.8k').toString();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Reel Thumbnail Cover
                buildSmartImage(thumb, fit: BoxFit.cover),

                // 2. High-contrast gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // 3. Top-left: Views count badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          likes,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Bottom Info (Title & Mandal Name)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mandalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFFB370),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 12),
                        ],
                      ),
                    ],
                  ),
                ),

                // 6. Tap to open Reel Viewer
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        final allSavedReelItems = _savedReels.asMap().entries.map((entry) {
                          final r = entry.value;
                          final i = entry.key;
                          final itemThumb = _resolveReelThumbnail(r);
                          return ReelItem(
                            id: (r['id'] ?? 'saved_reel_$i').toString(),
                            thumbnailUrl: itemThumb,
                            videoUrl: (r['videoUrl'] != null && r['videoUrl'].toString().isNotEmpty)
                                ? r['videoUrl'].toString()
                                : 'assets/images/1st_Scene.mp4',
                            title: (r['title'] ?? 'Divine Mandal Clip').toString(),
                            audioTrack: (r['audioTrack'] ?? 'Original Mandal Audio • Sacred Chants').toString(),
                            views: (r['likes'] ?? '10.5k').toString(),
                            likes: int.tryParse(r['likes']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '1200') ?? 1200,
                            isSaved: true,
                          );
                        }).toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullscreenReelViewer(
                              startIndex: index,
                              reels: allSavedReelItems,
                              mandalName: mandalName,
                              avatarUrl: (reel['avatarUrl'] ?? 'assets/images/new_year_card.png').toString(),
                            ),
                          ),
                        ).then((_) => _loadSavedData());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveReelThumbnail(Map<String, dynamic> reel) {
    final t = (reel['thumbnailUrl'] ?? reel['image'] ?? '').toString();
    if (t.isNotEmpty) return t;
    final title = (reel['title'] ?? '').toString().toLowerCase();
    final mandal = (reel['mandalName'] ?? '').toString().toLowerCase();
    if (title.contains('bappa') || mandal.contains('ganesh') || mandal.contains('lalbaug')) {
      return 'assets/images/new_year_card.png';
    }
    if (title.contains('somnath') || title.contains('shiv')) {
      return 'assets/images/somnath_hero.png';
    }
    if (title.contains('krishna')) {
      return 'assets/images/krishna.png';
    }
    if (title.contains('diya') || title.contains('diwali')) {
      return 'assets/images/dhanterash.png';
    }
    return 'assets/images/ram_bhajan.png';
  }
}
