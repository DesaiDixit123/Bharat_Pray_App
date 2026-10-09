import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY WIDGET
// ─────────────────────────────────────────────────────────────────────────────
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
  List<Map<String, String>> _verses = [];
  bool _isLoadingPages = true;
  bool _sepiaMode = true;

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
              try { shlokas = await ApiService.getShlokasByPage(pageId); } catch (_) {}
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
                    parsedVerses.add({'sanskrit': sanskrit, 'transliteration': transliteration, 'english': english, 'hindi': hindi});
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
                  'transliteration': transliteration, 'english': english, 'hindi': hindi,
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
            parsedVerses.add(item.map((key, value) => MapEntry(key.toString(), (value ?? '').toString())));
          } else if (item != null && item.toString().trim().isNotEmpty) {
            parsedVerses.add({'sanskrit': item.toString(), 'transliteration': '', 'english': '', 'hindi': ''});
          }
        }
      }
    }

    if (parsedVerses.isEmpty) {
      final desc = (widget.chapter['description'] ?? '').toString().trim();
      final trans = (widget.chapter['translation'] ?? '').toString().trim();
      final content = (widget.chapter['content'] ?? '').toString().trim();
      final String bodyText = trans.isNotEmpty ? trans : (content.isNotEmpty ? content : desc);
      final sanskritText = (widget.chapter['sanskritName'] ?? widget.chapter['sanskrit'] ?? widget.chapter['name'] ?? widget.chapter['title'] ?? '').toString();
      if (sanskritText.isNotEmpty || bodyText.isNotEmpty) {
        parsedVerses = [
          {'sanskrit': sanskritText, 'transliteration': (widget.chapter['transliteration'] ?? '').toString(), 'english': bodyText, 'hindi': ''}
        ];
      }
    }

    if (mounted) {
      setState(() { _verses = parsedVerses; _isLoadingPages = false; });
    }
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
            style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.w700, fontSize: 17),
          ),
          actions: [
            IconButton(
              onPressed: () => setState(() => _sepiaMode = !_sepiaMode),
              icon: const Icon(Icons.palette_outlined, color: Color(0xFF2E2A36)),
              tooltip: 'Toggle Parchment Theme',
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _isLoadingPages
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C1A)))
              : _BookViewer(
                  granth: widget.granth,
                  granthTitle: granthTitle,
                  chapterTitle: chapterTitle,
                  verses: _verses,
                  sepiaMode: _sepiaMode,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED BOOK VIEWER
// Combines Hardbound cover opening + Soft page peeling with V-style open gutter
// ─────────────────────────────────────────────────────────────────────────────
class _BookViewer extends StatefulWidget {
  const _BookViewer({
    required this.granth,
    required this.granthTitle,
    required this.chapterTitle,
    required this.verses,
    required this.sepiaMode,
  });

  final Map<String, dynamic> granth;
  final String granthTitle;
  final String chapterTitle;
  final List<Map<String, String>> verses;
  final bool sepiaMode;

  @override
  State<_BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<_BookViewer> with TickerProviderStateMixin {
  int _currentPage = 0; // 0 = Cover, 1...N = Verses, N+1 = Back Cover
  bool _isTurning = false;
  bool _turnForward = true;
  double _dragProgress = 0.0; // 0.0 to 1.0
  bool _isDragging = false;
  bool _isClosingBook = false;

  late AnimationController _turnCtrl;
  late Animation<double> _turnAnim;

  int get totalPages => widget.verses.length + 2;

  @override
  void initState() {
    super.initState();
    _turnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _turnAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeInOutSine));
    _turnAnim.addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() { _turnCtrl.dispose(); super.dispose(); }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_isClosingBook) {
        Navigator.pop(context);
        return;
      }
      if (_turnForward && _currentPage == totalPages - 1) {
        // Swiped past the back cover!
        Navigator.pop(context);
        return;
      }
      
      setState(() {
        if (_turnForward) {
          _currentPage = (_currentPage + 1).clamp(0, totalPages - 1);
        } else {
          _currentPage = (_currentPage - 1).clamp(0, totalPages - 1);
        }
        _isTurning = false;
        _dragProgress = 0;
      });
      _turnCtrl.reset();
    } else if (status == AnimationStatus.dismissed) {
      // The drag was aborted and snapped back to 0.
      setState(() {
        _isTurning = false;
        _dragProgress = 0;
      });
    }
  }

  void _triggerTurn({required bool forward, int? durationMs}) {
    if (_isTurning || _isClosingBook) return;
    if (forward && _currentPage >= totalPages) return;
    if (!forward && _currentPage <= 0) return;
    HapticFeedback.lightImpact();
    setState(() { _isTurning = true; _turnForward = forward; });
    if (durationMs != null) {
      _turnCtrl.duration = Duration(milliseconds: durationMs);
    } else {
      _turnCtrl.duration = const Duration(milliseconds: 650);
    }
    _turnCtrl.forward(from: _dragProgress.clamp(0.0, 0.99));
  }

  void _triggerReturn({int? durationMs}) {
    if (_isTurning) return;
    setState(() { _isTurning = true; });
    if (durationMs != null) {
      _turnCtrl.duration = Duration(milliseconds: durationMs);
    } else {
      _turnCtrl.duration = const Duration(milliseconds: 650);
    }
    _turnCtrl.reverse(from: _dragProgress.clamp(0.01, 1.0));
  }

  void _triggerCloseBookAnimation() {
    if (_isTurning || _isClosingBook) return;
    setState(() {
      _isClosingBook = true;
      _turnForward = true; // Swings from right to left
    });
    _turnCtrl.duration = const Duration(milliseconds: 900); // Slower, dramatic close
    _turnCtrl.forward(from: 0.0);
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    if (_isTurning || _isClosingBook) return;
    setState(() { 
      _isDragging = true; 
      _dragProgress = 0; 
      // Sanitize turn direction so we don't try to turn backward from page 0 (causes null crash on long press)
      if (_currentPage <= 0) _turnForward = true;
      if (_currentPage >= totalPages - 1) _turnForward = false;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (!_isDragging || _isTurning) return;
    final width = context.size?.width ?? 350;
    final delta = -(d.primaryDelta! / width);
    
    // Don't drag forward on back cover
    if (delta > 0 && _currentPage >= totalPages - 1) return;
    // Don't drag backward on front cover
    if (delta < 0 && _currentPage <= 0) return;
    
    if (delta > 0 && _currentPage < totalPages) {
      setState(() { _turnForward = true; _dragProgress = (_dragProgress + delta * 1.5).clamp(0.0, 0.99); });
    } else if (delta < 0 && _currentPage > 0) {
      setState(() { _turnForward = false; _dragProgress = (_dragProgress - delta * 1.5).clamp(0.0, 0.99); });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);
    
    final velocity = d.primaryVelocity ?? 0;
    
    // We want the visual finish to take a fixed minimum time so it doesn't instantly teleport.
    // 250ms for fast flicks, 350ms for slow releases.
    final int targetMs = velocity.abs() > 300 ? 250 : 350;

    // Calculate how much animation is left (minimum 5% to avoid divide-by-zero or massive numbers)
    final double remForward = (1.0 - _dragProgress).clamp(0.05, 1.0);
    final double remBackward = _dragProgress.clamp(0.05, 1.0);
    
    // Scale the total duration so the *remaining* sweep takes exactly targetMs
    final int forwardTotalMs = (targetMs / remForward).round();
    final int returnTotalMs = (targetMs / remBackward).round();
    
    if (velocity.abs() > 300) { // Fast swipe
      if (_turnForward) {
        // We were dragging Right-to-Left (opening page)
        if (velocity < 0 && _currentPage < totalPages - 1) { // Flipped leftwards
          _triggerTurn(forward: true, durationMs: forwardTotalMs);
        } else { // Flipped rightwards (aborted)
          _triggerReturn(durationMs: returnTotalMs);
        }
      } else {
        // We were dragging Left-to-Right (closing page)
        if (velocity > 0 && _currentPage > 0) { // Flipped rightwards
          _triggerTurn(forward: false, durationMs: forwardTotalMs);
        } else { // Flipped leftwards (aborted)
          _triggerReturn(durationMs: returnTotalMs);
        }
      }
    } else { // Slow drag release
      if (_dragProgress > 0.35) {
        _triggerTurn(forward: _turnForward, durationMs: forwardTotalMs);
      } else {
        _triggerReturn(durationMs: returnTotalMs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top Progress ──────────────────────────────────────────────────
        if (_currentPage > 0 && _currentPage < totalPages - 1) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page $_currentPage', style: GoogleFonts.outfit(color: const Color(0xFF8B6048), fontSize: 12)),
                Text('${widget.verses.length} pages', style: GoogleFonts.outfit(color: const Color(0xFF8B6048), fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.verses.isEmpty ? 0 : (_currentPage - 1) / widget.verses.length,
                backgroundColor: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8C1A)),
                minHeight: 3,
              ),
            ),
          ),
        ] else
          const SizedBox(height: 28), // Placeholder

        // ── Book Canvas ───────────────────────────────────────────────────
        Expanded(
          child: Center(
            child: Padding(
              // Keep padding on left so the open book "V style" left pages have room to bleed
              padding: const EdgeInsets.only(left: 20),
              child: GestureDetector(
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: AnimatedBuilder(
                  animation: _turnCtrl,
                  builder: (context, _) {
                    final progress = _isTurning ? _turnAnim.value : _dragProgress;
                    return _build3DBookCanvas(progress);
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // ── Controls ──────────────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: (_currentPage > 0 && !(_currentPage == 1 && _isTurning && !_turnForward))
              ? Padding(
                  key: const ValueKey('nav_controls'),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _triggerTurn(forward: false),
                        icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF2E2A36), size: 36),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: _currentPage < totalPages - 1 ? () => _triggerTurn(forward: true) : null,
                        icon: Icon(Icons.chevron_right_rounded,
                            color: _currentPage < totalPages - 1 ? const Color(0xFF2E2A36) : Colors.grey.shade400, size: 36),
                      ),
                    ],
                  ),
                )
              : Padding(
                  key: const ValueKey('open_button'),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: GestureDetector(
                    onTap: () => _triggerTurn(forward: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8C1A), Color(0xFFD45B00)]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF8C1A).withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('Open Book', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget? _getStaticLeftPage(int index, double w, double h) {
    if (index < 0 || index >= totalPages) return null;
    if (index == 0 || index == totalPages - 1) {
      return _buildInsideCover(w, h);
    }
    return _getPage(index, w, h); // the readable verse
  }

  Widget? _getInsidePage(int index, double w, double h) {
    if (index < 0 || index >= totalPages) return null;
    if (index == 0 || index == totalPages - 1) {
      return _buildInsideCover(w, h);
    }
    // For verses, the physical back of the page is just blank paper color
    return Container(
      width: w, height: h,
      color: widget.sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6),
    );
  }

  Widget _buildInsideCover(double w, double h) {
    return Container(
      width: w, height: h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF381406), Color(0xFF1E0A03)], 
          begin: Alignment.topLeft, end: Alignment.bottomRight
        ),
      ),
    );
  }

  Widget _build3DBookCanvas(double progress) {
    final size = MediaQuery.of(context).size;
    final w = size.width * 0.82;  // the original full book width
    final h = size.height * 0.65;

    final bool isAnimatingOrDragging = progress > 0 || _isDragging || _isClosingBook;
    final int basePageIndex = !isAnimatingOrDragging ? _currentPage : (_turnForward ? (_currentPage + 1) : _currentPage);
    final int topPageIndex = _isClosingBook 
        ? (totalPages - 1) 
        : (!isAnimatingOrDragging ? _currentPage : (_turnForward ? _currentPage : (_currentPage - 1)));

    // Pages are always rendered at the FULL book width (w x h)
    final Widget? basePage = _isClosingBook ? null : _getPage(basePageIndex, w, h);
    final Widget? topPage = _getPage(topPageIndex, w, h);

    final bool isTurning = (progress > 0 || _isDragging || _isClosingBook) && topPage != null;
    final bool isFrontCoverTurn = (topPageIndex == 0) && !_isClosingBook; 

    // Dynamic Thickness Calculation
    final double maxStackW = 10.0;
    final double swipeProgress = isTurning ? (_turnForward ? progress : -progress) : 0.0;
    final double effectivePage = (_currentPage + swipeProgress).clamp(0.0, totalPages - 1.0);
    final double dynamicRatio = totalPages > 1 ? (effectivePage / (totalPages - 1)) : 0.0;
    
    final double leftStackW = maxStackW * dynamicRatio;
    final double rightStackW = maxStackW * (1.0 - dynamicRatio);

    // The sliver of the left/previous page that peeks out from the spine.
    final double peekSliver = 18.0;

    Widget content;
    if (!isAnimatingOrDragging) {
      content = topPage != null ? _wrapPage(topPageIndex, topPage) : const SizedBox.shrink();
    } else {
      if (isFrontCoverTurn || _isClosingBook) {
        // True 2-Sided 180-Degree Rigid Door Swing for the Front/Back Cover
        final double turnAngle = _isClosingBook
            ? (progress * math.pi) // Closing back cover swings right to left
            : (_turnForward ? (progress * math.pi) : ((1.0 - progress) * math.pi));

        final bool isFrontVisible = _isClosingBook
            ? turnAngle <= math.pi / 2
            : turnAngle <= math.pi / 2;

        content = Stack(
          clipBehavior: Clip.none,
          children: [
            if (basePage != null && !_isClosingBook) _wrapPage(basePageIndex, basePage),
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Standard perspective
                ..rotateY(turnAngle),
              child: isFrontVisible 
                  ? _wrapPage(topPageIndex, topPage!) 
                  : Transform(
                      // Render the OUTSIDE of the cover! Flipped so it's not mirrored when swung -180 deg
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                      child: _wrapPage(
                        topPageIndex, 
                        _isClosingBook ? _fallbackCover(w, h, showTitle: false) : (_getInsidePage(topPageIndex, w, h) ?? topPage!), 
                        isLeft: false
                      ),
                    ),
            ),
          ],
        );
      } else {
        // Unified peel engine for inner pages
        content = _TruePagePeelWidget(
          progress: progress,
          forward: _turnForward,
          frontPage: _wrapPage(topPageIndex, topPage!),
          basePage: basePage != null ? _wrapPage(basePageIndex, basePage) : const SizedBox.shrink(),
          backSidePage: _wrapPage(topPageIndex, _getInsidePage(topPageIndex, w, h) ?? topPage!),
          width: w,
          height: h,
        );
      }
    }

    // Determine which page should be visible statically on the left side.
    // If we are turning backward, the page peeling from left to right IS `_currentPage - 1`, 
    // so the static page left underneath must be `_currentPage - 2`!
    int leftStaticIndex = _currentPage - 1;
    if (isAnimatingOrDragging && !_turnForward) {
      leftStaticIndex = _currentPage - 2;
    }
    
    final Widget? activeLeftPeekPage = _getStaticLeftPage(leftStaticIndex, w, h);
    bool showLeftPeek = activeLeftPeekPage != null && leftStaticIndex >= 0;
    
    // If the cover is actively swinging, hide the static left page, because the swinging cover ITSELF handles the visual on the left!
    if (isAnimatingOrDragging && isFrontCoverTurn) {
      showLeftPeek = false;
    }

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none, 
        alignment: Alignment.centerLeft,
        children: [
          // ── BASE LAYERS (The rigid covers lying permanently on the table) ──
          if (_currentPage > 0 && !(isAnimatingOrDragging && isFrontCoverTurn))
            Positioned(
              left: -w, top: 0, bottom: 0, width: w,
              child: _wrapPage(0, _buildInsideCover(w, h), isLeft: true),
            ),
          if (_currentPage < totalPages - 1 && !_isClosingBook)
            Positioned(
              left: 0, top: 0, bottom: 0, width: w,
              child: _wrapPage(totalPages - 1, _buildInsideCover(w, h), isLeft: false),
            ),

          // ── 0. The full left page (e.g. static inner pages) ──
          // Rendered fully to the left of the hinge
          if (showLeftPeek)
            Positioned(
              left: -w,
              top: 0, bottom: 0, width: w,
              child: _wrapPage(leftStaticIndex, activeLeftPeekPage!, isLeft: true),
            ),

          // ── 1. Right Pages Stack (Fore-edge) ──
          if (rightStackW > 0.5 && _currentPage < totalPages - 1)
            Positioned(
              left: w - 12,
              top: 12, bottom: 12, width: rightStackW,
              child: _buildRightPageStack(),
            ),

          // ── 2. Left Pages Stack (Fore-edge) ──
          if (leftStackW > 0.5 && _currentPage > 0 && !(isAnimatingOrDragging && isFrontCoverTurn))
            Positioned(
              left: -w + 12 - leftStackW,
              top: 12, bottom: 12, width: leftStackW,
              child: _buildLeftPageStack(),
            ),

          // ── 3. Content (The Current Page & Turning Engine) ──
          // Always full width — the size never changes!
          Positioned.fill(
            child: content,
          ),

          // ── 4. Deep Spine Crease Shadow ──
          if (showLeftPeek)
            Positioned(
              left: peekSliver - 12,
              top: 0, bottom: 0, width: 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrapPage(int index, Widget child, {bool isLeft = false}) {
    final isCover = (index == 0 || index == totalPages - 1);
    final radius = Radius.circular(isCover ? 6 : 2);
    final borderRadius = isLeft 
        ? BorderRadius.only(topLeft: radius, bottomLeft: radius)
        : BorderRadius.only(topRight: radius, bottomRight: radius);

    // Inner paper pages are slightly smaller than the covers to show the hardcover borders (squares)
    final margin = isCover ? EdgeInsets.zero : EdgeInsets.only(
      top: 12, bottom: 12, 
      left: isLeft ? 12 : 0, 
      right: isLeft ? 0 : 12
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isCover ? const Color(0xFF1E0A03) : (widget.sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6)),
        borderRadius: borderRadius,
        border: Border.all(
          color: isCover ? const Color(0xFFD4AF37).withValues(alpha: 0.8) : const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: isCover ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLeft ? 0.15 : 0.35),
            blurRadius: isLeft ? 6 : 12,
            offset: Offset(isLeft ? -2 : 4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  Widget _buildRightPageStack() {
    return Container(
      decoration: BoxDecoration(
        color: widget.sepiaMode ? const Color(0xFFD4C5A9) : const Color(0xFFE5D5BA),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: Color(0xFFBBA78B), width: 0.8),
          bottom: BorderSide(color: Color(0xFFBBA78B), width: 0.8),
          right: BorderSide(color: Color(0xFFBBA78B), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(4, 3)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ForeEdgeLinesPainter(horizontal: false))),
          Positioned(
            left: 0, top: 0, bottom: 0, width: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPageStack() {
    return Container(
      decoration: BoxDecoration(
        color: widget.sepiaMode ? const Color(0xFFD4C5A9) : const Color(0xFFE5D5BA),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: Color(0xFFBBA78B), width: 0.8),
          bottom: BorderSide(color: Color(0xFFBBA78B), width: 0.8),
          left: BorderSide(color: Color(0xFFBBA78B), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(-3, 3)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ForeEdgeLinesPainter(horizontal: false)),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Replaced by _DynamicCurvedPage internals

  Widget? _getPage(int index, double w, double h) {
    if (index < 0 || index >= totalPages) return null;
    if (index == 0) {
      return _buildCoverFace(w, h);
    } else if (index == totalPages - 1) {
      return _BackCoverPage(
        granthName: widget.granthTitle, 
        onReadAgain: () => setState(() { _currentPage = 0; }),
        onClose: _triggerCloseBookAnimation,
      );
    } else {
      return _VersePage(verse: widget.verses[index - 1], verseIndex: index - 1, sepiaMode: widget.sepiaMode);
    }
  }

  // ── Cover face ─────────────────────────────────────────────────────────────
  Widget _buildCoverFace(double w, double h) {
    final rawCover = (widget.granth['coverImage'] ?? widget.granth['image'] ?? widget.granth['cover'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(rawCover);

    Widget imageContent;
    if (resolvedUrl.startsWith('http')) {
      imageContent = Image.network(resolvedUrl, fit: BoxFit.cover, width: w, height: h,
          errorBuilder: (_, __, ___) => _fallbackCover(w, h));
    } else if (rawCover.startsWith('assets/')) {
      imageContent = Image.asset(rawCover, fit: BoxFit.cover, width: w, height: h,
          errorBuilder: (_, __, ___) => _fallbackCover(w, h));
    } else {
      imageContent = _fallbackCover(w, h);
    }

    return Stack(
      children: [
        Positioned.fill(child: imageContent),
        // Leather gloss overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent, Colors.black.withValues(alpha: 0.25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackCover(double w, double h, {bool showTitle = true}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF5C2008), Color(0xFF1E0A03), Color(0xFF4A1C08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LeatherTexturePainter())),
          if (showTitle)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD4AF37), width: 1.5), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: Color(0xFFD4AF37), size: 56),
                        const SizedBox(height: 16),
                        Text(widget.granthTitle, textAlign: TextAlign.center,
                            style: GoogleFonts.notoSerifDevanagari(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFFFD700), height: 1.3)),
                        const SizedBox(height: 10),
                        Text('❖ ──── ॐ ──── ❖', style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 11)),
                        const SizedBox(height: 8),
                        Text(widget.chapterTitle, textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: const Color(0xFFFFD700).withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRUE MATHEMATICAL 2D PAGE FOLD WIDGET
// Folds the right side of the page over itself flawlessly, no shaders needed.
// ─────────────────────────────────────────────────────────────────────────────
class _TruePagePeelWidget extends StatelessWidget {
  const _TruePagePeelWidget({
    required this.progress,
    required this.forward,
    required this.frontPage,
    required this.basePage,
    required this.backSidePage,
    required this.width,
    required this.height,
  });

  final double progress; // 0.0 to 1.0 (0=flat, 1=fully turned)
  final bool forward;
  final Widget frontPage;    // The page being turned (current)
  final Widget basePage;     // The page underneath (next)
  final Widget backSidePage; // What shows on the BACK of the turning page (real content)
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // F = fold crease X position: starts at rightmost edge, moves left as user swipes
    final double F = forward ? width * (1.0 - progress) : width * progress;
    // backLeft = left edge of the folded flap (mirrors around F)
    final double backLeft = (2 * F - width).clamp(-width, width);
    
    // Slight diagonal (conical) lift — peaks at midpoint of swipe
    final double liftAngle = math.sin(progress * math.pi) * 0.05; // ~2.9 degrees

    // Allow the peel widget to overflow to the left so the page can physically land on the left cover!
    // We clip top/bottom strictly to height, but allow left to go to -width.
    return ClipRect(
      clipper: _OverflowClipper(-width, width * 2, height),
      child: Stack(
        children: [
          // 1. Base Page (the next page, revealed as the front page peels away)
          Positioned.fill(child: basePage),

          // 2. Drop shadow cast by the fold crease onto the base page
          if (progress > 0.01 && progress < 0.99)
            Positioned(
              left: F, top: 0, bottom: 0,
              width: math.min(50.0, width - F),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

          // 3. Flat left portion of the front page (not yet peeled)
          if (F > 0)
            ClipRect(
              clipper: _RectClipper(0, F),
              child: frontPage,
            ),

          // 4. The folded flap — back side shows actual page content (bleed-through)
          if (progress > 0.01 && progress < 0.99 && F > backLeft)
            Transform(
              // Rotate around the fold crease at x=F
              alignment: Alignment(F / width * 2 - 1, 0), // normalize to [-1,1]
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // slight 3D perspective
                ..rotateY(math.pi - progress * math.pi * 0.18) // slight tilt = feels 3D
                ..rotateZ(forward ? -liftAngle : liftAngle), // diagonal corner lift
              child: ClipRect(
                clipper: _RectClipper(F > 0 ? F : 0, width),
                child: Stack(
                  children: [
                    // The back of the page — real content, horizontally flipped
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                      child: backSidePage,
                    ),
                    // Paper semi-opacity overlay (real book paper is slightly translucent)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: Colors.white.withValues(alpha: 0.82)),
                      ),
                    ),
                    // Fold lighting: bright highlight on the crease, shadow on the far edge
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.0),   // free edge (left)
                                Colors.white.withValues(alpha: 0.45),  // specular highlight at crease
                                Colors.black.withValues(alpha: 0.35),  // inner shadow at crease
                              ],
                              stops: const [0.0, 0.75, 1.0],
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
        ],
      ),
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.left, this.right);
  final double left;
  final double right;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(math.max(0, left), 0, math.min(size.width, right), size.height);
  }

  @override
  bool shouldReclip(_RectClipper old) => old.left != left || old.right != right;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _ForeEdgeLinesPainter extends CustomPainter {
  _ForeEdgeLinesPainter({required this.horizontal});
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBA78B).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    if (horizontal) {
      for (double y = 4; y < size.height; y += 3) { canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); }
    } else {
      for (double x = 4; x < size.width; x += 3) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _LeatherTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 8) { canvas.drawLine(Offset(0, y), Offset(size.width, y + 4), paint); }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// VERSE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _VersePage extends StatelessWidget {
  const _VersePage({required this.verse, required this.verseIndex, required this.sepiaMode});
  final Map<String, String> verse;
  final int verseIndex;
  final bool sepiaMode;

  @override
  Widget build(BuildContext context) {
    final bodyColor = sepiaMode ? const Color(0xFF332014) : const Color(0xFF261910);
    final sanskritText = (verse['sanskrit'] ?? '').trim();
    final transliterationText = (verse['transliteration'] ?? '').trim();
    String rawEnglish = (verse['english'] ?? '').trim();
    String rawHindi = (verse['hindi'] ?? '').trim();

    if (rawHindi.isEmpty && rawEnglish.contains('\n\n')) {
      final parts = rawEnglish.split('\n\n');
      if (parts.length >= 2 && RegExp(r'[\u0900-\u097F]').hasMatch(parts[0])) {
        rawHindi = parts[0].trim();
        rawEnglish = parts.sublist(1).join('\n\n').trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45), width: 1.2),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.22), width: 0.8),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
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
                const SizedBox(height: 6),
                Text('Verse ${verseIndex + 1}',
                    style: GoogleFonts.outfit(color: const Color(0xFF8B6048), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
                if (sanskritText.isNotEmpty) ...[
                  Text(sanskritText, textAlign: TextAlign.center,
                      style: GoogleFonts.notoSerifDevanagari(fontSize: 19, height: 1.8, color: const Color(0xFF4A1005), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                ],
                if (transliterationText.isNotEmpty) ...[
                  Text(transliterationText, textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 14, height: 1.6, color: bodyColor.withValues(alpha: 0.85), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                ],
                if (rawHindi.isNotEmpty) ...[
                  _divider('भावार्थ', devanagari: true),
                  const SizedBox(height: 8),
                  Text(rawHindi, textAlign: TextAlign.center,
                      style: GoogleFonts.notoSerifDevanagari(fontSize: 16, height: 1.7, color: bodyColor.withValues(alpha: 0.95), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                ],
                if (rawEnglish.isNotEmpty) ...[
                  _divider('English Translation'),
                  const SizedBox(height: 8),
                  Text(rawEnglish, textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 14.5, height: 1.65, color: bodyColor.withValues(alpha: 0.92), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(String label, {bool devanagari = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 26, height: 1, color: const Color(0xFFC59239).withValues(alpha: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(label,
              style: devanagari
                  ? GoogleFonts.notoSerifDevanagari(fontSize: 12, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold)
                  : GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        Container(width: 26, height: 1, color: const Color(0xFFC59239).withValues(alpha: 0.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACK COVER PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _BackCoverPage extends StatelessWidget {
  const _BackCoverPage({required this.granthName, required this.onReadAgain, required this.onClose});
  final String granthName;
  final VoidCallback onReadAgain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text('❖ ──────── ॐ ──────── ❖', style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 12)),
            const SizedBox(height: 22),
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 46),
            const SizedBox(height: 16),
            Text('ॐ शान्तिः शान्तिः शान्तिः ॐ', textAlign: TextAlign.center,
                style: GoogleFonts.notoSerifDevanagari(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFFD700))),
            const SizedBox(height: 10),
            Text('You have reached the end of this chapter.', textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: onReadAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, color: Colors.white, size: 16),
                    label: Text('Read Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Color(0xFFFF8C1A), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFFF8C1A), size: 16),
                    label: Text('Close Book', style: GoogleFonts.outfit(color: const Color(0xFFFF8C1A), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowClipper extends CustomClipper<Rect> {
  final double leftOffset;
  final double width;
  final double height;

  _OverflowClipper(this.leftOffset, this.width, this.height);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(leftOffset, 0, width, height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
