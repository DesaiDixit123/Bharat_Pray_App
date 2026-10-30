import 'dart:io';
import 'dart:async';

import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/tts_service.dart';
import '../../services/user_verse_recording_service.dart';
import '../../widgets/granth/granth_voice_selector_sheet.dart';
import '../../widgets/granth/record_verse_voice_sheet.dart';

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
  State<GranthChapterReaderScreen> createState() =>
      _GranthChapterReaderScreenState();
}

class _VersePhrase {
  final String spokenText;
  final String delimiter;
  final List<int> wordIndices;
  final List<int> wordStarts;
  final List<int> relativeOffsetsMs;
  final int totalDurationMs;
  final int pauseMs;

  _VersePhrase({
    required this.spokenText,
    required this.delimiter,
    required this.wordIndices,
    required this.wordStarts,
    required this.relativeOffsetsMs,
    required this.totalDurationMs,
    required this.pauseMs,
  });
}

class _VerseSection {
  final String section; // 'sanskrit', 'transliteration', 'hindi', 'english'
  final String displayText;
  final List<String> words;
  final List<_VersePhrase> phrases;
  final String langCode;

  _VerseSection({
    required this.section,
    required this.displayText,
    required this.words,
    required this.phrases,
    required this.langCode,
  });
}

class _GranthChapterReaderScreenState extends State<GranthChapterReaderScreen> {
  List<Map<String, String>> _verses = [];
  bool _isLoadingPages = true;
  final bool _sepiaMode = true;
  int _currentPage = 0;
  int _targetPage = 0;
  final GlobalKey<_BookViewerState> _bookViewerKey =
      GlobalKey<_BookViewerState>();

  // Audio Playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _verseAudioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();
  bool _isPlaying = false;
  String? _audioUrl;
  bool _isLoadingAudio = false;
  double _speedMultiplier = 1.0;
  int _readingSpeedMs = 600;

  // TTS engine
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;
  String _ttsLang = 'hi-IN';

  // Section-by-section continuous speech & lockstep highlight synchronization
  String _activeSection = '';
  int _currentLocalWord = -1;
  int _currentSectionIndex = 0;
  List<_VerseSection> _activeVerseSections = [];
  int _speechLoopSession = 0;
  Completer<void>? _wordCompleter;
  VoidCallback? _ttsPhraseStartCallback;
  void Function(int startOffset)? _ttsPhraseProgressCallback;

  Timer? _wordTimer;
  Timer? _paceTicker;
  Timer? _transitionTimer;
  bool _isAutoTurning = false;
  bool _isPageCompleted = false;

  StreamSubscription? _completeSub;
  bool _isFullScreen = false;

