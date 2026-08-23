import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      appBar: AppBar(
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
              final postIndex = (post['postIndex'] as int?) ?? 0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MandalPostsFeedScreen(
                    startIndex: postIndex,
                    mandalName: mandalName,
                    avatarUrl: (post['avatarUrl'] ?? 'assets/images/new_year_card.png').toString(),
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _savedReels.length,
      itemBuilder: (context, index) {
        final reel = _savedReels[index];
        final mandalName = (reel['mandalName'] ?? 'Mandal').toString();
        final title = (reel['title'] ?? 'Reel').toString();

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
              // Parse the reel index from the stored id e.g. 'reel_MandalName_2'
              final reelId = (reel['id'] ?? '').toString();
              final parts = reelId.split('_');
              final reelIndex = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullscreenReelViewer(
                    startIndex: reelIndex,
                    mandalName: mandalName,
                    avatarUrl: (reel['avatarUrl'] ?? 'assets/images/new_year_card.png').toString(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.movie_creation_rounded, color: Color(0xFFFF8C1A), size: 26),
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
                        const SizedBox(height: 4),
                        Text(
                          mandalName,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF8C1A), size: 24),
                    onPressed: () async {
                      await SavedItemsService.toggleSaveReel(reel, mandalName, (reel['avatarUrl'] ?? '').toString());
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
}
