import 'dart:async';
import 'dart:math' as math;

import 'package:flip_page/flip_page.dart';
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
  late final FlipPageController _flipController;
  late final List<Map<String, String>> _verses;
  int _currentVerseIndex = 0;
  final double _readerFontSize = 16.0;
  bool _sepiaMode = true;

  bool _isLoadingPages = true;

  @override
  void initState() {
    super.initState();
    _flipController = FlipPageController(initialPage: 0);
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
    _flipController.dispose();
    super.dispose();
  }

  void _goToVerse(int index) {
    if (index < 0 || index >= _verses.length) {
      return;
    }
    unawaited(_flipController.animateTo(index));
  }

  double _measureTextHeight(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    return textPainter.height;
  }

  double _getVersePageHeight(BuildContext context, Map<String, String> verse) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 26 - 28;
    final bodyColor = const Color(0xFF33261A);

    final sanskritHeight = _measureTextHeight(
      verse['sanskrit'] ?? '',
      GoogleFonts.notoSerifDevanagari(
        fontSize: _readerFontSize + 4,
        height: 1.8,
        color: bodyColor,
        fontWeight: FontWeight.w600,
      ),
      availableWidth,
    );

    final transliterationHeight = _measureTextHeight(
      verse['transliteration'] ?? '',
      GoogleFonts.outfit(
        fontSize: _readerFontSize + 1,
        height: 1.7,
        color: bodyColor.withOpacity(0.88),
        fontWeight: FontWeight.w500,
      ),
      availableWidth,
    );

    final meaningLabelHeight = _measureTextHeight(
      'English Meaning',
      GoogleFonts.outfit(
        fontSize: _readerFontSize + 1,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      availableWidth,
    );

    final englishHeight = _measureTextHeight(
      verse['english'] ?? '',
      GoogleFonts.outfit(
        fontSize: _readerFontSize,
        height: 1.8,
        color: bodyColor.withOpacity(0.88),
        fontWeight: FontWeight.w500,
      ),
      availableWidth,
    );

    return 28 + sanskritHeight + 30 + transliterationHeight + 28 + 2.5 + 30 + meaningLabelHeight + 18 + englishHeight + 28;
  }

  double _getBookHeight(BuildContext context) {
    final maxPageHeight = _verses.fold<double>(
      0,
      (currentMax, verse) => math.max(currentMax, _getVersePageHeight(context, verse)),
    );
    return maxPageHeight + 68;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundTop = _sepiaMode ? const Color(0xFF4A2B13) : const Color(0xFF191919);
    final backgroundBottom = _sepiaMode ? const Color(0xFF26160B) : const Color(0xFF0B0B0B);

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
            onPressed: () {},
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _sepiaMode = !_sepiaMode;
              });
            },
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
          child: _isLoadingPages
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8C1A)),
                )
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

  Widget _buildBookView(BuildContext context) {
    final paperColor = _sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6);
    final bookHeight = math.max(_getBookHeight(context), 460.0);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: bookHeight,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF26150B), // Rich mahogany leather cover
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Realistic Stacked Paper Edge on Right & Bottom (Layered Physical Pages)
              Positioned(
                right: 0,
                top: 10,
                bottom: 10,
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

              // Main Parchment Page Sheet
              Positioned(
                left: 12,
                right: 8,
                top: 8,
                bottom: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: paperColor,
                    child: Stack(
                      children: [
                        // Left Spine Crease Shadow (3D Book Binding Fold)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 22,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.38),
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),

                        // Interactive Moveable Page Flip View
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: FlipPage(
                              controller: _flipController,
                              initialPage: _currentVerseIndex,
                              edgeHitZoneFraction: 0.40,
                              animationDuration: const Duration(milliseconds: 380),
                              pages: List<Widget>.generate(
                                _verses.length,
                                (index) => _buildVersePage(_verses[index], index),
                              ),
                              onPageChanged: (index) {
                                setState(() {
                                  _currentVerseIndex = index;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersePage(Map<String, String> verse, int pageIndex) {
    final bodyColor = _sepiaMode ? const Color(0xFF332014) : const Color(0xFF261910);
    final paperBg = _sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6);
    final sanskritText = verse['sanskrit'] ?? '';
    final transliterationText = verse['transliteration'] ?? '';
    final englishText = verse['english'] ?? '';

    return Container(
      color: paperBg,
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45), width: 1.2),
        ),
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25), width: 0.8),
          ),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Sacred Vedic Header & OM Motif
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('❖ ──────── ', style: GoogleFonts.outfit(color: const Color(0xFFC59239), fontSize: 11)),
                  Text('ॐ', style: GoogleFonts.notoSerifDevanagari(fontSize: 20, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold)),
                  Text(' ──────── ❖', style: GoogleFonts.outfit(color: const Color(0xFFC59239), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 18),

              // Sanskrit / Devanagari Verse Text
              if (sanskritText.isNotEmpty) ...[
                Text(
                  sanskritText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: _readerFontSize + 4,
                    height: 1.85,
                    color: const Color(0xFF4A1005),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Transliteration (if available)
              if (transliterationText.isNotEmpty) ...[
                Text(
                  transliterationText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: _readerFontSize,
                    height: 1.65,
                    color: bodyColor.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Golden Vedic Divider Line
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 1.2,
                    color: const Color(0xFFC59239).withValues(alpha: 0.6),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('❖', style: GoogleFonts.outfit(color: const Color(0xFFC59239), fontSize: 10)),
                  ),
                  Container(
                    width: 50,
                    height: 1.2,
                    color: const Color(0xFFC59239).withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // English Meaning Label & Content
              Text(
                'English Translation',
                style: GoogleFonts.outfit(
                  fontSize: _readerFontSize + 1,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C1405),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                englishText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: _readerFontSize,
                  height: 1.75,
                  color: bodyColor.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final verseCount = _verses.length;

    return Column(
      children: [
        SliderTheme( // Corrected from withValues to withOpacity
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF8C1A),
            inactiveTrackColor: Colors.white.withOpacity(0.18),
            thumbColor: const Color(0xFFFF8C1A),
            overlayColor: const Color(0xFFFF8C1A).withOpacity(0.14),
            trackHeight: 3.5,
          ),
          child: Slider(
            min: 0,
            max: verseCount > 1 ? (verseCount - 1).toDouble() : 1,
            value: _currentVerseIndex.toDouble().clamp(0, verseCount > 1 ? (verseCount - 1).toDouble() : 1),
            onChanged: verseCount <= 1
                ? null
                : (value) {
                    _goToVerse(value.round());
                  },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentVerseIndex > 0
                  ? () => _goToVerse(_currentVerseIndex - 1)
                  : null,
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_currentVerseIndex + 1} / $verseCount',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: _currentVerseIndex < verseCount - 1
                  ? () => _goToVerse(_currentVerseIndex + 1)
                  : null,
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.white.withOpacity(0.14), height: 1),
      ],
    );
  }
}
