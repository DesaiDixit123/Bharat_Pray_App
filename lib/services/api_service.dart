import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // Hosts for Android:
  // 1. '127.0.0.1' (Direct USB tunnel via adb reverse tcp:3020 tcp:3020 - 100% reliable)
  // 2. '192.168.29.113' (Wi-Fi LAN)
  // 3. '10.0.2.2' (Android Emulator)
  static String _activeAndroidHost = '127.0.0.1';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$_activeAndroidHost:3020/user';
    }
    return 'http://localhost:3020/user';
  }

  static void _switchHost() {
    if (_activeAndroidHost == '127.0.0.1') {
      _activeAndroidHost = '192.168.29.113';
    } else if (_activeAndroidHost == '192.168.29.113') {
      _activeAndroidHost = '10.0.2.2';
    } else {
      _activeAndroidHost = '127.0.0.1';
    }
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final baseDomain = baseUrl.replaceAll('/user', '');
    
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.replaceFirst(RegExp(r'http://[0-9.]+:3020'), baseDomain)
                    .replaceFirst(RegExp(r'http://localhost:3020'), baseDomain)
                    .replaceFirst(RegExp(r'https://api.bharatpray.com'), baseDomain);
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
}
