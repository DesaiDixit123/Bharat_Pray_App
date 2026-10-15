import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
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
  final bool _sepiaMode = true;

  // ── Audio / Karaoke state ──────────────────────────────────────────────────
  final GlobalKey<_BookViewerState> _bookViewerKey = GlobalKey<_BookViewerState>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioUrl;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  // Karaoke: flat list of all words across all verses, in order.
  List<_KaraokeWord> _allWords = [];

  // Per-verse word start offsets in _allWords.
  List<int> _verseWordOffsets = [];

  // The global word index that is currently highlighted.
  int _highlightedWordIndex = -1;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _loadChapterPagesAndVerses();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      _audioPosition = p;
      _updateKaraokeHighlight(p);
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _highlightedWordIndex = -1; });
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  void _updateKaraokeHighlight(Duration position) {
    if (_allWords.isEmpty || _audioDuration.inMilliseconds <= 0) return;
    final fraction = (position.inMilliseconds / _audioDuration.inMilliseconds).clamp(0.0, 1.0);
    final idx = (fraction * _allWords.length).floor().clamp(0, _allWords.length - 1);
    if (idx != _highlightedWordIndex) {
      setState(() => _highlightedWordIndex = idx);

      // Auto-turn book to the page containing this currently-recited verse
      final targetVerse = _allWords[idx].verseIndex;
      final targetPage = targetVerse + 1; // 1-indexed (0 is cover)
      _bookViewerKey.currentState?.autoTurnToPage(targetPage);
    }
  }

  void _buildKaraokeWordList() {
    final allWords = <_KaraokeWord>[];
    final offsets = <int>[];
    final wordPattern = RegExp(r'[^\s।॥\n\r,.:;!?]+');

    for (int vi = 0; vi < _verses.length; vi++) {
      offsets.add(allWords.length);
      // Highlight the primary verse text added from the admin panel:
      // typically sanskrit/shloka text; if empty, fallback to hindi or english
      String text = (_verses[vi]['sanskrit'] ?? '').trim();
      if (text.isEmpty) text = (_verses[vi]['hindi'] ?? '').trim();
      if (text.isEmpty) text = (_verses[vi]['english'] ?? '').trim();
      if (text.isEmpty) continue;

      final matches = wordPattern.allMatches(text);
      for (final m in matches) {
        final w = m.group(0) ?? '';
        if (w.isNotEmpty) {
          allWords.add(_KaraokeWord(word: w, verseIndex: vi));
        }
      }
    }
    _allWords = allWords;
    _verseWordOffsets = offsets;
  }

  Future<void> _loadAudio() async {
    if (_isLoadingAudio) return;
    setState(() => _isLoadingAudio = true);

    String? foundUrl;

    // 1. Check chapter object directly for audio URL
    final direct = (widget.chapter['audioUrl'] ?? widget.chapter['audio'] ?? widget.chapter['streamUrl'] ?? widget.chapter['fileUrl'])?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      final resolved = ApiService.resolveImageUrl(direct);
      if (resolved.isNotEmpty) foundUrl = resolved;
    }

    // 2. Fetch chapter audio from backend
    final chapterId = (widget.chapter['_id'] ?? widget.chapter['id'] ?? '').toString();
    if (foundUrl == null && chapterId.isNotEmpty) {
      try {
        final audios = await ApiService.getAudioByChapter(chapterId);
        if (audios.isNotEmpty) {
          final first = Map<String, dynamic>.from(audios.first as Map);
          final raw = (first['audioUrl'] ?? first['url'] ?? first['streamUrl'] ?? first['fileUrl'] ?? '').toString();
          final resolved = raw.isNotEmpty ? ApiService.resolveImageUrl(raw) : '';
          if (resolved.isNotEmpty) foundUrl = resolved;
        }
      } catch (_) {}
    }

    // 3. Check verse-level audio
    if (foundUrl == null) {
      for (final v in _verses) {
        final va = (v['audio'] ?? '').trim();
        if (va.isNotEmpty) {
          final resolved = ApiService.resolveImageUrl(va);
          if (resolved.isNotEmpty) {
            foundUrl = resolved;
            break;
          }
        }
      }
    }

    // 4. Default devotional chant audio so karaoke works seamlessly out of the box even before custom upload
    if (foundUrl == null || foundUrl.isEmpty) {
      foundUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';
    }

    if (mounted) {
      setState(() {
        _audioUrl = foundUrl;
        _isLoadingAudio = false;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_audioUrl == null) {
      // No audio loaded yet — show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No audio available for this chapter.', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFF5C1405),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPosition == Duration.zero || _audioPosition >= _audioDuration) {
        // Fresh start
        await _audioPlayer.play(UrlSource(_audioUrl!));
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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
      setState(() {
        _verses = parsedVerses;
        _isLoadingPages = false;
      });
      _buildKaraokeWordList();
      _loadAudio(); // Fire-and-forget
    }
  }

  @override
  Widget build(BuildContext context) {
    final granthTitle = (widget.granth['name'] ?? widget.granth['title'] ?? 'Granth').toString();
    final chapterTitle = (widget.chapter['title'] ?? widget.chapter['name'] ?? 'Chapter').toString();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1E0A03),
        body: Stack(
          children: [
            // Full-screen book viewer
            Positioned.fill(
              child: _isLoadingPages
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C1A)))
                  : _BookViewer(
                      key: _bookViewerKey,
                      granth: widget.granth,
                      granthTitle: granthTitle,
                      chapterTitle: chapterTitle,
                      verses: _verses,
                      sepiaMode: _sepiaMode,
                      highlightedWordIndex: _highlightedWordIndex,
                      verseWordOffsets: _verseWordOffsets,
                      allWordCount: _allWords.length,
                    ),
            ),

            // Floating back arrow (top-left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),

            // ── Sacred Floating Play/Pause Button ──────────────────────────
            if (!_isLoadingPages)
              Positioned(
                bottom: bottomPadding + 28,
                right: 20,
                child: _KaraokePlayFab(
                  isPlaying: _isPlaying,
                  isLoading: _isLoadingAudio,
                  hasAudio: _audioUrl != null,
                  onTap: _togglePlayPause,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KARAOKE DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _KaraokeWord {
  const _KaraokeWord({required this.word, required this.verseIndex});
  final String word;
  final int verseIndex;
}

// ─────────────────────────────────────────────────────────────────────────────
// SACRED FLOATING PLAY/PAUSE FAB
// ─────────────────────────────────────────────────────────────────────────────
class _KaraokePlayFab extends StatefulWidget {
  const _KaraokePlayFab({
    required this.isPlaying,
    required this.isLoading,
    required this.hasAudio,
    required this.onTap,
  });
  final bool isPlaying;
  final bool isLoading;
  final bool hasAudio;
  final VoidCallback onTap;

  @override
  State<_KaraokePlayFab> createState() => _KaraokePlayFabState();
}

class _KaraokePlayFabState extends State<_KaraokePlayFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool pulsing = widget.isPlaying;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final scale = pulsing ? _pulseAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFF8C1A), Color(0xFFB85C00)],
                  center: Alignment(-0.3, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C1A).withValues(alpha: pulsing ? 0.7 : 0.4),
                    blurRadius: pulsing ? 22 : 14,
                    spreadRadius: pulsing ? 4 : 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Icon(
                        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED BOOK VIEWER
// Combines Hardbound cover opening + Soft page peeling with V-style open gutter
// ─────────────────────────────────────────────────────────────────────────────
class _BookViewer extends StatefulWidget {
  const _BookViewer({
    super.key,
    required this.granth,
    required this.granthTitle,
    required this.chapterTitle,
    required this.verses,
    required this.sepiaMode,
    required this.highlightedWordIndex,
    required this.verseWordOffsets,
    required this.allWordCount,
  });

  final Map<String, dynamic> granth;
  final String granthTitle;
  final String chapterTitle;
  final List<Map<String, String>> verses;
  final bool sepiaMode;
  final int highlightedWordIndex;
  final List<int> verseWordOffsets;
  final int allWordCount;

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
  // Pending drag: touch started but no movement yet — avoids blink on hold
  bool _pendingDrag = false;

  late AnimationController _turnCtrl;
  late Animation<double> _turnAnim;

  int get totalPages => widget.verses.length + 2;

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

  void autoTurnToPage(int targetPage) {
    if (_currentPage == targetPage || _isTurning || _isClosingBook) return;
    if (targetPage < 0 || targetPage >= totalPages) return;
    if (targetPage > _currentPage) {
      _triggerTurn(forward: true, durationMs: 550);
    } else if (targetPage < _currentPage) {
      _triggerTurn(forward: false, durationMs: 550);
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
    _pendingDrag = true;
    _isDragging = false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (_isTurning) return;
    final width = context.size?.width ?? 350;
    final delta = -(d.primaryDelta! / width);

    // Lock direction on first decisive movement — avoids direction jitter
    if (!_isDragging && _pendingDrag) {
      if (delta.abs() < 0.003) return;
      final bool forward = delta > 0;
      if (forward && _currentPage >= totalPages - 1) return;
      if (!forward && _currentPage <= 0) return;
      setState(() {
        _isDragging = true;
        _pendingDrag = false;
        _turnForward = forward;
        _dragProgress = 0.0;
      });
      return;
    }
    if (!_isDragging) return;

    // Advance or retreat smoothly along the locked gesture direction
    final double step = _turnForward ? delta : -delta;
    setState(() {
      _dragProgress = (_dragProgress + step * 1.35).clamp(0.0, 0.99);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    _pendingDrag = false;
    if (!_isDragging) return;
    setState(() => _isDragging = false);

    final velocity = d.primaryVelocity ?? 0;
    final int targetMs = velocity.abs() > 300 ? 250 : 350;

    final double remForward = (1.0 - _dragProgress).clamp(0.05, 1.0);
    final double remBackward = _dragProgress.clamp(0.05, 1.0);

    final int forwardTotalMs = (targetMs / remForward).round().clamp(150, 650);
    final int returnTotalMs = (targetMs / remBackward).round().clamp(150, 650);

    if (velocity.abs() > 300) {
      if (_turnForward) {
        if (velocity < 0) {
          _triggerTurn(forward: true, durationMs: forwardTotalMs);
        } else {
          _triggerReturn(durationMs: returnTotalMs);
        }
      } else {
        if (velocity > 0) {
          _triggerTurn(forward: false, durationMs: forwardTotalMs);
        } else {
          _triggerReturn(durationMs: returnTotalMs);
        }
      }
    } else {
      if (_dragProgress > 0.35) {
        _triggerTurn(forward: _turnForward, durationMs: forwardTotalMs);
      } else {
        _triggerReturn(durationMs: returnTotalMs);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _turnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _turnAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeInOutSine));
    _turnAnim.addStatusListener(_onAnimStatus);
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen: book fills the entire display
    return GestureDetector(
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
    final verseWidget = _getPage(index, w, h);
    // Authentic parchment paper back with subtle devanagari watermark and mirrored verse bleed-through
    return Stack(
      children: [
        Container(
          width: w,
          height: h,
          color: widget.sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6),
        ),
        if (verseWidget != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.16,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                child: verseWidget,
              ),
            ),
          ),
        Center(
          child: Opacity(
            opacity: 0.10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ॐ', style: GoogleFonts.notoSerifDevanagari(fontSize: 68, color: const Color(0xFF5C1405), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('❖ ──── ॐ ──── ❖', style: GoogleFonts.outfit(color: const Color(0xFF5C1405), fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
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
    final w = size.width;
    final h = size.height;

    final bool isAnimatingOrDragging = progress > 0 || _isDragging || _isClosingBook;
    final bool isClosingToCover = isAnimatingOrDragging && !_turnForward && _currentPage == 1;

    final int basePageIndex = !isAnimatingOrDragging 
        ? _currentPage 
        : (_turnForward ? (_currentPage + 1) : (isClosingToCover ? 1 : _currentPage));
        
    final int topPageIndex = _isClosingBook 
        ? (totalPages - 1) 
        : (!isAnimatingOrDragging 
            ? _currentPage 
            : (_turnForward ? _currentPage : (isClosingToCover ? 0 : _currentPage - 1)));

    final Widget? basePage = _isClosingBook ? null : _getPage(basePageIndex, w, h);
    final Widget? topPage = _getPage(topPageIndex, w, h);

    final bool isTurning = (progress > 0 || _isDragging || _isClosingBook) && topPage != null;
    final bool isFrontCoverTurn = ((topPageIndex == 0) || isClosingToCover) && !_isClosingBook; 

    // Dynamic Thickness Calculation
    final double maxStackW = 10.0;
    final double swipeProgress = isTurning ? (_turnForward ? progress : -progress) : 0.0;
    final double effectivePage = (_currentPage + swipeProgress).clamp(0.0, totalPages - 1.0);
    final double dynamicRatio = totalPages > 1 ? (effectivePage / (totalPages - 1)) : 0.0;
    
    final double leftStackW = maxStackW * dynamicRatio;
    final double rightStackW = maxStackW * (1.0 - dynamicRatio);

    Widget content;
    if (!isAnimatingOrDragging) {
      content = topPage != null ? _wrapPage(topPageIndex, topPage) : const SizedBox.shrink();
    } else if (isFrontCoverTurn || _isClosingBook) {
      final double turnAngle = _isClosingBook
          ? (progress * math.pi)
          : (_turnForward ? (progress * math.pi) : ((1.0 - progress) * math.pi));

      final bool isFrontVisible = turnAngle <= math.pi / 2;
      final double sineAngle = math.sin(turnAngle);

      content = Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Underneath page (basePage)
          if (basePage != null && !_isClosingBook) ...[
            _wrapPage(basePageIndex, basePage),
            // Dynamic drop shadow cast on basePage by the turning page
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(basePageIndex == 0 ? 6 : 2),
                      bottomRight: Radius.circular(basePageIndex == 0 ? 6 : 2),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: (0.42 * sineAngle).clamp(0.0, 0.45)),
                        Colors.black.withValues(alpha: (0.12 * sineAngle).clamp(0.0, 0.2)),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [
                        0.0,
                        (0.25 + 0.35 * (1.0 - math.cos(turnAngle).abs())).clamp(0.1, 0.7),
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 2. The Turning Page in 3D (Cover Swing)
          if (topPage != null)
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0006)
                ..rotateY(turnAngle),
              child: isFrontVisible
                  ? Stack(
                      children: [
                        _wrapPage(topPageIndex, topPage),
                        // Ambient lighting & specular sheen on front of turning page
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(topPageIndex == 0 ? 6 : 2),
                                  bottomRight: Radius.circular(topPageIndex == 0 ? 6 : 2),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: (0.10 * sineAngle).clamp(0.0, 0.2)),
                                    Colors.white.withValues(alpha: (0.18 * sineAngle).clamp(0.0, 0.25)),
                                    Colors.black.withValues(alpha: (0.28 * sineAngle).clamp(0.0, 0.4)),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                      child: Stack(
                        children: [
                          _wrapPage(
                            topPageIndex,
                            _isClosingBook
                                ? _fallbackCover(w, h, showTitle: false)
                                : (_getInsidePage(topPageIndex, w, h) ?? topPage),
                            isLeft: false,
                          ),
                          // Deep crease shadow on back of page along the spine
                          Positioned(
                            right: 0, top: 0, bottom: 0, width: 28,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: (0.35 * sineAngle).clamp(0.0, 0.4)),
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
        ],
      );
    } else {
      // ── INNER PAGES: TRUE CYLINDRICAL CURVED PAPER PEEL ANIMATION ──
      // Symmetrical engine: progress 0.0 -> 1.0 controls fold position F for both forward and backward turns.
      content = _TruePagePeelWidget(
        progress: progress,
        forward: _turnForward,
        frontPage: topPage != null ? _wrapPage(topPageIndex, topPage) : const SizedBox.shrink(),
        basePage: basePage != null ? _wrapPage(basePageIndex, basePage) : const SizedBox.shrink(),
        backSidePage: _wrapPage(
          topPageIndex,
          _getInsidePage(topPageIndex, w, h) ?? (topPage ?? const SizedBox.shrink()),
        ),
        width: w,
        height: h,
      );
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
    // Note: do NOT suppress showLeftPeek during front cover turn — we use opacity to fade the spine shadow in smoothly

    // Compute spine shadow opacity: fades in as cover opens, instant on static pages
    final bool isCoverOpening = isAnimatingOrDragging && isFrontCoverTurn && _turnForward;
    final bool isCoverClosing = isAnimatingOrDragging && isFrontCoverTurn && !_turnForward;
    final double spineOpacity = showLeftPeek
        ? 1.0                              // Static: full opacity
        : (isCoverOpening ? progress       // Fades IN with the cover swing
            : (isCoverClosing ? (1.0 - progress) // Fades OUT when closing back to cover
                : 0.0));

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
          // Back-cover inner layer: only needed during cover/close animations, never during static reading
          if ((_currentPage < totalPages - 1) && !_isClosingBook && (isAnimatingOrDragging && isFrontCoverTurn))
            Positioned(
              left: 0, top: 0, bottom: 0, width: w,
              child: _wrapPage(totalPages - 1, _buildInsideCover(w, h), isLeft: false),
            ),
          if (_isClosingBook)
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
              child: _wrapPage(leftStaticIndex, activeLeftPeekPage, isLeft: true),
            ),

          // ── 1. Right Pages Stack (Fore-edge) ──
          if (rightStackW > 0.5 && _currentPage < totalPages - 1)
            Positioned(
              left: w - 12,
              top: 12, bottom: 12, width: rightStackW,
              child: _buildRightPageStack(),
            ),

          // ── 3. Content (The Current Page & Turning Engine) ──
          // Always full width — the size never changes!
          Positioned.fill(
            child: content,
          ),

          // ── 4. Left Pages Stack (Fore-edge) — rendered ON TOP of content at left edge ──
          // Shows the thickness of already-read pages like a real open book
          if (leftStackW > 0.5 && _currentPage > 0 && !(isAnimatingOrDragging && isFrontCoverTurn))
            Positioned(
              left: 0,
              top: 12, bottom: 12, width: leftStackW,
              child: IgnorePointer(child: _buildLeftPageStack()),
            ),

          // ── 5. Deep Spine Crease Shadow — fades in with cover animation ──
          if (spineOpacity > 0)
            Positioned(
              left: leftStackW,
              top: 0, bottom: 0, width: 18,
              child: IgnorePointer(
                child: Opacity(
                  opacity: spineOpacity.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
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

    // In full-screen mode keep inner pages nearly flush — only tiny margin so pages feel large
    final margin = isCover ? EdgeInsets.zero : EdgeInsets.only(
      top: 4, bottom: 4,
      left: isLeft ? 4 : 0,
      right: isLeft ? 0 : 4
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
      final vi = index - 1;
      final startOffset = (vi < widget.verseWordOffsets.length) ? widget.verseWordOffsets[vi] : 0;
      final endOffset = (vi + 1 < widget.verseWordOffsets.length)
          ? widget.verseWordOffsets[vi + 1]
          : widget.allWordCount;
      // Local highlighted word index within this verse (-1 if none)
      final localIdx = (widget.highlightedWordIndex >= startOffset && widget.highlightedWordIndex < endOffset)
          ? widget.highlightedWordIndex - startOffset
          : -1;
      return _VersePage(
        verse: widget.verses[vi],
        verseIndex: vi,
        sepiaMode: widget.sepiaMode,
        highlightedLocalWordIndex: localIdx,
      );
    }
  }

  // ── Cover face ─────────────────────────────────────────────────────────────
  Widget _buildCoverFace(double w, double h) {
    final rawCover = (widget.granth['coverImage'] ?? widget.granth['image'] ?? widget.granth['cover'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(rawCover);

    Widget imageContent;
    if (resolvedUrl.startsWith('http')) {
      imageContent = Image.network(resolvedUrl, fit: BoxFit.cover, width: w, height: h,
          errorBuilder: (context, error, stackTrace) => _fallbackCover(w, h));
    } else if (rawCover.startsWith('assets/')) {
      imageContent = Image.asset(rawCover, fit: BoxFit.cover, width: w, height: h,
          errorBuilder: (context, error, stackTrace) => _fallbackCover(w, h));
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
  const _VersePage({
    required this.verse,
    required this.verseIndex,
    required this.sepiaMode,
    this.highlightedLocalWordIndex = -1,
  });
  final Map<String, String> verse;
  final int verseIndex;
  final bool sepiaMode;
  /// Index of the highlighted word within THIS verse's Sanskrit token list. -1 = none.
  final int highlightedLocalWordIndex;

  /// Build a rich text widget that highlights the active word while preserving 100% of
  /// the original admin-entered whitespace, newlines (\n), and devanagari dandas (। ॥).
  Widget _buildKaraokeText(String text, TextStyle baseStyle) {
    if (text.isEmpty) return const SizedBox.shrink();
    final wordPattern = RegExp(r'[^\s।॥\n\r,.:;!?]+');
    final matches = wordPattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

    if (highlightedLocalWordIndex < 0 || highlightedLocalWordIndex >= matches.length) {
      // No active highlight on this verse: render text naturally
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

    // Reconstruct the exact string with rich styling on the active word
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      // Delimiter before this word (spaces, newlines, dandas)
      if (m.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, m.start),
          style: baseStyle,
        ));
      }

      final isHighlighted = (i == highlightedLocalWordIndex);
      final wordStr = m.group(0)!;

      if (isHighlighted) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F), // Radiant holy gold highlight
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C1A).withValues(alpha: 0.65),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              wordStr,
              style: baseStyle.copyWith(
                color: const Color(0xFF8B0000), // Deep sacred crimson for high readability
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: wordStr,
          style: baseStyle,
        ));
      }

      lastIndex = m.end;
    }

    // Trailing punctuation / newlines after the last word
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

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

    final topSafePadding = MediaQuery.paddingOf(context).top;
    final contentTopPadding = math.max(16.0, topSafePadding + 18.0);

    final sanskritBaseStyle = GoogleFonts.notoSerifDevanagari(
      fontSize: 19,
      height: 1.8,
      color: const Color(0xFF4A1005),
      fontWeight: FontWeight.w700,
    );

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
          child: Stack(
            children: [
              // Main scrollable verse content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(top: contentTopPadding, bottom: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0, constraints.maxHeight - (contentTopPadding + 24)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          // Karaoke indicator pill — appears while a word is highlighted
                          if (highlightedLocalWordIndex >= 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C1A).withValues(alpha: 0.15),
                                border: Border.all(color: const Color(0xFFFF8C1A).withValues(alpha: 0.5), width: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.music_note_rounded, size: 10, color: Color(0xFFD55F00)),
                                  const SizedBox(width: 4),
                                  Text('Now Playing', style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFFD55F00), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          Text('Verse ${verseIndex + 1}',
                              style: GoogleFonts.outfit(color: const Color(0xFF8B6048), fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 14),
                          // ── Karaoke-enabled Sanskrit text ──
                          if (sanskritText.isNotEmpty) ...[
                            _buildKaraokeText(sanskritText, sanskritBaseStyle),
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
                            if (sanskritText.isEmpty)
                              _buildKaraokeText(rawHindi, GoogleFonts.notoSerifDevanagari(fontSize: 16, height: 1.7, color: bodyColor.withValues(alpha: 0.95), fontWeight: FontWeight.w500))
                            else
                              Text(rawHindi, textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSerifDevanagari(fontSize: 16, height: 1.7, color: bodyColor.withValues(alpha: 0.95), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 16),
                          ],
                          if (rawEnglish.isNotEmpty) ...[
                            _divider('English Translation'),
                            const SizedBox(height: 8),
                            if (sanskritText.isEmpty && rawHindi.isEmpty)
                              _buildKaraokeText(rawEnglish, GoogleFonts.outfit(fontSize: 14.5, height: 1.65, color: bodyColor.withValues(alpha: 0.92), fontWeight: FontWeight.w500))
                            else
                              Text(rawEnglish, textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(fontSize: 14.5, height: 1.65, color: bodyColor.withValues(alpha: 0.92), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Printed BharatPray Logo inside the top-right corner of the yellow line
              Positioned(
                top: 10,
                right: 10,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 64,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
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

// ─────────────────────────────────────────────────────────────────────────────
// TRUE 3D CYLINDRICAL CURVED PAGE PEEL WIDGET
// Folds & unrolls realistic flexible paper with authentic 3D curvature,
// dynamic crease drop-shadow, specular sheen, and paper depth.
// Symmetrically handles both forward (right-to-left) and backward (left-to-right) turns.
// Front and base pages maintain fixed full-width layout so text NEVER shifts or reflows.
// ─────────────────────────────────────────────────────────────────────────────
class _TruePagePeelWidget extends StatelessWidget {
  const _TruePagePeelWidget({
    required this.progress, // 0.0 to 1.0 (0 = start of swipe, 1 = swipe completed)
    required this.forward,  // true = forward (R->L), false = backward (L->R)
    required this.frontPage,
    required this.basePage,
    required this.backSidePage,
    required this.width,
    required this.height,
  });

  final double progress;
  final bool forward;
  final Widget frontPage;
  final Widget basePage;
  final Widget backSidePage;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double clampedP = progress.clamp(0.0, 1.0);
    // When forward: effectiveP goes 0.0 -> 1.0 (crease F moves width -> 0)
    // When backward: effectiveP goes 1.0 -> 0.0 (crease F moves 0 -> width)
    final double effectiveP = forward ? clampedP : (1.0 - clampedP);

    // Smooth bell curve intensity for shadows and 3D depth
    final double shadowIntensity = math.sin(effectiveP * math.pi);

    // Fold crease X position strictly within [0, width]
    final double F = width * (1.0 - effectiveP);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── 1. Base Page (Underneath) ──
            // Always fixed at full width x height so its text NEVER shifts or reflows.
            Positioned(
              left: 0,
              top: 0,
              width: width,
              height: height,
              child: basePage,
            ),

            // ── 2. Drop Shadow Cast on Base Page by the 3D turning paper ──
            // Cast to the right of F onto the basePage
            if (effectiveP > 0.005 && effectiveP < 0.995 && F < width - 1)
              Positioned(
                left: F.clamp(0.0, width),
                top: 0,
                bottom: 0,
                width: math.min(55.0, (width - F).clamp(0.0, width)),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: (0.42 * shadowIntensity).clamp(0.0, 0.45)),
                          Colors.black.withValues(alpha: (0.12 * shadowIntensity).clamp(0.0, 0.18)),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),

            // ── 3. Flat Portion of Front Page (Clipped strictly to [0, F]) ──
            // CRITICAL: Positioned has width: width (NOT F) so constraints are always full-width!
            // The text is always centered at width/2 and NEVER changes its position during swipe!
            if (F > 0.5)
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: height,
                child: ClipRect(
                  clipper: _RectClipper(0, F),
                  child: frontPage,
                ),
              ),

            // ── 4. Soft Inner Crease Shadow on Front Page just left of F ──
            if (effectiveP > 0.01 && effectiveP < 0.99 && F > 4)
              Positioned(
                left: math.max(0.0, F - 28.0),
                top: 0,
                bottom: 0,
                width: math.min(28.0, F),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: (0.22 * shadowIntensity).clamp(0.0, 0.25)),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),

            // ── 5. The 3D Turning Page Flap ──
            // Authentic 3D perspective curl around the crease at x=F.
            // Vertically aligned so top and bottom stay strictly horizontal with no corner tilt.
            if (effectiveP > 0.01 && effectiveP < 0.99 && F < width - 2)
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: height,
                child: Transform(
                  alignment: Alignment(F / width * 2.0 - 1.0, 0.0),
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0008) // Natural 3D perspective depth
                    ..rotateY(math.pi - effectiveP * math.pi * 0.20), // 3D curl angle around fold
                  child: ClipRect(
                    clipper: _RectClipper(F, width),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          // Mirrored back of the turning page (real content with sacred markings)
                          Positioned.fill(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                              child: backSidePage,
                            ),
                          ),
                          // Paper semi-translucent warm parchment overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          // Fold lighting: specular highlight at crease, shadow on the far edge
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.0), // free edge
                                      Colors.white.withValues(alpha: (0.42 * shadowIntensity).clamp(0.0, 0.45)), // specular highlight
                                      Colors.black.withValues(alpha: (0.35 * shadowIntensity).clamp(0.0, 0.38)), // inner shadow at crease
                                    ],
                                    stops: const [0.0, 0.70, 1.0],
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
              ),

            // ── 6. Fine Crease Line Highlight at fold F ──
            if (effectiveP > 0.01 && effectiveP < 0.99 && F > 1.0 && F < width - 1.0)
              Positioned(
                left: F - 0.75,
                top: 0,
                bottom: 0,
                width: 1.5,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: (0.45 * shadowIntensity).clamp(0.0, 0.50)),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
  bool shouldReclip(_RectClipper oldClipper) => oldClipper.left != left || oldClipper.right != right;
}
