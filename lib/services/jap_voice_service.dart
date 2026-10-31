import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tts_voice_model.dart';
import 'tts_service.dart';

/// Google Cloud voices for Jap chanting. The chosen voice is stored separately
/// from the Granth voice, and each mantra clip is saved on the device so that
/// repeated taps never wait for the network.
class JapVoiceService {
  static final JapVoiceService _instance = JapVoiceService._internal();
  factory JapVoiceService() => _instance;
  JapVoiceService._internal();

  static const String _prefKey = 'jap_selected_voice_id';
  static const String defaultVoiceId = 'hi-IN-Chirp3-HD-Charon';
  static const double _chantRate = 0.9;

  static const List<TtsVoice> voices = [
    TtsVoice(
      id: 'hi-IN-Chirp3-HD-Charon',
      name: 'Charon',
      gender: 'Male',
      locale: 'hi-IN',
      tier: 'Chirp 3 HD',
      languages: ['Hindi'],
      title: 'Natural Male Voice',
      description: 'Warm, steady male voice, like a temple storyteller.',
      previewUrl: '',
      defaultRate: _chantRate,
      isDefault: true,
      languageCategory: 'Hindi',
    ),
    TtsVoice(
      id: 'hi-IN-Chirp3-HD-Fenrir',
      name: 'Fenrir',
      gender: 'Male',
      locale: 'hi-IN',
      tier: 'Chirp 3 HD',
      languages: ['Hindi'],
      title: 'Clear and Resonant Male Voice',
      description: 'Deep, clear male voice for a powerful chant.',
      previewUrl: '',
      defaultRate: _chantRate,
      isDefault: false,
      languageCategory: 'Hindi',
    ),
    TtsVoice(
      id: 'hi-IN-Chirp3-HD-Puck',
      name: 'Puck',
      gender: 'Male',
      locale: 'hi-IN',
      tier: 'Chirp 3 HD',
      languages: ['Hindi'],
      title: 'Young Male Voice',
      description: 'Light, gentle voice of a young man.',
      previewUrl: '',
      defaultRate: _chantRate,
      isDefault: false,
      languageCategory: 'Hindi',
    ),
    TtsVoice(
      id: 'hi-IN-Chirp3-HD-Kore',
      name: 'Kore',
      gender: 'Female',
      locale: 'hi-IN',
      tier: 'Chirp 3 HD',
      languages: ['Hindi'],
      title: 'Sweet Female Voice',
      description: 'Calm, sweet and soft female voice.',
      previewUrl: '',
      defaultRate: _chantRate,
      isDefault: false,
      languageCategory: 'Hindi',
    ),
    TtsVoice(
      id: 'hi-IN-Chirp3-HD-Aoede',
      name: 'Aoede',
      gender: 'Female',
      locale: 'hi-IN',
      tier: 'Chirp 3 HD',
      languages: ['Hindi'],
      title: 'Melodious Female Voice',
      description: 'Melodious female voice, like a hymn sung in a temple.',
      previewUrl: '',
      defaultRate: _chantRate,
      isDefault: false,
      languageCategory: 'Hindi',
    ),
    TtsVoice(
      id: 'hi-IN-Chirp3-HD-Zephyr',
      name: 'Zephyr',
      gender: 'Female',
      locale: 'hi-IN',
      tier: 'Chirp 3 HD',
      languages: ['Hindi'],
      title: 'Soft and Gentle Female Voice',
      description: 'Soft, slow and heartfelt female voice.',
      previewUrl: '',
      defaultRate: _chantRate,
      isDefault: false,
      languageCategory: 'Hindi',
    ),
  ];

  static String voiceName(String voiceId) {
    return voices
        .firstWhere((v) => v.id == voiceId, orElse: () => voices.first)
        .name;
  }

  Future<String> loadSelectedVoiceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && voices.any((v) => v.id == saved)) return saved;
    } catch (e) {
      debugPrint('[JapVoiceService] Error loading voice: $e');
    }
    return defaultVoiceId;
  }

  Future<void> saveSelectedVoiceId(String voiceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, voiceId);
    } catch (e) {
      debugPrint('[JapVoiceService] Error saving voice: $e');
    }
  }

  /// Returns the audio URL of the mantra spoken in the given voice.
  Future<String?> synthesizeMantra(String mantraText, String voiceId) {
    return TtsService().synthesizeScriptureAudio(
      text: mantraText,
      language: 'Hindi',
      voiceId: voiceId,
      speakingRate: _chantRate,
      pitch: 0.0,
      sectionType: 'other',
    );
  }

  /// Returns a local file of the mantra in the given voice, or null if it could
  /// not be fetched (the screen then falls back to its bundled clip).
  Future<String?> prepareChantClip(String mantraText, String voiceId) async {
    try {
      final dir = await getTemporaryDirectory();
      final clipDir = Directory('${dir.path}/jap_voice');
      if (!clipDir.existsSync()) clipDir.createSync(recursive: true);

      final mantraKey = base64Url.encode(utf8.encode(mantraText));
      final clip = File('${clipDir.path}/${voiceId}_$mantraKey.mp3');
      if (clip.existsSync() && clip.lengthSync() > 0) return clip.path;

      final url = await synthesizeMantra(mantraText, voiceId);
      if (url == null) return null;

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;

      await clip.writeAsBytes(response.bodyBytes, flush: true);
      return clip.path;
    } catch (e) {
      debugPrint('[JapVoiceService] Error preparing clip: $e');
      return null;
    }
  }
}
