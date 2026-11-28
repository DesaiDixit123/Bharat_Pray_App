import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/jap_models.dart';
import '../../models/jap_theme_config.dart';
import '../../services/api_service.dart';
import '../../services/jap_voice_service.dart';
import '../granth/granth_voice_selector_sheet.dart';
import 'jap_custom_voice_selector_sheet.dart';

/// Shared voice selection for the Jap screens: loads the chosen voice, prepares
/// its mantra clip, and provides the button that opens the voice sheet.
mixin JapVoiceSelection<T extends StatefulWidget> on State<T> {
  final JapVoiceService _japVoiceService = JapVoiceService();
  String _japVoiceId = JapVoiceService.defaultVoiceId;
  String? japChantClipPath;
  Source? _customVoiceSource;

  JapConfig get japEntry;

  bool get _hasCustomVoiceOptions => japEntry.voiceOptions.isNotEmpty;

  JapVoiceOption? get _selectedCustomVoiceOption {
    if (!_hasCustomVoiceOptions) return null;
    for (final opt in japEntry.voiceOptions) {
      if (opt.id == _japVoiceId) return opt;
    }
    return japEntry.voiceOptions.first;
  }

  late final JapThemeConfig _japTheme = JapThemeConfig.resolveFromEntry(
    name: japEntry.displayName.isNotEmpty ? japEntry.displayName : japEntry.name,
    shlokText: japEntry.mantraText.isNotEmpty ? japEntry.mantraText : japEntry.shlokText,
  );

  String get japMantraText => japEntry.mantraText.isNotEmpty ? japEntry.mantraText : _japTheme.mantraText;

  /// Returns the exact deity cover/darshan image for this Jap entry (never hardcoded to Ram).
  String get japEffectiveImageAsset {
    if (japEntry.isCustom && japEntry.darshanImageUrl.isNotEmpty) {
      return japEntry.darshanImageUrl;
    }
    if (japEntry.localDarshanAsset != null && japEntry.localDarshanAsset!.isNotEmpty) {
      return japEntry.localDarshanAsset!;
    }
    if (japEntry.darshanImageUrl.isNotEmpty &&
        japEntry.darshanImageUrl.startsWith('assets/')) {
      return japEntry.darshanImageUrl;
    }
    return _japTheme.coverAsset;
  }

  late String japDarshanVideoUrl = japEntry.darshanVideoUrl;

  /// Looks up this custom Jap's generated live darshan video, if it is ready yet.
  Future<void> refreshJapDarshanVideo({bool notifyIfPending = false}) async {
    if (!japEntry.isCustom) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        final japs = await ApiService.getMyCustomJaps(token);
        final match = japs.whereType<Map>().where(
              (jap) => (jap['_id'] ?? jap['id']).toString() == japEntry.id,
            );
        if (match.isNotEmpty) {
          final url = ApiService.resolveImageUrl(match.first['darshanVideo']?.toString());
          if (url.isNotEmpty && mounted) setState(() => japDarshanVideoUrl = url);
        }
      }
    } catch (e) {
      debugPrint('[JapVoiceSelection] Darshan video lookup error: $e');
    }
    if (notifyIfPending && mounted && japDarshanVideoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your live darshan video is still being prepared. It will play here once it is ready.'),
        ),
      );
    }
  }

  /// The selected voice's clip, or this mantra's bundled clip until it is ready.
  Source get japChantSource {
    if (_hasCustomVoiceOptions) {
      if (_customVoiceSource != null) return _customVoiceSource!;
      final opt = _selectedCustomVoiceOption;
      if (opt != null) {
        final fallback = JapVoiceService.immediateFallbackSource(opt);
        if (fallback != null) return fallback;
      }
    }

    // 1. If the selected voice clip is ready, ALWAYS use it!
    // This ensures whichever voice the user chooses (Charon, Fenrir, Puck, Kore, etc.) plays immediately
    final clip = japChantClipPath;
    if (clip != null) return DeviceFileSource(clip);

    // 2. Custom / Server audio if present (local file, HTTP URL, or bundled asset)
    if (japEntry.shlokAudioUrl != null && japEntry.shlokAudioUrl!.isNotEmpty) {
      final audioPath = japEntry.shlokAudioUrl!;
      if (audioPath.startsWith('http')) {
        return UrlSource(audioPath);
      } else if (audioPath.startsWith('assets/')) {
        return AssetSource(audioPath.replaceFirst('assets/', ''));
      } else {
        return DeviceFileSource(audioPath);
      }
    }

    // 3. Fallback to bundled studio asset while voice is loading or offline
    return AssetSource(_japTheme.audioAsset.replaceFirst('assets/', ''));
  }

  Future<void> prepareJapVoice() async {
    if (_hasCustomVoiceOptions) {
      final voiceId = await _japVoiceService.loadSelectedVoiceForJap(
        japEntry.id,
        japEntry.voiceOptions,
      );
      if (!mounted) return;
      final selectedOption = japEntry.voiceOptions.firstWhere(
        (v) => v.id == voiceId,
        orElse: () => japEntry.voiceOptions.first,
      );
      setState(() {
        _japVoiceId = selectedOption.id;
        _customVoiceSource = JapVoiceService.immediateFallbackSource(selectedOption);
      });
      final resolvedSource = await _japVoiceService.resolveVoiceOptionSource(selectedOption);
      if (!mounted || selectedOption.id != _japVoiceId) return;
      if (resolvedSource != null) {
        setState(() => _customVoiceSource = resolvedSource);
      }
      return;
    }

    final voiceId = await _japVoiceService.loadSelectedVoiceId();
    if (!mounted) return;
    setState(() => _japVoiceId = voiceId);
    await _loadJapChantClip(voiceId);
  }

  Future<void> _loadJapChantClip(String voiceId) async {
    final textToSpeak = japEntry.voiceText.isNotEmpty
        ? japEntry.voiceText
        : japMantraText;
    final clip = await _japVoiceService.prepareChantClip(
      textToSpeak,
      voiceId,
    );
    if (!mounted || voiceId != _japVoiceId) return;
    setState(() => japChantClipPath = clip);
  }

  void _openJapVoiceSheet() {
    HapticFeedback.lightImpact();
    if (_hasCustomVoiceOptions) {
      JapCustomVoiceSelectorSheet.show(
        context,
        japId: japEntry.id,
        voiceOptions: japEntry.voiceOptions,
        onVoiceChanged: prepareJapVoice,
      );
      return;
    }
    GranthVoiceSelectorSheet.show(
      context,
      japMantraText: _japTheme.mantraText,
      onVoiceChanged: prepareJapVoice,
    );
  }

  String get _activeVoiceButtonLabel {
    if (_hasCustomVoiceOptions) {
      return _selectedCustomVoiceOption?.name ?? 'Select Voice';
    }
    return JapVoiceService.voiceName(_japVoiceId);
  }

  Widget buildJapVoiceButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, right: 12),
        child: GestureDetector(
          onTap: _openJapVoiceSheet,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFFB300),
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.record_voice_over_rounded,
                  size: 15,
                  color: Color(0xFFFFD54F),
                ),
                const SizedBox(width: 6),
                Text(
                  'Voice: $_activeVoiceButtonLabel',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
