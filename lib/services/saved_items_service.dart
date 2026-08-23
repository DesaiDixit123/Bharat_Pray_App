import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedItemsService {
  static const String _keySavedGranths = 'saved_granths_list';
  static const String _keySavedChapters = 'saved_chapters_list';
  static const String _keySavedPosts = 'saved_posts_list';
  static const String _keySavedReels = 'saved_reels_list';

  // --- GRANTHS ---
  static Future<List<Map<String, dynamic>>> getSavedGranths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keySavedGranths);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isGranthSaved(String granthId) async {
    if (granthId.isEmpty) return false;
    final saved = await getSavedGranths();
    return saved.any((g) => (g['_id'] ?? g['id'] ?? '').toString() == granthId);
  }

  static Future<bool> toggleSaveGranth(Map<String, dynamic> granth) async {
    final prefs = await SharedPreferences.getInstance();
    final granthId = (granth['_id'] ?? granth['id'] ?? '').toString();
    if (granthId.isEmpty) return false;

    final list = await getSavedGranths();
    final index = list.indexWhere((g) => (g['_id'] ?? g['id'] ?? '').toString() == granthId);

    bool isNowSaved = false;
    if (index >= 0) {
      list.removeAt(index);
      isNowSaved = false;
    } else {
      list.add({
        '_id': granthId,
        'name': granth['name'] ?? granth['title'] ?? 'Sacred Granth',
        'title': granth['title'] ?? granth['name'] ?? 'Sacred Granth',
        'coverImage': granth['coverImage'] ?? granth['image'] ?? '',
        'author': granth['author'] ?? 'Maharishi Ved Vyas',
        'rawGranth': granth,
        'savedAt': DateTime.now().toIso8601String(),
      });
      isNowSaved = true;
    }

    await prefs.setString(_keySavedGranths, jsonEncode(list));
    return isNowSaved;
  }

  // --- CHAPTERS ---
  static Future<List<Map<String, dynamic>>> getSavedChapters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keySavedChapters);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isChapterSaved(String chapterId) async {
    if (chapterId.isEmpty) return false;
    final saved = await getSavedChapters();
    return saved.any((c) => (c['_id'] ?? c['id'] ?? c['title'] ?? '').toString() == chapterId);
  }

  static Future<bool> toggleSaveChapter(Map<String, dynamic> chapter, Map<String, dynamic> granth) async {
    final prefs = await SharedPreferences.getInstance();
    final chapterId = (chapter['_id'] ?? chapter['id'] ?? chapter['title'] ?? '').toString();
    if (chapterId.isEmpty) return false;

    final list = await getSavedChapters();
    final index = list.indexWhere((c) => (c['_id'] ?? c['id'] ?? c['title'] ?? '').toString() == chapterId);

    bool isNowSaved = false;
    if (index >= 0) {
      list.removeAt(index);
      isNowSaved = false;
    } else {
      list.add({
        '_id': chapterId,
        'name': chapter['name'] ?? chapter['title'] ?? 'Chapter',
        'title': chapter['title'] ?? chapter['name'] ?? 'Chapter',
        'sanskritName': chapter['sanskritName'] ?? '',
        'granthId': granth['_id'] ?? granth['id'] ?? '',
        'granthName': granth['name'] ?? granth['title'] ?? 'Granth',
        'chapter': chapter,
        'granth': granth,
        'savedAt': DateTime.now().toIso8601String(),
      });
      isNowSaved = true;
    }

    await prefs.setString(_keySavedChapters, jsonEncode(list));
    return isNowSaved;
  }

  // --- POSTS ---
  static Future<List<Map<String, dynamic>>> getSavedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keySavedPosts);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isPostSaved(String postId) async {
    if (postId.isEmpty) return false;
    final saved = await getSavedPosts();
    return saved.any((p) => (p['id'] ?? p['content'] ?? '').toString() == postId);
  }

  static Future<bool> toggleSavePost(Map<String, dynamic> post, String mandalName, String avatarUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final postId = (post['id'] ?? post['content'] ?? '').toString();
    if (postId.isEmpty) return false;

    final list = await getSavedPosts();
    final index = list.indexWhere((p) => (p['id'] ?? p['content'] ?? '').toString() == postId);

    bool isNowSaved = false;
    if (index >= 0) {
      list.removeAt(index);
      isNowSaved = false;
    } else {
      list.add({
        'id': postId,
        'mandalName': mandalName,
        'avatarUrl': avatarUrl,
        'content': post['content'] ?? '',
        'time': post['time'] ?? 'Just now',
        'image': post['image'] ?? '',
        'likes': post['likes'] ?? 0,
        'shares': post['shares'] ?? 0,
        'savedAt': DateTime.now().toIso8601String(),
      });
      isNowSaved = true;
    }

    await prefs.setString(_keySavedPosts, jsonEncode(list));
    return isNowSaved;
  }

  // --- REELS ---
  static Future<List<Map<String, dynamic>>> getSavedReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keySavedReels);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isReelSaved(String reelId) async {
    if (reelId.isEmpty) return false;
    final saved = await getSavedReels();
    return saved.any((r) => (r['id'] ?? r['title'] ?? '').toString() == reelId);
  }

  static Future<bool> toggleSaveReel(Map<String, dynamic> reel, String mandalName, String avatarUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final reelId = (reel['id'] ?? reel['title'] ?? '').toString();
    if (reelId.isEmpty) return false;

    final list = await getSavedReels();
    final index = list.indexWhere((r) => (r['id'] ?? r['title'] ?? '').toString() == reelId);

    bool isNowSaved = false;
    if (index >= 0) {
      list.removeAt(index);
      isNowSaved = false;
    } else {
      list.add({
        'id': reelId,
        'mandalName': mandalName,
        'avatarUrl': avatarUrl,
        'title': reel['title'] ?? 'Reel',
        'likes': reel['likes'] ?? '1.2K',
        'savedAt': DateTime.now().toIso8601String(),
      });
      isNowSaved = true;
    }

    await prefs.setString(_keySavedReels, jsonEncode(list));
    return isNowSaved;
  }
}
