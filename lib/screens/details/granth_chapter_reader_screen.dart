import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

  // ── Auto-Reading & Highlighting State ──────────────────────────────────────
  final GlobalKey<_BookViewerState> _bookViewerKey = GlobalKey<_BookViewerState>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioUrl;
  bool _isPlaying = false; // Starts paused by default as requested
  bool _isLoadingAudio = false;

  int _currentPage = 0; // 0 = Cover, 1...N = Verses, N+1 = Back Cover
  int _currentWordOnPage = 0;
  double _speedMultiplier = 1.0;
  int _readingSpeedMs = 550; // Calmer, slightly slower devotional pace (~550ms per word at 1.0x)
  Timer? _wordTimer;
  bool _isAutoTurning = false;
  bool _isPageCompleted = false;

  // Pre-tokenized words for every verse across Sanskrit, Hindi, and English
  List<List<_PageWordToken>> _verseTokens = [];

  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _loadChapterPagesAndVerses();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted && _isPlaying && _audioUrl != null) {
        // Loop audio if user desires background chant while reading
        _audioPlayer.play(UrlSource(_audioUrl!));
      }
    });
  }

  /// Active section on the currently displayed verse ('sanskrit', 'hindi', 'english', or '')
  String get activeSection {
    if (!_isPlaying || _currentPage < 1 || _currentPage > _verses.length) return '';
    final vi = _currentPage - 1;
    if (vi >= _verseTokens.length) return '';
    final tokens = _verseTokens[vi];
    if (_currentWordOnPage >= tokens.length) return '';
    return tokens[_currentWordOnPage].section;
  }

  /// Active word index within its section (-1 if not highlighting)
  int get activeLocalWordIndex {
    if (!_isPlaying || _currentPage < 1 || _currentPage > _verses.length) return -1;
    final vi = _currentPage - 1;
    if (vi >= _verseTokens.length) return -1;
    final tokens = _verseTokens[vi];
    if (_currentWordOnPage >= tokens.length) return -1;
    return tokens[_currentWordOnPage].localIndex;
  }

  void _startWordTimer() {
    _wordTimer?.cancel();
    if (!_isPlaying) return;

    _wordTimer = Timer.periodic(Duration(milliseconds: _readingSpeedMs), (timer) {
      if (!mounted || !_isPlaying || _isAutoTurning) return;

      final vi = _currentPage - 1;
      if (vi < 0 || vi >= _verseTokens.length) return;

      final tokens = _verseTokens[vi];
      if (tokens.isEmpty) {
        _handlePageComplete();
        return;
      }

      if (_currentWordOnPage < tokens.length - 1) {
        setState(() {
          _currentWordOnPage++;
        });
      } else {
        // All words on the current page are complete!
        _handlePageComplete();
      }
    });
  }

  void _handlePageComplete() {
    _wordTimer?.cancel();
    if (!_isPlaying || _isAutoTurning) return;

    final totalPages = _verses.length + 2;
    final nextPage = _currentPage + 1;

    // Show the entire page completed/read state (all text warmly illuminated)
    setState(() {
      _isPageCompleted = true;
    });

    // Pause for 1200ms so reader comfortably absorbs the completed verse
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || !_isPlaying || _isAutoTurning) return;

      if (nextPage < totalPages - 1) {
        // Auto-turn to the next verse page smoothly and gracefully (650ms)
        _isAutoTurning = true;
        _bookViewerKey.currentState?.autoTurnToPage(nextPage, durationMs: 650);

        // Wait for page turn animation to finish (~700ms), then start reading the next page
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _isAutoTurning = false;
          if (_isPlaying) {
            setState(() {
              _currentPage = nextPage;
              _currentWordOnPage = 0;
              _isPageCompleted = false;
            });
            _startWordTimer();
          }
        });
      } else if (nextPage == totalPages - 1) {
        // Reached end of chapter verses, automatically turn to back cover gracefully
        _isAutoTurning = true;
        _bookViewerKey.currentState?.autoTurnToPage(nextPage, durationMs: 650);
        setState(() {
          _isPlaying = false;
          _isAutoTurning = false;
          _currentPage = nextPage;
          _currentWordOnPage = 0;
          _isPageCompleted = false;
        });
        if (_audioUrl != null) _audioPlayer.stop();
      } else {
        setState(() {
          _isPlaying = false;
          _currentWordOnPage = 0;
          _isPageCompleted = false;
        });
      }
    });
  }

  void _toggleAutoRead() {
    if (_isPlaying) {
      _wordTimer?.cancel();
      if (_audioUrl != null) _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
        _isPageCompleted = false;
      });
    } else {
      final totalPages = _verses.length + 2;
      if (_currentPage == 0) {
        // Currently on front cover: turn smoothly (650ms) to Page 1
        _bookViewerKey.currentState?.autoTurnToPage(1, durationMs: 650);
        setState(() {
          _isPlaying = true;
          _currentPage = 1;
          _currentWordOnPage = 0;
          _isPageCompleted = false;
        });
        if (_audioUrl != null) {
          _audioPlayer.play(UrlSource(_audioUrl!));
        }
        Future.delayed(const Duration(milliseconds: 750), () {
          if (mounted && _isPlaying) {
            _startWordTimer();
          }
        });
      } else if (_currentPage >= totalPages - 1) {
        // On back cover: return to Page 1 and start fresh
        _bookViewerKey.currentState?.autoTurnToPage(1, durationMs: 650);
        setState(() {
          _isPlaying = true;
          _currentPage = 1;
          _currentWordOnPage = 0;
          _isPageCompleted = false;
        });
        if (_audioUrl != null) {
          _audioPlayer.play(UrlSource(_audioUrl!));
        }
        Future.delayed(const Duration(milliseconds: 750), () {
          if (mounted && _isPlaying) {
            _startWordTimer();
          }
        });
      } else {
        // On a verse page: start or resume immediately
        setState(() {
          _isPlaying = true;
          _isPageCompleted = false;
        });
        if (_audioUrl != null) {
          _audioPlayer.resume();
        }
        _startWordTimer();
      }
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_speedMultiplier == 1.0) {
        _speedMultiplier = 1.25;
      } else if (_speedMultiplier == 1.25) {
        _speedMultiplier = 1.5;
      } else if (_speedMultiplier == 1.5) {
        _speedMultiplier = 0.8;
      } else {
        _speedMultiplier = 1.0;
      }
      _readingSpeedMs = (550 / _speedMultiplier).round();
    });
    if (_isPlaying) {
      _startWordTimer();
    }
  }

  void _onPageChanged(int newPage) {
    if (!mounted) return;
    if (_currentPage == newPage) return;
    setState(() {
      _currentPage = newPage;
      _currentWordOnPage = 0;
      _isPageCompleted = false;
    });
    if (_isPlaying) {
      if (newPage >= 1 && newPage <= _verses.length) {
        _startWordTimer();
      } else {
        _wordTimer?.cancel();
        if (_audioUrl != null) _audioPlayer.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  void _goToPrevPage() {
    if (_currentPage > 0) {
      _bookViewerKey.currentState?.autoTurnToPage(_currentPage - 1, durationMs: 580);
    }
  }

  void _goToNextPage() {
    final totalPages = _verses.length + 2;
    if (_currentPage < totalPages - 1) {
      _bookViewerKey.currentState?.autoTurnToPage(_currentPage + 1, durationMs: 580);
    }
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    _completeSub?.cancel();
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

    final tokens = List.generate(
      parsedVerses.length,
      (vi) => _extractTokensForVerse(parsedVerses[vi]),
    );

    if (mounted) {
      setState(() {
        _verses = parsedVerses;
        _verseTokens = tokens;
        _isLoadingPages = false;
      });
      _loadOptionalAudio();
    }
  }

  Future<void> _loadOptionalAudio() async {
    if (_isLoadingAudio) return;
    _isLoadingAudio = true;
    String? foundUrl;
    final direct = (widget.chapter['audioUrl'] ?? widget.chapter['audio'] ?? widget.chapter['streamUrl'] ?? widget.chapter['fileUrl'])?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      final resolved = ApiService.resolveImageUrl(direct);
      if (resolved.isNotEmpty) foundUrl = resolved;
    }
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
    if (mounted) {
      setState(() {
        _audioUrl = foundUrl;
        _isLoadingAudio = false;
      });
    }
  }

  static List<_PageWordToken> _extractTokensForVerse(Map<String, String> verse) {
    final tokens = <_PageWordToken>[];
    final wordPattern = RegExp(r'[^\s।॥\n\r,.:;!?]+');

    void addSection(String sectionName, String text) {
      if (text.trim().isEmpty) return;
      final matches = wordPattern.allMatches(text);
      int localIdx = 0;
      for (final m in matches) {
        final w = m.group(0) ?? '';
        if (w.isNotEmpty) {
          tokens.add(_PageWordToken(section: sectionName, localIndex: localIdx, word: w));
          localIdx++;
        }
      }
    }

    addSection('sanskrit', (verse['sanskrit'] ?? '').trim());
    addSection('transliteration', (verse['transliteration'] ?? '').trim());
    addSection('hindi', (verse['hindi'] ?? '').trim());
    addSection('english', (verse['english'] ?? '').trim());

    return tokens;
  }

  @override
  Widget build(BuildContext context) {
    final granthTitle = (widget.granth['name'] ?? widget.granth['title'] ?? 'Granth').toString();
    final chapterTitle = (widget.chapter['title'] ?? widget.chapter['name'] ?? 'Chapter').toString();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    // Book fills the readable area: just the status bar at top, nav controls region at bottom
    final double vInset = screenHeight * 0.045;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7EFE2),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7EFE2),
        body: Stack(
          children: [
            // Ambient sacred reading sanctuary background matching the app's divine cream theme
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.35,
                    colors: [
                      Color(0xFFFFF9F0), // Divine warm light cream
                      Color(0xFFF8EDE0), // Sandalwood cream
                      Color(0xFFEDE0CF), // Warm beige
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Book viewer reduced 10% from top and bottom with authentic desk drop shadow
            Positioned(
              top: vInset,
              bottom: vInset,
              left: 0,
              right: 0,
              child: _isLoadingPages
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C1A)))
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: const Color(0xFF5C1405).withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _BookViewer(
                        key: _bookViewerKey,
                        granth: widget.granth,
                        granthTitle: granthTitle,
                        chapterTitle: chapterTitle,
                        verses: _verses,
                        sepiaMode: _sepiaMode,
                        activeVerseIndex: (_isPlaying && _currentPage >= 1 && _currentPage <= _verses.length)
                            ? _currentPage - 1
                            : -1,
                        activeSection: activeSection,
                        activeLocalWordIndex: activeLocalWordIndex,
                        isPageCompleted: _isPageCompleted,
                        onPageChanged: _onPageChanged,
                      ),
                    ),
            ),

            // Floating back arrow (top-left) styled to match theme
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 10,
              child: Material(
                color: const Color(0xFF5C1405).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5C1405), size: 20),
                  ),
                ),
              ),
            ),

            // ── Floating Sacred Reading Control Bar ──────────────────────────
            if (!_isLoadingPages)
              Positioned(
                bottom: bottomPadding + 14,
                left: 16,
                right: 16,
                child: Center(
                  child: _SacredReaderControlBar(
                    isPlaying: _isPlaying,
                    currentVerseIndex: (_currentPage >= 1 && _currentPage <= _verses.length) ? _currentPage - 1 : -1,
                    totalVerses: _verses.length,
                    speed: _speedMultiplier,
                    onTogglePlay: _toggleAutoRead,
                    onSpeedCycle: _cycleSpeed,
                    onPrevPage: _goToPrevPage,
                    onNextPage: _goToNextPage,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD TOKEN DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _PageWordToken {
  const _PageWordToken({
    required this.section,
    required this.localIndex,
    required this.word,
  });
  final String section; // 'sanskrit', 'hindi', 'english'
  final int localIndex;
  final String word;
}

// ─────────────────────────────────────────────────────────────────────────────
// SACRED FLOATING CONTROL BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SacredReaderControlBar extends StatefulWidget {
  const _SacredReaderControlBar({
    required this.isPlaying,
    required this.currentVerseIndex,
    required this.totalVerses,
    required this.speed,
    required this.onTogglePlay,
    required this.onSpeedCycle,
    required this.onPrevPage,
    required this.onNextPage,
  });

  final bool isPlaying;
  final int currentVerseIndex;
  final int totalVerses;
  final double speed;
  final VoidCallback onTogglePlay;
  final VoidCallback onSpeedCycle;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;

  @override
  State<_SacredReaderControlBar> createState() => _SacredReaderControlBarState();
}

class _SacredReaderControlBarState extends State<_SacredReaderControlBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
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
    final hasVerse = widget.currentVerseIndex >= 0;
    final verseNum = widget.currentVerseIndex + 1;
    final speedLabel = '${widget.speed == 1.0 ? '1' : widget.speed.toString()}x';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0A03).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (widget.isPlaying)
            BoxShadow(
              color: const Color(0xFFFF8C1A).withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Previous Verse Button
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFFFFD54F), size: 24),
            tooltip: 'Previous Page',
            onPressed: widget.onPrevPage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),

          // Speed Multiplier Pill
          GestureDetector(
            onTap: widget.onSpeedCycle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF381406),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed_rounded, size: 13, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 3),
                  Text(
                    speedLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Center Pulsing Play/Pause FAB
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              final scale = widget.isPlaying ? _pulseAnim.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: widget.onTogglePlay,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF9E3D), Color(0xFFB85C00)],
                        center: Alignment(-0.2, -0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C1A).withValues(alpha: widget.isPlaying ? 0.7 : 0.4),
                          blurRadius: widget.isPlaying ? 16 : 8,
                          spreadRadius: widget.isPlaying ? 2 : 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Reading Status Pill
          Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF381406),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 0.8),
            ),
            child: Center(
              child: Text(
                hasVerse
                    ? (widget.isPlaying ? 'Verse $verseNum/${widget.totalVerses}' : 'Verse $verseNum')
                    : (widget.isPlaying ? 'Reciting' : '॥ ॐ ॥'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFE082),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Next Verse Button
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFFFD54F), size: 24),
            tooltip: 'Next Page',
            onPressed: widget.onNextPage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
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
    super.key,
    required this.granth,
    required this.granthTitle,
    required this.chapterTitle,
    required this.verses,
    required this.sepiaMode,
    required this.activeVerseIndex,
    required this.activeSection,
    required this.activeLocalWordIndex,
    required this.isPageCompleted,
    this.onPageChanged,
  });

  final Map<String, dynamic> granth;
  final String granthTitle;
  final String chapterTitle;
  final List<Map<String, String>> verses;
  final bool sepiaMode;
  final int activeVerseIndex;
  final String activeSection;
  final int activeLocalWordIndex;
  final bool isPageCompleted;
  final ValueChanged<int>? onPageChanged;

  @override
  State<_BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<_BookViewer> with TickerProviderStateMixin {
  /// Width of the visible leather spine strip on the left of the cover, in logical pixels.
  static const double _spineW = 22.0;

  /// Physical thickness of the dense hardbound cover board in logical pixels.
  /// 4.0px matches authentic, slim, elegant luxury hardbound binder's board thickness.
  static const double _boardThickness = 4.0;

  int _currentPage = 0; // 0 = Cover, 1...N = Verses, N+1 = Back Cover
  bool _isTurning = false;
  bool _turnForward = true;
  double _dragProgress = 0.0; // 0.0 to 1.0
  bool _isDragging = false;
  bool _isClosingBook = false;
  bool _isReturning = false;
  // Pending drag: touch started but no movement yet — avoids blink on hold
  bool _pendingDrag = false;

  // 2D Gesture tracking for Apple Books-style diagonal corner peel
  Offset? _dragStart;
  Offset? _dragCurrent;

  late AnimationController _turnCtrl;
  late Animation<double> _turnAnim;

  int get totalPages => widget.verses.length + 2;
  int get currentPage => _currentPage;

  @override
  void dispose() { _turnCtrl.dispose(); super.dispose(); }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_isReturning) {
        setState(() {
          _isReturning = false;
          _isTurning = false;
          _dragProgress = 0;
          _dragStart = null;
          _dragCurrent = null;
        });
        _turnCtrl.reset();
        return;
      }
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
        _isReturning = false;
        _dragProgress = 0;
        _dragStart = null;
        _dragCurrent = null;
      });
      _turnCtrl.reset();
      widget.onPageChanged?.call(_currentPage);
    } else if (status == AnimationStatus.dismissed) {
      // The drag was aborted and snapped back to 0.
      setState(() {
        _isTurning = false;
        _isReturning = false;
        _dragProgress = 0;
        _dragStart = null;
        _dragCurrent = null;
      });
    }
  }

  void autoTurnToPage(int targetPage, {int durationMs = 650}) {
    if (_currentPage == targetPage || _isTurning || _isClosingBook) return;
    if (targetPage < 0 || targetPage >= totalPages) return;
    final w = context.size?.width ?? 350;
    final h = context.size?.height ?? 600;
    _dragProgress = 0.0;
    if (targetPage > _currentPage) {
      _dragStart = Offset(w, h * 0.82); // Natural bottom-right corner peel
      _dragCurrent = _dragStart;
      _triggerTurn(forward: true, durationMs: durationMs);
    } else if (targetPage < _currentPage) {
      _dragStart = Offset(0, h * 0.82);
      _dragCurrent = _dragStart;
      _triggerTurn(forward: false, durationMs: durationMs);
    }
  }

  void _triggerTurn({required bool forward, int? durationMs}) {
    if (_isTurning || _isClosingBook) return;
    if (forward && _currentPage >= totalPages) return;
    if (!forward && _currentPage <= 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isTurning = true;
      _turnForward = forward;
      _isReturning = false;
    });

    final double startP = _dragProgress.clamp(0.0, 0.99);
    _turnAnim = Tween<double>(begin: startP, end: 1.0).animate(
      CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic),
    );

    // Dignified, physical paper inertia: cover is heavier hardbound board (640ms), inner pages (540ms)
    final bool isCoverTurn = (_currentPage == 0 && forward) || (_currentPage == 1 && !forward);
    final double remaining = (1.0 - startP).clamp(0.12, 1.0);
    final int defaultBase = isCoverTurn ? 640 : 540;
    final int duration = durationMs != null
        ? (durationMs * remaining).clamp(isCoverTurn ? 480.0 : 380.0, 720.0).toInt()
        : (defaultBase * remaining).clamp(isCoverTurn ? 480.0 : 380.0, 720.0).toInt();

    _turnCtrl.duration = Duration(milliseconds: duration);
    _turnCtrl.forward(from: 0.0);
  }

  void _triggerReturn({int? durationMs}) {
    if (_isTurning) return;
    setState(() {
      _isTurning = true;
      _isReturning = true;
    });

    final double startP = _dragProgress.clamp(0.01, 1.0);
    _turnAnim = Tween<double>(begin: startP, end: 0.0).animate(
      CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic),
    );

    final int duration = durationMs ?? (380 + (startP * 120)).clamp(360, 480).toInt();
    _turnCtrl.duration = Duration(milliseconds: duration);
    _turnCtrl.forward(from: 0.0);
  }

  void _triggerCloseBookAnimation() {
    if (_isTurning || _isClosingBook) return;
    setState(() {
      _isClosingBook = true;
      _turnForward = true; // Swings from right to left
      _isReturning = false;
    });
    _turnAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic),
    );
    _turnCtrl.duration = const Duration(milliseconds: 620);
    _turnCtrl.forward(from: 0.0);
  }

  void _onPanStart(DragStartDetails d) {
    if (_isTurning || _isClosingBook) return;
    _pendingDrag = true;
    _isDragging = false;
    _dragStart = d.localPosition;
    _dragCurrent = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isTurning) return;
    _dragCurrent = d.localPosition;
    final width = context.size?.width ?? 350;
    final dx = (_dragCurrent!.dx - (_dragStart?.dx ?? d.localPosition.dx));

    // Lock direction on first decisive horizontal movement (dx < 0 is forward, dx > 0 is reverse)
    if (!_isDragging && _pendingDrag) {
      if (dx.abs() < 5.0) return;
      final bool forward = (dx < 0);
      if (forward && _currentPage >= totalPages - 1) return;
      if (!forward && _currentPage <= 0) return;
      _isDragging = true;
      _pendingDrag = false;
      _turnForward = forward;
      _dragProgress = 0.0;
    }
    if (!_isDragging) return;

    // Smoothly calculate progress based on drag distance
    final double dragDist = _turnForward ? -dx : dx;
    final double rawProgress = (dragDist / (width * 0.82)).clamp(0.0, 1.0);
    setState(() {
      _dragProgress = rawProgress;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    _pendingDrag = false;
    if (!_isDragging) {
      _dragStart = null;
      _dragCurrent = null;
      return;
    }
    setState(() => _isDragging = false);

    final vx = d.velocity.pixelsPerSecond.dx;
    // Even if user flings/swipes fast, maintain majestic, calm, slow turning speed (560ms)
    if (vx.abs() > 200) {
      if (_turnForward) {
        if (vx < 0) {
          _triggerTurn(forward: true, durationMs: 560);
        } else {
          _triggerReturn(durationMs: 420);
        }
      } else {
        if (vx > 0) {
          _triggerTurn(forward: false, durationMs: 560);
        } else {
          _triggerReturn(durationMs: 420);
        }
      }
    } else {
      if (_dragProgress > 0.28) {
        _triggerTurn(forward: _turnForward, durationMs: 580);
      } else {
        _triggerReturn(durationMs: 420);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _turnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 580));
    _turnAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic));
    _turnCtrl.addStatusListener(_onAnimStatus);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          // Explicitly no onTapUp: Tapping on page or hardbound cover does NOT trigger turns
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: AnimatedBuilder(
            animation: _turnCtrl,
            builder: (context, _) {
              final progress = _isTurning ? _turnAnim.value : _dragProgress;
              return _build3DBookCanvas(progress, w, h);
            },
          ),
        );
      },
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
      width: w,
      height: h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0D04), Color(0xFF160602)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LeatherTexturePainter()),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25), width: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ॐ',
                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 52,
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '॥ ॐ श्री परमात्मने नमः ॥',
                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 13,
                    color: const Color(0xFFE5C158).withValues(alpha: 0.70),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadband() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B0000), // crimson red
            Color(0xFFFFD700), // gold
            Color(0xFF8B0000),
            Color(0xFFFFD700),
            Color(0xFF8B0000),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }

  Widget _build3DBookCanvas(double progress, double w, double h) {

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
    final double rightStackW = maxStackW * (1.0 - dynamicRatio);

    // Reading page leaf dimensions (sits cleanly to the right of the spine binding)
    final double leafW = w - _spineW - 4.0;
    final double leafH = h - 8.0;
    final bool isFullCoverView = (!isAnimatingOrDragging && _currentPage == 0) || isFrontCoverTurn || _isClosingBook;

    Widget content;
    if (!isAnimatingOrDragging) {
      if (_currentPage == 0) {
        content = topPage != null ? _wrapPage(0, topPage) : const SizedBox.shrink();
      } else {
        content = topPage != null ? _wrapInnerLeaf(topPageIndex, topPage) : const SizedBox.shrink();
      }
    } else if (isFrontCoverTurn || _isClosingBook) {
      content = _buildHardcoverTurningEngine(
        progress: progress,
        forward: _turnForward,
        isClosing: _isClosingBook,
        basePage: basePage,
        w: w,
        h: h,
      );
    } else {
      // ── INNER PAGES: AUTHENTIC 3D CORNER-ANCHORED DIAGONAL PAGE PEEL ENGINE ──
      content = _TruePagePeelWidget(
        progress: progress,
        forward: _turnForward,
        dragStart: _dragStart,
        dragCurrent: _dragCurrent,
        isDragging: _isDragging,
        frontPage: topPage != null ? _wrapInnerLeaf(topPageIndex, topPage) : const SizedBox.shrink(),
        basePage: basePage != null ? _wrapInnerLeaf(basePageIndex, basePage) : const SizedBox.shrink(),
        backSidePage: _wrapInnerLeaf(
          topPageIndex,
          _getInsidePage(topPageIndex, leafW, leafH) ?? (topPage ?? const SizedBox.shrink()),
        ),
        width: leafW,
        height: leafH,
      );
    }

    // Determine which page should be visible statically on the left side.
    int leftStaticIndex = _currentPage - 1;
    if (isAnimatingOrDragging && !_turnForward) {
      leftStaticIndex = _currentPage - 2;
    }
    
    final Widget? activeLeftPeekPage = _getStaticLeftPage(leftStaticIndex, w, h);
    bool showLeftPeek = activeLeftPeekPage != null && leftStaticIndex >= 0;

    // Compute spine shadow opacity: fades in as cover opens, instant on static pages
    final bool isCoverOpening = isAnimatingOrDragging && isFrontCoverTurn && _turnForward;
    final bool isCoverClosing = isAnimatingOrDragging && isFrontCoverTurn && !_turnForward;
    final double spineOpacity = showLeftPeek
        ? 1.0                              // Static: full opacity
        : (isCoverOpening ? progress       // Fades IN with the cover swing
            : (isCoverClosing ? (1.0 - progress) // Fades OUT when closing back to cover
                : 0.0));

    // Show realistic open book left binding (Image 3) when book is open or opening/closing
    final bool showOpenLeftBinding = (_currentPage >= 1 || isCoverClosing) && !_isClosingBook;
    final double leftBindingOpacity = (_currentPage >= 1 && !isClosingToCover && !isCoverClosing)
        ? 1.0
        : (isCoverOpening
            ? ((progress - 0.25) / 0.75).clamp(0.0, 1.0)
            : (isCoverClosing ? (1.0 - (progress / 0.75)).clamp(0.0, 1.0) : 0.0));

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
              left: _spineW - (w - _spineW), top: 0, bottom: 0, width: w - _spineW,
              child: _wrapInsideCoverBoard(_buildInsideCover(w - _spineW, h), w - _spineW, h),
            ),
          if (_isClosingBook)
            Positioned(
              left: 0, top: 0, bottom: 0, width: w,
              child: _wrapPage(totalPages - 1, _buildInsideCover(w, h), isLeft: false),
            ),

          // ── 0. The full left page (e.g. static inner pages) ──
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

          // ── 2. Open Book Left Side Binding (Image 3) ──
          // Renders the authentic curved spine gutter, left page stack, and center crease
          if (showOpenLeftBinding && leftBindingOpacity > 0.0)
            Positioned(
              left: 0,
              top: 4,
              bottom: 4,
              width: _spineW,
              child: Opacity(
                opacity: leftBindingOpacity,
                child: _buildOpenBookLeftBinding(_spineW, h - 8),
              ),
            ),

          // ── 3. Deep Spine Crease Shadow & Sacred Book Gutter (Image 3) ──
          if (spineOpacity > 0 && _currentPage >= 1 && !isClosingToCover && !isCoverClosing) ...[
            // Concave gutter shadow extending onto the reading page
            Positioned(
              left: _spineW,
              top: 4,
              bottom: 4,
              width: 36.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: spineOpacity.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.52),
                          Colors.black.withValues(alpha: 0.24),
                          Colors.black.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.20, 0.60, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Convex 3D Paper arch highlight catching room light (Image 3)
            Positioned(
              left: _spineW + 36.0,
              top: 4,
              bottom: 4,
              width: 18.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (spineOpacity * 0.75).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.16),
                          Colors.transparent,
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

          // ── 4. Content (The Current Page & Turning Engine) ──
          // Positioned precisely: full-screen for covers, exact leaf geometry for inner pages
          if (isFullCoverView)
            Positioned.fill(
              child: content,
            )
          else
            Positioned(
              left: _spineW,
              top: 4,
              width: leafW,
              height: leafH,
              child: content,
            ),
        ],
      ),
    );
  }

  // ── Open Book Left Binding Structure (Image 3) ──
  Widget _buildOpenBookLeftBinding(double bindW, double h) {
    return Container(
      width: bindW,
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFF1B0A03), // Hardcover casing border
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Stack(
        children: [
          // 1. Stacked pages of the left side (thickness of read pages)
          Positioned(
            left: 2.5,
            top: 2,
            bottom: 2,
            width: bindW - 5.5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5D5BA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                border: Border.all(color: const Color(0xFFBBA78B), width: 0.5),
              ),
              child: Stack(
                children: [
                  // Fore-edge paper lines
                  Positioned.fill(
                    child: CustomPaint(painter: _ForeEdgeLinesPainter(horizontal: false)),
                  ),
                  // Left page curving into the center gutter with gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEDE0CB),
                            const Color(0xFFDFCEB5),
                            const Color(0xFF8B6B48).withValues(alpha: 0.55),
                          ],
                          stops: const [0.0, 0.65, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  // Faint text lines on left curving page (like in Image 3)
                  Positioned(
                    left: 2,
                    right: 3,
                    top: 14,
                    bottom: 14,
                    child: IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          12,
                          (i) => Container(
                            height: 1.0,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C1405).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Center Binding Crease (the deep seam where left & right pages meet)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 3.5,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF260D04),
                    Color(0xFF0D0301),
                    Color(0xFF1F0903),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 3. Woven silk headband visible at head and foot of binding seam
          Positioned(
            right: 0,
            top: 0,
            width: 8,
            height: 4.5,
            child: _buildHeadband(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: 8,
            height: 4.5,
            child: _buildHeadband(),
          ),
        ],
      ),
    );
  }

  /// Wraps an inner book page leaf with authentic solid cream parchment,
  /// 100% opacity, gold foil bevel border, and ZERO outer margins so there is
  /// never any transparent gap or border during 3D page curl.
  Widget _wrapInnerLeaf(int index, Widget child) {
    final isBackCover = (index == totalPages - 1);
    final radius = Radius.circular(isBackCover ? 6 : 2);
    final borderRadius = BorderRadius.only(topRight: radius, bottomRight: radius);

    return Container(
      decoration: BoxDecoration(
        color: isBackCover ? const Color(0xFF1E0A03) : (widget.sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6)),
        borderRadius: borderRadius,
        border: isBackCover
            ? Border(
                top: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
                right: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
                bottom: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
              )
            : Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.50),
                width: 1.0,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  Widget _wrapPage(int index, Widget child, {bool isLeft = false}) {
    final isCover = (index == 0 || index == totalPages - 1);
    final radius = Radius.circular(isCover ? 6 : 2);
    final borderRadius = isLeft 
        ? BorderRadius.only(topLeft: radius, bottomLeft: radius)
        : BorderRadius.only(topRight: radius, bottomRight: radius);

    // When inside book, left margin is _spineW so readable page sits right beside the open binding
    final margin = isCover ? EdgeInsets.zero : EdgeInsets.only(
      top: 4, bottom: 4,
      left: isLeft ? 4 : _spineW,
      right: isLeft ? 0 : 4,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isCover ? const Color(0xFF1E0A03) : (widget.sepiaMode ? const Color(0xFFF9F4E8) : const Color(0xFFF3EFE6)),
        borderRadius: borderRadius,
        border: (index == 0)
            ? const Border(
                // Right fore-edge board thickness border; top/bottom edge bevels and spine headbands are rendered internally in _buildCoverFace
                right: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              )
            : (isCover
                ? Border(
                    top: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
                    right: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
                    bottom: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 2.0),
                  )
                : Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                    width: 1.0,
                  )),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLeft ? 0.20 : 0.40),
            blurRadius: isLeft ? 8 : 16,
            offset: Offset(isLeft ? -3 : 4, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, -3),
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

  // Page content rendering

  Widget? _getPage(int index, double w, double h) {
    if (index < 0 || index >= totalPages) return null;
    if (index == 0) {
      return _buildCoverFace(w, h);
    } else if (index == totalPages - 1) {
      return _BackCoverPage(
        granthName: widget.granthTitle,
        onReadAgain: () => setState(() {
          _currentPage = 0;
          widget.onPageChanged?.call(0);
        }),
        onClose: _triggerCloseBookAnimation,
      );
    } else {
      final vi = index - 1;
      final bool isThisVerseActive = (widget.activeVerseIndex == vi);
      return _VersePage(
        key: ValueKey('verse_$vi'),
        verse: widget.verses[vi],
        verseIndex: vi,
        sepiaMode: widget.sepiaMode,
        activeSection: isThisVerseActive ? widget.activeSection : '',
        activeLocalWordIndex: isThisVerseActive ? widget.activeLocalWordIndex : -1,
        isPageCompleted: isThisVerseActive ? widget.isPageCompleted : false,
      );
    }
  }

  // ── Front cover board face — deity artwork, sacred frame, vignettes, and quarter-bound leather ──
  Widget _buildFrontBoardFace(double faceW, double h) {
    final rawCover = (widget.granth['coverImage'] ?? widget.granth['image'] ?? widget.granth['cover'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(rawCover);

    Widget imageContent;
    if (resolvedUrl.startsWith('http')) {
      imageContent = Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        width: faceW,
        height: h,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _buildFallbackCoverFace(faceW, h),
      );
    } else if (rawCover.startsWith('assets/')) {
      imageContent = Image.asset(
        rawCover,
        fit: BoxFit.cover,
        width: faceW,
        height: h,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _buildFallbackCoverFace(faceW, h),
      );
    } else {
      imageContent = _buildFallbackCoverFace(faceW, h);
    }

    return SizedBox(
      width: faceW,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Authentic dark leather base board beneath artwork
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E0A03),
            ),
          ),

          // Deity Artwork (aspect ratio strictly preserved with BoxFit.cover)
          Positioned.fill(
            child: imageContent,
          ),

          // Sacred Book Inset Devotional Border & Frame
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SacredCoverFramePainter(),
              ),
            ),
          ),

          // Soft ambient edge vignette (darkens margins to focus illumination on deity)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.05),
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0.55, 0.82, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Satin specular sheen across cover board (simulates curved bound cloth/leather sheen)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.22),
                    ],
                    stops: const [0.0, 0.38, 1.0],
                    begin: const Alignment(-0.8, -1.0),
                    end: const Alignment(0.8, 1.0),
                  ),
                ),
              ),
            ),
          ),

          // Top-edge hardcover board bevel highlight (catching room light)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 2.5,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      const Color(0xFFFFE082).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Bottom-edge hardcover board bevel shadow
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 3.5,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.50),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Subtle inner hinge contact shadow
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3.0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
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
    );
  }

  // ── Cover face — 3D curved spine + physical hinge joint + front board artwork ──
  Widget _buildCoverFace(double w, double h) {
    final double faceW = w - _spineW;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Front Cover Board (Artwork & Devotional Hardcover Surface)
          Positioned(
            left: _spineW,
            top: 0,
            right: 0,
            bottom: 0,
            child: _buildFrontBoardFace(faceW, h),
          ),

          // 2. Left 3D Curved Leather Spine (Static Left Depth Edge)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _spineW,
            child: _buildSpineStrip(_spineW, h),
          ),

          // 3. The French Groove (Hinge Joint Indentation)
          Positioned(
            left: _spineW - 2.0,
            top: 0,
            bottom: 0,
            width: 4.0,
            child: _buildFrenchGroove(),
          ),
        ],
      ),
    );
  }

  // ── The French Groove (Hinge Joint Indentation) ──
  Widget _buildFrenchGroove() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF150502).withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.95), // Deep trough
              Colors.black.withValues(alpha: 0.95),
              const Color(0xFFFFF3D0).withValues(alpha: 0.65), // Board shoulder highlight
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.55, 0.80, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Widget _wrapCoverBoard(Widget child, double boardW, double h) {
    const radius = Radius.circular(6);
    const borderRadius = BorderRadius.only(topRight: radius, bottomRight: radius);

    return Container(
      width: boardW,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E0A03),
        borderRadius: borderRadius,
        border: const Border(
          right: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(4, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  Widget _wrapInsideCoverBoard(Widget child, double boardW, double h) {
    const radius = Radius.circular(6);
    const borderRadius = BorderRadius.only(topRight: radius, bottomRight: radius);

    return Container(
      width: boardW,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E0A03),
        borderRadius: borderRadius,
        border: const Border(
          right: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  // ── 3D Hardcover Turning Engine (Realistic Thickness, Connected Hinge, Dynamic Shadow) ──
  Widget _buildHardcoverTurningEngine({
    required double progress,
    required bool forward,
    required bool isClosing,
    required Widget? basePage,
    required double w,
    required double h,
  }) {
    // 1. Turn angle: 0.0 (closed) to pi (fully open)
    final double turnAngle = isClosing
        ? (progress * math.pi)
        : (forward ? (progress * math.pi) : ((1.0 - progress) * math.pi));

    final double sineAngle = math.sin(turnAngle);
    final double cosAngle = math.cos(turnAngle);
    final bool isFrontVisible = turnAngle <= (math.pi / 2);
    final double boardW = w - _spineW;
    final double leafW = w - _spineW - 4.0;
    final double leafH = h - 8.0;
    final double normalizedOpen = (turnAngle / math.pi).clamp(0.0, 1.0);
    final double leftBindingFade = ((normalizedOpen - 0.25) / 0.75).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── A. Underneath Page (Verse 1) with Authentic Cream Parchment & Borders ──
        if (basePage != null && !isClosing) ...[
          // Stack of read pages on the right
          if (w - 12 > 0)
            Positioned(
              left: w - 12,
              top: 12,
              bottom: 12,
              width: 10.0,
              child: _buildRightPageStack(),
            ),

          // Verse 1 reading leaf (positioned at exact coordinates of static Verse 1)
          Positioned(
            left: _spineW,
            top: 4,
            width: leafW,
            height: leafH,
            child: _wrapInnerLeaf(1, basePage),
          ),

          // Open book left binding (fades in as cover swings open)
          if (leftBindingFade > 0.0)
            Positioned(
              left: 0,
              top: 4,
              bottom: 4,
              width: _spineW,
              child: Opacity(
                opacity: leftBindingFade,
                child: _buildOpenBookLeftBinding(_spineW, leafH),
              ),
            ),

          // Spine gutter shadow & arch highlight matching static reading layout
          if (leftBindingFade > 0.0) ...[
            Positioned(
              left: _spineW,
              top: 4,
              bottom: 4,
              width: 36.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: leftBindingFade,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.52),
                          Colors.black.withValues(alpha: 0.24),
                          Colors.black.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.20, 0.60, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _spineW + 36.0,
              top: 4,
              bottom: 4,
              width: 18.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: leftBindingFade * 0.75,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.16),
                          Colors.transparent,
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

          // Dynamic cast shadow from the swinging cover board onto Verse 1
          if (sineAngle > 0.01)
            Positioned(
              left: _spineW,
              top: 4,
              bottom: 4,
              right: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: (0.46 * sineAngle).clamp(0.0, 0.50)),
                        Colors.black.withValues(alpha: (0.18 * sineAngle).clamp(0.0, 0.22)),
                        Colors.black.withValues(alpha: (0.04 * sineAngle).clamp(0.0, 0.06)),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.20, 0.60, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
        ],

        // ── B. The Rigid Hardcover Board (Swings around hinge at X = _spineW) ──
        Positioned(
          left: _spineW,
          top: 0,
          bottom: 0,
          width: boardW,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0004)
              ..rotateY(turnAngle),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Inside Cover (facing viewer when turned past 90°)
                if (!isFrontVisible)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(0, 0, -1.0)
                      ..setTranslationRaw(0.0, 0.0, -_boardThickness),
                    child: _wrapInsideCoverBoard(_buildInsideCover(boardW, h), boardW, h),
                  ),

                // 2. Front Cover Board Face (Artwork & Sacred Frame, visible 0° to 90°)
                if (isFrontVisible)
                  Stack(
                    children: [
                      _wrapCoverBoard(_buildFrontBoardFace(boardW, h), boardW, h),
                      // Ambient tilt darkening on front face
                      if (sineAngle > 0.01)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: (0.10 * sineAngle).clamp(0.0, 0.20)),
                                    Colors.white.withValues(alpha: (0.12 * sineAngle).clamp(0.0, 0.20)),
                                    Colors.black.withValues(alpha: (0.28 * sineAngle).clamp(0.0, 0.40)),
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
                  ),
              ],
            ),
          ),
        ),

        // ── C. 3D HARDCOVER FORE-EDGE THICKNESS SLAB ──
        if (sineAngle > 0.01)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _Hardcover3DEdgesPainter(
                  hingeX: _spineW,
                  boardW: boardW,
                  thickness: _boardThickness,
                  height: h,
                  turnAngle: turnAngle,
                  sineAngle: sineAngle,
                  cosAngle: cosAngle,
                  isFrontVisible: isFrontVisible,
                ),
              ),
            ),
          ),

        // ── D. STATIC LEFT SPINE DEPTH EDGE & FRENCH GROOVE ──
        if (leftBindingFade < 1.0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _spineW,
            child: Opacity(
              opacity: (1.0 - leftBindingFade).clamp(0.0, 1.0),
              child: _buildSpineStrip(_spineW, h),
            ),
          ),

        Positioned(
          left: _spineW - 2.0,
          top: 0,
          bottom: 0,
          width: 4.0,
          child: _buildFrenchGroove(),
        ),
      ],
    );
  }


  // ── Fallback cover face (used when no cover image is available) ────────────
  Widget _buildFallbackCoverFace(double faceW, double h) {
    return Container(
      width: faceW,
      height: h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A1A06), Color(0xFF1E0A03), Color(0xFF381406)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LeatherTexturePainter())),
          Positioned.fill(child: CustomPaint(painter: _SacredCoverFramePainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF1E0A03).withValues(alpha: 0.6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_stories_rounded, color: Color(0xFFD4AF37), size: 56),
                      const SizedBox(height: 16),
                      Text(widget.granthTitle, textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerifDevanagari(
                              fontSize: 22, fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700), height: 1.3)),
                      const SizedBox(height: 10),
                      Text('❖ ──── ॐ ──── ❖',
                          style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(widget.chapterTitle, textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                              fontSize: 13, fontWeight: FontWeight.w600)),
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

  // ── Spine strip — realistic antique leather binding on the left of the closed cover ──
  Widget _buildSpineStrip(double spineW, double h) {
    return Container(
      width: spineW,
      height: h,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
        // Cylindrical barrel gradient: curvature turns away on the left, crowns at ~28%, falls off into the French groove
        gradient: const LinearGradient(
          colors: [
            Color(0xFF140502), // Outer curvature rim receding into shadow
            Color(0xFF260C05), // Turning into light
            Color(0xFF6B260D), // Rising leather shoulder
            Color(0xFF8C3312), // Apex crown of cylindrical spine (at 28%)
            Color(0xFF63220A), // Warm mahogany leather
            Color(0xFF3D1405), // Leather flank
            Color(0xFF1F0802), // Entering French groove
            Color(0xFF0C0301), // Bottom of French groove
          ],
          stops: [0.0, 0.08, 0.20, 0.30, 0.45, 0.70, 0.88, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // 1. Organic leather pebble grain micro-texture
          Positioned.fill(
            child: CustomPaint(painter: _LeatherTexturePainter()),
          ),

          // 2. Curvature specular gleam (vertical highlight beam along the spine crown)
          Positioned(
            left: spineW * 0.15,
            top: 0,
            bottom: 0,
            width: spineW * 0.35,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.18),
                      const Color(0xFFFFE082).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.40, 0.70, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // 3. Five raised leather ribs (spine bands / sewing cord ridges)
          Positioned.fill(
            child: CustomPaint(
              painter: _SpineRibsPainter(),
            ),
          ),

          // 4. Headband (woven silk crimson & gold endband at the top)
          Positioned(
            left: 1,
            right: 0,
            top: 0,
            height: 4.0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(3)),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B0000),
                      Color(0xFFFFD700),
                      Color(0xFF8B0000),
                      Color(0xFFFFD700),
                      Color(0xFF8B0000),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Footband (woven silk crimson & gold endband at the bottom)
          Positioned(
            left: 1,
            right: 0,
            bottom: 0,
            height: 4.0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(3)),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B0000),
                      Color(0xFFFFD700),
                      Color(0xFF8B0000),
                      Color(0xFFFFD700),
                      Color(0xFF8B0000),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 3,
                      offset: const Offset(0, -1.5),
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

}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS & PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

/// Paints the 3D multi-ply binder's board edges (fore-edge, top head-edge, bottom tail-edge)
/// with exact perspective vertex projection ($d = 0.0010$) matching the 3D cover board.
/// This ensures the thick hardbound edges are permanently locked to the board faces
/// with zero gaps, zero drift, and full physical volume.
class _Hardcover3DEdgesPainter extends CustomPainter {
  final double hingeX;
  final double boardW;
  final double thickness;
  final double height;
  final double turnAngle;
  final double sineAngle;
  final double cosAngle;
  final bool isFrontVisible;

  const _Hardcover3DEdgesPainter({
    required this.hingeX,
    required this.boardW,
    required this.thickness,
    required this.height,
    required this.turnAngle,
    required this.sineAngle,
    required this.cosAngle,
    required this.isFrontVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sineAngle < 0.005) return;

    final double h = height;
    final double edgeW = (thickness * sineAngle).clamp(1.0, thickness);

    // Projected outer edge position along X axis in root coordinates with matching 3D perspective
    final double scale = 1.0 / (1.0 - (boardW * sineAngle * 0.0004));
    final double outerEdgeX = hingeX + boardW * cosAngle * scale;

    // Fore-edge thickness slab: attached to the outer edge of the swinging cover board
    final double leftX = isFrontVisible ? outerEdgeX : (outerEdgeX - edgeW);
    final double rightX = leftX + edgeW;

    final rect = Rect.fromLTRB(leftX, 0, rightX, h);

    // 1. Multi-ply dense binder's board cross-section gradient
    final forePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(leftX, 0),
        Offset(rightX, 0),
        [
          const Color(0xFFFFD54F), // Front gold foil bevel rim
          const Color(0xFF2C1006), // Front leather turn-in fold
          const Color(0xFF4A1E0D), // Outer binder board ply
          const Color(0xFF1A0802), // Dense dark core binder board
          const Color(0xFF4A1E0D), // Inner binder board ply
          const Color(0xFF240B03), // Inside leather turn-in
          const Color(0xFFD4AF37), // Inside gold edge trim
        ],
        [0.0, 0.15, 0.32, 0.50, 0.68, 0.85, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, forePaint);

    // 2. Fine horizontal grain lines of the multi-ply binder board
    if (edgeW > 2.0) {
      final plyPaint = Paint()
        ..color = const Color(0xFF1E0A03).withValues(alpha: 0.35)
        ..strokeWidth = 0.5;
      for (double y = 4.0; y < h; y += 8.0) {
        canvas.drawLine(Offset(leftX + 0.5, y), Offset(rightX - 0.5, y), plyPaint);
      }
    }

    // 3. Center gilded fillet line running down the edge slab
    final goldFoilPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: (0.85 * sineAngle).clamp(0.0, 0.90))
      ..strokeWidth = 0.7;
    final double centerX = (leftX + rightX) / 2.0;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, h), goldFoilPaint);

    // 4. Dynamic ambient specular sheen across the fore-edge slab
    final sheenPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX, 0),
        Offset(centerX, h),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: (0.25 * sineAngle).clamp(0.0, 0.35)),
          Colors.transparent,
        ],
        [0.15, 0.50, 0.85],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, sheenPaint);

    // 5. Outer edge border lines for crisp definition
    final edgeBorderPaint = Paint()
      ..color = const Color(0xFFB59350).withValues(alpha: (0.75 * sineAngle).clamp(0.0, 0.80))
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, h), edgeBorderPaint);
    canvas.drawLine(Offset(rightX, 0), Offset(rightX, h), edgeBorderPaint);

    // 6. Top & bottom gilded end-caps (closing the top and bottom of the 4px slab)
    final capPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: (0.80 * sineAngle).clamp(0.0, 0.85))
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(leftX, 0), Offset(rightX, 0), capPaint);
    canvas.drawLine(Offset(leftX, h), Offset(rightX, h), capPaint);
  }

  @override
  bool shouldRepaint(covariant _Hardcover3DEdgesPainter oldDelegate) {
    return oldDelegate.turnAngle != turnAngle ||
        oldDelegate.boardW != boardW ||
        oldDelegate.height != height;
  }
}

