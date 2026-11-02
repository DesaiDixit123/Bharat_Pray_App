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

/// Shared voice selection for the Jap screens: loads the chosen voice, prepares
/// its mantra clip, and provides the button that opens the voice sheet.
mixin JapVoiceSelection<T extends StatefulWidget> on State<T> {
  final JapVoiceService _japVoiceService = JapVoiceService();
  String _japVoiceId = JapVoiceService.defaultVoiceId;
  String? japChantClipPath;

  JapConfig get japEntry;

  late final JapThemeConfig _japTheme = JapThemeConfig.resolveFromEntry(
    name: japEntry.name,
    shlokText: japEntry.shlokText,
  );

  String get japMantraText => _japTheme.mantraText;

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
    final clip = japChantClipPath;
    if (clip != null) return DeviceFileSource(clip);
    return AssetSource(_japTheme.audioAsset.replaceFirst('assets/', ''));
  }

  Future<void> prepareJapVoice() async {
    final voiceId = await _japVoiceService.loadSelectedVoiceId();
    if (!mounted) return;
    setState(() => _japVoiceId = voiceId);
    await _loadJapChantClip(voiceId);
  }

  Future<void> _loadJapChantClip(String voiceId) async {
    final clip = await _japVoiceService.prepareChantClip(
      _japTheme.mantraText,
      voiceId,
    );
    if (!mounted || voiceId != _japVoiceId) return;
    setState(() => japChantClipPath = clip);
  }

  void _openJapVoiceSheet() {
    HapticFeedback.lightImpact();
    GranthVoiceSelectorSheet.show(
      context,
      japMantraText: _japTheme.mantraText,
      onVoiceChanged: prepareJapVoice,
    );
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
                  'Voice: ${JapVoiceService.voiceName(_japVoiceId)}',
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
