
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
      var data = await ApiService.getChaptersByGranth(granthId);
      if (data.isEmpty) {
        data = ApiService.defaultGitaChapters;
      }
      if (!mounted) return;
      setState(() {
        _savedChapterIds.clear();
        _savedChapterIds.addAll(savedIds);
        _chapters = data;
        _isLoading = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chapters = ApiService.defaultGitaChapters;
        _isLoading = false;
        _error = '';
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

  Widget _buildHeaderImage() {
    final rawImg = (widget.granth['coverImage'] ?? widget.granth['image'] ?? '').toString();
    final granthName = (widget.granth['name'] ?? widget.granth['title'] ?? '').toString().toLowerCase();

    String finalPath = rawImg;
    if (finalPath.isEmpty) {
      if (granthName.contains('ramcharitmanas') || granthName.contains('ram')) {
        finalPath = 'assets/images/bal_kand_cover.jpg';
      } else if (granthName.contains('hanuman')) {
        finalPath = 'assets/images/image_4.png';
      } else if (granthName.contains('shiv')) {
        finalPath = 'assets/images/deity_shiva.png';
      } else if (granthName.contains('durga') || granthName.contains('saptashati')) {
        finalPath = 'assets/images/image_4_1.png';
      } else {
        finalPath = 'assets/images/bhagavad_gita.png';
      }
    }

    final resolvedUrl = ApiService.resolveImageUrl(finalPath);
    if (resolvedUrl.startsWith('http')) {
      return Image.network(
        resolvedUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    } else if (finalPath.startsWith('assets/')) {
      return Image.asset(
        finalPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    }
    return Image.asset(
      'assets/images/bhagavad_gita.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: Colors.white.withValues(alpha: 0.15),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
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

    final granthTitle = (widget.granth['name'] ?? widget.granth['title'] ?? 'Sacred Granth').toString();
    final granthDesc = (widget.granth['description'] ?? 'Sacred scripture of Sanatan Dharma containing divine wisdom.').toString();

    int fallbackCount = 1;
    final dynamic totalCh = widget.granth['totalChapters'] ?? widget.granth['chaptersCount'] ?? widget.granth['chapterCount'];
    if (totalCh != null && int.tryParse(totalCh.toString()) != null && int.parse(totalCh.toString()) > 0) {
      fallbackCount = int.parse(totalCh.toString());
    } else {
      final name = granthTitle.toLowerCase();
      if (name.contains('gita')) fallbackCount = 18;
      else if (name.contains('ramcharitmanas') || name.contains('ramayana')) fallbackCount = 7;
      else if (name.contains('chalisa') || name.contains('aarti') || name.contains('stotra')) fallbackCount = 1;
      else if (name.contains('durga saptashati')) fallbackCount = 13;
      else if (name.contains('rigveda') || name.contains('rig veda')) fallbackCount = 10;
      else if (name.contains('samaveda') || name.contains('sama veda')) fallbackCount = 6;
      else if (name.contains('yajurveda') || name.contains('yajur veda')) fallbackCount = 40;
      else if (name.contains('atharvaveda') || name.contains('atharva veda')) fallbackCount = 20;
      else if (name.contains('bhagavat puran') || name.contains('bhagavata')) fallbackCount = 12;
      else if (name.contains('shiv mahapuran') || name.contains('shiva puran')) fallbackCount = 7;
    }

    final realChapterCount = _chapters.isNotEmpty
        ? _chapters.length
        : fallbackCount;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        // ── Royal Saffron Granth Hero Banner ────────────────────────────
        Container(
          constraints: const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6F00),
                Color(0xFFFF9E3D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 96,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: _buildHeaderImage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            'SACRED SCRIPTURE',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      granthTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      granthDesc,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Section Title & Count ───────────────────────────────────────
        Row(
          children: [
            Text(
              'Chapters',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$realChapterCount ${realChapterCount == 1 ? 'Chapter' : 'Chapters'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD35400),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
          ..._chapters.asMap().entries.map((entry) => _buildChapterCard(entry.value as Map<String, dynamic>, entry.key + 1)),
      ],
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter, int fallbackIndex) {
    final isSaved = _savedChapterIds.contains(_chapterId(chapter));
    final chapNum = chapter['chapterNumber'] ?? chapter['number'] ?? fallbackIndex;
    final versesList = chapter['verses'];
    final verseCount = versesList is List ? versesList.length : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E4D6), width: 1.2),
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
                granth: widget.granth,
                chapter: chapter,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Chapter Number badge
              Container(
                width: 52,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD4AE), width: 1.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$chapNum',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF7700),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Adhyay',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD35400),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Chapter Title & Sanskrit name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (chapter['name'] ?? chapter['title'] ?? 'Chapter $chapNum').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (chapter['sanskritName'] ?? chapter['description'] ?? chapter['translation'] ?? 'Sacred chapter verses').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.58),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (verseCount != null && verseCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7EF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFE0C2), width: 0.7),
                        ),
                        child: Text(
                          '$verseCount Verses',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD35400),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons: Bookmark and Arrow
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _toggleChapterSave(chapter),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSaved ? const Color(0xFFFFF1E5) : const Color(0xFFF7F3EF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? const Color(0xFFFF7700) : const Color(0xFFA28D7B),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF7700),
                      size: 16,
                    ),
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