  // My Voice Recording
  final UserVerseRecordingService _userRecordingService =
      UserVerseRecordingService();
  Map<int, String> _chapterUserRecordings = {};
  String? _currentChapterId;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadChapterPagesAndVerses();
    _initAudioListeners();
    _initTts();
  }

  void _initAudioListeners() {
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted && _isPlaying && _audioUrl != null) {
        _audioPlayer.play(UrlSource(_audioUrl!));
      }
    });
  }

  /// Active section on the currently displayed verse ('sanskrit', 'transliteration', 'hindi', 'english', or '')
  String get activeSection {
    if (!_isPlaying || _currentPage < 1 || _currentPage > _verses.length) {
      return '';
    }
    return _activeSection;
  }

  /// Active word index within its section (-1 if not highlighting)
  int get activeLocalWordIndex {
    if (!_isPlaying || _currentPage < 1 || _currentPage > _verses.length) {
      return -1;
    }
    return _currentLocalWord;
  }

  /// Canonical regex for extracting words consistently across TTS timing and UI highlighting
  static final RegExp granthWordPattern = RegExp(
    r'''[^\s।॥\n\r,.:;!?~❖✦★☆◆◇_─━═()\[\]{}|‖¦/'"“”‘’–—]+''',
  );
  static final RegExp citationPattern = RegExp(
    r'^[\d०-९]+(?:[-–—.:][\d०-९]+)?$',
  );

  /// Dynamically computes the natural speech duration (in ms) for a word using
  /// Chhandas-inspired phonetic mora for Devanagari and syllable metrics for Latin text.
  static int _computePhoneticDurationMs(
    String word,
    String lang,
    double rateScale,
  ) {
    if (word.isEmpty) return 0;

    final bool isDevanagari = word.runes.any((r) => r >= 0x0900 && r <= 0x097F);

    double baseMs;
    if (isDevanagari) {
      int morae = 0;
      final runes = word.runes.toList();
      for (int i = 0; i < runes.length; i++) {
        final r = runes[i];
        if (r == 0x0906 ||
            r == 0x0908 ||
            r == 0x090A ||
            r == 0x090F ||
            r == 0x0910 ||
            r == 0x0913 ||
            r == 0x0914 ||
            r == 0x093E ||
            r == 0x0940 ||
            r == 0x0942 ||
            r == 0x0947 ||
            r == 0x0948 ||
            r == 0x094B ||
            r == 0x094C) {
          morae += 2;
        } else if (r == 0x0902 || r == 0x0903) {
          morae += 1;
        } else if (r >= 0x0915 && r <= 0x0939) {
          morae += 1;
        } else if (r >= 0x0904 && r <= 0x090B) {
          morae += 1;
        }
      }
      if (morae < 1) morae = 1;
      baseMs = 120.0 + (morae * 110.0);
    } else {
      final vowelMatches = RegExp(
        r'[aeiouy]+',
        caseSensitive: false,
      ).allMatches(word).length;
      final syllables = math.max(1, vowelMatches);
      baseMs = 130.0 + (syllables * 120.0);
    }

    final duration = (baseMs * rateScale).round();
    return duration.clamp(
      (220 * rateScale).round(),
      (2200 * rateScale).round(),
    );
  }

  /// Builds structured sections with word tokens and calibrated pause durations for a verse.
  static List<_VerseSection> _buildVerseSections(
    Map<String, String> verse,
    double calibratedRate,
  ) {
    final sections = <_VerseSection>[];

    final sanskrit = (verse['sanskrit'] ?? '').trim();
    final transliteration = (verse['transliteration'] ?? '').trim();
    String rawEnglish = (verse['english'] ?? '').trim();
    String rawHindi = (verse['hindi'] ?? '').trim();

    // Normalize if Hindi translation is embedded inside the English field
    if (rawHindi.isEmpty && rawEnglish.contains('\n\n')) {
      final parts = rawEnglish.split('\n\n');
      if (parts.length >= 2 && RegExp(r'[\u0900-\u097F]').hasMatch(parts[0])) {
        rawHindi = parts[0].trim();
        rawEnglish = parts.sublist(1).join('\n\n').trim();
      }
    }

    final rawList = [
      ('sanskrit', sanskrit, 'hi-IN'),
      ('transliteration', transliteration, 'hi-IN'),
      ('hindi', rawHindi, 'hi-IN'),
      ('english', rawEnglish, 'en-IN'),
    ];

    final nativeRate = Platform.isAndroid
        ? (calibratedRate * 2.0)
        : calibratedRate;
    final double rateScale = 0.50 / nativeRate.clamp(0.12, 2.0);

    for (final item in rawList) {
      final secName = item.$1;
      final rawText = item.$2;
      final lang = item.$3;
      if (rawText.isEmpty) continue;

      final allMatches = granthWordPattern.allMatches(rawText).toList();
      if (allMatches.isEmpty) continue;

      final words = allMatches.map((m) => m.group(0) ?? '').toList();

      final phraseRegex = RegExp(r'([^।॥|\n,.;!?:]+)([।॥|\n,.;!?:]*)');
      final phraseMatches = phraseRegex.allMatches(rawText).toList();
      final phrases = <_VersePhrase>[];

      int wordCursor = 0;

      for (final pm in phraseMatches) {
        final content = pm.group(1)?.trim() ?? '';
        final delim = pm.group(2) ?? '';
        if (content.isEmpty) continue;

        final phraseWords = granthWordPattern.allMatches(content).toList();
        if (phraseWords.isEmpty) continue;

        final cleanSpokenWords = <String>[];
        final phraseWordIndices = <int>[];
        final wordStarts = <int>[];
        final relativeOffsets = <int>[];
        int currentSpokenLen = 0;
        int phraseDurationMs = 0;

        for (final pw in phraseWords) {
          final rawWord = pw.group(0) ?? '';
          if (wordCursor < words.length) {
            final isCitation = citationPattern.hasMatch(rawWord);
            final clean = rawWord
                .replaceAll(
                  RegExp(r'[^\p{L}\p{N}\u0900-\u097F]', unicode: true),
                  '',
                )
                .trim();

            if (!isCitation && clean.isNotEmpty) {
              if (cleanSpokenWords.isNotEmpty) {
                currentSpokenLen += 1;
              }
              wordStarts.add(currentSpokenLen);
              cleanSpokenWords.add(clean);
              currentSpokenLen += clean.length;

              phraseWordIndices.add(wordCursor);
              relativeOffsets.add(phraseDurationMs);

              final wordMs = _computePhoneticDurationMs(clean, lang, rateScale);
              phraseDurationMs += wordMs;
            }

            wordCursor++;
          }
        }

        if (cleanSpokenWords.isNotEmpty) {
          int pauseMs = 80;
          if (delim.contains('॥') || delim.contains('\n\n')) {
            pauseMs = 550;
          } else if (delim.contains('।') ||
              delim.contains('.') ||
              delim.contains('|')) {
            pauseMs = 350;
          } else if (delim.contains(',') || delim.contains(';')) {
            pauseMs = 180;
          } else if (delim.contains('\n')) {
            pauseMs = 240;
          }

          phrases.add(
            _VersePhrase(
              spokenText: cleanSpokenWords.join(' '),
              delimiter: delim,
              wordIndices: phraseWordIndices,
              wordStarts: wordStarts,
              relativeOffsetsMs: relativeOffsets,
              totalDurationMs: math.max(400, phraseDurationMs),
              pauseMs: pauseMs,
            ),
          );
        }
      }

      if (phrases.isEmpty) continue;

      sections.add(
        _VerseSection(
          section: secName,
          displayText: rawText,
          words: words,
          phrases: phrases,
          langCode: lang,
        ),
      );
    }

    return sections;
  }

  /// Detects TTS language from book/chapter metadata and content.
  String _detectTtsLanguage() {
    final langMeta =
        (widget.granth['language'] ?? widget.chapter['language'] ?? '')
            .toString()
            .toLowerCase();

    if (langMeta.contains('gu') || langMeta.contains('gujarat')) {
      return 'gu-IN';
    }
    if (langMeta.contains('hi') || langMeta.contains('hindi')) {
      return 'hi-IN';
    }
    if (langMeta.contains('sa') || langMeta.contains('sanskrit')) {
      return 'hi-IN';
    }
    if (langMeta.contains('en') || langMeta.contains('english')) {
      return 'en-IN';
    }

    if (_verses.isNotEmpty) {
      final sample =
          (_verses.first['sanskrit'] ?? '') +
          (_verses.first['hindi'] ?? '') +
          (_verses.first['english'] ?? '');
      if (sample.runes.any((r) => r >= 0x0A80 && r <= 0x0AFF)) {
        return 'gu-IN';
      }
      if (sample.runes.any((r) => r >= 0x0900 && r <= 0x097F)) {
        return 'hi-IN';
      }
    }

    return 'hi-IN';
  }

  /// Selects the most natural, human-like compatible voice available for the given language.
  Future<void> _selectOptimalVoice(String lang) async {
    try {
      final voices = await _tts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        final langPrefix = lang.toLowerCase().split('-').first;
        final targetLocale = lang.toLowerCase();
        Map<String, String>? fallbackMatch;
        Map<String, String>? bestMatch;
        int highestScore = -1;

        for (final item in voices) {
          if (item is Map) {
            final name = (item['name'] ?? '').toString();
            final locale = (item['locale'] ?? '').toString();
            final nLower = name.toLowerCase();
            final lLower = locale.toLowerCase();

            if (lLower == targetLocale ||
                lLower.startsWith(langPrefix) ||
                lLower.contains(langPrefix)) {
              fallbackMatch ??= {'name': name, 'locale': locale};
              int score = 0;
              if (lLower == targetLocale) score += 15;
              if (nLower.contains('neural') || nLower.contains('wavenet')) {
                score += 35;
              }
              if (nLower.contains('x-hie') ||
                  nLower.contains('x-hid') ||
                  nLower.contains('x-ene') ||
                  nLower.contains('x-end')) {
                score += 25;
              }
              if (nLower.contains('x-hic') ||
                  nLower.contains('x-hib') ||
                  nLower.contains('x-hia')) {
                score += 20;
              }
              if (nLower.contains('network') || nLower.contains('natural')) {
                score += 10;
              }
              if (score > highestScore) {
                highestScore = score;
                bestMatch = {'name': name, 'locale': locale};
              }
            }
          }
        }

        final selected = bestMatch ?? fallbackMatch;
        if (selected != null) {
          await _tts.setVoice(selected);
          debugPrint(
            '[TTS] Configured optimal voice: ${selected['name']} (${selected['locale']}) [score: $highestScore]',
          );
        }
      }
    } catch (e) {
      debugPrint('[TTS] Voice configuration notice: $e');
    }
  }

  /// Computes the platform-calibrated speech rate for a calm, serene scripture chanting speed.
  /// Android: 0.25 delivers peaceful, meditative, clearly articulated sacred chanting.
  /// iOS: 0.28 produces smooth, sacred recitation.
  double get _calibratedSpeechRate {
    final double baseRate = Platform.isAndroid ? 0.25 : 0.28;
    return (baseRate * _speedMultiplier).clamp(0.12, 0.85);
  }

  /// Explicitly applies rate, pitch, and volume before speech begins.
  Future<void> _applySpeechSettings() async {
    final rate = _calibratedSpeechRate;
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(1.0); // Pure, natural human vocal resonance
    await _tts.setVolume(1.0);
    debugPrint(
      '[TTS] Applied speech settings -> platform: ${Platform.operatingSystem}, rate: $rate, pitch: 1.0',
    );
  }

  Future<void> _initTts() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (e) {
      debugPrint('[TTS] Could not set Google TTS engine: $e');
    }

    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}

    _ttsLang = _detectTtsLanguage();
    await _tts.setLanguage(_ttsLang);
    await _selectOptimalVoice(_ttsLang);
    await _applySpeechSettings();

    _tts.setStartHandler(() {
      _ttsPhraseStartCallback?.call();
    });

    _tts.setProgressHandler((String text, int start, int end, String word) {
      _ttsPhraseProgressCallback?.call(start);
    });

    // Word completion callback: unblocks the lockstep chanting loop precisely when speaker finishes the word
    _tts.setCompletionHandler(() {
      if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
        _wordCompleter!.complete();
      }
    });

    _tts.setErrorHandler((msg) {
      if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
        _wordCompleter!.complete();
      }
      debugPrint('[TTS] Error notice: $msg');
    });

    if (mounted) setState(() => _ttsInitialized = true);
  }

  void _transitionToNextSection() {
    _transitionTimer?.cancel();
    if (!mounted || !_isPlaying) return;

    final nextSecIdx = _currentSectionIndex + 1;
    if (nextSecIdx < _activeVerseSections.length) {
      // Reverent 600ms pause between scripture sections (Sanskrit -> Transliteration -> Hindi)
      _transitionTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted || !_isPlaying) return;
        _currentSectionIndex = nextSecIdx;
        _currentLocalWord = 0;
        _speakCurrentSection();
      });
    } else {
      // All sections of the verse finished!
      _handlePageComplete();
    }
  }

  /// Speaks the current section line-by-line / phrase-by-phrase in sacred cadence.
  /// Every single word in the scripture is 100% vocalized by Google TTS (zero dropped words).
  /// Words are highlighted in real-time as they are spoken via TTS audio callbacks.
  /// Punctuation marks (।, ॥, |, ;, :, .) are never spoken aloud.
  Future<void> _speakCurrentSection() async {
    _transitionTimer?.cancel();

    if (!mounted || !_isPlaying) return;

    if (_currentSectionIndex >= _activeVerseSections.length) {
      _handlePageComplete();
      return;
    }

    final section = _activeVerseSections[_currentSectionIndex];

    // ── My Voice: if devotee recorded their own voice for this verse, play it ──
    if (_currentSectionIndex == 0 &&
        _currentChapterId != null &&
        _currentChapterId!.isNotEmpty) {
      final vi = _currentPage - 1;
      final userAudio = await _userRecordingService.getAudioForVerse(
        _currentChapterId!,
        vi,
      );
      if (userAudio != null && userAudio.isNotEmpty && mounted && _isPlaying) {
        final currentSession = ++_speechLoopSession;
        setState(() {
          _activeSection = 'sanskrit';
        });
        try {
          await _verseAudioPlayer.stop();
          final completionFuture = _verseAudioPlayer.onPlayerComplete.first;
          if (userAudio.startsWith('http')) {
            await _verseAudioPlayer.play(UrlSource(userAudio));
          } else {
            await _verseAudioPlayer.play(DeviceFileSource(userAudio));
          }
          await completionFuture.timeout(
            const Duration(seconds: 60),
            onTimeout: () {},
          );
        } catch (_) {}
        if (mounted && _isPlaying && _speechLoopSession == currentSession) {
          _handlePageComplete();
        }
        return;
      }
    }

    if (_ttsLang != section.langCode) {
      _ttsLang = section.langCode;
      await _tts.setLanguage(_ttsLang);
      await _selectOptimalVoice(_ttsLang);
    }

    await _applySpeechSettings();

    if (!mounted || !_isPlaying) return;

    final currentSession = ++_speechLoopSession;

    setState(() {
      _activeSection = section.section;
    });

    for (int p = 0; p < section.phrases.length; p++) {
      if (!mounted || !_isPlaying || _speechLoopSession != currentSession) {
        return;
      }

      final phrase = section.phrases[p];
      if (phrase.wordIndices.isEmpty || phrase.spokenText.isEmpty) {
        if (phrase.pauseMs > 0) {
          await Future.delayed(
            Duration(milliseconds: (phrase.pauseMs / _speedMultiplier).round()),
          );
        }
        continue;
      }

      // Highlight the first word of the line immediately
      setState(() {
        _currentLocalWord = phrase.wordIndices.first;
      });

      final completer = Completer<void>();
      _wordCompleter = completer;

      bool audioStarted = false;
      int audioStartTime = 0;
      Timer? phraseTicker;

      void startAudioTicker() {
        if (audioStarted) return;
        audioStarted = true;
        audioStartTime = DateTime.now().millisecondsSinceEpoch;

        phraseTicker?.cancel();
        phraseTicker = Timer.periodic(const Duration(milliseconds: 25), (t) {
          if (!mounted || !_isPlaying || _speechLoopSession != currentSession) {
            t.cancel();
            return;
          }

          final elapsed =
              DateTime.now().millisecondsSinceEpoch - audioStartTime;
          int activeIdx = phrase.wordIndices.first;
          for (int k = 0; k < phrase.relativeOffsetsMs.length; k++) {
            if (elapsed >= phrase.relativeOffsetsMs[k]) {
              activeIdx = phrase.wordIndices[k];
            } else {
              break;
            }
          }

          if (activeIdx != _currentLocalWord && mounted) {
            setState(() {
              _currentLocalWord = activeIdx;
            });
          }
        });
      }

      _ttsPhraseStartCallback = () {
        startAudioTicker();
      };

      _ttsPhraseProgressCallback = (int charOffset) {
        audioStarted = true;
        for (int k = 0; k < phrase.wordStarts.length; k++) {
          if (charOffset >= phrase.wordStarts[k] &&
              (k == phrase.wordStarts.length - 1 ||
                  charOffset < phrase.wordStarts[k + 1])) {
            final targetIdx = phrase.wordIndices[k];
            if (targetIdx != _currentLocalWord && mounted) {
              setState(() {
                _currentLocalWord = targetIdx;
              });
            }
            break;
          }
        }
      };

      // Speak the entire line naturally via Google Cloud TTS (zero dropped words)
      String? cloudAudioUrl;
      try {
                final prefs = await _ttsService.loadPreferences();
        final selectedVoiceId = prefs.selectedVoiceId ?? _ttsService.getVoiceForLanguage('Gujarati', prefs: prefs);

        final isGujarati = phrase.spokenText.runes.any(
          (r) => r >= 0x0A80 && r <= 0x0AFF,
        );
        final langCategory = isGujarati
            ? 'Gujarati'
            : (section.section == 'sanskrit'
                  ? 'Sanskrit'
                  : (section.langCode == 'en-IN' ? 'English' : 'Hindi'));

        cloudAudioUrl = await _ttsService.synthesizeScriptureAudio(
          text: phrase.spokenText,
          language: langCategory,
          voiceId: selectedVoiceId,
          speakingRate: _speedMultiplier,
          sectionType: section.section,
        );
      } catch (e) {
        debugPrint('[TTS] Cloud audio synthesis error: $e');
      }

      if (cloudAudioUrl != null &&
          cloudAudioUrl.isNotEmpty &&
          mounted &&
          _isPlaying &&
          _speechLoopSession == currentSession) {
        startAudioTicker();
        try {
          await _verseAudioPlayer.stop();
          final completionFuture = _verseAudioPlayer.onPlayerComplete.first;
          await _verseAudioPlayer.play(UrlSource(cloudAudioUrl));

          final timeoutMs = math.max(
            3500,
            (phrase.totalDurationMs * 2.8).round(),
          );
          await completionFuture.timeout(
            Duration(milliseconds: (timeoutMs / _speedMultiplier).round()),
            onTimeout: () {},
          );
        } catch (_) {}
      } else {
        try {
          await _tts.speak(phrase.spokenText);
        } catch (e) {
          debugPrint('[TTS] Device TTS fallback error: $e');
        }
        // Fallback timer: if onStart didn't fire within 350ms, start ticker anyway
        Timer(const Duration(milliseconds: 350), () {
          if (!audioStarted &&
              mounted &&
              _speechLoopSession == currentSession) {
            startAudioTicker();
          }
        });

        final timeoutMs = math.max(
          2500,
          (phrase.totalDurationMs * 2.5).round(),
        );
        try {
          await completer.future.timeout(
            Duration(milliseconds: (timeoutMs / _speedMultiplier).round()),
            onTimeout: () {},
          );
        } catch (_) {}
      }

      phraseTicker?.cancel();

      if (!mounted || !_isPlaying || _speechLoopSession != currentSession) {
        return;
      }

      // Ensure last word of this line is reached
      setState(() {
        _currentLocalWord = phrase.wordIndices.last;
      });

      // Natural pause at line / verse boundary
      if (phrase.pauseMs > 0) {
        await Future.delayed(
          Duration(milliseconds: (phrase.pauseMs / _speedMultiplier).round()),
        );
      }
    }

    if (!mounted || !_isPlaying || _speechLoopSession != currentSession) {
      return;
    }

    // Section completed!
    setState(() {
      _currentLocalWord = section.words.length;
    });

    _transitionToNextSection();
  }

  /// Start playback for the current page
  Future<void> _startWordTimer() async {
    _wordTimer?.cancel();
    _paceTicker?.cancel();
    _transitionTimer?.cancel();

    if (!_isPlaying) return;

    final vi = _currentPage - 1;
    if (vi < 0 || vi >= _verses.length) return;

    if (!_ttsInitialized) {
      _startWordTimerFallback();
      return;
    }

    _activeVerseSections = _buildVerseSections(
      _verses[vi],
      _calibratedSpeechRate,
    );
    if (_activeVerseSections.isEmpty) {
      _handlePageComplete();
      return;
    }

    _currentSectionIndex = 0;
    _currentLocalWord = 0;
    _speakCurrentSection();
  }

  /// Fallback: timer-based word stepping (used when TTS unavailable)
  void _startWordTimerFallback() {
    _wordTimer?.cancel();
    if (!_isPlaying) return;

    final vi = _currentPage - 1;
    if (vi < 0 || vi >= _verses.length) return;

    if (_activeVerseSections.isEmpty) {
      _activeVerseSections = _buildVerseSections(
        _verses[vi],
        _calibratedSpeechRate,
      );
      if (_activeVerseSections.isEmpty) {
        _handlePageComplete();
        return;
      }
      _currentSectionIndex = 0;
      _currentLocalWord = 0;
    }

    _wordTimer = Timer.periodic(Duration(milliseconds: _readingSpeedMs), (
      timer,
    ) {
      if (!mounted || !_isPlaying || _isAutoTurning) return;
      if (_currentSectionIndex >= _activeVerseSections.length) {
        _handlePageComplete();
        return;
      }

      final sec = _activeVerseSections[_currentSectionIndex];
      if (_currentLocalWord < sec.words.length - 1) {
        setState(() {
          _activeSection = sec.section;
          _currentLocalWord++;
        });
      } else {
        if (_currentSectionIndex + 1 < _activeVerseSections.length) {
          setState(() {
            _currentSectionIndex++;
            _activeSection = _activeVerseSections[_currentSectionIndex].section;
            _currentLocalWord = 0;
          });
        } else {
          _handlePageComplete();
        }
      }
    });
  }

  void _handlePageComplete() {
    _speechLoopSession++;
    if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
      _wordCompleter!.complete();
    }
    _transitionTimer?.cancel();
    _wordTimer?.cancel();
    _tts.stop();

    if (!_isPlaying || _isAutoTurning) return;

    final totalPages = _verses.length + 2;
    final nextPage = _currentPage + 1;

    setState(() {
      _isPageCompleted = true;
      _currentLocalWord = 99999;
    });

    // Pause for 1200ms so reader comfortably absorbs the completed verse
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || !_isPlaying || _isAutoTurning) return;

      if (nextPage < totalPages - 1) {
        _isAutoTurning = true;
        _bookViewerKey.currentState?.autoTurnToPage(nextPage, durationMs: 650);

        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _isAutoTurning = false;

          if (_isPlaying) {
            setState(() {
              _currentPage = nextPage;
              _targetPage = nextPage;
              _currentLocalWord = -1;
              _activeSection = '';
              _isPageCompleted = false;
            });
            _startWordTimer();
          }
        });
      } else if (nextPage == totalPages - 1) {
        _isAutoTurning = true;
        _bookViewerKey.currentState?.autoTurnToPage(nextPage, durationMs: 650);

        setState(() {
          _isPlaying = false;
          _isAutoTurning = false;
          _currentPage = nextPage;
          _targetPage = nextPage;
          _currentLocalWord = -1;
          _activeSection = '';
          _isPageCompleted = false;
        });

        if (_audioUrl != null) _audioPlayer.stop();
      } else {
        setState(() {
          _isPlaying = false;
          _currentLocalWord = -1;
          _activeSection = '';
          _isPageCompleted = false;
        });
      }
    });
  }

  void _toggleAutoRead() {
    if (_isPlaying) {
      _speechLoopSession++;
      if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
        _wordCompleter!.complete();
      }
      _transitionTimer?.cancel();
      _wordTimer?.cancel();
      _verseAudioPlayer.stop();
      _tts.stop();
      if (_audioUrl != null) _audioPlayer.pause();

      setState(() {
        _isPlaying = false;
        _isPageCompleted = false;
      });
    } else {
      final totalPages = _verses.length + 2;

      if (_currentPage == 0) {
        _bookViewerKey.currentState?.autoTurnToPage(1, durationMs: 650);

        setState(() {
          _isPlaying = true;
          _currentSectionIndex = 0;
          _currentLocalWord = 0;
          _isPageCompleted = false;
        });

        if (_audioUrl != null) {
          _audioPlayer.setVolume(0.18);
          _audioPlayer.play(UrlSource(_audioUrl!));
        }

        Future.delayed(const Duration(milliseconds: 750), () {
          if (mounted && _isPlaying) {
            _currentPage = 1;
            _targetPage = 1;
            _startWordTimer();
          }
        });
      } else if (_currentPage >= totalPages - 1) {
        _bookViewerKey.currentState?.autoTurnToPage(1, durationMs: 650);

        setState(() {
          _isPlaying = true;
          _currentPage = 1;
          _targetPage = 1;
          _currentSectionIndex = 0;
          _currentLocalWord = 0;
          _isPageCompleted = false;
        });

        if (_audioUrl != null) {
          _audioPlayer.setVolume(0.18);
          _audioPlayer.play(UrlSource(_audioUrl!));
        }

        Future.delayed(const Duration(milliseconds: 750), () {
          if (mounted && _isPlaying) {
            _startWordTimer();
          }
        });
      } else {
        setState(() {
          _isPlaying = true;
          _isPageCompleted = false;
        });

        if (_audioUrl != null) {
          _audioPlayer.resume();
        }

        if (_activeVerseSections.isNotEmpty &&
            _currentSectionIndex < _activeVerseSections.length) {
          _speakCurrentSection();
        } else {
          _startWordTimer();
        }
      }
    }
  }

  void _cycleSpeed() async {
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
      _readingSpeedMs = (600 / _speedMultiplier).round();
    });

    _speechLoopSession++;
    if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
      _wordCompleter!.complete();
    }
    _paceTicker?.cancel();
    _transitionTimer?.cancel();
    await _applySpeechSettings();

    if (_isPlaying) {
      await _verseAudioPlayer.stop();
      await _tts.stop();
      final vi = _currentPage - 1;
      if (vi >= 0 && vi < _verses.length) {
        _activeVerseSections = _buildVerseSections(
          _verses[vi],
          _calibratedSpeechRate,
        );
        _speakCurrentSection();
      }
    }
  }

  void _onPageChanged(int newPage) {
    if (!mounted) return;
    if (_currentPage == newPage) return;

    _speechLoopSession++;
    if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
      _wordCompleter!.complete();
    }
    _transitionTimer?.cancel();
    _wordTimer?.cancel();
    _verseAudioPlayer.stop();

    setState(() {
      _currentPage = newPage;
      _targetPage = newPage;
      _currentLocalWord = -1;
      _activeSection = '';
      _isPageCompleted = false;
    });

    if (_isPlaying) {
      if (newPage >= 1 && newPage <= _verses.length) {
        _tts.stop();
        _startWordTimer();
      } else {
        _tts.stop();
        if (_audioUrl != null) _audioPlayer.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  void _onPageChanging(int targetPage) {
    if (!mounted) return;
    if (_targetPage != targetPage) {
      setState(() {
        _targetPage = targetPage;
      });
    }
  }

  void _goToPrevPage() {
    _verseAudioPlayer.stop();
    if (_currentPage > 0) {
      _bookViewerKey.currentState?.autoTurnToPage(
        _currentPage - 1,
        durationMs: 580,
      );
    }
  }

  void _goToNextPage() {
    _verseAudioPlayer.stop();
    final totalPages = _verses.length + 2;
    if (_currentPage < totalPages - 1) {
      _bookViewerKey.currentState?.autoTurnToPage(
        _currentPage + 1,
        durationMs: 580,
      );
    }
  }

  @override
  void dispose() {
    _speechLoopSession++;
    if (_wordCompleter != null && !_wordCompleter!.isCompleted) {
      _wordCompleter!.complete();
    }
    _transitionTimer?.cancel();
    _wordTimer?.cancel();
    _verseAudioPlayer.stop();
    _verseAudioPlayer.dispose();
    _tts.stop();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    _userRecordingService.dispose();
    super.dispose();
  }

  Future<void> _loadChapterPagesAndVerses() async {
    final chapterId = (widget.chapter['_id'] ?? widget.chapter['id'] ?? '')
        .toString();

    List<Map<String, String>> parsedVerses = [];

    if (chapterId.isNotEmpty) {
      try {
        final pages = await ApiService.getPagesByChapter(chapterId);

        if (pages.isNotEmpty) {
          for (final page in pages) {
            final pageMap = Map<String, dynamic>.from(page as Map);

            final pageId = (pageMap['_id'] ?? pageMap['id'] ?? '').toString();

            List<dynamic> shlokas = [];

            if (pageMap['shlokas'] is List &&
                (pageMap['shlokas'] as List).isNotEmpty) {
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

                  final sanskrit =
                      (sMap['sanskritText'] ??
                              sMap['sanskrit'] ??
                              sMap['shloka'] ??
                              '')
                          .toString()
                          .trim();

                  final transliteration =
                      (sMap['transliteration'] ?? sMap['transliterate'] ?? '')
                          .toString()
                          .trim();

                  final english =
                      (sMap['englishMeaning'] ??
                              sMap['englishTranslation'] ??
                              sMap['english'] ??
                              sMap['content'] ??
                              '')
                          .toString()
                          .trim();

                  final hindi =
                      (sMap['hindiMeaning'] ??
                              sMap['hindiTranslation'] ??
                              sMap['hindi'] ??
                              '')
                          .toString()
                          .trim();

                  if (sanskrit.isNotEmpty ||
                      english.isNotEmpty ||
                      hindi.isNotEmpty) {
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
              final pageContent =
                  (pageMap['content'] ?? pageMap['description'] ?? '')
                      .toString()
                      .trim();

              final sanskrit =
                  (pageMap['sanskrit'] ?? pageMap['sanskritText'] ?? '')
                      .toString()
                      .trim();

              final transliteration = (pageMap['transliteration'] ?? '')
                  .toString()
                  .trim();

              final english =
                  (pageMap['english'] ??
                          pageMap['englishTranslation'] ??
                          pageMap['englishMeaning'] ??
                          pageContent)
                      .toString()
                      .trim();

              final hindi =
                  (pageMap['hindi'] ??
                          pageMap['hindiTranslation'] ??
                          pageMap['hindiMeaning'] ??
                          '')
                      .toString()
                      .trim();

              if (sanskrit.isNotEmpty ||
                  english.isNotEmpty ||
                  hindi.isNotEmpty) {
                parsedVerses.add({
                  'sanskrit': sanskrit.isNotEmpty
                      ? sanskrit
                      : (widget.chapter['sanskritName'] ??
                                widget.chapter['name'] ??
                                '')
                            .toString(),

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
      final rawVerses =
          widget.chapter['verses'] ??
          widget.chapter['shlokas'] ??
          widget.chapter['content'];

      if (rawVerses is List) {
        for (final item in rawVerses) {
          if (item is Map) {
            parsedVerses.add(
              item.map(
                (key, value) =>
                    MapEntry(key.toString(), (value ?? '').toString()),
              ),
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

      final String bodyText = trans.isNotEmpty
          ? trans
          : (content.isNotEmpty ? content : desc);

      final sanskritText =
          (widget.chapter['sanskritName'] ??
                  widget.chapter['sanskrit'] ??
                  widget.chapter['name'] ??
                  widget.chapter['title'] ??
                  '')
              .toString();

      if (sanskritText.isNotEmpty || bodyText.isNotEmpty) {
        parsedVerses = [
          {
            'sanskrit': sanskritText,
            'transliteration': (widget.chapter['transliteration'] ?? '')
                .toString(),
            'english': bodyText,
            'hindi': '',
          },
        ];
      }
    }

    if (mounted) {
      setState(() {
        _verses = parsedVerses;
        _isLoadingPages = false;
      });

      // Load user's personal voice recordings for this chapter
      _currentChapterId = (widget.chapter['_id'] ?? widget.chapter['id'] ?? '')
          .toString();
      if (_currentChapterId!.isNotEmpty) {
        try {
          final recs = await _userRecordingService.fetchChapterRecordings(
            _currentChapterId!,
          );
          if (mounted) {
            setState(() => _chapterUserRecordings = recs);
          }
        } catch (_) {}
      }

      _loadOptionalAudio();

      // Re-detect language now that verses are available

      final detectedLang = _detectTtsLanguage();

      if (detectedLang != _ttsLang) {
        _ttsLang = detectedLang;

        _tts.setLanguage(_ttsLang);

        _selectOptimalVoice(_ttsLang);
      }
    }
  }

  Future<void> _loadOptionalAudio() async {
    if (_isLoadingAudio) return;

    _isLoadingAudio = true;

    String? foundUrl;

    final direct =
        (widget.chapter['audioUrl'] ??
                widget.chapter['audio'] ??
                widget.chapter['streamUrl'] ??
                widget.chapter['fileUrl'])
            ?.toString()
            .trim();

    if (direct != null && direct.isNotEmpty) {
      final resolved = ApiService.resolveImageUrl(direct);

      if (resolved.isNotEmpty) foundUrl = resolved;
    }

    final chapterId = (widget.chapter['_id'] ?? widget.chapter['id'] ?? '')
        .toString();

    if (foundUrl == null && chapterId.isNotEmpty) {
      try {
        final audios = await ApiService.getAudioByChapter(chapterId);

        if (audios.isNotEmpty) {
          final first = Map<String, dynamic>.from(audios.first as Map);

          final raw =
              (first['audioUrl'] ??
                      first['url'] ??
                      first['streamUrl'] ??
                      first['fileUrl'] ??
                      '')
                  .toString();

          final resolved = raw.isNotEmpty
              ? ApiService.resolveImageUrl(raw)
              : '';

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

  Widget _buildOpenGranthButton() {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          if (!_isPlaying) {
            _toggleAutoRead();
          } else {
            _goToNextPage();
          }
        },

        borderRadius: BorderRadius.circular(28),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),

            gradient: const LinearGradient(
              colors: [
                Color(0xFF3B1607), // Rich dark mahogany

                Color(0xFF220C04), // Dark walnut leather

                Color(0xFF140502), // Deep leather
              ],

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,
            ),

            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.85),

              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9E3D).withValues(alpha: 0.28),

                blurRadius: 18,

                spreadRadius: 1,

                offset: const Offset(0, 4),
              ),

              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),

                blurRadius: 12,

                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(
                Icons.auto_stories_rounded,

                color: Color(0xFFFFD54F),

                size: 20,
              ),

              const SizedBox(width: 10),

              Text(
                'ग्रंथ खोलें • Open Granth',

                style: GoogleFonts.outfit(
                  fontSize: 14.5,

                  fontWeight: FontWeight.w700,

                  color: const Color(0xFFFFE082),

                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,

                color: Color(0xFFFFD54F),

                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final granthTitle =
        (widget.granth['name'] ?? widget.granth['title'] ?? 'Granth')
            .toString();

    final chapterTitle =
        (widget.chapter['title'] ?? widget.chapter['name'] ?? 'Chapter')
            .toString();

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final topPadding = MediaQuery.of(context).padding.top;

    final screenHeight = MediaQuery.of(context).size.height;

    final screenWidth = MediaQuery.of(context).size.width;

    final bool isClosedCover = (_currentPage == 0);

    // Compute proper book bounds

    // In Full-screen mode: 100% edge-to-edge full width immersion without letterboxing

    // In Normal mode: perfectly aligned along the mobile border with subtle 4px elevation margin

    // Constant width/height ensures text NEVER contracts, wraps differently, or moves when opening or closing!

    final double bookW = _isFullScreen
        ? screenWidth
        : math.max(0.0, screenWidth - 8.0);

    final double bookLeft = _isFullScreen ? 0.0 : 4.0;

    final double bookTop = _isFullScreen ? topPadding : (topPadding + 20.0);

    final double bookH = _isFullScreen
        ? (screenHeight -
              topPadding -
              (isClosedCover ? (bottomPadding + 56.0) : (bottomPadding + 68.0)))
        : math.max(
            0.0,
            screenHeight - (topPadding + 36.0) - (bottomPadding + 70.0),
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: Brightness.light,

        statusBarBrightness: Brightness.dark,

        systemNavigationBarColor: Color(0xFF100502),

        systemNavigationBarIconBrightness: Brightness.light,
      ),

      child: Scaffold(
        backgroundColor: const Color(0xFF100502),

        body: Stack(
          children: [
            // Ambient sacred sanctuary altar background: warm teakwood & rosewood altar desk with Diya glow
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.20),

                    radius: 1.35,

                    colors: [
                      Color(
                        0xFF421C0E,
                      ), // Warm golden teakwood altar surface beneath Diya light

                      Color(0xFF2E1207), // Polished rosewood temple desk

                      Color(0xFF1C0904), // Deep walnut border

                      Color(0xFF0F0402), // Sanctum edge shadow
                    ],

                    stops: [0.0, 0.40, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Book viewer resting on the altar (NO outer ClipRRect so 3D rotation & page peel never get cropped!)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 580),

              curve: Curves.easeOutCubic,

              top: bookTop,

              left: bookLeft,

              width: bookW,

              height: bookH,

              child: _isLoadingPages
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF8C1A),
                      ),
                    )
                  : _SacredAltarBookPlatform(
                      isFullScreen: _isFullScreen,

                      isCoverClosed: isClosedCover,

                      child: _BookViewer(
                        key: _bookViewerKey,

                        granth: widget.granth,

                        chapter: widget.chapter,

                        granthTitle: granthTitle,

                        chapterTitle: chapterTitle,

                        verses: _verses,

                        sepiaMode: _sepiaMode,

                        activeVerseIndex:
                            (_isPlaying &&
                                _currentPage >= 1 &&
                                _currentPage <= _verses.length)
                            ? _currentPage - 1
                            : -1,

                        activeSection: activeSection,

                        activeLocalWordIndex: activeLocalWordIndex,

                        isPageCompleted: _isPageCompleted,

                        onPageChanged: _onPageChanged,

                        onPageChanging: _onPageChanging,

                        chapterUserRecordings: _chapterUserRecordings,

                        onRecordVerseVoice: (vi) {
                          if (_currentChapterId == null ||
                              _currentChapterId!.isEmpty)
                            return;
                          final verse = vi < _verses.length
                              ? _verses[vi]
                              : <String, String>{};
                          final chTitle =
                              (widget.chapter['name'] ??
                                      widget.chapter['title'] ??
                                      '')
                                  .toString();
                          RecordVerseVoiceSheet.show(
                            context,
                            chapterId: _currentChapterId!,
                            chapterTitle: chTitle,
                            verseIndex: vi,
                            totalVerses: _verses.length,
                            sanskritText: verse['sanskrit'] ?? '',
                            transliterationText: verse['transliteration'] ?? '',
                            meaningText:
                                verse['hindi'] ?? verse['english'] ?? '',
                            onRecordingSaved: () {
                              _userRecordingService
                                  .fetchChapterRecordings(_currentChapterId!)
                                  .then((recs) {
                                    if (mounted)
                                      setState(
                                        () => _chapterUserRecordings = recs,
                                      );
                                  });
                            },
                          );
                        },
                      ),
                    ),
            ),

            // Floating back arrow (top-left) with warm gold on dark sanctuary glass
            Positioned(
              top: topPadding + 8,

              left: 10,

              child: Material(
                color: const Color(0xFF1E0A04).withValues(alpha: 0.65),

                borderRadius: BorderRadius.circular(24),

                child: InkWell(
                  borderRadius: BorderRadius.circular(24),

                  onTap: () => Navigator.pop(context),

                  child: const Padding(
                    padding: EdgeInsets.all(10),

                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,

                      color: Color(0xFFFFD700),

                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Floating Fullscreen toggle button (top-right)
            Positioned(
              top: topPadding + 8,

              right: 12,

              child: Material(
                color: const Color(0xFF1E0A04).withValues(alpha: 0.65),

                borderRadius: BorderRadius.circular(24),

                child: InkWell(
                  borderRadius: BorderRadius.circular(24),

                  onTap: () {
                    HapticFeedback.lightImpact();

                    setState(() {
                      _isFullScreen = !_isFullScreen;
                    });
                  },

                  child: Padding(
                    padding: const EdgeInsets.all(10),

                    child: Icon(
                      _isFullScreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,

                      color: const Color(0xFFFFD700),

                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Floating Voice Settings button (top-right, adjacent to fullscreen)
            Positioned(
              top: topPadding + 8,

              right: 56,

              child: Material(
                color: const Color(0xFF1E0A04).withValues(alpha: 0.65),

                borderRadius: BorderRadius.circular(24),

                child: InkWell(
                  borderRadius: BorderRadius.circular(24),

                  onTap: () {
                    HapticFeedback.lightImpact();
                    GranthVoiceSelectorSheet.show(
                      context,
                      initialLanguage: _detectTtsLanguage(),
                      onVoiceChanged: () {
                        if (_isPlaying) {
                          _verseAudioPlayer.stop();
                          _tts.stop();
                          _speakCurrentSection();
                        } else if (_currentPage >= 1 &&
                            _currentPage <= _verses.length) {
                          _toggleAutoRead();
                        }
                      },
                    );
                  },

                  child: const Padding(
                    padding: EdgeInsets.all(10),

                    child: Icon(
                      Icons.record_voice_over_rounded,

                      color: Color(0xFFFFD700),

                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // ── Floating Controls: "Open Granth" on cover, full reading bar inside ──
            if (!_isLoadingPages)
              Positioned(
                bottom: bottomPadding + 14,

                left: 16,

                right: 16,

                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),

                    switchInCurve: Curves.easeOutCubic,

                    switchOutCurve: Curves.easeInCubic,

                    child: isClosedCover
                        ? _buildOpenGranthButton()
                        : _SacredReaderControlBar(
                            isPlaying: _isPlaying,

                            currentVerseIndex:
                                (_currentPage >= 1 &&
                                    _currentPage <= _verses.length)
                                ? _currentPage - 1
                                : -1,

                            totalVerses: _verses.length,

                            speed: _speedMultiplier,

                            onTogglePlay: _toggleAutoRead,

                            onSpeedCycle: _cycleSpeed,

                            onPrevPage: _goToPrevPage,

                            onNextPage: _goToNextPage,

                            onVoiceSettings: () {
                              GranthVoiceSelectorSheet.show(
                                context,
                                initialLanguage: _detectTtsLanguage(),
                                onVoiceChanged: () {
                                  if (_isPlaying) {
                                    _verseAudioPlayer.stop();
                                    _tts.stop();
                                    _speakCurrentSection();
                                  } else if (_currentPage >= 1 &&
                                      _currentPage <= _verses.length) {
                                    _toggleAutoRead();
                                  }
                                },
                              );
                            },
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

class _SacredAltarBookPlatform extends StatelessWidget {
  const _SacredAltarBookPlatform({
    required this.child,

    required this.isFullScreen,

    required this.isCoverClosed,
  });

  final Widget child;

  final bool isFullScreen;

  final bool isCoverClosed;

  @override
  Widget build(BuildContext context) {
    // ALWAYS retain the exact same Stack hierarchy: child is NEVER reparented or rebuilt across fullscreen!

    return Stack(
      clipBehavior: Clip.none,

      children: [
        // 1. Altar Desk Diya Lamp Aura (steady, warm sanctuary pool beneath the holy granth)
        Positioned(
          left: -28,

          right: -28,

          top: -18,

          bottom: -32,

          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),

              curve: Curves.easeOutCubic,

              opacity: isFullScreen ? 0.0 : 1.0,

              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),

                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x28FF9E3D),

                      blurRadius: 44,

                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Pure physical desk elevation shadows - balanced, symmetrical, realistic

        // Symmetrical downward elevation eliminates ANY diagonal V-shaped shadow artifacts on the altar!
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),

              curve: Curves.easeOutCubic,

              opacity: isFullScreen ? 0.0 : (isCoverClosed ? 1.0 : 0.85),

              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),

                  boxShadow: [
                    // A. Direct contact occlusion line beneath the book base
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),

                      blurRadius: 8,

                      spreadRadius: -1,

                      offset: const Offset(0, 4),
                    ),

                    // B. Soft downward desk shadow (symmetrical X=0)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),

                      blurRadius: 26,

                      spreadRadius: 2,

                      offset: const Offset(0, 14),
                    ),

                    // C. Ambient teakwood altar penumbra
                    BoxShadow(
                      color: const Color(0x40180502),

                      blurRadius: 40,

                      spreadRadius: 4,

                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. The Book Viewer (always mounted in the exact same render slot)
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

    this.onVoiceSettings,
  });

  final bool isPlaying;

  final int currentVerseIndex;

  final int totalVerses;

  final double speed;

  final VoidCallback onTogglePlay;

  final VoidCallback onSpeedCycle;

  final VoidCallback onPrevPage;

  final VoidCallback onNextPage;

  final VoidCallback? onVoiceSettings;

  @override
  State<_SacredReaderControlBar> createState() =>
      _SacredReaderControlBarState();
}

class _SacredReaderControlBarState extends State<_SacredReaderControlBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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

    final speedLabel =
        '${widget.speed == 1.0 ? '1' : widget.speed.toString()}x';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

      decoration: BoxDecoration(
        color: const Color(0xFF1E0A03).withValues(alpha: 0.92),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
          width: 1.1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),

            blurRadius: 14,

            offset: const Offset(0, 4),
          ),

          if (widget.isPlaying)
            BoxShadow(
              color: const Color(0xFFFF8C1A).withValues(alpha: 0.25),

              blurRadius: 12,

              spreadRadius: 1.5,
            ),
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // Previous Verse Button
          IconButton(
            icon: const Icon(
              Icons.skip_previous_rounded,
              color: Color(0xFFFFD54F),
              size: 20,
            ),

            tooltip: 'Previous Page',

            onPressed: widget.onPrevPage,

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),

          const SizedBox(width: 3),

          // Speed Multiplier Pill
          GestureDetector(
            onTap: widget.onSpeedCycle,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),

              decoration: BoxDecoration(
                color: const Color(0xFF381406),

                borderRadius: BorderRadius.circular(12),

                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.speed_rounded,
                    size: 11,
                    color: Color(0xFFFFD54F),
                  ),

                  const SizedBox(width: 3),

                  Text(
                    speedLabel,

                    style: GoogleFonts.outfit(
                      fontSize: 11,

                      fontWeight: FontWeight.w700,

                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

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
                    width: 40,

                    height: 40,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF9E3D), Color(0xFFB85C00)],

                        center: Alignment(-0.2, -0.2),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF8C1A,
                          ).withValues(alpha: widget.isPlaying ? 0.7 : 0.4),

                          blurRadius: widget.isPlaying ? 12 : 6,

                          spreadRadius: widget.isPlaying ? 1.5 : 1,
                        ),
                      ],
                    ),

                    child: Center(
                      child: Icon(
                        widget.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,

                        color: Colors.white,

                        size: 24,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 6),

          // Reading Status Pill
          Container(
            constraints: const BoxConstraints(minWidth: 68),

            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),

            decoration: BoxDecoration(
              color: const Color(0xFF381406),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),

            child: Center(
              child: Text(
                hasVerse
                    ? (widget.isPlaying
                          ? 'Verse $verseNum/${widget.totalVerses}'
                          : 'Verse $verseNum')
                    : (widget.isPlaying ? 'Reciting' : '॥ ॐ ॥'),

                style: GoogleFonts.outfit(
                  fontSize: 11,

                  fontWeight: FontWeight.w600,

                  color: const Color(0xFFFFE082),
                ),
              ),
            ),
          ),

          const SizedBox(width: 3),

          // Next Verse Button
          IconButton(
            icon: const Icon(
              Icons.skip_next_rounded,
              color: Color(0xFFFFD54F),
              size: 20,
            ),

            tooltip: 'Next Page',

            onPressed: widget.onNextPage,

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),

          if (widget.onVoiceSettings != null) ...[
            const SizedBox(width: 3),
            IconButton(
              icon: const Icon(
                Icons.record_voice_over_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
              tooltip: 'Choose Voice',
              onPressed: widget.onVoiceSettings,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
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

    required this.chapter,

    required this.granthTitle,

    required this.chapterTitle,

    required this.verses,

    required this.sepiaMode,

    required this.activeVerseIndex,

    required this.activeSection,

    required this.activeLocalWordIndex,

    required this.isPageCompleted,

    this.onPageChanged,

    this.onPageChanging,

    this.chapterUserRecordings,

    this.onRecordVerseVoice,
  });

  final Map<String, dynamic> granth;

  final Map<String, dynamic> chapter;

  final String granthTitle;

  final String chapterTitle;

  final List<Map<String, String>> verses;

  final bool sepiaMode;

  final int activeVerseIndex;

  final String activeSection;

  final int activeLocalWordIndex;

  final bool isPageCompleted;

  final ValueChanged<int>? onPageChanged;

  final ValueChanged<int>? onPageChanging;

  final Map<int, String>? chapterUserRecordings;

  final ValueChanged<int>? onRecordVerseVoice;

  @override
  State<_BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<_BookViewer>
    with TickerProviderStateMixin {
  /// Width of the visible leather spine strip on the left of the cover, in logical pixels.

  static const double _spineW = 24.0;

  /// Physical thickness of the dense hardbound cover board in logical pixels.

  /// 2.2px matches authentic, slim, elegant luxury hardbound binder's board thickness.

  static const double _boardThickness = 3.6;

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
  void dispose() {
    _turnCtrl.dispose();
    super.dispose();
  }

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

        widget.onPageChanging?.call(_currentPage);

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

      widget.onPageChanging?.call(_currentPage);
    } else if (status == AnimationStatus.dismissed) {
      // The drag was aborted and snapped back to 0.

      setState(() {
        _isTurning = false;

        _isReturning = false;

        _dragProgress = 0;

        _dragStart = null;

        _dragCurrent = null;
      });

      widget.onPageChanging?.call(_currentPage);
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

    final int nextTarget = forward ? (_currentPage + 1) : (_currentPage - 1);

    widget.onPageChanging?.call(nextTarget.clamp(0, totalPages - 1));

    final double startP = _dragProgress.clamp(0.0, 0.99);

    _turnAnim = Tween<double>(
      begin: startP,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic));

    // Dignified, physical paper inertia: cover is heavier hardbound board (640ms), inner pages (540ms)

    final bool isCoverTurn =
        (_currentPage == 0 && forward) || (_currentPage == 1 && !forward);

    final double remaining = (1.0 - startP).clamp(0.12, 1.0);

    final int defaultBase = isCoverTurn ? 640 : 540;

    final int duration = durationMs != null
        ? (durationMs * remaining)
              .clamp(isCoverTurn ? 480.0 : 380.0, 720.0)
              .toInt()
        : (defaultBase * remaining)
              .clamp(isCoverTurn ? 480.0 : 380.0, 720.0)
              .toInt();

    _turnCtrl.duration = Duration(milliseconds: duration);

    _turnCtrl.forward(from: 0.0);
  }

  void _triggerReturn({int? durationMs}) {
    if (_isTurning) return;

    setState(() {
      _isTurning = true;

      _isReturning = true;
    });

    widget.onPageChanging?.call(_currentPage);

    final double startP = _dragProgress.clamp(0.01, 1.0);

    _turnAnim = Tween<double>(
      begin: startP,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic));

    final int duration =
        durationMs ?? (380 + (startP * 120)).clamp(360, 480).toInt();

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

    _turnAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic));

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

      final int dragTarget = forward ? (_currentPage + 1) : (_currentPage - 1);

      widget.onPageChanging?.call(dragTarget.clamp(0, totalPages - 1));
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

    _turnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );

    _turnAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _turnCtrl, curve: Curves.easeOutCubic));

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

          color: widget.sepiaMode
              ? const Color(0xFFF9F4E8)
              : const Color(0xFFF3EFE6),
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
                Text(
                  'ॐ',
                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 68,
                    color: const Color(0xFF5C1405),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '❖ ──── ॐ ──── ❖',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF5C1405),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsideCover(double w, double h) {
    final bgColor = widget.sepiaMode
        ? const Color(0xFFF9F4E8)
        : const Color(0xFFF3EFE6);

    return Container(
      width: w,

      height: h,

      decoration: BoxDecoration(
        color: bgColor,

        gradient: LinearGradient(
          colors: [
            bgColor,

            widget.sepiaMode
                ? const Color(0xFFF2E9D8)
                : const Color(0xFFEAE3D5),

            bgColor,
          ],

          stops: const [0.0, 0.5, 1.0],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,
        ),
      ),

      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ParchmentTexturePainter()),
          ),

          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),

              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
                    width: 1.2,
                  ),

                  borderRadius: BorderRadius.circular(4),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(6),

                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
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
                  '❖ ─── ॐ ─── ❖',

                  style: GoogleFonts.outfit(
                    fontSize: 13,

                    color: const Color(0xFFC59239),

                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'ॐ',

                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 54,

                    color: const Color(0xFF5C1405),

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '॥ श्री सीतारामचन्द्राभ्यां नमः ॥',

                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 15,

                    color: const Color(0xFF5C1405),

                    fontWeight: FontWeight.w700,

                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '॥ ॐ श्री परमात्मने नमः ॥',

                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 13,

                    color: const Color(0xFF8C5320),

                    fontWeight: FontWeight.w600,

                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  '॥ बालकाण्ड ॥',

                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 18,

                    color: const Color(0xFFB37418),

                    fontWeight: FontWeight.bold,

                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DBookCanvas(double progress, double w, double h) {
    final bool isAnimatingOrDragging =
        progress > 0 || _isDragging || _isClosingBook;

    final bool isClosingToCover =
        isAnimatingOrDragging && !_turnForward && _currentPage == 1;

    final int basePageIndex = !isAnimatingOrDragging
        ? _currentPage
        : (_turnForward
              ? (_currentPage + 1)
              : (isClosingToCover ? 1 : _currentPage));

    final int topPageIndex = _isClosingBook
        ? (totalPages - 1)
        : (!isAnimatingOrDragging
              ? _currentPage
              : (_turnForward
                    ? _currentPage
                    : (isClosingToCover ? 0 : _currentPage - 1)));

    final Widget? basePage = _isClosingBook
        ? null
        : _getPage(basePageIndex, w, h);

    final Widget? topPage = _getPage(topPageIndex, w, h);

    final bool isTurning =
        (progress > 0 || _isDragging || _isClosingBook) && topPage != null;

    final bool isFrontCoverTurn =
        ((topPageIndex == 0) || isClosingToCover) && !_isClosingBook;

    // Dynamic Thickness Calculation

    final double maxStackW = 10.0;

    final double swipeProgress = isTurning
        ? (_turnForward ? progress : -progress)
        : 0.0;

    final double effectivePage = (_currentPage + swipeProgress).clamp(
      0.0,
      totalPages - 1.0,
    );

    final double dynamicRatio = totalPages > 1
        ? (effectivePage / (totalPages - 1))
        : 0.0;

    final double rightStackW = maxStackW * (1.0 - dynamicRatio);

    final double leftStackW =
        (_currentPage >= 1 || (isFrontCoverTurn && progress > 0.45))
        ? math.max(6.0, maxStackW * (dynamicRatio > 0 ? dynamicRatio : 0.65))
        : 0.0;

    // Reading page leaf dimensions - full book width when open

    final double leafW = w;

    final double leafH = h;

    Widget content;

    if (!isAnimatingOrDragging) {
      if (_currentPage == 0) {
        content = topPage != null
            ? _wrapPage(0, topPage)
            : const SizedBox.shrink();
      } else {
        content = topPage != null
            ? _wrapInnerLeaf(topPageIndex, topPage)
            : const SizedBox.shrink();
      }
    } else if (isFrontCoverTurn || _isClosingBook) {
      content = _buildHardcoverTurningEngine(
        progress: progress,

        forward: _turnForward,

        isClosing: _isClosingBook,

        basePage: basePage,

        rightStackW: rightStackW,

        leftStackW: leftStackW,

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

        frontPage: topPage != null
            ? _wrapInnerLeaf(topPageIndex, topPage)
            : const SizedBox.shrink(),

        basePage: basePage != null
            ? _wrapInnerLeaf(basePageIndex, basePage)
            : const SizedBox.shrink(),

        backSidePage: _wrapInnerLeaf(
          topPageIndex,

          _getInsidePage(topPageIndex, leafW, leafH) ??
              (topPage ?? const SizedBox.shrink()),
        ),

        width: leafW,

        height: leafH,
      );
    }

    return SizedBox(
      width: w,

      height: h,

      child: Stack(
        clipBehavior: Clip.none,

        children: [Positioned.fill(child: content)],
      ),
    );
  }

  /// Wraps an inner book page leaf with authentic solid cream parchment,

  /// 100% opacity, gold foil bevel border, and ZERO outer margins so there is

  /// never any transparent gap or border during 3D page curl.

  Widget _wrapInnerLeaf(int index, Widget child) {
    final isBackCover = (index == totalPages - 1);

    final radius = Radius.circular(isBackCover ? 6 : 4);

    final borderRadius = BorderRadius.all(radius);

    return Container(
      decoration: BoxDecoration(
        color: isBackCover
            ? const Color(0xFF1E0A03)
            : (widget.sepiaMode
                  ? const Color(0xFFF9F4E8)
                  : const Color(0xFFF3EFE6)),

        borderRadius: borderRadius,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),

            blurRadius: 8,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }

  Widget _wrapPage(int index, Widget child, {bool isLeft = false}) {
    final isCover = (index == 0 || index == totalPages - 1);

    final radius = Radius.circular(isCover ? 6 : 4);

    final borderRadius = BorderRadius.all(radius);

    final margin = EdgeInsets.zero;

    final pageBg = widget.sepiaMode
        ? const Color(0xFFF9F4E8)
        : const Color(0xFFF3EFE6);

    return Container(
      margin: margin,

      decoration: BoxDecoration(
        color: (index == totalPages - 1 && !isLeft)
            ? const Color(0xFF1E0A03)
            : (index == 0 && !isLeft)
            ? const Color(0xFF1E0A03)
            : pageBg,

        borderRadius: borderRadius,

        border: (index == 0 && !isLeft)
            ? const Border(
                // Right fore-edge board thickness border; top/bottom edge bevels and spine headbands are rendered internally in _buildCoverFace
                right: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              )
            : (isCover && !isLeft)
            ? Border(
                top: BorderSide(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 2.0,
                ),

                right: BorderSide(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 2.0,
                ),

                bottom: BorderSide(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 2.0,
                ),
              )
            : Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),

                width: 1.0,
              ),

        boxShadow: (index == 0 && !isLeft)
            ? [
                // 1. Direct contact occlusion shadow grounding the physical book
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),

                  blurRadius: 8,

                  offset: const Offset(0, 4),
                ),

                // 2. Ambient sanctuary desk shadow (dense volume of sacred granth)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),

                  blurRadius: 24,

                  spreadRadius: 1,

                  offset: const Offset(0, 12),
                ),
              ]
            : [
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

      child: ClipRRect(borderRadius: borderRadius, child: child),
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

        activeLocalWordIndex: isThisVerseActive
            ? widget.activeLocalWordIndex
            : -1,

        isPageCompleted: isThisVerseActive ? widget.isPageCompleted : false,

        hasUserRecording:
            widget.chapterUserRecordings?.containsKey(vi) ?? false,

        onRecordTap: () => widget.onRecordVerseVoice?.call(vi),
      );
    }
  }

  // ── Front cover board face — deity artwork, quarter-bound shoulder, bevels, and satin sheen ──

  Widget _buildFrontBoardFace(double faceW, double h) {
    // 1. Detect if this is Bal Kand or Ramcharitmanas/Ramayan

    final String chName =
        (widget.chapter['name'] ??
                widget.chapter['title'] ??
                widget.chapter['chapterTitle'] ??
                '')
            .toString()
            .toLowerCase();

    final String grName =
        (widget.granth['name'] ?? widget.granth['title'] ?? '')
            .toString()
            .toLowerCase();

    final String rawCover =
        (widget.chapter['coverImage'] ??
                widget.chapter['image'] ??
                widget.granth['coverImage'] ??
                widget.granth['image'] ??
                widget.granth['cover'] ??
                '')
            .toString();

    final bool isBalKand =
        chName.contains('bal') ||
        chName.contains('बाल') ||
        chName.contains('ball') ||
        chName.contains('baal') ||
        grName.contains('bal') ||
        grName.contains('बाल') ||
        grName.contains('ball') ||
        grName.contains('baal') ||
        rawCover.toLowerCase().contains('bal') ||
        (rawCover.isEmpty &&
            (grName.contains('ram') || grName.contains('राम'))) ||
        ((widget.chapter['chapterNumber'] == 1 ||
                widget.chapter['chapterNumber'] == '1') &&
            (grName.contains('ram') || grName.contains('राम')));

    Widget imageContent;

    if (isBalKand) {
      imageContent = Image.asset(
        'assets/images/bal_kand_cover.jpg',

        fit: BoxFit.fill,

        width: faceW,

        height: h,

        alignment: Alignment.center,

        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackCoverFace(faceW, h),
      );
    } else {
      final resolvedUrl = ApiService.resolveImageUrl(rawCover);

      if (resolvedUrl.startsWith('http')) {
        imageContent = Image.network(
          resolvedUrl,

          fit: BoxFit.cover,

          width: faceW,

          height: h,

          alignment: Alignment.center,

          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackCoverFace(faceW, h),
        );
      } else if (rawCover.startsWith('assets/')) {
        imageContent = Image.asset(
          rawCover,

          fit: BoxFit.fill,

          width: faceW,

          height: h,

          alignment: Alignment.center,

          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackCoverFace(faceW, h),
        );
      } else {
        imageContent = Image.asset(
          'assets/images/bal_kand_cover.jpg',

          fit: BoxFit.fill,

          width: faceW,

          height: h,

          alignment: Alignment.center,

          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackCoverFace(faceW, h),
        );
      }
    }

    return SizedBox(
      width: faceW,

      height: h,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          // 1. Authentic sacred cream parchment base board beneath artwork
          Positioned.fill(
            child: Container(
              color: widget.sepiaMode
                  ? const Color(0xFFF9F4E8)
                  : const Color(0xFFF3EFE6),
            ),
          ),

          // 2. Deity Artwork (aspect ratio strictly preserved with BoxFit.cover)
          Positioned.fill(child: imageContent),

          // 3. Quarter-bound leather shoulder shadow along the left edge (where board meets French groove)
          Positioned(
            left: 0,

            top: 0,

            bottom: 0,

            width: 8.0,

            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.45),

                      Colors.black.withValues(alpha: 0.15),

                      Colors.transparent,
                    ],

                    stops: const [0.0, 0.45, 1.0],

                    begin: Alignment.centerLeft,

                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // 4. Soft ambient edge vignette (darkens outer margins to focus illumination on deity)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.05),

                    radius: 1.05,

                    colors: [
                      Colors.transparent,

                      Colors.black.withValues(alpha: 0.10),

                      Colors.black.withValues(alpha: 0.35),
                    ],

                    stops: const [0.65, 0.88, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 5. Satin specular sheen across cover board (simulates physical laminated book cloth)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.14),

                      Colors.white.withValues(alpha: 0.03),

                      Colors.black.withValues(alpha: 0.18),
                    ],

                    stops: const [0.0, 0.35, 1.0],

                    begin: const Alignment(-0.8, -1.0),

                    end: const Alignment(0.8, 1.0),
                  ),
                ),
              ),
            ),
          ),

          // 6. Top-edge hardcover board bevel highlight (catching room/desk light)
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
                      Colors.white.withValues(alpha: 0.45),

                      const Color(0xFFFFE082).withValues(alpha: 0.30),

                      Colors.transparent,
                    ],

                    begin: Alignment.topCenter,

                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 7. Bottom-edge hardcover board bevel shadow
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

          // 8. Fore-edge right gold foil trim line along the board rim
          Positioned(
            right: 0,

            top: 0,

            bottom: 0,

            width: 1.5,

            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,

                      const Color(0xFFFFD54F).withValues(alpha: 0.50),

                      const Color(0xFFD4AF37).withValues(alpha: 0.90),
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

  // ── Cover face — 3D curved spine + physical hinge joint + front board artwork + gilded page block reveal ──

  Widget _buildCoverFace(double w, double h) {
    final double faceW = w - _spineW;

    return SizedBox(
      width: w,

      height: h,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          // 1. Front Cover Board (Artwork & Devotional Hardcover Surface - identical dimensions to turning state!)
          Positioned(
            left: _spineW,

            top: 0,

            right: 0,

            bottom: 0,

            child: _buildFrontBoardFace(faceW, h),
          ),

          // 2. Radiant Temple Gold Brocade Spine (Shown from the very start when cover is closed!)
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

            width: 4.5,

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
              const Color(
                0xFF0F0301,
              ).withValues(alpha: 0.90), // Deep groove trough

              Colors.black.withValues(alpha: 0.95), // Shadow joint

              const Color(
                0xFFFFD54F,
              ).withValues(alpha: 0.65), // Board shoulder gold highlight

              const Color(0xFFD4AF37).withValues(alpha: 0.35),

              Colors.transparent,
            ],

            stops: const [0.0, 0.35, 0.65, 0.85, 1.0],

            begin: Alignment.centerLeft,

            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Widget _wrapCoverBoard(Widget child, double boardW, double h) {
    const radius = Radius.circular(5);

    const borderRadius = BorderRadius.only(
      topRight: radius,
      bottomRight: radius,
    );

    return Container(
      width: boardW,

      height: h,

      decoration: BoxDecoration(
        color: widget.sepiaMode
            ? const Color(0xFFF9F4E8)
            : const Color(0xFFF3EFE6),

        borderRadius: borderRadius,

        border: const Border(
          right: BorderSide(color: Color(0xFFD4AF37), width: 1.0),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),

            blurRadius: 8,

            offset: const Offset(2, 4),
          ),
        ],
      ),

      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }

  Widget _wrapInsideCoverBoard(Widget child, double boardW, double h) {
    const radius = Radius.circular(5);

    const borderRadius = BorderRadius.only(
      topRight: radius,
      bottomRight: radius,
    );

    return Container(
      width: boardW,

      height: h,

      decoration: BoxDecoration(
        color: widget.sepiaMode
            ? const Color(0xFFF9F4E8)
            : const Color(0xFFF3EFE6),

        borderRadius: borderRadius,

        border: const Border(
          right: BorderSide(color: Color(0xFFD4AF37), width: 1.0),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),

            blurRadius: 8,

            offset: const Offset(2, 4),
          ),
        ],
      ),

      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }

  // ── 3D Hardcover Turning Engine (Realistic Thickness, Connected Hinge, Dynamic Shadow) ──

  Widget _buildHardcoverTurningEngine({
    required double progress,

    required bool forward,

    required bool isClosing,

    required Widget? basePage,

    required double rightStackW,

    required double leftStackW,

    required double w,

    required double h,
  }) {
    // 1. Turn angle: 0.0 (closed) to pi (fully open)

    final double turnAngle = isClosing
        ? (progress * math.pi)
        : (forward ? (progress * math.pi) : ((1.0 - progress) * math.pi));

    final double sineAngle = math.sin(turnAngle);

    final bool isFrontVisible = turnAngle <= (math.pi / 2);

    final double boardW = w - _spineW;

    final double openFactor = (turnAngle / math.pi).clamp(0.0, 1.0);

    final double stretchFactor = Curves.easeInOutCubic.transform(openFactor);

    final double spineFade = (1.0 - stretchFactor).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,

      children: [
        // ── A. Underneath Page (Verse 1) - Static, full-width (text NEVER moves or contracts) ──
        if (basePage != null)
          Positioned(
            left: 0,

            top: 0,

            bottom: 0,

            width: w,

            child: _wrapInnerLeaf(1, basePage),
          ),

        // Dynamic cast shadow from the swinging cover board onto the static page
        if (basePage != null && sineAngle > 0.01)
          Positioned(
            left: 0,

            top: 0,

            bottom: 0,

            width: w,

            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(
                        0xFF8C7355,
                      ).withValues(alpha: (0.16 * sineAngle).clamp(0.0, 0.20)),

                      const Color(
                        0xFF8C7355,
                      ).withValues(alpha: (0.05 * sineAngle).clamp(0.0, 0.08)),

                      Colors.transparent,
                    ],

                    stops: const [0.0, 0.25, 1.0],

                    begin: Alignment.centerLeft,

                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

        // ── B. Spine & French Groove at X = 0 (fades out as page stretches over it) ──
        if (spineFade > 0.005) ...[
          Positioned(
            left: 0,

            top: 0,

            bottom: 0,

            width: _spineW,

            child: Opacity(
              opacity: spineFade,

              child: _buildSpineStrip(_spineW, h),
            ),
          ),

          Positioned(
            left: _spineW - 2.0,

            top: 0,

            bottom: 0,

            width: 4.5,

            child: Opacity(opacity: spineFade, child: _buildFrenchGroove()),
          ),
        ],

        // ── C. The Rigid Hardcover Board (Swings around hinge at X = _spineW with true 3D solid thickness) ──
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
                // 1. Inside Cover (facing viewer when turned past 90°) - constant depth maintains realistic thickness
                if (!isFrontVisible)
                  Transform(
                    alignment: Alignment.center,

                    transform: Matrix4.identity()
                      ..setEntry(0, 0, -1.0)
                      ..setTranslationRaw(0.0, 0.0, -_boardThickness),

                    child: _wrapInsideCoverBoard(
                      _buildInsideCover(boardW, h),
                      boardW,
                      h,
                    ),
                  ),

                // 2. Front Cover Board Face (Artwork, visible 0° to 90°)
                if (isFrontVisible)
                  Stack(
                    children: [
                      _wrapCoverBoard(
                        _buildFrontBoardFace(boardW, h),
                        boardW,
                        h,
                      ),

                      // Ambient tilt darkening on front face
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (sineAngle * 0.8).clamp(0.0, 1.0),

                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.18),

                                    Colors.white.withValues(alpha: 0.15),

                                    Colors.black.withValues(alpha: 0.35),
                                  ],

                                  stops: const [0.0, 0.45, 1.0],

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

                // 3. 3D Hardcover Fore-Edge Thickness Slab (permanently locked to outer edge x = boardW)
                Positioned(
                  left: boardW,

                  top: 0,

                  bottom: 0,

                  width: _boardThickness,

                  child: Transform(
                    alignment: Alignment.centerLeft,

                    transform: Matrix4.identity()..rotateY(math.pi / 2),

                    child: _buildForeEdge3DSlab(_boardThickness, h, turnAngle),
                  ),
                ),

                // 4. 3D Hardcover Top Head-Edge Slab (permanently locked to top edge y = 0)
                Positioned(
                  left: 0,

                  right: 0,

                  top: 0,

                  height: _boardThickness,

                  child: Transform(
                    alignment: Alignment.topCenter,

                    transform: Matrix4.identity()..rotateX(-math.pi / 2),

                    child: _buildTopEdge3DSlab(
                      boardW,
                      _boardThickness,
                      turnAngle,
                    ),
                  ),
                ),

                // 5. 3D Hardcover Bottom Tail-Edge Slab (permanently locked to bottom edge y = h)
                Positioned(
                  left: 0,

                  right: 0,

                  bottom: 0,

                  height: _boardThickness,

                  child: Transform(
                    alignment: Alignment.bottomCenter,

                    transform: Matrix4.identity()..rotateX(math.pi / 2),

                    child: _buildBottomEdge3DSlab(
                      boardW,
                      _boardThickness,
                      turnAngle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForeEdge3DSlab(double thickness, double h, double turnAngle) {
    final double sineAngle = math.sin(turnAngle);

    final double lightHighlight = (sineAngle * 0.40).clamp(0.0, 0.50);

    return Container(
      width: thickness,

      height: h,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD54F), // Front gold foil bevel rim

            Color(0xFFFFE082), // Gold rim

            Color(0xFFF9F4E8), // Cream parchment outer endpaper

            Color(0xFFD4AF37), // Solid gilded gold core ply

            Color(0xFFF9F4E8), // Cream parchment inner endpaper

            Color(0xFFFFE082), // Inside gold bevel

            Color(0xFFD4AF37), // Inside gold edge trim
          ],

          stops: [0.0, 0.15, 0.32, 0.50, 0.68, 0.85, 1.0],

          begin: Alignment.centerLeft,

          end: Alignment.centerRight,
        ),
      ),

      child: Stack(
        children: [
          // Dynamic specular sheen across the fore-edge
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,

                      Colors.white.withValues(alpha: lightHighlight),

                      Colors.transparent,
                    ],

                    stops: const [0.2, 0.5, 0.8],

                    begin: Alignment.topCenter,

                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Center gilded core thread line
          Center(
            child: Container(
              width: 0.6,

              color: const Color(0xFFFFD700).withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEdge3DSlab(
    double boardW,
    double thickness,
    double turnAngle,
  ) {
    return Container(
      width: boardW,

      height: thickness,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFFFE082), Color(0xFFD4AF37)],

          begin: Alignment.centerLeft,

          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildBottomEdge3DSlab(
    double boardW,
    double thickness,
    double turnAngle,
  ) {
    return Container(
      width: boardW,

      height: thickness,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8C6D23), Color(0xFFB59350), Color(0xFF8C6D23)],

          begin: Alignment.centerLeft,

          end: Alignment.centerRight,
        ),
      ),
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
          Positioned.fill(
            child: CustomPaint(painter: _LeatherTexturePainter()),
          ),

          Positioned.fill(
            child: CustomPaint(painter: _SacredCoverFramePainter()),
          ),

          Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.5,
                    ),

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
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFFD4AF37),
                        size: 56,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        widget.granthTitle,
                        textAlign: TextAlign.center,

                        style: GoogleFonts.notoSerifDevanagari(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,

                          color: const Color(0xFFFFD700),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '❖ ──── ॐ ──── ❖',

                        style: GoogleFonts.outfit(
                          color: const Color(0xFFD4AF37),
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.chapterTitle,
                        textAlign: TextAlign.center,

                        style: GoogleFonts.outfit(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.85),

                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // ── Spine strip — authentic 3D curved hardcover spine matching the back of the book ──

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

            blurRadius: 6,

            spreadRadius: 0,

            offset: const Offset(-2, 2),
          ),
        ],

        // Radiant Temple Gold & Amber Brocade Spine (Shown from starting!)
        gradient: const LinearGradient(
          colors: [
            Color(0xFF331D03), // Deep antique gold shadow on outer curve

            Color(0xFF5A3608),

            Color(0xFF7A4E12), // Rising golden brocade shoulder

            Color(0xFFB57C1C), // Warm golden silk

            Color(
              0xFFE5A836,
            ), // Apex crown of cylindrical spine with radiant gleam

            Color(0xFFC58B24), // Flank

            Color(0xFF8C5B17), // Turning toward French groove

            Color(0xFF452705), // Entering groove joint
          ],

          stops: [0.0, 0.08, 0.18, 0.32, 0.50, 0.70, 0.88, 1.0],

          begin: Alignment.centerLeft,

          end: Alignment.centerRight,
        ),
      ),

      child: Stack(
        children: [
          // 0. Outer left 3D cylindrical roll-off shadow (physical curvature)
          Positioned(
            left: 0,

            top: 0,

            bottom: 0,

            width: 7.5,

            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),

                    bottomLeft: Radius.circular(5),
                  ),

                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.80),

                      Colors.black.withValues(alpha: 0.45),

                      Colors.black.withValues(alpha: 0.15),

                      Colors.transparent,
                    ],

                    stops: const [0.0, 0.40, 0.75, 1.0],

                    begin: Alignment.centerLeft,

                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // 1. Organic golden fabric / parchment texture
          Positioned.fill(
            child: CustomPaint(painter: _LeatherTexturePainter()),
          ),

          // 2. Curvature specular gleam (vertical highlight beam along the spine crown)
          Positioned(
            left: spineW * 0.18,

            top: 0,

            bottom: 0,

            width: spineW * 0.36,

            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,

                      Colors.white.withValues(alpha: 0.28),

                      const Color(0xFFFFF3D0).withValues(alpha: 0.38),

                      Colors.transparent,
                    ],

                    stops: const [0.0, 0.40, 0.65, 1.0],

                    begin: Alignment.centerLeft,

                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // 3. Five raised gold & amber spine ribs
          Positioned.fill(
            child: const CustomPaint(painter: _SpineRibsPainter()),
          ),

          // 4. Gold tooling line along the inner hinge edge
          Positioned(
            right: 0,

            top: 0,

            bottom: 0,

            width: 1.5,

            child: Container(
              color: const Color(0xFFFFD700).withValues(alpha: 0.70),
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
      canvas.drawLine(
        Offset(size.width, y),
        Offset(0, y + 3),
        shadowPebblePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ParchmentTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fiberPaint = Paint()
      ..color = const Color(0xFF8C7355).withValues(alpha: 0.04)
      ..strokeWidth = 0.6;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;

    for (double y = 4.0; y < size.height; y += 12.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 2.0), fiberPaint);
    }

    for (double y = 8.0; y < size.height; y += 16.0) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - 1.5),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpineRibsPainter extends CustomPainter {
  const _SpineRibsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 5 raised sewing cords / spine ribs

    const ribPositions = [0.10, 0.28, 0.50, 0.72, 0.90];

    const double ribH = 4.5;

    final topHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final bottomShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final goldLinePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.85)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    for (final relY in ribPositions) {
      final y = size.height * relY;

      final rect = Rect.fromLTWH(0, y - ribH / 2, size.width, ribH);

      // Raised ridge 3D cylindrical convex gradient matching book leather

      final ribPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF5E390A),

            Color(0xFFB57C1C),

            Color(0xFFFFD700),

            Color(0xFFB57C1C),

            Color(0xFF5E390A),
          ],

          stops: [0.0, 0.20, 0.45, 0.75, 1.0],

          begin: Alignment.centerLeft,

          end: Alignment.centerRight,
        ).createShader(rect);

      canvas.drawRect(rect, ribPaint);

      // Top light-catching specular line

      canvas.drawLine(
        Offset(1, y - ribH / 2 + 0.3),
        Offset(size.width, y - ribH / 2 + 0.3),
        topHighlightPaint,
      );

      // Dual gold fillet tooling (top and bottom fine gold hot-stamped lines)

      canvas.drawLine(
        Offset(2, y - 0.9),
        Offset(size.width - 1, y - 0.9),
        goldLinePaint,
      );

      canvas.drawLine(
        Offset(2, y + 0.9),
        Offset(size.width - 1, y + 0.9),
        goldLinePaint,
      );

      // Bottom deep cast shadow onto spine leather below

      canvas.drawLine(
        Offset(0, y + ribH / 2),
        Offset(size.width, y + ribH / 2),
        bottomShadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SacredCoverFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double margin = 10.0;

    final outerRect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

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

    canvas.drawLine(
      Offset(outerRect.left - 2, outerRect.top + bracketLen),
      Offset(outerRect.left - 2, outerRect.top - 2),
      cornerFlourishPaint,
    );

    canvas.drawLine(
      Offset(outerRect.left - 2, outerRect.top - 2),
      Offset(outerRect.left + bracketLen, outerRect.top - 2),
      cornerFlourishPaint,
    );

    // Top-Right corner bracket

    canvas.drawLine(
      Offset(outerRect.right + 2, outerRect.top + bracketLen),
      Offset(outerRect.right + 2, outerRect.top - 2),
      cornerFlourishPaint,
    );

    canvas.drawLine(
      Offset(outerRect.right + 2, outerRect.top - 2),
      Offset(outerRect.right - bracketLen, outerRect.top - 2),
      cornerFlourishPaint,
    );

    // Bottom-Left corner bracket

    canvas.drawLine(
      Offset(outerRect.left - 2, outerRect.bottom - bracketLen),
      Offset(outerRect.left - 2, outerRect.bottom + 2),
      cornerFlourishPaint,
    );

    canvas.drawLine(
      Offset(outerRect.left - 2, outerRect.bottom + 2),
      Offset(outerRect.left + bracketLen, outerRect.bottom + 2),
      cornerFlourishPaint,
    );

    // Bottom-Right corner bracket

    canvas.drawLine(
      Offset(outerRect.right + 2, outerRect.bottom - bracketLen),
      Offset(outerRect.right + 2, outerRect.bottom + 2),
      cornerFlourishPaint,
    );

    canvas.drawLine(
      Offset(outerRect.right + 2, outerRect.bottom + 2),
      Offset(outerRect.right - bracketLen, outerRect.bottom + 2),
      cornerFlourishPaint,
    );
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

    this.hasUserRecording = false,

    this.onRecordTap,
  });

  final Map<String, String> verse;

  final int verseIndex;

  final bool sepiaMode;

  final String
  activeSection; // 'sanskrit', 'transliteration', 'hindi', 'english', or ''

  final int activeLocalWordIndex; // -1 if none

  final bool isPageCompleted;

  final bool hasUserRecording;

  final VoidCallback? onRecordTap;

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
      if (widget.activeSection == 'sanskrit' ||
          widget.activeSection == 'transliteration') {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
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

  Widget _buildKaraokeText(
    String text,
    TextStyle baseStyle,
    String sectionName,
  ) {
    if (text.isEmpty) return const SizedBox.shrink();

    final matches = _GranthChapterReaderScreenState.granthWordPattern
        .allMatches(text)
        .toList();

    if (matches.isEmpty) {
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

    final isSectionActive = (widget.activeSection == sectionName);

    final isPageComplete = widget.isPageCompleted;

    const sectionOrder = ['sanskrit', 'transliteration', 'hindi', 'english'];

    final currentSectionIdx = sectionOrder.indexOf(widget.activeSection);

    final thisSectionIdx = sectionOrder.indexOf(sectionName);

    final bool isPastSection =
        currentSectionIdx > thisSectionIdx && currentSectionIdx != -1;

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
        spans.add(
          TextSpan(text: text.substring(lastIndex, m.start), style: baseStyle),
        );
      }

      final wordStr = m.group(0)!;
      final isCitation = _GranthChapterReaderScreenState.citationPattern
          .hasMatch(wordStr);

      final isHighlighted =
          isSectionActive && (i == widget.activeLocalWordIndex) && !isCitation;

      final isWordRead =
          isPageComplete ||
          isPastSection ||
          (isSectionActive && i < widget.activeLocalWordIndex);

      if (isHighlighted) {
        // Pure text highlight without background box - glowing sacred saffron

        spans.add(
          TextSpan(
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
          ),
        );
      } else if (isWordRead) {
        // Completed/read word - warm sacred terracotta/amber tone

        spans.add(
          TextSpan(
            text: wordStr,

            style: baseStyle.copyWith(
              color: const Color(0xFFA04000), // Rich warm amber text

              fontWeight: FontWeight.w700,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: wordStr, style: baseStyle));
      }

      lastIndex = m.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.center);
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = widget.sepiaMode
        ? const Color(0xFF332014)
        : const Color(0xFF261910);

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

    const double contentTopPadding = 14.0;

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

          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),

            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
              width: 0.8,
            ),
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

                    padding: EdgeInsets.only(
                      top: contentTopPadding,
                      bottom: 24,
                    ),

                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          constraints.maxHeight - (contentTopPadding + 24),
                        ),
                      ),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                '❖ ──── ',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFC59239),
                                  fontSize: 10,
                                ),
                              ),

                              Text(
                                'ॐ',
                                style: GoogleFonts.notoSerifDevanagari(
                                  fontSize: 18,
                                  color: const Color(0xFF5C1405),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                ' ──── ❖',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFC59239),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Reading indicator pil/l — shows current active recitation section
                          if (!widget.isPageCompleted &&
                              widget.activeLocalWordIndex >= 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),

                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),

                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF8C1A,
                                ).withValues(alpha: 0.15),

                                border: Border.all(
                                  color: const Color(
                                    0xFFFF8C1A,
                                  ).withValues(alpha: 0.5),
                                  width: 0.8,
                                ),

                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  const Icon(
                                    Icons.auto_stories_rounded,
                                    size: 11,
                                    color: Color(0xFFD55F00),
                                  ),

                                  const SizedBox(width: 5),

                                  Text(
                                    widget.activeSection == 'sanskrit'
                                        ? 'श्लोक पाठ'
                                        : (widget.activeSection ==
                                                  'transliteration'
                                              ? 'उच्चारण पाठ'
                                              : (widget.activeSection == 'hindi'
                                                    ? 'भावार्थ पाठ'
                                                    : 'English Translation')),

                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: const Color(0xFFD55F00),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Text(
                            'Verse ${widget.verseIndex + 1}',

                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8B6048),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── My Voice recording badge / button ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.hasUserRecording)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF5A623,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFF5A623),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.mic,
                                        size: 13,
                                        color: Color(0xFFD55F00),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'તમારો અવાજ',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: const Color(0xFFD55F00),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              GestureDetector(
                                onTap: widget.onRecordTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1E0A04,
                                    ).withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF8B6048,
                                      ).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.hasUserRecording
                                            ? Icons.mic
                                            : Icons.mic_none,
                                        size: 14,
                                        color: const Color(0xFF8B6048),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.hasUserRecording
                                            ? 'ફેરફાર કરો'
                                            : 'અવાજ રેકોર્ડ',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: const Color(0xFF8B6048),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

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

                              GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.6,
                                color: bodyColor.withValues(alpha: 0.85),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),

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

                              GoogleFonts.notoSerifDevanagari(
                                fontSize: 16,
                                height: 1.7,
                                color: bodyColor.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w500,
                              ),

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

                              GoogleFonts.outfit(
                                fontSize: 14.5,
                                height: 1.65,
                                color: bodyColor.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w500,
                              ),

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

                    filterQuality: FilterQuality.high,
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
        Container(
          width: 26,
          height: 1,
          color: const Color(0xFFC59239).withValues(alpha: 0.5),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),

          child: Text(
            label,

            style: devanagari
                ? GoogleFonts.notoSerifDevanagari(
                    fontSize: 12,
                    color: const Color(0xFF5C1405),
                    fontWeight: FontWeight.bold,
                  )
                : GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF5C1405),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
          ),
        ),

        Container(
          width: 26,
          height: 1,
          color: const Color(0xFFC59239).withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// BACK COVER PAGE

// ─────────────────────────────────────────────────────────────────────────────

class _BackCoverPage extends StatelessWidget {
  const _BackCoverPage({
    required this.granthName,
    required this.onReadAgain,
    required this.onClose,
  });

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
            Text(
              '❖ ──────── ॐ ──────── ❖',
              style: GoogleFonts.outfit(
                color: const Color(0xFFD4AF37),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 22),

            const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 46),

            const SizedBox(height: 16),

            Text(
              'ॐ शान्तिः शान्तिः शान्तिः ॐ',
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

            const SizedBox(height: 26),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: onReadAgain,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C1A),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),

                    icon: const Icon(
                      Icons.restart_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),

                    label: Text(
                      'Read Again',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: onClose,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,

                      side: const BorderSide(
                        color: Color(0xFFFF8C1A),
                        width: 1.5,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),

                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFFF8C1A),
                      size: 16,
                    ),

                    label: Text(
                      'Close Book',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF8C1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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

    required this.forward, // true = right-to-left, false = left-to-right

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

    final double normY = ((touchY - height * 0.5) / (height * 0.5)).clamp(
      -1.0,
      1.0,
    );

    // 2. Corner Lead & Lag Physics

    // Zone A (Top): normY < -0.18 -> Top corner peels first, bottom lags

    // Zone B (Bottom): normY > 0.18 -> Bottom corner peels first, top lags

    // Zone C (Middle): |normY| <= 0.18 -> Balanced cylindrical curl

    double pTop = clampedP;

    double pBottom = clampedP;

    if (normY < -0.18) {
      final double strength = ((-normY - 0.18) / 0.82).clamp(0.0, 1.0);

      final double bias =
          0.36 * (0.35 + 0.65 * strength) * math.sin(clampedP * math.pi);

      pTop = (clampedP + bias).clamp(0.0, 1.0);

      pBottom = (clampedP - bias).clamp(0.0, 1.0);
    } else if (normY > 0.18) {
      final double strength = ((normY - 0.18) / 0.82).clamp(0.0, 1.0);

      final double bias =
          0.36 * (0.35 + 0.65 * strength) * math.sin(clampedP * math.pi);

      pBottom = (clampedP + bias).clamp(0.0, 1.0);

      pTop = (clampedP - bias).clamp(0.0, 1.0);
    } else {
      pTop = clampedP;

      pBottom = clampedP;
    }

    // 3. Crease Fold Coordinates

    // Forward (Right-to-Left): fold sweeps from width (p=0) to 0 (p=1)

    // Reverse (Left-to-Right): fold sweeps from 0 (p=0) to width (p=1)

    final double fTop = forward ? width * (1.0 - pTop) : width * pTop;

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

                    child: SizedBox(
                      width: width,
                      height: height,
                      child: basePage,
                    ),
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

                    opacity: (0.45 * math.sin(clampedP * math.pi)).clamp(
                      0.0,
                      0.48,
                    ),
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
                          color: Colors.black.withValues(
                            alpha: (0.35 * math.sin(clampedP * math.pi)).clamp(
                              0.0,
                              0.38,
                            ),
                          ),

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

                                  Colors.white.withValues(
                                    alpha: 0.45 * math.sin(clampedP * math.pi),
                                  ),

                                  Colors.black.withValues(
                                    alpha: 0.30 * math.sin(clampedP * math.pi),
                                  ),
                                ],

                                stops: const [0.0, 0.70, 1.0],

                                begin: forward
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,

                                end: forward
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
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
      ..shader =
          LinearGradient(
            colors: [
              Colors.black.withValues(alpha: opacity),

              Colors.black.withValues(alpha: opacity * 0.40),

              Colors.black.withValues(alpha: opacity * 0.10),

              Colors.transparent,
            ],

            stops: const [0.0, 0.25, 0.65, 1.0],

            begin: Alignment.centerLeft,

            end: Alignment.centerRight,
          ).createShader(
            Rect.fromLTRB(
              math.min(xt, xb),

              0,

              math.max(xt, xb) + shadowWidth,

              h,
            ),
          );

    canvas.drawPath(shadowPath, paint);
  }

  @override
  bool shouldRepaint(_DiagonalCreaseShadowPainter old) =>
      old.fTop != fTop ||
      old.fBottom != fBottom ||
      old.forward != forward ||
      old.opacity != opacity;
}