class _ForeEdgeLinesPainter extends CustomPainter {
  _ForeEdgeLinesPainter({required this.horizontal});
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBA78B).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    if (horizontal) {
      for (double y = 4; y < size.height; y += 3) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      for (double x = 4; x < size.width; x += 3) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LeatherTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final finePebblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final shadowPebblePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Cross-hatch micro-grain to simulate morocco goatskin / calfskin texture
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 3), finePebblePaint);
    }
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(size.width, y), Offset(0, y + 3), shadowPebblePaint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _SpineRibsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 5 raised sewing cords / spine ribs
    const ribPositions = [0.10, 0.28, 0.50, 0.72, 0.90];
    const double ribH = 4.5;

    final topHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final bottomShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final goldLinePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.85)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    for (final relY in ribPositions) {
      final y = size.height * relY;
      final rect = Rect.fromLTWH(0, y - ribH / 2, size.width, ribH);

      // Raised ridge 3D cylindrical convex gradient
      final ribPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF140401),
            Color(0xFF5A1E0A),
            Color(0xFF8B3312),
            Color(0xFF5A1E0A),
            Color(0xFF140401),
          ],
          stops: [0.0, 0.20, 0.40, 0.75, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect);

      canvas.drawRect(rect, ribPaint);

      // Top light-catching specular line
      canvas.drawLine(Offset(1, y - ribH / 2 + 0.3), Offset(size.width, y - ribH / 2 + 0.3), topHighlightPaint);

      // Dual gold fillet tooling (top and bottom fine gold hot-stamped lines)
      canvas.drawLine(Offset(2, y - 0.9), Offset(size.width - 1, y - 0.9), goldLinePaint);
      canvas.drawLine(Offset(2, y + 0.9), Offset(size.width - 1, y + 0.9), goldLinePaint);

      // Bottom deep cast shadow onto spine leather below
      canvas.drawLine(Offset(0, y + ribH / 2), Offset(size.width, y + ribH / 2), bottomShadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SacredCoverFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double margin = 10.0;
    final outerRect = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);
    if (outerRect.width <= 0 || outerRect.height <= 0) return;

    final outerGoldPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.70)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final innerGoldPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.50)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw outer fine gold rectangle
    canvas.drawRect(outerRect, outerGoldPaint);

    // Draw inner fine gold rectangle (inset 3.5px)
    final innerRect = outerRect.deflate(3.5);
    if (innerRect.width > 0 && innerRect.height > 0) {
      canvas.drawRect(innerRect, innerGoldPaint);
    }

    // Corner decorative bracket flourishes at 4 corners
    const double bracketLen = 14.0;
    final cornerFlourishPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Top-Left corner bracket
    canvas.drawLine(Offset(outerRect.left - 2, outerRect.top + bracketLen), Offset(outerRect.left - 2, outerRect.top - 2), cornerFlourishPaint);
    canvas.drawLine(Offset(outerRect.left - 2, outerRect.top - 2), Offset(outerRect.left + bracketLen, outerRect.top - 2), cornerFlourishPaint);

    // Top-Right corner bracket
    canvas.drawLine(Offset(outerRect.right + 2, outerRect.top + bracketLen), Offset(outerRect.right + 2, outerRect.top - 2), cornerFlourishPaint);
    canvas.drawLine(Offset(outerRect.right + 2, outerRect.top - 2), Offset(outerRect.right - bracketLen, outerRect.top - 2), cornerFlourishPaint);

    // Bottom-Left corner bracket
    canvas.drawLine(Offset(outerRect.left - 2, outerRect.bottom - bracketLen), Offset(outerRect.left - 2, outerRect.bottom + 2), cornerFlourishPaint);
    canvas.drawLine(Offset(outerRect.left - 2, outerRect.bottom + 2), Offset(outerRect.left + bracketLen, outerRect.bottom + 2), cornerFlourishPaint);

    // Bottom-Right corner bracket
    canvas.drawLine(Offset(outerRect.right + 2, outerRect.bottom - bracketLen), Offset(outerRect.right + 2, outerRect.bottom + 2), cornerFlourishPaint);
    canvas.drawLine(Offset(outerRect.right + 2, outerRect.bottom + 2), Offset(outerRect.right - bracketLen, outerRect.bottom + 2), cornerFlourishPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─────────────────────────────────────────────────────────────────────────────
// VERSE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _VersePage extends StatefulWidget {
  const _VersePage({
    super.key,
    required this.verse,
    required this.verseIndex,
    required this.sepiaMode,
    required this.activeSection,
    required this.activeLocalWordIndex,
    this.isPageCompleted = false,
  });

  final Map<String, String> verse;
  final int verseIndex;
  final bool sepiaMode;
  final String activeSection; // 'sanskrit', 'transliteration', 'hindi', 'english', or ''
  final int activeLocalWordIndex; // -1 if none
  final bool isPageCompleted;

  @override
  State<_VersePage> createState() => _VersePageState();
}

