import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // Set to true to use the live production server, false for local testing
  static const bool isLive = true;

  // Hosts for Android physical device (when isLive = false):
  // '10.192.149.19'  → Wi-Fi LAN IP of the PC running the backend
  // '10.0.2.2'       → USB tunnel (run: adb reverse tcp:3020 tcp:3020)
  static String _activeAndroidHost = '10.192.149.19';

  static String get baseUrl {
    if (isLive) {
      return 'https://api.bharatpray.com/user';
    }
    
    if (Platform.isAndroid) {
      return 'http://$_activeAndroidHost:3020/user';
    }
    return 'http://localhost:3020/user';
  }

  /// Rotate between Wi-Fi IP and USB tunnel only — 127.0.0.1 excluded (unusable on physical devices).
  static void _switchHost() {
    if (_activeAndroidHost == '10.192.149.19') {
      _activeAndroidHost = '10.0.2.2';
    } else {
      _activeAndroidHost = '10.192.149.19';
    }
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('assets/')) return trimmed; // Keep local assets as is
    
    // Extract base domain without /api or /user
    final baseDomain = baseUrl.replaceAll(RegExp(r'/api.*|/user.*'), '');
    
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.replaceFirst(RegExp(r'http://[0-9.]+:3020'), baseDomain)
                    .replaceFirst(RegExp(r'http://localhost:3020'), baseDomain)
                    .replaceFirst(RegExp(r'https://api.bharatpray.com'), baseDomain)
                    .replaceFirst(RegExp(r'https://apis.bambamcabs.com'), baseDomain);
    }
    
    final isUploads = trimmed.contains('uploads/');
    final pathPrefix = trimmed.startsWith('/') ? '' : '/';
    return '$baseDomain${isUploads ? "" : "/uploads"}$pathPrefix$trimmed';
  }

  static Future<http.Response> _safeGet(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
    } catch (e) {
      if (Platform.isAndroid) {
        _switchHost();
        final fallbackUri = Uri.parse(uri.toString().replaceFirst(RegExp(r'http://[0-9.]+:3020'), 'http://$_activeAndroidHost:3020'));
        return await http.get(fallbackUri, headers: headers).timeout(const Duration(seconds: 6));
      }
      rethrow;
    }
  }

  static Future<http.Response> _safePost(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 4));
    } catch (e) {
      if (Platform.isAndroid) {
        _switchHost();
        final fallbackUri = Uri.parse(uri.toString().replaceFirst(RegExp(r'http://[0-9.]+:3020'), 'http://$_activeAndroidHost:3020'));
        return await http.post(fallbackUri, headers: headers, body: body).timeout(const Duration(seconds: 6));
      }
      rethrow;
    }
  }

  // Helper to handle http responses
  static Map<String, dynamic> _processResponse(http.Response response) {
    final body = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body['IsSuccess'] == true) {
        return body;
      } else {
        throw Exception(body['Message'] ?? 'Something went wrong.');
      }
    } else {
      throw Exception(body['Message'] ?? 'Server returned error status ${response.statusCode}');
    }
  }

  // POST /user/send-otp
  static Future<Map<String, dynamic>> sendOtp(String contact) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contact': contact,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'device_id': 'default_device_id',
        'fcm_token': 'default_fcm_token',
      }),
    );
    return _processResponse(response);
  }

  // POST /user/verify-otp
  static Future<Map<String, dynamic>> verifyOtp(String contact, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contact': contact,
        'otp': otp,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'device_id': 'default_device_id',
        'fcm_token': 'default_fcm_token',
      }),
    );
    return _processResponse(response);
  }

  // POST /user/google-auth
  static Future<Map<String, dynamic>> googleAuth({
    required String googleId,
    required String email,
    required String name,
    required String profilePic,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/google-auth'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'google_id': googleId,
        'email': email,
        'name': name,
        'profile_pic': profilePic,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'device_id': 'default_device_id',
        'fcm_token': 'default_fcm_token',
      }),
    );
    return _processResponse(response);
  }

  // POST /user/register (Multipart for profile_pic upload)
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String contact,
    File? profilePicFile,
  }) async {
    final uri = Uri.parse('$baseUrl/register');
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['contact'] = contact;
    request.fields['device_type'] = Platform.isAndroid ? 'android' : 'ios';
    request.fields['device_id'] = 'default_device_id';
    request.fields['fcm_token'] = 'default_fcm_token';

    if (profilePicFile != null) {
      final stream = http.ByteStream(profilePicFile.openRead());
      final length = await profilePicFile.length();
      final multipartFile = http.MultipartFile(
        'profile_pic',
        stream,
        length,
        filename: 'profile_pic.png',
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  // GET /user/profile
  static Future<UserModel> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = _processResponse(response);
    return UserModel.fromJson(data['Data']);
  }

  // GET /user/darshan/home
  static Future<Map<String, dynamic>> getDarshanHome(String token) async {
    final response = await _safeGet(
      Uri.parse('$baseUrl/darshan/home'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/jap/list
  static Future<List<dynamic>> getJapList(String token) async {
    final response = await _safeGet(
      Uri.parse('$baseUrl/jap/list'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/jap/sync-progress
  static Future<Map<String, dynamic>> syncJapProgress(String token, String japId, int count) async {
    final response = await _safePost(
      Uri.parse('$baseUrl/jap/sync-progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'japId': japId,
        'count': count
      }),
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/darshan/list
  static Future<Map<String, dynamic>> getDarshansList({
    required String token,
    String? search,
    String? categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
      queryParams['categoryId'] = categoryId;
    }

    final uri = Uri.parse('$baseUrl/darshan/list').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/darshan/details/:id
  static Future<Map<String, dynamic>> getDarshanDetails(String token, String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/darshan/details/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/darshan/categories
  static Future<List<dynamic>> getGodCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/darshan/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/darshan/favourite/toggle
  static Future<Map<String, dynamic>> toggleFavorite(String token, String darshanId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/darshan/favourite/toggle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'darshanId': darshanId}),
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/darshan/favourites
  static Future<List<dynamic>> getFavorites(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/darshan/favourites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/darshan/search/recent
  static Future<List<dynamic>> getRecentSearches(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/darshan/search/recent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/darshan/search/save
  static Future<Map<String, dynamic>> saveSearchQuery(String token, String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/darshan/search/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'query': query}),
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/darshan/search/clear
  static Future<Map<String, dynamic>> clearRecentSearches(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/darshan/search/clear'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/darshan/search/suggest
  static Future<List<dynamic>> getSearchSuggestions(String token, String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/darshan/search/suggest?q=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/live-darshan/status/:id
  static Future<Map<String, dynamic>> getLiveDarshanStatus(String token, String darshanId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/live-darshan/status/$darshanId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // GET /user/live-darshan/comments/:id
  static Future<Map<String, dynamic>> getLiveComments(String token, String darshanId, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/live-darshan/comments/$darshanId?page=$page&limit=20'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/live-darshan/details (joins stream and returns metadata)
  static Future<Map<String, dynamic>> getLiveDarshanDetails(String token, String darshanId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/live-darshan/details'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'darshan_id': darshanId}),
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/live-darshan/action (share trigger)
  static Future<Map<String, dynamic>> incrementShareCount(String token, String darshanId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/live-darshan/action'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'darshan_id': darshanId,
        'type': 'share',
        'action': 'increment'
      }),
    );
    return _processResponse(response)['Data'];
  }

  // ==========================================
  // Yatra Flow APIs
  // ==========================================

  // GET /user/yatra/list (Popular Yatras)
  static Future<List<dynamic>> getPopularYatras(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching popular yatras: $e');
      return []; // Return empty list gracefully if endpoint is missing
    }
  }

  // GET /user/yatra/journey/current (Continue Yatras)
  static Future<List<dynamic>> getContinueYatras(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/journey/current'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching continue yatras: $e');
      return [];
    }
  }

  // POST /user/yatra/journey/start
  static Future<Map<String, dynamic>> startYatra(String token, String yatraId) async {
    final response = await _safePost(
      Uri.parse('$baseUrl/yatra/journey/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'routeId': yatraId}),
    );
    return _processResponse(response)['Data'] ?? {};
  }

  // GET /user/yatra/progress/user
  static Future<Map<String, dynamic>> getUserProgress(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/progress/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error fetching user progress: $e');
      return {};
    }
  }

  // GET /user/yatra/group/:groupId/members
  static Future<List<dynamic>> getGroupMembers(String token, String groupId) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/group/$groupId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  // POST /user/yatra/group/start
  static Future<Map<String, dynamic>> createGroupJourney(String token, Map<String, dynamic> data) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/yatra/group/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error creating group journey: $e');
      return {};
    }
  }

  // POST /user/yatra/journey/resume
  static Future<Map<String, dynamic>> resumeJourney(String token, String journeyId) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/yatra/journey/resume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'journeyId': journeyId}),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error resuming journey: $e');
      rethrow;
    }
  }

  // POST /user/yatra/journey/stop
  static Future<Map<String, dynamic>> stopJourney(String token, String journeyId) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/yatra/journey/stop'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'journeyId': journeyId}),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error stopping journey: $e');
      return {};
    }
  }

  // POST /user/yatra/journey/complete
  static Future<Map<String, dynamic>> completeJourney(String token, String journeyId) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/yatra/journey/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'journeyId': journeyId}),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error completing journey: $e');
      return {};
    }
  }

  // GET /user/yatra/journey/progress
  static Future<Map<String, dynamic>> getJourneyProgress(String token, String journeyId) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/journey/progress?journeyId=$journeyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error fetching journey progress: $e');
      return {};
    }
  }

  // GET /user/yatra/journey/distance-remaining
  static Future<Map<String, dynamic>> getJourneyDistanceRemaining(String token, String journeyId) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/journey/distance-remaining?journeyId=$journeyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error fetching journey distance remaining: $e');
      return {};
    }
  }

  // POST /user/yatra/journey/location (Sync progress)
  static Future<bool> updateJourneyLocation(String token, String journeyId, int stepsIncrement, double distanceMeters) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/yatra/journey/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'journeyId': journeyId,
          'latitude': 20.8880,
          'longitude': 70.4012,
          'stepsIncrement': stepsIncrement,
          'distanceIncrementMeters': distanceMeters,
        }),
      );
      final jsonResponse = _processResponse(response);
      return jsonResponse['IsSuccess'] ?? false;
    } catch (e) {
      print('Error updating journey location: $e');
      return false;
    }
  }

  // GET /user/yatra/solo/nearby
  static Future<List<dynamic>> getNearbyPilgrims(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/solo/nearby'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching nearby pilgrims: $e');
      return [];
    }
  }

  // GET /user/yatra/group-chat/:groupId/messages
  static Future<List<dynamic>> getGroupMessages(String token, String groupId) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/group-chat/$groupId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching group messages: $e');
      return [];
    }
  }

  // GET /user/yatra/personal-chat/:chatId/messages
  static Future<List<dynamic>> getPersonalMessages(String token, String chatId) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/personal-chat/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching personal messages: $e');
      return [];
    }
  }

  // POST /user/yatra/certificate/generate
  static Future<Map<String, dynamic>> generateCertificate(String token, String yatraId) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/yatra/certificate/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'yatraId': yatraId}),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error generating certificate: $e');
      return {};
    }
  }

  // GET /user/yatra/journey/summary
  static Future<Map<String, dynamic>> getJourneySummary(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/journey/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error fetching journey summary: $e');
      return {};
    }
  }

  // GET /user/yatra/journey/timeline
  static Future<List<dynamic>> getJourneyTimeline(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/yatra/journey/timeline'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching journey timeline: $e');
      return [];
    }
  }
}
