import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/tts_voice_model.dart';
import 'api_service.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _currentlyPlayingPreviewUrl;
  bool _isPlayingPreview = false;

  final StreamController<bool> _previewStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get previewStateStream => _previewStateController.stream;
  bool get isPlayingPreview => _isPlayingPreview;
  String? get activePreviewUrl => _currentlyPlayingPreviewUrl;

  List<TtsVoice> _cachedVoices = [];
  List<TtsVoice> _customVoices = [];
  List<TtsVoice> get customVoices => _customVoices;
  TtsPreferences? _currentPreferences;

  // Local cache for verse audio URLs to prevent any redundant network calls
  final Map<String, String> _localAudioCache = {};

  void clearAudioCache() {
    _localAudioCache.clear();
  }

  Future<void> init() async {
    _previewPlayer.onPlayerComplete.listen((_) {
      _isPlayingPreview = false;
      _currentlyPlayingPreviewUrl = null;
      _previewStateController.add(false);
    });
    await loadPreferences();
    await loadCustomVoices();
  }

  /// Load user voice preferences from local persistent storage (SharedPreferences)
  Future<TtsPreferences> loadPreferences() async {
    if (_currentPreferences != null) return _currentPreferences!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final selVoiceId = prefs.getString('tts_selected_voice_id');
      final selVoiceGender = prefs.getString('tts_selected_voice_gender');
      final selVoiceLang = prefs.getString('tts_selected_voice_language');

      var gujaratiVoiceId = prefs.getString('tts_voice_gujarati') ?? selVoiceId;
      var hindiVoiceId = prefs.getString('tts_voice_hindi') ?? selVoiceId;
      var sanskritVoiceId = prefs.getString('tts_voice_sanskrit') ?? selVoiceId;
      var englishVoiceId = prefs.getString('tts_voice_english') ?? selVoiceId;

      if (gujaratiVoiceId == null) gujaratiVoiceId = 'gu-IN-Chirp3-HD-Kore';
      if (hindiVoiceId == null) hindiVoiceId = 'hi-IN-Chirp3-HD-Kore';
      if (sanskritVoiceId == null) sanskritVoiceId = 'hi-IN-Chirp3-HD-Charon';
      if (englishVoiceId == null) englishVoiceId = 'en-IN-Neural2-D';

      final speakingRate = prefs.getDouble('tts_speaking_rate') ?? 0.92;
      final pitch = prefs.getDouble('tts_pitch') ?? 0.0;

      _currentPreferences = TtsPreferences(
        selectedVoiceId: selVoiceId,
        selectedVoiceGender: selVoiceGender,
        selectedVoiceLanguage: selVoiceLang,
        gujaratiVoiceId: gujaratiVoiceId,
        hindiVoiceId: hindiVoiceId,
        sanskritVoiceId: sanskritVoiceId,
        englishVoiceId: englishVoiceId,
        speakingRate: speakingRate,
        pitch: pitch,
      );
    } catch (e) {
      debugPrint('[TtsService] Error loading preferences: $e');
      _currentPreferences = TtsPreferences();
    }
    return _currentPreferences!;
  }

  /// Save user voice preferences to local persistent storage and backend
  Future<void> savePreferences(
    TtsPreferences preferences, {
    String? token,
  }) async {
    _currentPreferences = preferences;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (preferences.selectedVoiceId != null) {
        await prefs.setString('tts_selected_voice_id', preferences.selectedVoiceId!);
      }
      if (preferences.selectedVoiceGender != null) {
        await prefs.setString('tts_selected_voice_gender', preferences.selectedVoiceGender!);
      }
      if (preferences.selectedVoiceLanguage != null) {
        await prefs.setString('tts_selected_voice_language', preferences.selectedVoiceLanguage!);
      }
      await prefs.setString('tts_voice_gujarati', preferences.gujaratiVoiceId);
      await prefs.setString('tts_voice_hindi', preferences.hindiVoiceId);
      await prefs.setString('tts_voice_sanskrit', preferences.sanskritVoiceId);
      await prefs.setString('tts_voice_english', preferences.englishVoiceId);
      await prefs.setDouble('tts_speaking_rate', preferences.speakingRate);
      await prefs.setDouble('tts_pitch', preferences.pitch);

      // Also persist to backend if token available
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('${ApiService.baseUrl}/api/tts/preferences');
        await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(preferences.toJson()),
            )
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('[TtsService] Error saving preferences: $e');
    }
  }

  /// Retrieve voice ID matching user's preference.
  /// If the devotee selected a voice for Granth, that exact voice is returned for all languages!
  String getVoiceForLanguage(String language, {TtsPreferences? prefs}) {
    final p = prefs ?? _currentPreferences ?? TtsPreferences();
    if (p.selectedVoiceId != null && p.selectedVoiceId!.isNotEmpty) {
      return p.selectedVoiceId!;
    }
    final langLower = language.toLowerCase();
    if (langLower.contains('gujarat')) {
      return p.gujaratiVoiceId;
    } else if (langLower.contains('sanskrit')) {
      return p.sanskritVoiceId;
    } else if (langLower.contains('english')) {
      return p.englishVoiceId;
    }
    return p.hindiVoiceId;
  }

  /// Keep one selected Granth voice persona across all spoken language sections.
  void applyGranthVoiceSelection(TtsPreferences preferences, TtsVoice voice) {
    final voiceId = voice.id;
    preferences.selectedVoiceId = voiceId;
    preferences.selectedVoiceGender = voice.gender;
    preferences.selectedVoiceLanguage = voice.languageCategory;

    // Apply the chosen voice ID universally across all language slots
    preferences.gujaratiVoiceId = voiceId;
    preferences.hindiVoiceId = voiceId;
    preferences.sanskritVoiceId = voiceId;
    preferences.englishVoiceId = voiceId;
  }

  /// Load custom voices saved locally in persistent SharedPreferences
  Future<List<TtsVoice>> loadCustomVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString('tts_custom_voices_list');
      if (customJson != null && customJson.isNotEmpty) {
        final decoded = jsonDecode(customJson);
        if (decoded is List) {
          _customVoices = decoded
              .map(
                (item) =>
                    TtsVoice.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
          return _customVoices;
        }
      }
    } catch (e) {
      debugPrint('[TtsService] Error loading local custom voices: $e');
    }
    return _customVoices;
  }

  /// Add a new personal custom voice profile
  Future<TtsVoice> addCustomVoice({
    required String name,
    required String gender,
    required String language,
    String? baseVoiceId,
    double pitch = 0.0,
    double speakingRate = 0.92,
    String? localAudioSample,
    String? token,
  }) async {
    final cleanName = name.trim().isEmpty ? 'My Voice' : name.trim();
    final isGuj = language.toLowerCase().contains('guj');
    final voiceId = 'custom-voice-${DateTime.now().millisecondsSinceEpoch}';
    final defaultBase = gender == 'Male'
        ? (isGuj ? 'gu-IN-Chirp3-HD-Charon' : 'hi-IN-Chirp3-HD-Charon')
        : (isGuj ? 'gu-IN-Chirp3-HD-Kore' : 'hi-IN-Chirp3-HD-Kore');

    TtsVoice newVoice = TtsVoice(
      id: voiceId,
      name: '$cleanName (Your Voice)',
      gender: gender,
      locale: isGuj ? 'gu-IN' : 'hi-IN',
      tier: 'Custom Voice',
      languages: [language],
      title: 'Your Personal Devotional Voice',
      description: 'Personal recitation model of your own voice.',
      previewUrl: '',
      defaultRate: speakingRate,
      pitch: pitch,
      baseVoiceId: baseVoiceId ?? defaultBase,
      localAudioSample: localAudioSample,
      isDefault: false,
      isCustom: true,
      languageCategory: isGuj ? 'Gujarati' : 'Hindi',
    );

    // Call backend to generate preview audio and persist to user profile
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/tts/custom-voice');
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'name': cleanName,
              'gender': gender,
              'language': language,
              'baseVoiceId': baseVoiceId ?? defaultBase,
              'pitch': pitch,
              'speakingRate': speakingRate,
              'localAudioSample': localAudioSample,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['Data'] != null) {
          newVoice = TtsVoice.fromJson(
            Map<String, dynamic>.from(decoded['Data'] as Map),
          );
        }
      }
    } catch (e) {
      debugPrint('[TtsService] Error registering custom voice on backend: $e');
    }

    _customVoices.removeWhere((v) => v.id == newVoice.id);
    _customVoices.insert(0, newVoice);
    _cachedVoices.clear();

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customVoices.map((v) => v.toJson()).toList();
    await prefs.setString('tts_custom_voices_list', jsonEncode(jsonList));

    return newVoice;
  }

  /// Remove a custom voice
  Future<void> deleteCustomVoice(String voiceId, {String? token}) async {
    _customVoices.removeWhere((v) => v.id == voiceId);
    _cachedVoices.clear();
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customVoices.map((v) => v.toJson()).toList();
    await prefs.setString('tts_custom_voices_list', jsonEncode(jsonList));

    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/tts/custom-voice/$voiceId',
      );
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Fetch verified Google Cloud TTS voice catalog from backend (with Custom Voices at top)
  Future<List<TtsVoice>> fetchVoices() async {
    if (_cachedVoices.isNotEmpty) return _cachedVoices;

    List<TtsVoice> standardVoices = [];
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/tts/voices');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Data'] != null && data['Data']['voices'] is List) {
          standardVoices = (data['Data']['voices'] as List)
              .map(
                (item) =>
                    TtsVoice.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[TtsService] Error fetching voices from backend: $e');
    }

    if (standardVoices.isEmpty) {
      standardVoices = _getDefaultVoices();
    }

    final customList = await loadCustomVoices();
    final merged = <TtsVoice>[
      ...customList,
      ...standardVoices.where((v) => !customList.any((c) => c.id == v.id)),
    ];
    _cachedVoices = merged;
    return merged;
  }

  /// Synthesize scripture verse / text into natural Google Cloud TTS audio
  Future<String?> synthesizeScriptureAudio({
    required String text,
    String? language,
    String? voiceId,
    double? speakingRate,
    double? pitch,
    String? granthId,
    String? chapterId,
    String? shlokaId,
    String? sectionType,
    String? token,
  }) async {
    if (text.trim().isEmpty) return null;

    final trimmedText = text.trim();
    final prefs = await loadPreferences();
    if (_customVoices.isEmpty) {
      await loadCustomVoices();
    }
    final effectiveLang = language ?? _detectLanguage(trimmedText);
    final effectiveVoice =
        voiceId ?? getVoiceForLanguage(effectiveLang, prefs: prefs);
    final effectiveRate = speakingRate ?? prefs.speakingRate;

    double effectivePitch = pitch ?? prefs.pitch;
    String? baseVoiceId;
    final customMatch = _customVoices
        .where((v) => v.id == effectiveVoice)
        .firstOrNull;
    if (customMatch != null) {
      if (pitch == null || pitch == 0.0) {
        effectivePitch = customMatch.pitch;
      }
      baseVoiceId = customMatch.baseVoiceId;
    }

    // 1. Check client-side in-memory cache
    final localKey =
        '$trimmedText|$effectiveVoice|$effectiveRate|$effectivePitch';
    if (_localAudioCache.containsKey(localKey)) {
      return _localAudioCache[localKey];
    }

    // 2. Call backend synthesis API
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/tts/synthesize');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        'text': trimmedText,
        'language': effectiveLang,
        'voiceId': effectiveVoice,
        'baseVoiceId': baseVoiceId,
        'speakingRate': effectiveRate,
        'pitch': effectivePitch,
        'granthId': granthId,
        'chapterId': chapterId,
        'shlokaId': shlokaId,
        'sectionType': sectionType ?? 'sanskrit',
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['Data'] ?? {};
        final rawAudioUrl = (data['audioUrl'] ?? '').toString();

        if (rawAudioUrl.isNotEmpty) {
          final resolvedUrl = _resolveFullAudioUrl(rawAudioUrl);
          _localAudioCache[localKey] = resolvedUrl;
          return resolvedUrl;
        }
      } else {
        debugPrint(
          '[TtsService] Synthesis failed status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[TtsService] Error in synthesizeScriptureAudio: $e');
    }

    return null;
  }

  /// Play audio preview for voice selection
  Future<void> playPreview(String relativeOrFullUrl) async {
    if (relativeOrFullUrl.isEmpty) return;
    final fullUrl = _resolveFullAudioUrl(relativeOrFullUrl);

    if (_isPlayingPreview && _currentlyPlayingPreviewUrl == fullUrl) {
      await stopPreview();
      return;
    }

    try {
      await _previewPlayer.stop();
      _currentlyPlayingPreviewUrl = fullUrl;
      _isPlayingPreview = true;
      _previewStateController.add(true);
      await _previewPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint('[TtsService] Error playing preview: $e');
      _isPlayingPreview = false;
      _currentlyPlayingPreviewUrl = null;
      _previewStateController.add(false);
    }
  }

  /// Stop preview playback
  Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    _isPlayingPreview = false;
    _currentlyPlayingPreviewUrl = null;
    _previewStateController.add(false);
  }

  void dispose() {
    _previewPlayer.dispose();
    _previewStateController.close();
  }

  String _resolveFullAudioUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiService.baseUrl}/$cleanPath';
  }

  String _detectLanguage(String text) {
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) return 'Gujarati';
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      if (RegExp(r'[।॥]').hasMatch(text)) return 'Sanskrit';
      return 'Hindi';
    }
    return 'English';
  }

  List<TtsVoice> _getDefaultVoices() {
    return const [
      TtsVoice(
        id: 'gu-IN-Chirp3-HD-Kore',
        name: 'Kore (Sweet Female Voice)',
        gender: 'Female',
        locale: 'gu-IN',
        tier: 'Chirp 3 HD',
        languages: ['Gujarati'],
        title: 'Very Sweet Female Voice',
        description:
            'Calm, sweet and natural human female voice. Sacred recitation with no robotic sound.',
        previewUrl:
            'uploads/granth_audio/previews/preview_gu-IN-Chirp3-HD-Kore.mp3',
        defaultRate: 0.92,
        isDefault: true,
        languageCategory: 'Gujarati',
      ),
      TtsVoice(
        id: 'gu-IN-Chirp3-HD-Puck',
        name: 'Puck (Child / Young Voice)',
        gender: 'Male',
        locale: 'gu-IN',
        tier: 'Chirp 3 HD',
        languages: ['Gujarati'],
        title: 'Sweet Boy Voice',
        description:
            'Natural, innocent and sweet voice of a child or young man. Very pleasant for religious stories.',
        previewUrl:
            'uploads/granth_audio/previews/preview_gu-IN-Chirp3-HD-Puck.mp3',
        defaultRate: 0.94,
        isDefault: false,
        languageCategory: 'Gujarati',
      ),
      TtsVoice(
        id: 'gu-IN-Chirp3-HD-Aoede',
        name: 'Aoede (Melodious Female Voice)',
        gender: 'Female',
        locale: 'gu-IN',
        tier: 'Chirp 3 HD',
        languages: ['Gujarati'],
        title: 'Melodious Devotional Female Voice',
        description: 'Sweet, melodious female voice, like a hymn sung in a temple.',
        previewUrl:
            'uploads/granth_audio/previews/preview_gu-IN-Chirp3-HD-Aoede.mp3',
        defaultRate: 0.92,
        isDefault: false,
        languageCategory: 'Gujarati',
      ),
      TtsVoice(
        id: 'gu-IN-Chirp3-HD-Charon',
        name: 'Charon (Natural Male Voice)',
        gender: 'Male',
        locale: 'gu-IN',
        tier: 'Chirp 3 HD',
        languages: ['Gujarati'],
        title: 'Natural Male Narrator',
        description:
            'Male voice like a temple storyteller, with real breath and emotion.',
        previewUrl:
            'uploads/granth_audio/previews/preview_gu-IN-Chirp3-HD-Charon.mp3',
        defaultRate: 0.92,
        isDefault: false,
        languageCategory: 'Gujarati',
      ),
      TtsVoice(
        id: 'hi-IN-Chirp3-HD-Kore',
        name: 'Kore (कोरे - मधुर स्त्री स्वर)',
        gender: 'Female',
        locale: 'hi-IN',
        tier: 'Chirp 3 HD',
        languages: ['Hindi'],
        title: 'अत्यंत मधुर स्त्री स्वर (Sweet Female Voice)',
        description: 'शांत, कोमल और स्वाभाविक मानवीय स्त्री स्वर।',
        previewUrl:
            'uploads/granth_audio/previews/preview_hi-IN-Chirp3-HD-Kore.mp3',
        defaultRate: 0.92,
        isDefault: true,
        languageCategory: 'Hindi',
      ),
      TtsVoice(
        id: 'hi-IN-Chirp3-HD-Puck',
        name: 'Puck (पक - बालक / युवा स्वर)',
        gender: 'Male',
        locale: 'hi-IN',
        tier: 'Chirp 3 HD',
        languages: ['Hindi'],
        title: 'मधुर बालक / युवा स्वर (Boy Voice)',
        description: 'निर्दोष, कोमल और स्वाभाविक युवा बालक की आवाज।',
        previewUrl:
            'uploads/granth_audio/previews/preview_hi-IN-Chirp3-HD-Puck.mp3',
        defaultRate: 0.94,
        isDefault: false,
        languageCategory: 'Hindi',
      ),
      TtsVoice(
        id: 'hi-IN-Chirp3-HD-Charon',
        name: 'Devavani Charon (Sanskrit Shloka Recitation - Male)',
        gender: 'Male',
        locale: 'hi-IN',
        tier: 'Chirp 3 HD',
        languages: ['Sanskrit'],
        title: 'Natural Sanskrit Shloka Recitation',
        description:
            'Sacred Sanskrit shloka recitation with human breath and rhythmic pauses.',
        previewUrl:
            'uploads/granth_audio/previews/preview_hi-IN-Chirp3-HD-Charon-sa.mp3',
        defaultRate: 0.88,
        isDefault: true,
        languageCategory: 'Sanskrit',
      ),
      TtsVoice(
        id: 'hi-IN-Chirp3-HD-Kore',
        name: 'Devavani Kore (Sweet Sanskrit Hymn Singing - Female)',
        gender: 'Female',
        locale: 'hi-IN',
        tier: 'Chirp 3 HD',
        languages: ['Sanskrit'],
        title: 'Sweet Sanskrit Hymn Singing',
        description:
            'Sanskrit stotra and mantra singing with a very sweet and calm feel.',
        previewUrl:
            'uploads/granth_audio/previews/preview_hi-IN-Chirp3-HD-Kore-sa.mp3',
        defaultRate: 0.88,
        isDefault: false,
        languageCategory: 'Sanskrit',
      ),
    ];
  }
}
