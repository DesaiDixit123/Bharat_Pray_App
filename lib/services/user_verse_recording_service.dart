import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service for devotees to record and play their genuine human voice
/// for scripture verses ("મારો પોતાનો સાચો અવાજ").
///
/// When a devotee records a verse, their authentic recording is saved
/// locally on disk and synced to the BharatPray backend. During scripture recitation,
/// the app plays their actual recorded audio verbatim.
class UserVerseRecordingService {
  static final UserVerseRecordingService _instance =
      UserVerseRecordingService._internal();
  factory UserVerseRecordingService() => _instance;
  UserVerseRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();

  // In-memory cache of verse recordings by chapter: chapterId -> { verseIndex: urlOrPath }
  final Map<String, Map<int, String>> _cachedRecordings = {};

  // Track active recording state
  String? _currentRecordingPath;
  String? _activeChapterId;
  int? _activeVerseIndex;
  DateTime? _recordingStartTime;

  /// Clean unique device identifier for guest recordings
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('user_verse_recording_device_id');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId =
          'dev_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
      await prefs.setString('user_verse_recording_device_id', deviceId);
    }
    return deviceId;
  }

  /// Whether the app should prioritize devotee's own recordings over AI narration
  Future<bool> isPrioritizeMyVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('granth_prioritize_my_recordings') ?? true;
  }

  Future<void> setPrioritizeMyVoice(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('granth_prioritize_my_recordings', enabled);
  }

  /// Check and request microphone permission
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('[UserVerseRecording] Permission check error: $e');
      return false;
    }
  }

  /// Check if recording is currently active
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (_) {
      return false;
    }
  }

  /// Start recording devotee's voice for a specific verse
  Future<String?> startRecording({
    required String chapterId,
    required int verseIndex,
  }) async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        debugPrint('[UserVerseRecording] Microphone permission not granted');
        return null;
      }

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final dir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${dir.path}/devotee_recordings');
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync(recursive: true);
      }

      final safeChapter = chapterId.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '');
      final fileName =
          'verse_${safeChapter}_v${verseIndex}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${recordingsDir.path}/$fileName';

      _activeChapterId = chapterId;
      _activeVerseIndex = verseIndex;
      _currentRecordingPath = filePath;
      _recordingStartTime = DateTime.now();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      debugPrint('[UserVerseRecording] Recording started: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[UserVerseRecording] Failed to start recording: $e');
      _currentRecordingPath = null;
      _activeChapterId = null;
      _activeVerseIndex = null;
      return null;
    }
  }

  /// Stop recording and return the recorded file path
  Future<String?> stopRecording() async {
    try {
      if (!await _recorder.isRecording()) {
        return _currentRecordingPath;
      }

      final path = await _recorder.stop();
      final finalPath = path ?? _currentRecordingPath;

      if (finalPath != null && File(finalPath).existsSync()) {
        final length = await File(finalPath).length();
        debugPrint(
            '[UserVerseRecording] Recording stopped: $finalPath ($length bytes)');
        if (length > 1000 &&
            _activeChapterId != null &&
            _activeVerseIndex != null) {
          // Cache locally immediately
          _cacheLocalVerse(
            chapterId: _activeChapterId!,
            verseIndex: _activeVerseIndex!,
            localPath: finalPath,
          );
        }
      }

      return finalPath;
    } catch (e) {
      debugPrint('[UserVerseRecording] Stop recording error: $e');
      return null;
    }
  }

  /// Cancel current recording and remove temp file
  Future<void> cancelRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) file.deleteSync();
      }
    } catch (e) {
      debugPrint('[UserVerseRecording] Cancel recording error: $e');
    } finally {
      _currentRecordingPath = null;
      _activeChapterId = null;
      _activeVerseIndex = null;
      _recordingStartTime = null;
    }
  }

  /// Save local recording reference into memory and persistent preferences
  Future<void> _cacheLocalVerse({
    required String chapterId,
    required int verseIndex,
    required String localPath,
  }) async {
    _cachedRecordings.putIfAbsent(chapterId, () => {})[verseIndex] = localPath;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rec_loc_${chapterId}_v$verseIndex', localPath);
    } catch (_) {}
  }

  /// Upload the devotee's voice recording to backend
  Future<Map<String, dynamic>?> uploadRecording({
    required String chapterId,
    required int verseIndex,
    required String filePath,
    String? verseText,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('[UserVerseRecording] Upload error: file does not exist');
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      final deviceId = await getDeviceId();

      final uri = Uri.parse('${ApiService.baseUrl}/api/tts/my-recordings');
      final request = http.MultipartRequest('POST', uri);

      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['x-device-id'] = deviceId;

      request.fields['chapterId'] = chapterId;
      request.fields['verseIndex'] = verseIndex.toString();
      request.fields['deviceId'] = deviceId;
      if (verseText != null && verseText.isNotEmpty) {
        request.fields['verseText'] = verseText;
      }

      int durationMs = 0;
      if (_recordingStartTime != null) {
        durationMs =
            DateTime.now().difference(_recordingStartTime!).inMilliseconds;
        request.fields['durationMs'] = durationMs.toString();
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          filePath,
          filename: 'verse_${chapterId}_v$verseIndex.m4a',
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final audioUrl = data['Data']?['audioUrl'] ?? '';
        if (audioUrl.isNotEmpty) {
          await prefs.setString(
              'rec_srv_${chapterId}_v$verseIndex', audioUrl.toString());
        }
        await _cacheLocalVerse(
          chapterId: chapterId,
          verseIndex: verseIndex,
          localPath: filePath,
        );
        debugPrint(
            '[UserVerseRecording] Upload successful: $audioUrl for verse $verseIndex');
        return data['Data'] != null
            ? Map<String, dynamic>.from(data['Data'] as Map)
            : null;
      } else {
        debugPrint(
            '[UserVerseRecording] Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[UserVerseRecording] Upload exception: $e');
    }
    return null;
  }

  /// Fetch all recordings for a chapter from backend (and verify local files)
  Future<Map<int, String>> fetchChapterRecordings(String chapterId) async {
    final map = _cachedRecordings.putIfAbsent(chapterId, () => {});

    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      final deviceId = await getDeviceId();

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/tts/my-recordings?chapterId=${Uri.encodeComponent(chapterId)}&deviceId=${Uri.encodeComponent(deviceId)}',
      );

      final headers = <String, String>{
        'x-device-id': deviceId,
      };
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Data'] != null && data['Data']['recordings'] is List) {
          final list = data['Data']['recordings'] as List;
          for (final item in list) {
            final vIdx = item['verseIndex'];
            final srvUrl = item['audioUrl']?.toString();
            if (vIdx is int && srvUrl != null && srvUrl.isNotEmpty) {
              // Check if local file exists on disk
              final local = prefs.getString('rec_loc_${chapterId}_v$vIdx');
              if (local != null && File(local).existsSync()) {
                map[vIdx] = local;
              } else {
                map[vIdx] = srvUrl.startsWith('http')
                    ? srvUrl
                    : '${ApiService.baseUrl}/$srvUrl';
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[UserVerseRecording] Fetch recordings error: $e');
    }

    return map;
  }

  /// Get audio source for a verse: returns local file path or remote URL if devotee recorded it
  Future<String?> getAudioForVerse(String chapterId, int verseIndex) async {
    final prioritize = await isPrioritizeMyVoiceEnabled();
    if (!prioritize) return null;

    // Check memory cache
    final inMemory = _cachedRecordings[chapterId]?[verseIndex];
    if (inMemory != null) {
      if (!inMemory.startsWith('http') && File(inMemory).existsSync()) {
        return inMemory;
      } else if (inMemory.startsWith('http')) {
        return inMemory;
      }
    }

    // Check local preferences
    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('rec_loc_${chapterId}_v$verseIndex');
    if (localPath != null && File(localPath).existsSync()) {
      _cachedRecordings.putIfAbsent(chapterId, () => {})[verseIndex] =
          localPath;
      return localPath;
    }

    final srvUrl = prefs.getString('rec_srv_${chapterId}_v$verseIndex');
    if (srvUrl != null && srvUrl.isNotEmpty) {
      final fullUrl =
          srvUrl.startsWith('http') ? srvUrl : '${ApiService.baseUrl}/$srvUrl';
      _cachedRecordings.putIfAbsent(chapterId, () => {})[verseIndex] = fullUrl;
      return fullUrl;
    }

    return null;
  }

  /// Check whether devotee has recorded a specific verse
  Future<bool> hasRecordingForVerse(String chapterId, int verseIndex) async {
    final audio = await getAudioForVerse(chapterId, verseIndex);
    return audio != null && audio.isNotEmpty;
  }

  /// Count how many verses the devotee has recorded in a chapter
  Future<int> countRecordingsInChapter(
      String chapterId, int totalVersesCount) async {
    int count = 0;
    for (int i = 0; i < totalVersesCount; i++) {
      if (await hasRecordingForVerse(chapterId, i)) {
        count++;
      }
    }
    return count;
  }

  /// Delete a verse recording
  Future<bool> deleteRecording({
    required String chapterId,
    required int verseIndex,
  }) async {
    _cachedRecordings[chapterId]?.remove(verseIndex);

    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('rec_loc_${chapterId}_v$verseIndex');
    if (localPath != null && File(localPath).existsSync()) {
      try {
        File(localPath).deleteSync();
      } catch (_) {}
    }
    await prefs.remove('rec_loc_${chapterId}_v$verseIndex');
    await prefs.remove('rec_srv_${chapterId}_v$verseIndex');

    try {
      final token =
          prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      final deviceId = await getDeviceId();

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/tts/my-recordings?chapterId=${Uri.encodeComponent(chapterId)}&verseIndex=$verseIndex&deviceId=${Uri.encodeComponent(deviceId)}',
      );

      final headers = <String, String>{'x-device-id': deviceId};
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[UserVerseRecording] Delete error: $e');
      return true;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
