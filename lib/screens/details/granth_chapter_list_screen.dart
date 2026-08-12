import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

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
      final granthId = widget.granth['_id']?.toString() ?? '';
      if (granthId.isEmpty) {
        throw Exception('Granth ID is missing.');
      }
      final data = await ApiService.getChaptersByGranth(granthId);
      if (!mounted) return;
      setState(() {
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
    final number = chapter['number']?.toString() ?? '';
    final title = chapter['title']?.toString() ?? '';
    return '$number-$title';
  }

  void _toggleChapterSave(Map<String, dynamic> chapter) {
    final id = _chapterId(chapter);
    final chapterTitle = (chapter['title'] ?? chapter['name'] ?? 'Chapter').toString();
    final isSaved = _savedChapterIds.contains(id);

    setState(() {
      if (isSaved) {
        _savedChapterIds.remove(id);
      } else {
        _savedChapterIds.add(id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved ? '$chapterTitle removed from saved chapters' : '$chapterTitle saved',
          style: GoogleFonts.outfit(),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF2E2A36),
      ),
    );
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadChapters,
          child: _buildBody(),
        ),
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          height: 178,
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
              ApiService.resolveImageUrl((widget.category['image'] ?? '').toString())
                      .startsWith('http')
                  ? Image.network(
                        ApiService.resolveImageUrl((widget.category['image'] ?? '').toString()),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: const Color(0xFF8A4A18)),
                      )
                  : Image.asset((widget.category['image'] ?? 'assets/images/granth_card.png').toString(), fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFF8A4A18))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.42),
                        const Color(0xFF7A3A0F).withOpacity(0.62),
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
                        '${widget.granth['totalChapters'] ?? widget.granth['totalPages'] ?? _chapters.length} Chapters',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.92),
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
            child: Center(child: Text('No chapters found for this Granth.',
                style: GoogleFonts.outfit(
                    color: const Color(0xFF2E2A36).withOpacity(0.6)))),
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
            color: const Color(0xFFFF7700).withOpacity(0.06),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: const Color(0xFF2E2A36).withOpacity(0.54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _toggleChapterSave(chapter),
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? const Color(0xFFFF8C1A) : const Color(0xFFBFA58B),
                  size: 22,
                ),
                tooltip: isSaved ? 'Unsave chapter' : 'Save chapter',
              ),
              const Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFF9B38),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