class _VersePageState extends State<_VersePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hindiKey = GlobalKey();
  final GlobalKey _englishKey = GlobalKey();

  @override
  void didUpdateWidget(covariant _VersePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeSection != oldWidget.activeSection) {
      if (widget.activeSection == 'sanskrit' || widget.activeSection == 'transliteration') {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
        }
      } else if (widget.activeSection == 'hindi') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hindiKey.currentContext != null) {
            Scrollable.ensureVisible(
              _hindiKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
        });
      } else if (widget.activeSection == 'english') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_englishKey.currentContext != null) {
            Scrollable.ensureVisible(
              _englishKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Builds rich text that highlights purely the text itself without any background box or container.
  /// Also marks already-read words in a warm sacred tone and fully highlights all text when the page is completed.
  Widget _buildKaraokeText(String text, TextStyle baseStyle, String sectionName) {
    if (text.isEmpty) return const SizedBox.shrink();
    final wordPattern = RegExp(r'[^\s।॥\n\r,.:;!?]+');
    final matches = wordPattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

    final isSectionActive = (widget.activeSection == sectionName);
    final isPageComplete = widget.isPageCompleted;

    const sectionOrder = ['sanskrit', 'transliteration', 'hindi', 'english'];
    final currentSectionIdx = sectionOrder.indexOf(widget.activeSection);
    final thisSectionIdx = sectionOrder.indexOf(sectionName);
    final bool isPastSection = currentSectionIdx > thisSectionIdx && currentSectionIdx != -1;

    // If section hasn't started and page is not completed, render base style
    if (!isSectionActive && !isPastSection && !isPageComplete) {
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

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

      final isHighlighted = isSectionActive && (i == widget.activeLocalWordIndex);
      final isWordRead = isPageComplete || isPastSection || (isSectionActive && i < widget.activeLocalWordIndex);
      final wordStr = m.group(0)!;

      if (isHighlighted) {
        // Pure text highlight without background box - glowing sacred saffron
        spans.add(TextSpan(
          text: wordStr,
          style: baseStyle.copyWith(
            color: const Color(0xFFE65100), // Vibrant sacred saffron
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.75),
                blurRadius: 8,
              ),
              Shadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                blurRadius: 3,
              ),
            ],
          ),
        ));
      } else if (isWordRead) {
        // Completed/read word - warm sacred terracotta/amber tone
        spans.add(TextSpan(
          text: wordStr,
          style: baseStyle.copyWith(
            color: const Color(0xFFA04000), // Rich warm amber text
            fontWeight: FontWeight.w700,
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
    final bodyColor = widget.sepiaMode ? const Color(0xFF332014) : const Color(0xFF261910);
    final sanskritText = (widget.verse['sanskrit'] ?? '').trim();
    final transliterationText = (widget.verse['transliteration'] ?? '').trim();
    String rawEnglish = (widget.verse['english'] ?? '').trim();
    String rawHindi = (widget.verse['hindi'] ?? '').trim();

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
                    controller: _scrollController,
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

                          // Reading indicator pill — shows current active recitation section
                          if (!widget.isPageCompleted && widget.activeLocalWordIndex >= 0)
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
                                  const Icon(Icons.auto_stories_rounded, size: 11, color: Color(0xFFD55F00)),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.activeSection == 'sanskrit'
                                        ? 'श्लोक पाठ'
                                        : (widget.activeSection == 'transliteration'
                                            ? 'उच्चारण पाठ'
                                            : (widget.activeSection == 'hindi' ? 'भावार्थ पाठ' : 'English Translation')),
                                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFD55F00), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          Text('Verse ${widget.verseIndex + 1}',
                              style: GoogleFonts.outfit(color: const Color(0xFF8B6048), fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 14),

                          // ── Sanskrit Text ──
                          if (sanskritText.isNotEmpty) ...[
                            _buildKaraokeText(
                              sanskritText,
                              sanskritBaseStyle,
                              'sanskrit',
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Transliteration ──
                          if (transliterationText.isNotEmpty) ...[
                            _buildKaraokeText(
                              transliterationText,
                              GoogleFonts.outfit(fontSize: 14, height: 1.6, color: bodyColor.withValues(alpha: 0.85), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                              'transliteration',
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Hindi Meaning (भावार्थ) ──
                          if (rawHindi.isNotEmpty) ...[
                            Container(
                              key: _hindiKey,
                              child: _divider('भावार्थ', devanagari: true),
                            ),
                            const SizedBox(height: 8),
                            _buildKaraokeText(
                              rawHindi,
                              GoogleFonts.notoSerifDevanagari(fontSize: 16, height: 1.7, color: bodyColor.withValues(alpha: 0.95), fontWeight: FontWeight.w500),
                              'hindi',
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── English Translation ──
                          if (rawEnglish.isNotEmpty) ...[
                            Container(
                              key: _englishKey,
                              child: _divider('English Translation'),
                            ),
                            const SizedBox(height: 8),
                            _buildKaraokeText(
                              rawEnglish,
                              GoogleFonts.outfit(fontSize: 14.5, height: 1.65, color: bodyColor.withValues(alpha: 0.92), fontWeight: FontWeight.w500),
                              'english',
                            ),
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
// AUTHENTIC 3D DIAGONAL CORNER PAGE PEEL ENGINE
// Peels dynamically from the exact corner or edge touched by the user.
// Grab near top-right/top-left: top corner peels first across diagonal.
// ─────────────────────────────────────────────────────────────────────────────
// MASTERCLASS 3D CORNER-ANCHORED PAGE PEEL ENGINE
// ─────────────────────────────────────────────────────────────────────────────
// Features:
// 1. Top-Right / Top-Left Grab: Picks up the top corner first. Top corner peels
//    diagonally downward while bottom corner stays anchored initially.
// 2. Bottom-Right / Bottom-Left Grab: Picks up the bottom corner first. Bottom
//    corner peels diagonally upward while top corner stays anchored initially.
// 3. Middle Grab: Rolls the page uniformly in a majestic cylindrical curl.
// 4. Exact 3D reflection across the arbitrary diagonal fold line using
//    coordinate alignment matrices (T * Rz * Ry * Rz * T) for 100% seam continuity.
// 5. Symmetric for both Forward (Right-to-Left) and Reverse (Left-to-Right) turns.
// ─────────────────────────────────────────────────────────────────────────────
class _TruePagePeelWidget extends StatelessWidget {
  const _TruePagePeelWidget({
    required this.progress, // 0.0 to 1.0
    required this.forward,  // true = right-to-left, false = left-to-right
    required this.dragStart,
    required this.dragCurrent,
    required this.isDragging,
    required this.frontPage,
    required this.basePage,
    required this.backSidePage,
    required this.width,
    required this.height,
  });

  final double progress;
  final bool forward;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final bool isDragging;
  final Widget frontPage;
  final Widget basePage;
  final Widget backSidePage;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double clampedP = progress.clamp(0.0, 1.0);
    if (clampedP <= 0.001 && !isDragging) {
      return SizedBox(
        width: width,
        height: height,
        child: forward ? frontPage : basePage,
      );
    }
    if (clampedP >= 0.999 && !isDragging) {
      return SizedBox(
        width: width,
        height: height,
        child: forward ? basePage : frontPage,
      );
    }

    // 1. Physical Touch-Origin Zone Detection along height
    final double touchY = dragStart?.dy ?? (height * 0.5);
    final double normY = ((touchY - height * 0.5) / (height * 0.5)).clamp(-1.0, 1.0);

    // 2. Corner Lead & Lag Physics
    // Zone A (Top): normY < -0.18 -> Top corner peels first, bottom lags
    // Zone B (Bottom): normY > 0.18 -> Bottom corner peels first, top lags
    // Zone C (Middle): |normY| <= 0.18 -> Balanced cylindrical curl
    double pTop = clampedP;
    double pBottom = clampedP;

    if (normY < -0.18) {
      final double strength = ((-normY - 0.18) / 0.82).clamp(0.0, 1.0);
      final double bias = 0.36 * (0.35 + 0.65 * strength) * math.sin(clampedP * math.pi);
      pTop = (clampedP + bias).clamp(0.0, 1.0);
      pBottom = (clampedP - bias).clamp(0.0, 1.0);
    } else if (normY > 0.18) {
      final double strength = ((normY - 0.18) / 0.82).clamp(0.0, 1.0);
      final double bias = 0.36 * (0.35 + 0.65 * strength) * math.sin(clampedP * math.pi);
      pBottom = (clampedP + bias).clamp(0.0, 1.0);
      pTop = (clampedP - bias).clamp(0.0, 1.0);
    } else {
      pTop = clampedP;
      pBottom = clampedP;
    }

    // 3. Crease Fold Coordinates
    // Forward (Right-to-Left): fold sweeps from width (p=0) to 0 (p=1)
    // Reverse (Left-to-Right): fold sweeps from 0 (p=0) to width (p=1)
    final double fTop    = forward ? width * (1.0 - pTop)    : width * pTop;
    final double fBottom = forward ? width * (1.0 - pBottom) : width * pBottom;
    final double fMid = (fTop + fBottom) * 0.5;

    // Angle of diagonal fold line relative to vertical
    final double foldAngle = math.atan2(fBottom - fTop, height);

    // 4. 3D Curl Matrices
    final double curlLift = math.sin(clampedP * math.pi) * 0.26;
    final double curlAngle = math.pi - curlLift;

    final Matrix4 forwardFlapMatrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(fMid, height * 0.5, 0.0))
      ..rotateZ(-foldAngle)
      ..setEntry(3, 2, 0.0012)
      ..rotateY(curlAngle)
      ..rotateZ(foldAngle)
      ..multiply(Matrix4.translationValues(-fMid, -height * 0.5, 0.0));

    final Matrix4 reverseFlapMatrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(fMid, height * 0.5, 0.0))
      ..rotateZ(-foldAngle)
      ..setEntry(3, 2, 0.0012)
      ..rotateY(-curlAngle)
      ..rotateZ(foldAngle)
      ..multiply(Matrix4.translationValues(-fMid, -height * 0.5, 0.0));

    return ClipRect(
      clipper: _PeelOverflowClipper(width: width, height: height),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. Base Layer (Page underneath) ──
          // Forward: basePage is visible everywhere underneath the peeling page.
          // Reverse: basePage is visible to the RIGHT of the fold line (x > foldLine).
          Positioned.fill(
            child: forward
                ? basePage
                : ClipPath(
                    clipper: _DiagonalClipper(
                      fTop: fTop,
                      fBottom: fBottom,
                      isLeftPortion: false,
                    ),
                    child: SizedBox(width: width, height: height, child: basePage),
                  ),
          ),

          // ── 2. Crease Drop Shadow onto basePage ──
          if (clampedP > 0.01 && clampedP < 0.99)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DiagonalCreaseShadowPainter(
                    fTop: fTop,
                    fBottom: fBottom,
                    forward: forward,
                    opacity: (0.45 * math.sin(clampedP * math.pi)).clamp(0.0, 0.48),
                  ),
                ),
              ),
            ),

          // ── 3. Flat Portion of frontPage ──
          // Forward: flat on the LEFT of crease (x < foldLine).
          // Reverse: flat on the LEFT of crease (x < foldLine) as previous page unrolls.
          ClipPath(
            clipper: _DiagonalClipper(
              fTop: fTop,
              fBottom: fBottom,
              isLeftPortion: true,
            ),
            child: SizedBox(width: width, height: height, child: frontPage),
          ),

          // ── 3.5 Dynamic soft drop shadow under the airborne flap extending over the spine gutter ──
          if (clampedP > 0.01 && clampedP < 0.99)
            Transform(
              transform: forward ? forwardFlapMatrix : reverseFlapMatrix,
              child: ClipPath(
                clipper: _DiagonalClipper(
                  fTop: fTop,
                  fBottom: fBottom,
                  isLeftPortion: false,
                ),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: (0.35 * math.sin(clampedP * math.pi)).clamp(0.0, 0.38)),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(-8, 5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── 4. Airborne 3D Flap ──
          if (clampedP > 0.01 && clampedP < 0.99)
            Transform(
              transform: forward ? forwardFlapMatrix : reverseFlapMatrix,
              child: ClipPath(
                clipper: _DiagonalClipper(
                  fTop: fTop,
                  fBottom: fBottom,
                  isLeftPortion: false,
                ),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      // Back of the page (100% solid, fully opaque parchment)
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..setEntry(0, 0, -1.0),
                        child: backSidePage,
                      ),
                      // Specular sheen & bend shadow
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.45 * math.sin(clampedP * math.pi)),
                                  Colors.black.withValues(alpha: 0.30 * math.sin(clampedP * math.pi)),
                                ],
                                stops: const [0.0, 0.70, 1.0],
                                begin: forward ? Alignment.centerLeft : Alignment.centerRight,
                                end: forward ? Alignment.centerRight : Alignment.centerLeft,
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
}

/// Allows the curled page flap to cross over the spine gutter and swing onto the left side (-width to width)
/// without getting clipped by local widget bounds, while constraining vertical extent to the book canvas.
class _PeelOverflowClipper extends CustomClipper<Rect> {
  const _PeelOverflowClipper({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(-width, -8.0, width * 2.0 + 16.0, height + 16.0);
  }

  @override
  bool shouldReclip(covariant _PeelOverflowClipper oldClipper) =>
      oldClipper.width != width || oldClipper.height != height;
}

// ── Clipper along the diagonal fold line with 0.8px antialiasing bleed ──
class _DiagonalClipper extends CustomClipper<Path> {
  const _DiagonalClipper({
    required this.fTop,
    required this.fBottom,
    required this.isLeftPortion,
  });

  final double fTop;
  final double fBottom;
  final bool isLeftPortion;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double xt = fTop.clamp(0.0, w);
    final double xb = fBottom.clamp(0.0, w);

    if (isLeftPortion) {
      path.moveTo(0, 0);
      path.lineTo(xt + 0.8, 0);
      path.lineTo(xb + 0.8, h);
      path.lineTo(0, h);
      path.close();
    } else {
      path.moveTo(xt - 0.8, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(xb - 0.8, h);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) =>
      oldClipper.fTop != fTop ||
      oldClipper.fBottom != fBottom ||
      oldClipper.isLeftPortion != isLeftPortion;
}

// ── Dynamic soft drop shadow painter following the diagonal crease ──
class _DiagonalCreaseShadowPainter extends CustomPainter {
  const _DiagonalCreaseShadowPainter({
    required this.fTop,
    required this.fBottom,
    required this.forward,
    required this.opacity,
  });

  final double fTop;
  final double fBottom;
  final bool forward;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final double w = size.width;
    final double h = size.height;
    final double xt = fTop.clamp(0.0, w);
    final double xb = fBottom.clamp(0.0, w);
    const double shadowWidth = 42.0;

    final Path shadowPath = Path();
    shadowPath.moveTo(xt, 0);
    shadowPath.lineTo(math.min(w, xt + shadowWidth), 0);
    shadowPath.lineTo(math.min(w, xb + shadowWidth), h);
    shadowPath.lineTo(xb, h);
    shadowPath.close();

    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: opacity),
          Colors.black.withValues(alpha: opacity * 0.40),
          Colors.black.withValues(alpha: opacity * 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.65, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTRB(
        math.min(xt, xb),
        0,
        math.max(xt, xb) + shadowWidth,
        h,
      ));

    canvas.drawPath(shadowPath, paint);
  }

  @override
  bool shouldRepaint(_DiagonalCreaseShadowPainter old) =>
      old.fTop != fTop ||
      old.fBottom != fBottom ||
      old.forward != forward ||
      old.opacity != opacity;
}
