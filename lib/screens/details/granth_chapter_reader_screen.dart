import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey<PageFlipWidgetState> _pageFlipKey = GlobalKey<PageFlipWidgetState>();
  List<Map<String, String>> _verses = [];
  int _currentPageIndex = 0;
  final double _readerFontSize = 16.0;
  bool _sepiaMode = true;
  bool _isLoadingPages = true;

  @override
  void initState() {
    super.initState();
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
            final pageId = (pageMap['_id'] ?? pageMap['id'] ?? '').toString();

            List<dynamic> shlokas = [];
            if (pageMap['shlokas'] is List && (pageMap['shlokas'] as List).isNotEmpty) {
              shlokas = pageMap['shlokas'] as List;
            } else if (pageId.isNotEmpty) {
              try {
                shlokas = await ApiService.getShlokasByPage(pageId);
              } catch (_) {}
            }

            if (shlokas.isNotEmpty) {
              for (final shloka in shlokas) {
                if (shloka is Map) {
                  final sMap = Map<String, dynamic>.from(shloka);
                  final sanskrit = (sMap['sanskritText'] ?? sMap['sanskrit'] ?? sMap['shloka'] ?? '').toString().trim();
                  final transliteration = (sMap['transliteration'] ?? sMap['transliterate'] ?? '').toString().trim();
                  final english = (sMap['englishMeaning'] ?? sMap['englishTranslation'] ?? sMap['english'] ?? sMap['content'] ?? '').toString().trim();
                  final hindi = (sMap['hindiMeaning'] ?? sMap['hindiTranslation'] ?? sMap['hindi'] ?? '').toString().trim();

                  if (sanskrit.isNotEmpty || english.isNotEmpty || hindi.isNotEmpty) {
                    parsedVerses.add({
                      'sanskrit': sanskrit,
                      'transliteration': transliteration,
                      'english': english,
                      'hindi': hindi,
                    });
                  }
                }
              }
            } else {
              final pageContent = (pageMap['content'] ?? pageMap['description'] ?? '').toString().trim();
              final sanskrit = (pageMap['sanskrit'] ?? pageMap['sanskritText'] ?? '').toString().trim();
              final transliteration = (pageMap['transliteration'] ?? '').toString().trim();
              final english = (pageMap['english'] ?? pageMap['englishTranslation'] ?? pageMap['englishMeaning'] ?? pageContent).toString().trim();
              final hindi = (pageMap['hindi'] ?? pageMap['hindiTranslation'] ?? pageMap['hindiMeaning'] ?? '').toString().trim();

              if (sanskrit.isNotEmpty || english.isNotEmpty || hindi.isNotEmpty) {
                parsedVerses.add({
                  'sanskrit': sanskrit.isNotEmpty ? sanskrit : (widget.chapter['sanskritName'] ?? widget.chapter['name'] ?? '').toString(),
                  'transliteration': transliteration,
                  'english': english,
                  'hindi': hindi,
                });
              }
            }
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
              'hindi': '',
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
      if (trans.isNotEmpty) bodyText = trans;
      else if (content.isNotEmpty) bodyText = content;
      else if (desc.isNotEmpty) bodyText = desc;

      final sanskritText = (widget.chapter['sanskritName'] ?? widget.chapter['sanskrit'] ?? widget.chapter['name'] ?? widget.chapter['title'] ?? '').toString();
      if (sanskritText.isNotEmpty || bodyText.isNotEmpty) {
        parsedVerses = [
          {
            'sanskrit': sanskritText,
            'transliteration': (widget.chapter['transliteration'] ?? '').toString(),
            'english': bodyText,
            'hindi': '',
          }
        ];
      }
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
    super.dispose();
  }

  int get _totalBookPages => _verses.length + 2;

  void _goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _totalBookPages) return;
    try {
      _pageFlipKey.currentState?.goToPage(pageIndex);
    } catch (_) {}
    setState(() {
      _currentPageIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final granthTitle = (widget.granth['name'] ?? widget.granth['title'] ?? 'Granth').toString();
    final chapterTitle = (widget.chapter['title'] ?? widget.chapter['name'] ?? 'Chapter').toString();

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
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '$granthTitle - $chapterTitle',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
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
              icon: const Icon(Icons.palette_outlined, color: Color(0xFF2E2A36)),
              tooltip: 'Toggle Parchment Theme',
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFFFFE8D6),
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
      ),
    );
  }

  Widget _buildBookContainer(BuildContext context) {
    final int maxIndex = _totalBookPages - 1;
    double leftStackWidth = 0.0;
    double rightStackWidth = 0.0;

    if (_currentPageIndex == 0) {
      // Front Cover Page: ZERO left stack thickness, FULL right stack thickness
      leftStackWidth = 0.0;
      rightStackWidth = 14.0;
    } else if (_currentPageIndex == maxIndex) {
      // Back Cover Page: FULL left stack thickness, ZERO right stack thickness
      leftStackWidth = 14.0;
      rightStackWidth = 0.0;
    } else {
      // Inner Verses: Dynamic paper transfer from right to left
      final double innerProgress = maxIndex > 2
          ? ((_currentPageIndex - 1) / (maxIndex - 2)).clamp(0.0, 1.0)
          : 0.5;
      leftStackWidth = (3.5 + (9.5 * innerProgress)).clamp(3.5, 13.0);
      rightStackWidth = (13.0 - (9.5 * innerProgress)).clamp(3.5, 13.0);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B0E06), // Deep Mahogany Leather Frame
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B3A14).withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top Paper Block Edge (3D Top Book Thickness)
          if (_currentPageIndex > 0 && _currentPageIndex < maxIndex)
            Positioned(
              top: 0,
              left: leftStackWidth + 4,
              right: rightStackWidth + 4,
              height: 7,
              child: _buildTopBottomPaperEdge(isTop: true),
            ),

          // Bottom Paper Block Edge (3D Bottom Book Thickness)
          if (_currentPageIndex > 0 && _currentPageIndex < maxIndex)
            Positioned(
              bottom: 0,
              left: leftStackWidth + 4,
              right: rightStackWidth + 4,
              height: 7,
              child: _buildTopBottomPaperEdge(isTop: false),
            ),

          // Dynamic Stacked Paper Edges on Left Side (Grows as pages are flipped, 0 on Front Cover)
          if (leftStackWidth > 0)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              width: leftStackWidth,
              child: _buildStackedPaperEdges(isRightSide: false, width: leftStackWidth),
            ),

          // Dynamic Stacked Paper Edges on Right Side (Shrinks as remaining pages decrease, 0 on Back Cover)
          if (rightStackWidth > 0)
            Positioned(
              right: 0,
              top: 8,
              bottom: 8,
              width: rightStackWidth,
              child: _buildStackedPaperEdges(isRightSide: true, width: rightStackWidth),
            ),

          // Main Stacked Interactive PageFlip Canvas
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                leftStackWidth > 0 ? leftStackWidth + 2 : 6,
                7,
                rightStackWidth > 0 ? rightStackWidth + 2 : 6,
                7,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    PageFlipWidget(
                      key: _pageFlipKey,
                      backgroundColor: const Color(0xFF1E0F07),
                      duration: const Duration(milliseconds: 950), // Significantly slower, calm forward flip
                      cutoffForward: 0.55, // Slower, controlled forward drag trigger
                      cutoffPrevious: 0.45,
                      initialIndex: 0,
                      onPageFlipped: (pageIndex) {
                        setState(() {
                          _currentPageIndex = pageIndex;
                        });
                      },
                      lastPage: _buildBookBackCover(),
                      children: [
                        _buildBookFrontCover(),
                        ...List.generate(_verses.length, (index) => _buildVersePage(_verses[index], index)),
                      ],
                    ),

                    // Left Spine Binding Crease Shadow for Open Book
                    if (_currentPageIndex > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 22,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.black.withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
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
    );
  }

  Widget _buildTopBottomPaperEdge({required bool isTop}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC7B398).withValues(alpha: 0.6),
            const Color(0xFFF3E7D3).withValues(alpha: 0.9),
            const Color(0xFFEFE4D2).withValues(alpha: 0.9),
            const Color(0xFFC7B398).withValues(alpha: 0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildStackedPaperEdges({required bool isRightSide, required double width}) {
    if (width <= 0) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: isRightSide ? Radius.zero : const Radius.circular(5),
          right: isRightSide ? const Radius.circular(5) : Radius.zero,
        ),
        gradient: LinearGradient(
          colors: isRightSide
              ? [
                  const Color(0xFF7C6A57), // Spine seam shadow
                  const Color(0xFFF3E7D3), // Cream page 1
                  const Color(0xFFCCA78B), // Aged shadow line
                  const Color(0xFFFBF4E8), // Cream page 2
                  const Color(0xFFC5B296), // Aged shadow line
                  const Color(0xFFEFE4D2), // Cream page 3
                  const Color(0xFF98856C), // Outer deckle shadow
                ]
              : [
                  const Color(0xFF98856C), // Outer deckle shadow
                  const Color(0xFFEFE4D2), // Cream page 3
                  const Color(0xFFC5B296), // Aged shadow line
                  const Color(0xFFFBF4E8), // Cream page 2
                  const Color(0xFFCCA78B), // Aged shadow line
                  const Color(0xFFF3E7D3), // Cream page 1
                  const Color(0xFF7C6A57), // Spine seam shadow
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 5,
            spreadRadius: 1,
            offset: isRightSide ? const Offset(2, 0) : const Offset(-2, 0),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFBBA78B).withValues(alpha: 0.85),
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildBookFrontCover() {
    final rawCover = (widget.granth['coverImage'] ?? widget.granth['image'] ?? widget.granth['cover'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(rawCover);

    Widget coverContent;
    if (resolvedUrl.startsWith('http')) {
      coverContent = Image.network(
        resolvedUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackCoverImage(),
      );
    } else if (rawCover.startsWith('assets/')) {
      coverContent = Image.asset(
        rawCover,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackCoverImage(),
      );
    } else {
      coverContent = _fallbackCoverImage();
    }

    return Container(
      color: const Color(0xFF1E0F07),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: coverContent,
      ),
    );
  }

  Widget _fallbackCoverImage() {
    return Image.asset(
      'assets/images/bhagavad_gita.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _pureFullPageCoverArtwork(),
    );
  }

  Widget _pureFullPageCoverArtwork() {
    final granthName = (widget.granth['name'] ?? widget.granth['title'] ?? 'Sacred Granth').toString();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B1E0B), Color(0xFF190C05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories_rounded, color: Color(0xFFFFD700), size: 64),
            const SizedBox(height: 18),
            Text(
              granthName,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifDevanagari(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Text('❖ ──────── ॐ ──────── ❖', style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // Inner Content Verse Page
  Widget _buildVersePage(Map<String, String> verse, int verseIndex) {
    final bodyColor = _sepiaMode ? const Color(0xFF332014) : const Color(0xFF261910);
    final paperBg = _sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6);
    final sanskritText = (verse['sanskrit'] ?? '').trim();
    final transliterationText = (verse['transliteration'] ?? '').trim();
    String rawEnglish = (verse['english'] ?? '').trim();
    String rawHindi = (verse['hindi'] ?? '').trim();

    // If hindi was not passed separately, check if rawEnglish has both Hindi & English separated
    if (rawHindi.isEmpty && rawEnglish.contains('\n\n')) {
      final parts = rawEnglish.split('\n\n');
      if (parts.length >= 2) {
        final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(parts[0]);
        if (hasDevanagari) {
          rawHindi = parts[0].trim();
          rawEnglish = parts.sublist(1).join('\n\n').trim();
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: paperBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(-4, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(4, 0),
          ),
        ],
      ),
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
                if (rawHindi.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 32, height: 1.0, color: const Color(0xFFC59239).withValues(alpha: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('भावार्थ', style: GoogleFonts.notoSerifDevanagari(fontSize: 13, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold)),
                      ),
                      Container(width: 32, height: 1.0, color: const Color(0xFFC59239).withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rawHindi,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerifDevanagari(
                      fontSize: _readerFontSize + 0.5,
                      height: 1.7,
                      color: bodyColor.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (rawEnglish.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 32, height: 1.0, color: const Color(0xFFC59239).withValues(alpha: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('English Translation', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                      Container(width: 32, height: 1.0, color: const Color(0xFFC59239).withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rawEnglish,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: _readerFontSize,
                      height: 1.65,
                      color: bodyColor.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
      color: const Color(0xFF1E0F07),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
          gradient: const LinearGradient(
            colors: [Color(0xFF190C05), Color(0xFF381F0E)],
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
            inactiveTrackColor: const Color(0xFF2E2A36).withValues(alpha: 0.18),
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
              icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFF2E2A36), size: 34),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF3E4D6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _currentPageIndex == 0
                    ? 'Front Cover'
                    : _currentPageIndex == pageCount - 1
                        ? 'Back Cover'
                        : 'Page $_currentPageIndex / ${_verses.length}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2E2A36),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: _currentPageIndex < pageCount - 1 ? () => _goToPage(_currentPageIndex + 1) : null,
              icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF2E2A36), size: 34),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
