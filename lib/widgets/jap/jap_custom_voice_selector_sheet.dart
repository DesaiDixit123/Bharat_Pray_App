import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/jap_models.dart';
import '../../services/jap_voice_service.dart';

/// Dedicated voice selector bottom sheet for Jap entries that define their own
/// custom voice options (kept strictly separate from Granth).
class JapCustomVoiceSelectorSheet extends StatefulWidget {
  final String japId;
  final List<JapVoiceOption> voiceOptions;
  final VoidCallback? onVoiceChanged;

  const JapCustomVoiceSelectorSheet({
    super.key,
    required this.japId,
    required this.voiceOptions,
    this.onVoiceChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String japId,
    required List<JapVoiceOption> voiceOptions,
    VoidCallback? onVoiceChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JapCustomVoiceSelectorSheet(
        japId: japId,
        voiceOptions: voiceOptions,
        onVoiceChanged: onVoiceChanged,
      ),
    );
  }

  @override
  State<JapCustomVoiceSelectorSheet> createState() =>
      _JapCustomVoiceSelectorSheetState();
}

class _JapCustomVoiceSelectorSheetState
    extends State<JapCustomVoiceSelectorSheet> {
  final JapVoiceService _japVoiceService = JapVoiceService();
  final AudioPlayer _previewPlayer = AudioPlayer();

  String _selectedVoiceId = '';
  String? _playingVoiceId;
  bool _isLoading = true;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _completeSub = _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _playingVoiceId = null);
      }
    });
    _loadSelected();
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _previewPlayer.stop().catchError((_) {});
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSelected() async {
    final savedId = await _japVoiceService.loadSelectedVoiceForJap(
      widget.japId,
      widget.voiceOptions,
    );
    if (!mounted) return;
    setState(() {
      _selectedVoiceId = savedId;
      _isLoading = false;
    });
  }

  Future<void> _togglePreview(JapVoiceOption option) async {
    HapticFeedback.lightImpact();
    if (_playingVoiceId == option.id) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _playingVoiceId = null);
      return;
    }

    setState(() => _playingVoiceId = option.id);
    try {
      await _previewPlayer.stop();
      final source = await _japVoiceService.resolveVoiceOptionSource(option);
      if (!mounted) return;
      if (source == null) {
        setState(() => _playingVoiceId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not play this voice. Please try again.'),
          ),
        );
        return;
      }
      await _previewPlayer.play(source);
    } catch (e) {
      debugPrint('[JapCustomVoiceSelectorSheet] Preview error: $e');
      if (mounted) setState(() => _playingVoiceId = null);
    }
  }

  Future<void> _saveAndClose() async {
    HapticFeedback.mediumImpact();
    if (_playingVoiceId != null) {
      unawaited(_previewPlayer.stop().catchError((_) {}));
    }
    await _japVoiceService.saveSelectedVoiceForJap(
      widget.japId,
      _selectedVoiceId,
    );
    widget.onVoiceChanged?.call();
    if (!mounted) return;
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
                'Voice saved! Your jap will now use this voice.',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          'Jap Chant Voice',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3E1F07),
                          ),
                        ),
                        Text(
                          'Tap play to preview and choose a voice for this Jap',
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFFD97706)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: widget.voiceOptions.length,
                  itemBuilder: (ctx, idx) {
                    final option = widget.voiceOptions[idx];
                    final isSelected = option.id == _selectedVoiceId;
                    final isPlaying = _playingVoiceId == option.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFFBEB)
                            : Colors.white,
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
                          setState(() => _selectedVoiceId = option.id);
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
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
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
                                            option.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 15.5,
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
                                            color: option.gender == 'Female'
                                                ? const Color(0xFFFCE7F3)
                                                : const Color(0xFFE0F2FE),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            option.gender == 'Female'
                                                ? '♀ Female'
                                                : '♂ Male',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: option.gender == 'Female'
                                                  ? const Color(0xFFBE185D)
                                                  : const Color(0xFF0369A1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (option.title.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        option.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                    if (option.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        option.description,
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
                              IconButton(
                                onPressed: () => _togglePreview(option),
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
                                tooltip:
                                    isPlaying ? 'Stop Preview' : 'Play Preview',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndClose,
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
      ),
    );
  }
}
