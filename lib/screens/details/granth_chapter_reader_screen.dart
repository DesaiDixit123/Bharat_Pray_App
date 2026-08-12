import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_flip/page_flip.dart';

import '../../services/api_service.dart';

class GranthChapterReaderScreen extends StatefulWidget {
  const GranthChapterReaderScreen({
    super.key,
    required this.granth,
    required this.chapter,
  });

  final Map<String, dynamic> granth;
  final Map<String, dynamic> chapter;

  @override
  State<GranthChapterReaderScreen> createState() => _GranthChapterReaderScreenState();
}

class _GranthChapterReaderScreenState extends State<GranthChapterReaderScreen> {
  late final PageFlipController _pageFlipController;

  bool _isLoading = true;
  String _error = '';

  /// Each element is one "page" from the API, containing a list of shlokas.
  List<List<Map<String, dynamic>>> _pages = [];

  int _currentPageIndex = 0;
  final double _readerFontSize = 16.0;
  bool _sepiaMode = true;

  @override
  void initState() {
    super.initState();
    _pageFlipController = PageFlipController();
    _loadPages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPages() async {
    final chapterId = widget.chapter['_id']?.toString() ?? '';
    if (chapterId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid chapter ID.';
      });
      return;
    }

    try {
      // Step 1: fetch pages list for this chapter
      final pagesList = await ApiService.getPagesByChapter(chapterId);

      if (pagesList.isEmpty) {
        setState(() {
          _isLoading = false;
          _pages = [];
        });
        return;
      }

      // Step 2: for each page, fetch shlokas
      final List<List<Map<String, dynamic>>> allPages = [];
      for (final page in pagesList) {
        final pageId = page['_id']?.toString() ?? '';
        if (pageId.isEmpty) {
          allPages.add([]);
          continue;
        }
        try {
          final shlokas = await ApiService.getShlokasByPage(pageId);
          allPages.add(shlokas.map((s) => s as Map<String, dynamic>).toList());
        } catch (_) {
          allPages.add([]);
        }
      }

      if (mounted) {
        setState(() {
          _pages = allPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load chapter content: $e';
        });
      }
    }
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _pageFlipController.goToPage(index);
  }

  // ─── Height measurement helpers ──────────────────────────────────────────

  double _measureTextHeight(String text, TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  double _getPageHeight(BuildContext context, List<Map<String, dynamic>> shlokas) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 26 - 28;
    final bodyColor = const Color(0xFF33261A);

    double total = 28; // top padding

    if (shlokas.isEmpty) {
      total += 60; // empty state placeholder
    }

    for (int i = 0; i < shlokas.length; i++) {
      final s = shlokas[i];
      final sanskrit = (s['shloka'] ?? s['sanskrit'] ?? s['text'] ?? '').toString();
      final transliteration = (s['transliteration'] ?? '').toString();
      final english = (s['meaning'] ?? s['english'] ?? s['translation'] ?? '').toString();

      total += _measureTextHeight(
        sanskrit,
        GoogleFonts.notoSerifDevanagari(fontSize: _readerFontSize + 4, height: 1.8, color: bodyColor, fontWeight: FontWeight.w600),
        availableWidth,
      );
      total += 20;

      if (transliteration.isNotEmpty) {
        total += _measureTextHeight(
          transliteration,
          GoogleFonts.outfit(fontSize: _readerFontSize + 1, height: 1.7, color: bodyColor, fontWeight: FontWeight.w500),
          availableWidth,
        );
        total += 20;
      }

      if (english.isNotEmpty) {
        total += 2.5 + 24; // divider + label space
        total += _measureTextHeight(
          'Meaning',
          GoogleFonts.outfit(fontSize: _readerFontSize + 1, fontWeight: FontWeight.w700, color: bodyColor),
          availableWidth,
        );
        total += 12;
        total += _measureTextHeight(
          english,
          GoogleFonts.outfit(fontSize: _readerFontSize, height: 1.8, color: bodyColor, fontWeight: FontWeight.w500),
          availableWidth,
        );
        total += 20;
      }

      if (i < shlokas.length - 1) total += 16; // spacer between shlokas
    }

    total += 28; // bottom padding
    return total;
  }

  double _getBookHeight(BuildContext context) {
    if (_pages.isEmpty) return 280;
    final maxPageHeight = _pages.fold<double>(
      0,
      (cur, page) => math.max(cur, _getPageHeight(context, page)),
    );
    return maxPageHeight + 68;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final backgroundTop = _sepiaMode ? const Color(0xFF4A2B13) : const Color(0xFF191919);
    final backgroundBottom = _sepiaMode ? const Color(0xFF26160B) : const Color(0xFF0B0B0B);

    return Scaffold(
      backgroundColor: backgroundBottom,
      appBar: AppBar(
        backgroundColor: backgroundTop,
        elevation: 0,
        centerTitle: true,
        leading: Center(
          child: _TranslucentBackButton(
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          '${widget.granth['name'] ?? widget.granth['title'] ?? ''}'
          ' - ${widget.chapter['name'] ?? widget.chapter['title'] ?? ''}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => setState(() => _sepiaMode = !_sepiaMode),
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundTop, backgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C1A)))
              : _error.isNotEmpty
                  ? _buildError()
                  : _pages.isEmpty
                      ? _buildEmpty()
                      : Column(
                          children: [
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildBookView(context),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildPlaybackControls(),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF8C1A), size: 48),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = '';
                });
                _loadPages();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C1A)),
              child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, color: Color(0xFFFF8C1A), size: 48),
          const SizedBox(height: 16),
          Text(
            'No content available for this chapter yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildBookView(BuildContext context) {
    final paperColor = _sepiaMode ? const Color(0xFFF8EEDB) : const Color(0xFFEAE4D8);
    final bookHeight = _getBookHeight(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: bookHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Paper background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: paperColor,
                  ),
                ),
              ),
              // Left spine shadow
              Positioned(
                left: 0,
                top: 14,
                bottom: 14,
                width: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3E2A1E).withValues(alpha: 0.72),
                        const Color(0xFFFAF1E2).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Right binding bars
              Positioned(
                right: 12,
                top: 18,
                bottom: 18,
                width: 18,
                child: Column(
                  children: List.generate(11, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 1.5),
                        decoration: BoxDecoration(
                          color: index.isEven ? const Color(0xFFD5B892) : const Color(0xFFF6E8D1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Page flip content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 26, 28, 26),
                  child: PageFlipWidget(
                    controller: _pageFlipController,
                    initialIndex: _currentPageIndex,
                    backgroundColor: paperColor,
                    children: List<Widget>.generate(
                      _pages.length,
                      (i) => _buildShlokaPage(_pages[i], i),
                    ),
                    onPageFlipped: (index) {
                      setState(() => _currentPageIndex = index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShlokaPage(List<Map<String, dynamic>> shlokas, int pageIndex) {
    final bodyColor = const Color(0xFF33261A);
    final bgColor = _sepiaMode ? const Color(0xFFF8EEDB) : const Color(0xFFEAE4D8);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shlokas.isEmpty)
                Center(
                  child: Text(
                    'No shlokas on this page.',
                    style: GoogleFonts.outfit(color: bodyColor.withValues(alpha: 0.5), fontSize: 14),
                  ),
                )
              else
                ...shlokas.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final sanskrit = (s['shloka'] ?? s['sanskrit'] ?? s['text'] ?? '').toString();
                  final transliteration = (s['transliteration'] ?? '').toString();
                  final english = (s['meaning'] ?? s['english'] ?? s['translation'] ?? '').toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0) const SizedBox(height: 16),
                      if (i > 0)
                        Container(
                          width: 48,
                          height: 1.5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: bodyColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      // Sanskrit text
                      if (sanskrit.isNotEmpty)
                        Text(
                          sanskrit,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerifDevanagari(
                            fontSize: _readerFontSize + 4,
                            height: 1.8,
                            color: bodyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (transliteration.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          transliteration,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: _readerFontSize + 1,
                            height: 1.7,
                            color: bodyColor.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (english.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: 74,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: bodyColor.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Meaning',
                          style: GoogleFonts.outfit(
                            fontSize: _readerFontSize + 1,
                            fontWeight: FontWeight.w700,
                            color: bodyColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          english,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: _readerFontSize,
                            height: 1.8,
                            color: bodyColor.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final pageCount = _pages.length;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF8C1A),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
            thumbColor: const Color(0xFFFF8C1A),
            overlayColor: const Color(0xFFFF8C1A).withValues(alpha: 0.14),
            trackHeight: 3.5,
          ),
          child: Slider(
            min: 0,
            max: pageCount > 1 ? (pageCount - 1).toDouble() : 1,
            value: _currentPageIndex.toDouble().clamp(0, pageCount > 1 ? (pageCount - 1).toDouble() : 1),
            onChanged: pageCount <= 1
                ? null
                : (value) => _goToPage(value.round()),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentPageIndex > 0 ? () => _goToPage(_currentPageIndex - 1) : null,
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Page ${_currentPageIndex + 1} / $pageCount',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: _currentPageIndex < pageCount - 1 ? () => _goToPage(_currentPageIndex + 1) : null,
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
      ],
    );
  }
}

// ─── Back Button ─────────────────────────────────────────────────────────────

class _TranslucentBackButton extends StatelessWidget {
  final VoidCallback onTap;

  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#FFFFFF"/>
</svg>''';

  const _TranslucentBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.0),
        ),
        child: Center(
          child: SvgPicture.string(
            _backArrowSvg,
            width: 15,
            height: 15,
          ),
        ),
      ),
    );
  }
}
