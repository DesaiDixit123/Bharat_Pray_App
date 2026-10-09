import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/saved_items_service.dart';
import '../../widgets/top_toast_notification.dart';
import 'granth_chapter_reader_screen.dart';

class GranthChapterListScreen extends StatefulWidget {
  const GranthChapterListScreen({
    super.key,
    required this.category,
    required this.granth,
  });

  final Map<String, dynamic> category;
  final Map<String, dynamic> granth;

  @override
  State<GranthChapterListScreen> createState() => _GranthChapterListScreenState();
}

class _GranthChapterListScreenState extends State<GranthChapterListScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _chapters = [];
  final Set<String> _savedChapterIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final savedList = await SavedItemsService.getSavedChapters();
      final savedIds = savedList.map((c) => (c['_id'] ?? c['id'] ?? c['title'] ?? '').toString()).toSet();

      final granthId = widget.granth['_id']?.toString() ?? '';
      if (granthId.isEmpty) {
        throw Exception('Granth ID is missing.');
      }
      final data = await ApiService.getChaptersByGranth(granthId);
      if (!mounted) return;
      setState(() {
        _savedChapterIds.clear();
        _savedChapterIds.addAll(savedIds);
        _chapters = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load chapters.';
      });
    }
  }

  String _chapterId(Map<String, dynamic> chapter) {
    return (chapter['_id'] ?? chapter['id'] ?? chapter['title'] ?? '').toString();
  }

  Future<void> _toggleChapterSave(Map<String, dynamic> chapter) async {
    final isNowSaved = await SavedItemsService.toggleSaveChapter(chapter, widget.granth);
    final id = _chapterId(chapter);
    final chapterTitle = (chapter['title'] ?? chapter['name'] ?? 'Chapter').toString();

    setState(() {
      if (isNowSaved) {
        _savedChapterIds.add(id);
      } else {
        _savedChapterIds.remove(id);
      }
    });

    if (mounted) {
      final granthName = (widget.granth['name'] ?? widget.granth['title'] ?? '').toString();
      final displayTitle = granthName.isNotEmpty
          ? '$chapterTitle  ·  $granthName'
          : chapterTitle;
      TopToastNotification.showSavedNotification(
        context: context,
        title: displayTitle,
        isSaved: isNowSaved,
        savedTabIndex: 1,
      );
    }
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2E2A36),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            (widget.granth['name'] ?? widget.granth['title'] ?? 'Granth').toString(),
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _loadChapters,
            color: const Color(0xFFFF7700),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBannerImage() {
    final rawImg = (widget.granth['coverImage'] ?? widget.granth['image'] ?? widget.category['image'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(rawImg);

    if (resolvedUrl.startsWith('http')) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset('assets/images/bhagavad_gita.png', fit: BoxFit.cover),
      );
    } else if (rawImg.startsWith('assets/')) {
      return Image.asset(
        rawImg,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset('assets/images/bhagavad_gita.png', fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/bhagavad_gita.png', fit: BoxFit.cover);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: GoogleFonts.outfit(color: Colors.red.shade700)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadChapters,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
              child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
            )
          ],
        ),
      );
    }

    final realChapterCount = _chapters.isNotEmpty
        ? _chapters.length
        : (widget.granth['totalChapters'] ?? widget.granth['totalPages'] ?? 1);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeaderBannerImage(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        const Color(0xFF5A2A0B).withValues(alpha: 0.72),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        (widget.granth['name'] ?? widget.granth['title'] ?? 'Sacred Granth').toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$realChapterCount Chapters',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Chapters',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 14),
        if (_chapters.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'No chapters found for this Granth.',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          ..._chapters.map((c) => _buildChapterCard(c as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    final isSaved = _savedChapterIds.contains(_chapterId(chapter));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GranthChapterReaderScreen(
                granth: widget.granth,
                chapter: chapter,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFFF8C1A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (chapter['name'] ?? chapter['title'] ?? 'Chapter').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (chapter['sanskritName'] ?? chapter['description'] ?? chapter['translation'] ?? 'Sacred chapter content').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _toggleChapterSave(chapter),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? const Color(0xFFFF8C1A) : const Color(0xFFBFA58B),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF9B38),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
