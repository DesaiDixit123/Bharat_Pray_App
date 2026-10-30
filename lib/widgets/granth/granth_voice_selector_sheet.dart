import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/tts_voice_model.dart';
import '../../services/tts_service.dart';
import '../../services/user_verse_recording_service.dart';

class GranthVoiceSelectorSheet extends StatefulWidget {
  final String? initialLanguage;
  final VoidCallback? onVoiceChanged;

  const GranthVoiceSelectorSheet({
    super.key,
    this.initialLanguage,
    this.onVoiceChanged,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialLanguage,
    VoidCallback? onVoiceChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GranthVoiceSelectorSheet(
        initialLanguage: initialLanguage,
        onVoiceChanged: onVoiceChanged,
      ),
    );
  }

  @override
  State<GranthVoiceSelectorSheet> createState() =>
      _GranthVoiceSelectorSheetState();
}

class _GranthVoiceSelectorSheetState extends State<GranthVoiceSelectorSheet> {
  final TtsService _ttsService = TtsService();
  final UserVerseRecordingService _recordingService =
      UserVerseRecordingService();

  List<TtsVoice> _allVoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  late TtsPreferences _preferences;
  StreamSubscription? _previewSub;
  String? _activePlayingUrl;
  bool _prioritizeMyVoice = true;

  @override
  void initState() {
    super.initState();

    _previewSub = _ttsService.previewStateStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _activePlayingUrl = isPlaying ? _ttsService.activePreviewUrl : null;
        });
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _previewSub?.cancel();
    _ttsService.stopPreview();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await _ttsService.loadPreferences();
      final voices = await _ttsService.fetchVoices();
      final prioritize = await _recordingService.isPrioritizeMyVoiceEnabled();

      if (mounted) {
        setState(() {
          _preferences = prefs;
          _allVoices = voices;
          _prioritizeMyVoice = prioritize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load voices. Please try again.';
        });
      }
    }
  }

  Future<void> _saveAndClose() async {
    HapticFeedback.mediumImpact();
    _ttsService.clearAudioCache();
    await _ttsService.savePreferences(_preferences);
    await _recordingService.setPrioritizeMyVoice(_prioritizeMyVoice);
    widget.onVoiceChanged?.call();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'અવાજ સેવ થઈ ગયો છે! ગ્રંથ હવે આ અવાજમાં બોલશે.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddCustomVoiceDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2D6C3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'તમારો સાચો અવાજ કેવી રીતે સાચવવો?',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3E2723),
                          ),
                        ),
                        Text(
                          '૧૦૦% તમારો જ ઓરિજિનલ અવાજ સંભળાશે',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFD97706),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF8C7355),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD97706).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStepRow(
                      '૧',
                      'ગ્રંથ વાચન સ્ક્રીન પર કોઈપણ શ્લોક ખોલો.',
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      '૨',
                      'શ્લોકની નીચે આપેલા "🎤 મારો અવાજ રેકોર્ડ કરો" બટન પર ટેપ કરો.',
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      '૩',
                      'માઇક પર ટેપ કરી શ્લોક બોલો, અને સાંભળીને "સાચવો" પર ક્લિક કરો.',
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      '૪',
                      'બસ! હવે જ્યારે પણ તમે ગ્રંથ વાંચશો, ત્યારે ૧૦૦% તમારો જ સાચો અવાજ વાગશે!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(sheetCtx),
                child: Text(
                  'સમજાયું (Got It)',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildStepRow(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFD97706),
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFF4E342E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D6C3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.record_voice_over_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scripture Narration Voice',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3E1F07),
                        ),
                      ),
                      Text(
                        'Natural Google Cloud AI devotional recitation',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF8C7355),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF8C7355),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3ECE0)),

          // Authentic Voice Priority Banner
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD97706),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎙️ તમારો સાચો અવાજ (Your Voice)',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              Text(
                                'રેકોર્ડ કરેલા શ્લોકોમાં તમારો જ સાચો અવાજ બોલશે',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _prioritizeMyVoice,
                          activeColor: const Color(0xFFD97706),
                          onChanged: (val) {
                            setState(() {
                              _prioritizeMyVoice = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 14, color: Color(0xFFFDE68A)),
                    InkWell(
                      onTap: _showAddCustomVoiceDialog,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'કેવી રીતે રેકોર્ડ કરવું? શ્લોક પાસે આપેલા 🎤 બટન પર ટેપ કરો.',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFFB45309),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD97706)),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildUnifiedVoiceList(),
          ),

          // Speed & Rate Adjustment
          if (!_isLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: const Color(0xFFFAF6EE),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    size: 18,
                    color: Color(0xFF8C7355),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pacing:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A442E),
                    ),
                  ),
                  const Spacer(),
                  ...[0.80, 0.90, 1.0, 1.10].map((rate) {
                    final isSel =
                        (_preferences.speakingRate - rate).abs() < 0.04;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _preferences.speakingRate = rate);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFD97706) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFFD97706)
                                : const Color(0xFFE2D6C3),
                          ),
                        ),
                        child: Text(
                          '${rate.toStringAsFixed(2)}x',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSel
                                ? Colors.white
                                : const Color(0xFF5A442E),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Bottom Action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveAndClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Apply Voice Preference',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedVoiceList() {
    final seen = <String>{};
    final voices = <TtsVoice>[];
    for (final v in _allVoices) {
      if (!seen.contains(v.id)) {
        seen.add(v.id);
        voices.add(v);
      }
    }

    final selectedVoiceId =
        _preferences.selectedVoiceId ?? _preferences.gujaratiVoiceId;

    if (voices.isEmpty) {
      return Center(
        child: Text(
          'No voices available',
          style: GoogleFonts.outfit(color: const Color(0xFF8C7355)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: voices.length,
      itemBuilder: (ctx, idx) {
        final voice = voices[idx];
        final isSelected = voice.id == selectedVoiceId;
        final isPlaying = _activePlayingUrl != null &&
            voice.previewUrl.isNotEmpty &&
            (_activePlayingUrl!.contains(voice.previewUrl) ||
                _activePlayingUrl!.contains(voice.id));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD97706)
                  : const Color(0xFFEBE3D5),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _ttsService.applyGranthVoiceSelection(_preferences, voice);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD97706)
                            : const Color(0xFFB8A490),
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFFD97706)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                voice.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3E1F07),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: voice.gender == 'Female'
                                    ? const Color(0xFFFCE7F3)
                                    : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                voice.gender == 'Female'
                                    ? '♀ Female'
                                    : '♂ Male',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: voice.gender == 'Female'
                                      ? const Color(0xFFBE185D)
                                      : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (voice.title.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            voice.title,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                        if (voice.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            voice.description,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF6B5843),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (voice.previewUrl.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _ttsService.playPreview(voice.previewUrl);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? const Color(0xFFD97706)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying
                              ? Colors.white
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      tooltip: isPlaying ? 'Stop Preview' : 'Play Preview',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
