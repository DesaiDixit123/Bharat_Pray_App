import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/user_verse_recording_service.dart';

/// Modal bottom sheet allowing devotees to record their own real voice
/// for any verse of a scripture chapter.
class RecordVerseVoiceSheet extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;
  final int verseIndex;
  final int totalVerses;
  final String sanskritText;
  final String transliterationText;
  final String meaningText;
  final VoidCallback? onRecordingSaved;

  const RecordVerseVoiceSheet({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.verseIndex,
    required this.totalVerses,
    required this.sanskritText,
    this.transliterationText = '',
    this.meaningText = '',
    this.onRecordingSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String chapterId,
    required String chapterTitle,
    required int verseIndex,
    required int totalVerses,
    required String sanskritText,
    String transliterationText = '',
    String meaningText = '',
    VoidCallback? onRecordingSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordVerseVoiceSheet(
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        verseIndex: verseIndex,
        totalVerses: totalVerses,
        sanskritText: sanskritText,
        transliterationText: transliterationText,
        meaningText: meaningText,
        onRecordingSaved: onRecordingSaved,
      ),
    );
  }

  @override
  State<RecordVerseVoiceSheet> createState() => _RecordVerseVoiceSheetState();
}

enum _RecordState { idle, recording, recorded, playing, saving }

