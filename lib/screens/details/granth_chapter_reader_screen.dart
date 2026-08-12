import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late final PageController _pageController;
  List<Map<String, String>> _verses = [];
  int _currentPageIndex = 0;
  final double _readerFontSize = 16.0;
  bool _sepiaMode = true;
  bool _isLoadingPages = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadChapterPagesAndVerses();
  }

  Future<void> _loadChapterPagesAndVerses() async {
    final chapterId = (widget.chapter['_id'] ?? widget.chapter['id'] ?? '').toString();
    List<Map<String, String>> parsedVerses = [];

    if (chapterId.isNotEmpty) {
      try {
        final pages = await ApiService.getPagesByChapter(chapterId);
        if (pages.isNotEmpty) {
          for (final page in pages) {
            final pageMap = Map<String, dynamic>.from(page as Map);
            final pageContent = (pageMap['content'] ?? pageMap['description'] ?? '').toString().trim();
            final pageTitle = (pageMap['title'] ?? 'Page ${pageMap['pageNumber'] ?? 1}').toString();
            final sanskrit = (pageMap['sanskrit'] ?? widget.chapter['sanskritName'] ?? widget.chapter['name'] ?? pageTitle).toString();
            final transliteration = (pageMap['transliteration'] ?? '').toString();
            final english = pageContent.isNotEmpty
                ? pageContent
                : 'Sacred text and translation for $pageTitle will be updated soon.';

            parsedVerses.add({
              'sanskrit': sanskrit,
              'transliteration': transliteration,
              'english': english,
            });
          }
        }
      } catch (_) {}
    }

    if (parsedVerses.isEmpty) {
      final rawVerses = widget.chapter['verses'] ?? widget.chapter['shlokas'] ?? widget.chapter['content'];

      if (rawVerses is List) {
        for (final item in rawVerses) {
          if (item is Map) {
            parsedVerses.add(
              item.map((key, value) => MapEntry(key.toString(), (value ?? '').toString())),
            );
          } else if (item != null && item.toString().trim().isNotEmpty) {
            parsedVerses.add({
              'sanskrit': item.toString(),
              'transliteration': '',
              'english': '',
            });
          }
        }
      }
    }

    if (parsedVerses.isEmpty) {
      final desc = (widget.chapter['description'] ?? '').toString().trim();
      final trans = (widget.chapter['translation'] ?? '').toString().trim();
      final content = (widget.chapter['content'] ?? '').toString().trim();

      String bodyText = '';
      if (desc.isNotEmpty) bodyText = desc;
      else if (trans.isNotEmpty) bodyText = trans;
      else if (content.isNotEmpty) bodyText = content;
      else bodyText = 'Sacred text and translation for this chapter will be updated soon.';

      final sanskritText = (widget.chapter['sanskritName'] ?? widget.chapter['sanskrit'] ?? widget.chapter['name'] ?? widget.chapter['title'] ?? 'Chapter').toString();
      parsedVerses = [
        {
          'sanskrit': sanskritText,
          'transliteration': (widget.chapter['transliteration'] ?? '').toString(),
          'english': bodyText,
        }
      ];
    }

    if (mounted) {
      setState(() {
        _verses = parsedVerses;
        _isLoadingPages = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _totalBookPages => _verses.length + 2; // Front Cover + Content Pages + Back Cover

  void _goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _totalBookPages) return;
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundTop = _sepiaMode ? const Color(0xFF381F0E) : const Color(0xFF191919);
    final backgroundBottom = _sepiaMode ? const Color(0xFF1E1007) : const Color(0xFF0B0B0B);

    final granthTitle = (widget.granth['name'] ?? widget.granth['title'] ?? 'Granth').toString();
    final chapterTitle = (widget.chapter['title'] ?? widget.chapter['name'] ?? 'Chapter').toString();

    return Scaffold(
      backgroundColor: backgroundBottom,
      appBar: AppBar(
        backgroundColor: backgroundTop,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$granthTitle - $chapterTitle',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _sepiaMode = !_sepiaMode;
              });
            },
            icon: const Icon(Icons.palette_outlined, color: Colors.white),
            tooltip: 'Toggle Parchment Theme',
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
          child: _isLoadingPages
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8C1A)),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildBookContainer(context),
                      ),
                    ),
                    const SizedBox(height: 12),
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

  Widget _buildBookContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF231207), // Deep Hardcover Mahogany Leather
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Stacked Paper Edges (Real Physical Paper Stack on Right)
          Positioned(
            right: 0,
            top: 12,
            bottom: 12,
            width: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD2C1A8),
                    const Color(0xFFEFE4D2),
                    const Color(0xFFC7B398),
                    const Color(0xFFF5EBDC),
                    const Color(0xFFBBA78B),
                    const Color(0xFFECE1CE),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // Main 3D Book Page View
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Spine Crease Shadow (Left Binding Fold)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 24,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.42),
                              Colors.black.withValues(alpha: 0.20),
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    // Realistic 3D Smooth Page Flip Widget
                    Positioned.fill(
                      child: _buildSmooth3DFlipPageView(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmooth3DFlipPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _totalBookPages,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double pageOffset = 0.0;
            if (_pageController.position.haveDimensions) {
              pageOffset = (_pageController.page ?? _pageController.initialPage.toDouble()) - index;
            } else {
              pageOffset = (_pageController.initialPage - index).toDouble();
            }

            // Realistic 3D Perspective Rotation around Left Spine Fold
            final rotationAngle = (pageOffset * math.pi / 2.2).clamp(-math.pi / 2.2, math.pi / 2.2);
            final opacity = (1.0 - pageOffset.abs() * 0.35).clamp(0.0, 1.0);

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0014) // Perspective depth
              ..rotateY(-rotationAngle * 0.85);

            return Transform(
              transform: matrix,
              alignment: pageOffset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            );
          },
          child: _buildPageForIndex(index),
        );
      },
    );
  }

  Widget _buildPageForIndex(int index) {
    if (index == 0) {
      return _buildBookFrontCover();
    } else if (index == _totalBookPages - 1) {
      return _buildBookBackCover();
    } else {
      final verseIndex = index - 1;
      return _buildVersePage(_verses[verseIndex], verseIndex);
    }
  }

  // Page 0: Hardcover Front Book Cover Page
  Widget _buildBookFrontCover() {
    final granthName = (widget.granth['name'] ?? widget.granth['title'] ?? 'Sacred Granth').toString();
    final authorName = (widget.granth['author'] ?? 'Maharishi Ved Vyas').toString();
    final chapterName = (widget.chapter['name'] ?? widget.chapter['title'] ?? 'Chapter 1').toString();
    final coverImage = (widget.granth['coverImage'] ?? widget.granth['image'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(coverImage);

    return Container(
      color: const Color(0xFF26150B),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
          gradient: const LinearGradient(
            colors: [Color(0xFF381F0E), Color(0xFF201007)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('❖ ──────── ॐ ──────── ❖', style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 13)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: resolvedUrl.startsWith('http')
                  ? Image.network(
                      resolvedUrl,
                      width: 110,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _coverPlaceholderIcon(),
                    )
                  : _coverPlaceholderIcon(),
            ),
            const SizedBox(height: 18),
            Text(
              granthName,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifDevanagari(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'by $authorName',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
              ),
              child: Text(
                chapterName,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFE082),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _goToPage(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
              label: Text(
                'પ્રારંભ કરો • Open Book',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholderIcon() {
    return Container(
      width: 110,
      height: 140,
      color: const Color(0xFF4A2B13),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFFFD700), size: 48),
    );
  }

  // Content Verse Page
  Widget _buildVersePage(Map<String, String> verse, int verseIndex) {
    final bodyColor = _sepiaMode ? const Color(0xFF332014) : const Color(0xFF261910);
    final paperBg = _sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6);
    final sanskritText = verse['sanskrit'] ?? '';
    final transliterationText = verse['transliteration'] ?? '';
    final englishText = verse['english'] ?? '';

    return Container(
      color: paperBg,
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45), width: 1.2),
        ),
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25), width: 0.8),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('❖ ──── ', style: GoogleFonts.outfit(color: const Color(0xFFC59239), fontSize: 10)),
                    Text('ॐ', style: GoogleFonts.notoSerifDevanagari(fontSize: 18, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold)),
                    Text(' ──── ❖', style: GoogleFonts.outfit(color: const Color(0xFFC59239), fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 14),
                if (sanskritText.isNotEmpty) ...[
                  Text(
                    sanskritText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerifDevanagari(
                      fontSize: _readerFontSize + 3,
                      height: 1.8,
                      color: const Color(0xFF4A1005),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (transliterationText.isNotEmpty) ...[
                  Text(
                    transliterationText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: _readerFontSize,
                      height: 1.6,
                      color: bodyColor.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 40, height: 1.2, color: const Color(0xFFC59239).withValues(alpha: 0.6)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('❖', style: GoogleFonts.outfit(color: const Color(0xFFC59239), fontSize: 9)),
                    ),
                    Container(width: 40, height: 1.2, color: const Color(0xFFC59239).withValues(alpha: 0.6)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'English Translation',
                  style: GoogleFonts.outfit(
                    fontSize: _readerFontSize + 0.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C1405),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  englishText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: _readerFontSize,
                    height: 1.7,
                    color: bodyColor.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page N+1: Rear End Cover Page
  Widget _buildBookBackCover() {
    return Container(
      color: const Color(0xFF26150B),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
          gradient: const LinearGradient(
            colors: [Color(0xFF201007), Color(0xFF381F0E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('❖ ──────── ॐ ──────── ❖', style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 13)),
            const SizedBox(height: 24),
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 48),
            const SizedBox(height: 18),
            Text(
              'ॐ શાંતિઃ શાંતિઃ શાંતિઃ ॐ',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifDevanagari(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You have reached the end of this chapter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _goToPage(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              icon: const Icon(Icons.restart_alt_rounded, color: Colors.white, size: 18),
              label: Text(
                'ફરીથી વાંચો • Read Again',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final pageCount = _totalBookPages;

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
                : (value) {
                    _goToPage(value.round());
                  },
          ),
        ),
        const SizedBox(height: 4),
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
                _currentPageIndex == 0
                    ? 'Front Cover'
                    : _currentPageIndex == pageCount - 1
                        ? 'Back Cover'
                        : 'Page $_currentPageIndex / ${_verses.length}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
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
        const SizedBox(height: 6),
      ],
    );
  }
}