class _RecordVerseVoiceSheetState extends State<RecordVerseVoiceSheet>
    with SingleTickerProviderStateMixin {
  final UserVerseRecordingService _recordingService =
      UserVerseRecordingService();
  final AudioPlayer _previewPlayer = AudioPlayer();

  _RecordState _state = _RecordState.idle;
  String? _recordedFilePath;
  bool _hasExistingRecording = false;
  // ignore: unused_field
  String? _existingAudioUrl;

  Timer? _timer;
  int _recordSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _state = _RecordState.recorded;
        });
      }
    });

    _checkExistingRecording();
  }

  Future<void> _checkExistingRecording() async {
    final existing = await _recordingService.getAudioForVerse(
      widget.chapterId,
      widget.verseIndex,
    );
    if (mounted && existing != null && existing.isNotEmpty) {
      setState(() {
        _hasExistingRecording = true;
        _existingAudioUrl = existing;
        _recordedFilePath = existing;
        _state = _RecordState.recorded;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final permitted = await _recordingService.hasPermission();
    if (!permitted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('કૃપા કરીને માઇક્રોફોન ની પરવાનગી આપો.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _previewPlayer.stop();

    final path = await _recordingService.startRecording(
      chapterId: widget.chapterId,
      verseIndex: widget.verseIndex,
    );

    if (path != null && mounted) {
      setState(() {
        _state = _RecordState.recording;
        _recordSeconds = 0;
        _recordedFilePath = path;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recordingService.stopRecording();
    if (mounted) {
      setState(() {
        _state = _RecordState.recorded;
        _recordedFilePath = path ?? _recordedFilePath;
      });
    }
  }

  Future<void> _playPreview() async {
    if (_recordedFilePath == null) return;
    try {
      setState(() {
        _state = _RecordState.playing;
      });
      await _previewPlayer.stop();

      if (_recordedFilePath!.startsWith('http')) {
        await _previewPlayer.play(UrlSource(_recordedFilePath!));
      } else {
        await _previewPlayer.play(DeviceFileSource(_recordedFilePath!));
      }
    } catch (e) {
      debugPrint('[RecordVerseVoiceSheet] Preview error: $e');
      if (mounted) {
        setState(() {
          _state = _RecordState.recorded;
        });
      }
    }
  }

  Future<void> _stopPreview() async {
    await _previewPlayer.stop();
    if (mounted) {
      setState(() {
        _state = _RecordState.recorded;
      });
    }
  }

  Future<void> _saveRecording() async {
    if (_recordedFilePath == null) return;

    // If it's already an existing online recording and didn't re-record, just pop
    if (_recordedFilePath!.startsWith('http')) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _state = _RecordState.saving;
    });

    try {
      await _recordingService.uploadRecording(
        chapterId: widget.chapterId,
        verseIndex: widget.verseIndex,
        filePath: _recordedFilePath!,
        verseText: widget.sanskritText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'તમારો સાચો અવાજ સફળતાપૂર્વક સાચવવામાં આવ્યો! હવે આ શ્લોક તમારા અવાજમાં સંભળાશે.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onRecordingSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _RecordState.recorded;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('સેવ કરવામાં ભૂલ આવી: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecording() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('અવાજ કાઢી નાખવો છે?'),
        content: const Text(
          'શું તમે ખરેખર આ શ્લોક માટે તમારો રેકોર્ડ કરેલો અવાજ કાઢી નાખવા માંગો છો?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ના'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('હા, કાઢી નાખો', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _previewPlayer.stop();
      await _recordingService.deleteRecording(
        chapterId: widget.chapterId,
        verseIndex: widget.verseIndex,
      );

      if (mounted) {
        setState(() {
          _hasExistingRecording = false;
          _recordedFilePath = null;
          _existingAudioUrl = null;
          _state = _RecordState.idle;
        });
        widget.onRecordingSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('તમારો અવાજ કાઢી નાખવામાં આવ્યો છે.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE65100);
    final softGold = const Color(0xFFFFF8E1);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic, color: primaryOrange, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'તમારો સાચો અવાજ રેકોર્ડ કરો',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.chapterTitle} • શ્લોક ${widget.verseIndex + 1} / ${widget.totalVerses}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Devotional Shloka Text Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : softGold,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_stories, size: 16, color: primaryOrange),
                        const SizedBox(width: 6),
                        Text(
                          'શ્લોક (આ વાંચીને બોલો):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.sanskritText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        color: isDark ? Colors.amber[100] : const Color(0xFF3E2723),
                      ),
                    ),
                    if (widget.transliterationText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.transliterationText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                    if (widget.meaningText.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text(
                        'અર્થ: ${widget.meaningText}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recording / Playback Centerpiece
              Center(
                child: Column(
                  children: [
                    if (_state == _RecordState.recording) ...[
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.18),
                            border: Border.all(color: Colors.red, width: 3),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.red,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'રેકોર્ડિંગ ચાલુ છે... ${_formatTimer(_recordSeconds)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop),
                        label: const Text(
                          'બોલવાનું પૂર્ણ કરો (Stop)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else if (_state == _RecordState.recorded ||
                        _state == _RecordState.playing ||
                        _state == _RecordState.saving) ...[
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2E7D32).withOpacity(0.12),
                          border: Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Color(0xFF2E7D32),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _hasExistingRecording && _recordSeconds == 0
                          ? 'આ શ્લોક માટે તમારો અવાજ રેકોર્ડ થયેલો છે'
                          : 'અવાજ રેકોર્ડ થઈ ગયો! (${_formatTimer(_recordSeconds)})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Play / Stop preview button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _state == _RecordState.playing
                                ? _stopPreview
                                : _playPreview,
                            icon: Icon(
                              _state == _RecordState.playing
                                  ? Icons.stop
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              _state == _RecordState.playing
                                  ? 'સાંભળવાનું બંધ કરો'
                                  : 'મારો અવાજ સાંભળો',
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Re-record button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryOrange,
                              side: BorderSide(color: primaryOrange),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _startRecording,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('ફરી રેકોર્ડ કરો'),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Idle State: big mic button
                      InkWell(
                        onTap: _startRecording,
                        borderRadius: BorderRadius.circular(44),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryOrange.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'બોલવાનું શરૂ કરવા માટે ટેપ કરો',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Action Button
              if (_state == _RecordState.recorded ||
                  _state == _RecordState.playing ||
                  _state == _RecordState.saving) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _state == _RecordState.saving ? null : _saveRecording,
                  child: _state == _RecordState.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'આ શ્લોક માટે મારો અવાજ સાચવો (Apply Voice)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (_hasExistingRecording) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('સાચવેલો અવાજ કાઢી નાખો'),
                  ),
                ],
              ],

              const SizedBox(height: 12),

              // Reassurance info banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: primaryOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '૧૦૦% તમારો જ ઓરિજિનલ અવાજ: આ શ્લોક વગાડતી વખતે સીધો તમારો જ રેકોર્ડ કરેલો અવાજ સંભળાશે.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : const Color(0xFFBF360C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
