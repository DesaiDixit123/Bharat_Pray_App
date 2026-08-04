import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../models/user_model.dart';
import '../models/yatra_model.dart';
import '../models/journey_models.dart';

class ApiService {
  // Set to true to use the live production server, false for local testing
  static const bool isLive = false;

  // Local backend IP: Mac's Wi-Fi IP = 192.168.29.249, Port = 3020
  static const String _localIp = '192.168.29.249';
  static const int _localPort = 3020;
  static String get baseUrl {
    if (isLive) {
      return 'https://api.bharatpray.com';
    }
    return 'http://$_localIp:$_localPort';
  }

  static void _logApiCall(String method, Uri uri, {Map<String, String>? headers}) {
    final authHeader = headers?['Authorization'] ?? '';
    final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
    final tokenLen = token.length;
    final tokenPreview = tokenLen > 12 ? '${token.substring(0, 8)}...${token.substring(tokenLen - 4)}' : token;
    print('[API] $method $uri | tokenLen: $tokenLen | token: $tokenPreview');
  }

  static void _logApiResponse(String method, Uri uri, http.Response response) {
    final body = response.body;
    final snippet = body.length > 250 ? '${body.substring(0, 250)}...' : body;
    print('[API RESPONSE] $method $uri | status: ${response.statusCode} | body: $snippet');
  }

  static Future<T> _runBhajanApi<T>(String apiName, Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      print('[BHAJAN API ERROR] $apiName | $e');
      rethrow;
    }
  }

  static Future<T> _runGranthApi<T>(String apiName, Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      print('[GRANTH API ERROR] $apiName | $e');
      rethrow;
    }
  }

  static Map<String, String>? _optionalAuthHeaders(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    return _authHeaders(token);
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    var trimmed = url.trim();
    if (trimmed.startsWith('assets/')) return trimmed; // Keep local assets as is

    if (!isLive) {
      // Remap production URL or localhost to active local IP base URL
      trimmed = trimmed.replaceAll('https://api.bharatpray.com', baseUrl);
      trimmed = trimmed.replaceAll('http://api.bharatpray.com', baseUrl);
      trimmed = trimmed.replaceAll('http://localhost:3020', baseUrl);
      trimmed = trimmed.replaceAll('http://127.0.0.1:3020', baseUrl);
    }
        
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    
    final isUploads = trimmed.contains('uploads/');
    final pathPrefix = trimmed.startsWith('/') ? '' : '/';
    return '$baseUrl${isUploads ? "" : "/uploads"}$pathPrefix$trimmed';
  }

  static Future<http.Response> _safeGet(Uri uri, {Map<String, String>? headers}) async {
    try {
      _logApiCall('GET', uri, headers: headers);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      _logApiResponse('GET', uri, response);
      return response;
    } on TimeoutException catch (e) {
      print('[API TIMEOUT] GET $uri | $e');
      rethrow;
    } catch (e) {
      print('[API ERROR] GET $uri | $e');
      rethrow;
    }
  }

  static Future<http.Response> _safePost(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      _logApiCall('POST', uri, headers: headers);
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 30));
      _logApiResponse('POST', uri, response);
      return response;
    } on TimeoutException catch (e) {
      print('[API TIMEOUT] POST $uri | $e');
      rethrow;
    } catch (e) {
      print('[API ERROR] POST $uri | $e');
      rethrow;
    }
  }

  static Future<http.Response> _safePut(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      _logApiCall('PUT', uri, headers: headers);
      final response = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 30));
      _logApiResponse('PUT', uri, response);
      return response;
    } on TimeoutException catch (e) {
      print('[API TIMEOUT] PUT $uri | $e');
      rethrow;
    } catch (e) {
      print('[API ERROR] PUT $uri | $e');
      rethrow;
    }
  }

  static Future<http.Response> _safePatch(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      _logApiCall('PATCH', uri, headers: headers);
      final response = await http.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 30));
      _logApiResponse('PATCH', uri, response);
      return response;
    } on TimeoutException catch (e) {
      print('[API TIMEOUT] PATCH $uri | $e');
      rethrow;
    } catch (e) {
      print('[API ERROR] PATCH $uri | $e');
      rethrow;
    }
  }

  static Future<http.Response> _safeDelete(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      _logApiCall('DELETE', uri, headers: headers);
      final response = await http.delete(uri, headers: headers, body: body).timeout(const Duration(seconds: 30));
      _logApiResponse('DELETE', uri, response);
      return response;
    } on TimeoutException catch (e) {
      print('[API TIMEOUT] DELETE $uri | $e');
      rethrow;
    } catch (e) {
      print('[API ERROR] DELETE $uri | $e');
      rethrow;
    }
  }

  static Map<String, String> _jsonHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  static Map<String, String> getAuthHeaders(String token) {
    return _authHeaders(token);
  }

  // Helper to handle http responses
  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic> && body['IsSuccess'] == true) {
          return body;
        } else {
          throw Exception(body['Message'] ?? 'Something went wrong.');
        }
      } else {
        throw Exception(body['Message'] ?? 'Server returned error status ${response.statusCode}');
      }
    } on FormatException {
      throw Exception('Failed to decode server response. Status: ${response.statusCode}');
    }
  }

  // POST /user/send-otp
  static Future<Map<String, dynamic>> sendOtp(String contact) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/send-otp'),
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
      Uri.parse('$baseUrl/user/verify-otp'),
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
      Uri.parse('$baseUrl/user/google-auth'),
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
    final uri = Uri.parse('$baseUrl/user/register');
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
      Uri.parse('$baseUrl/user/profile'),
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
      Uri.parse('$baseUrl/user/darshan/home'),
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
      Uri.parse('$baseUrl/user/jap/list'),
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
      Uri.parse('$baseUrl/user/jap/sync-progress'),
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

    final uri = Uri.parse('$baseUrl/user/darshan/list').replace(queryParameters: queryParams);
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
      Uri.parse('$baseUrl/user/darshan/details/$id'),
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
      Uri.parse('$baseUrl/user/darshan/categories'),
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
      Uri.parse('$baseUrl/user/darshan/favourite/toggle'),
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
      Uri.parse('$baseUrl/user/darshan/favourites'),
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
      Uri.parse('$baseUrl/user/darshan/search/recent'),
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
      Uri.parse('$baseUrl/user/darshan/search/save'),
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
      Uri.parse('$baseUrl/user/darshan/search/clear'),
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
      Uri.parse('$baseUrl/user/darshan/search/suggest?q=$query'),
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
      Uri.parse('$baseUrl/user/live-darshan/status/$darshanId'),
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
      Uri.parse('$baseUrl/user/live-darshan/comments/$darshanId?page=$page&limit=20'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _processResponse(response)['Data'];
  }

  // POST /user/live-darshan/comment or /user/chat/live/comment
  static Future<Map<String, dynamic>> sendLiveComment(String token, String darshanId, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/live-darshan/comment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'darshan_id': darshanId,
          'sessionId': darshanId,
          'comment': comment,
          'content': comment,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/chat/live/comment'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'sessionId': darshanId,
            'darshan_id': darshanId,
            'content': comment,
            'comment': comment,
          }),
        );
        return _processResponse(response)['Data'] ?? {};
      } catch (err) {
        print('Error sending live comment via API: $err');
        return {};
      }
    }
  }

  // POST /user/live-darshan/details (joins stream and returns metadata)
  static Future<Map<String, dynamic>> getLiveDarshanDetails(String token, String darshanId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/live-darshan/details'),
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
      Uri.parse('$baseUrl/user/live-darshan/action'),
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
  // Bhajan Flow APIs (User)
  // ==========================================

  // GET /api/bhajan/home
  static Future<Map<String, dynamic>> getBhajanHome(String token) async {
    return _runBhajanApi('GET /api/bhajan/home', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/home'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/god-category
  static Future<List<dynamic>> getBhajanGodCategories(String token) async {
    return _runBhajanApi('GET /api/god-category', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/god-category'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/bhajan/category/:categoryId?page=&limit=
  static Future<Map<String, dynamic>> getBhajansByCategory(
    String token,
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    return _runBhajanApi('GET /api/bhajan/category/:categoryId', () async {
      final uri = Uri.parse('$baseUrl/api/bhajan/category/$categoryId').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
        },
      );
      final response = await _safeGet(uri, headers: _authHeaders(token));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan?page=&limit=&search=&categoryId=
  static Future<Map<String, dynamic>> getBhajanLibrary({
    required String token,
    int page = 1,
    int limit = 10,
    String search = '',
    String categoryId = '',
  }) async {
    return _runBhajanApi('GET /api/bhajan', () async {
      final uri = Uri.parse('$baseUrl/api/bhajan').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          'search': search,
          'categoryId': categoryId,
        },
      );
      final response = await _safeGet(uri, headers: _authHeaders(token));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan/:bhajanId
  static Future<Map<String, dynamic>> getBhajanDetails(String token, String bhajanId) async {
    return _runBhajanApi('GET /api/bhajan/:bhajanId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan/stream/:bhajanId (fetches the actual streamable URL)
  static Future<String> fetchBhajanStreamUrl(String token, String bhajanId) async {
    return _runBhajanApi('GET /api/bhajan/stream/:bhajanId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/stream/$bhajanId'),
        headers: _authHeaders(token),
      );
      final data = _processResponse(response)['Data'];
      final streamUrl = data?['streamUrl'] as String?;
      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('Stream URL not found in API response for bhajan $bhajanId.');
      }
      // The backend must return a direct, network-accessible URL.
      return streamUrl;
    });
  }

  // POST /api/bhajan/:bhajanId/like
  static Future<Map<String, dynamic>> likeBhajan(String token, String bhajanId) async {
    return _runBhajanApi('POST /api/bhajan/:bhajanId/like', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId/like'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // DELETE /api/bhajan/:bhajanId/like
  static Future<Map<String, dynamic>> unlikeBhajan(String token, String bhajanId) async {
    return _runBhajanApi('DELETE /api/bhajan/:bhajanId/like', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId/like'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/bhajan/:bhajanId/favourite
  static Future<Map<String, dynamic>> addFavouriteBhajan(String token, String bhajanId) async {
    return _runBhajanApi('POST /api/bhajan/:bhajanId/favourite', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId/favourite'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // DELETE /api/bhajan/:bhajanId/favourite
  static Future<Map<String, dynamic>> removeFavouriteBhajan(String token, String bhajanId) async {
    return _runBhajanApi('DELETE /api/bhajan/:bhajanId/favourite', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId/favourite'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan/favourites
  static Future<List<dynamic>> getFavouriteBhajans(String token) async {
    return _runBhajanApi('GET /api/bhajan/favourites', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/favourites'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // POST /api/bhajan/:bhajanId/download
  static Future<Map<String, dynamic>> downloadBhajan(String token, String bhajanId) async {
    return _runBhajanApi('POST /api/bhajan/:bhajanId/download', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId/download'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan/downloads
  static Future<List<dynamic>> getDownloadedBhajans(String token) async {
    return _runBhajanApi('GET /api/bhajan/downloads', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/downloads'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // POST /api/bhajan/:bhajanId/share
  static Future<Map<String, dynamic>> shareBhajan(String token, String bhajanId) async {
    return _runBhajanApi('POST /api/bhajan/:bhajanId/share', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/bhajan/$bhajanId/share'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan/search?search=&page=&limit=
  static Future<Map<String, dynamic>> searchBhajans({
    required String token,
    required String search,
    int page = 1,
    int limit = 10,
  }) async {
    return _runBhajanApi('GET /api/bhajan/search', () async {
      final uri = Uri.parse('$baseUrl/api/bhajan/search').replace(
        queryParameters: {
          'search': search,
          'page': '$page',
          'limit': '$limit',
        },
      );
      final response = await _safeGet(uri, headers: _authHeaders(token));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/bhajan/history
  static Future<Map<String, dynamic>> saveBhajanHistory(
    String token,
    String bhajanId,
    int lastPosition,
  ) async {
    return _runBhajanApi('POST /api/bhajan/history', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/bhajan/history'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'bhajanId': bhajanId,
          'lastPosition': lastPosition,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/bhajan/history
  static Future<List<dynamic>> getBhajanHistory(String token) async {
    return _runBhajanApi('GET /api/bhajan/history', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/history'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/bhajan/continue-listening
  static Future<Map<String, dynamic>> getContinueListeningBhajan(String token) async {
    return _runBhajanApi('GET /api/bhajan/continue-listening', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/bhajan/continue-listening'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // ==========================================
  // Bhajan Flow APIs (Admin)
  // ==========================================

  // GET /api/admin/bhajan?page=&limit=&search=&status=&popular=&categoryId=
  static Future<Map<String, dynamic>> adminGetBhajanList(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
    String popular = '',
    String categoryId = '',
  }) async {
    return _runBhajanApi('GET /api/admin/bhajan', () async {
      final uri = Uri.parse('$baseUrl/api/admin/bhajan').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          'search': search,
          'status': status,
          'popular': popular,
          'categoryId': categoryId,
        },
      );
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/admin/bhajan
  static Future<Map<String, dynamic>> adminAddBhajan(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runBhajanApi('POST /api/admin/bhajan', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/bhajan'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/admin/bhajan/edit/:bhajanId
  static Future<Map<String, dynamic>> adminGetBhajanEditData(String adminToken, String bhajanId) async {
    return _runBhajanApi('GET /api/admin/bhajan/edit/:bhajanId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/bhajan/edit/$bhajanId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // PUT /api/admin/bhajan/edit/:bhajanId
  static Future<Map<String, dynamic>> adminUpdateBhajan(
    String adminToken,
    String bhajanId,
    Map<String, dynamic> payload,
  ) async {
    return _runBhajanApi('PUT /api/admin/bhajan/edit/:bhajanId', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/bhajan/edit/$bhajanId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/admin/bhajan/:bhajanId
  static Future<Map<String, dynamic>> adminGetBhajanDetails(String adminToken, String bhajanId) async {
    return _runBhajanApi('GET /api/admin/bhajan/:bhajanId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/bhajan/$bhajanId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/admin/bhajan/upload-cover
  static Future<Map<String, dynamic>> adminUploadBhajanCover(String adminToken, File file) async {
    return _runBhajanApi('POST /api/admin/bhajan/upload-cover', () async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/bhajan/upload-cover'))
        ..headers.addAll(_authHeaders(adminToken))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/admin/bhajan/upload-audio
  static Future<Map<String, dynamic>> adminUploadBhajanAudio(String adminToken, File file) async {
    return _runBhajanApi('POST /api/admin/bhajan/upload-audio', () async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/bhajan/upload-audio'))
        ..headers.addAll(_authHeaders(adminToken))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/admin/bhajan/detect-duration
  static Future<Map<String, dynamic>> adminDetectBhajanDuration(
    String adminToken, {
    required String audioUrl,
    int? duration,
  }) async {
    return _runBhajanApi('POST /api/admin/bhajan/detect-duration', () async {
      final payload = <String, dynamic>{'audioUrl': audioUrl};
      if (duration != null) {
        payload['duration'] = duration;
      }

      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/bhajan/detect-duration'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/admin/bhajan/dashboard
  static Future<Map<String, dynamic>> adminGetBhajanDashboard(String adminToken) async {
    return _runBhajanApi('GET /api/admin/bhajan/dashboard', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/bhajan/dashboard'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // PATCH /api/admin/bhajan/status/:bhajanId
  static Future<Map<String, dynamic>> adminToggleBhajanStatus(String adminToken, String bhajanId) async {
    return _runBhajanApi('PATCH /api/admin/bhajan/status/:bhajanId', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/bhajan/status/$bhajanId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // PATCH /api/admin/bhajan/popular/:bhajanId
  static Future<Map<String, dynamic>> adminToggleBhajanPopular(String adminToken, String bhajanId) async {
    return _runBhajanApi('PATCH /api/admin/bhajan/popular/:bhajanId', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/bhajan/popular/$bhajanId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // DELETE /api/admin/bhajan/:bhajanId
  static Future<Map<String, dynamic>> adminDeleteBhajan(String adminToken, String bhajanId) async {
    return _runBhajanApi('DELETE /api/admin/bhajan/:bhajanId', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/bhajan/$bhajanId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // ==========================================
  // Granth Flow APIs (User)
  // ==========================================

  // GET /api/home
  static Future<Map<String, dynamic>> getGranthHomeData({String? token}) async {
    return _runGranthApi('GET /api/home', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/home'),
        headers: _optionalAuthHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/home/featured-granths
  static Future<Map<String, dynamic>> getFeaturedGranths({int page = 1, int limit = 10}) async {
    return _runGranthApi('GET /api/home/featured-granths', () async {
      final uri = Uri.parse('$baseUrl/api/home/featured-granths').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'},
      );
      final response = await _safeGet(uri);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/home/popular-granths
  static Future<Map<String, dynamic>> getPopularGranths({int page = 1, int limit = 10}) async {
    return _runGranthApi('GET /api/home/popular-granths', () async {
      final uri = Uri.parse('$baseUrl/api/home/popular-granths').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'},
      );
      final response = await _safeGet(uri);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/home/latest-granths
  static Future<Map<String, dynamic>> getLatestGranths({int page = 1, int limit = 10}) async {
    return _runGranthApi('GET /api/home/latest-granths', () async {
      final uri = Uri.parse('$baseUrl/api/home/latest-granths').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'},
      );
      final response = await _safeGet(uri);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/granth-category
  static Future<List<dynamic>> getGranthCategories() async {
    return _runGranthApi('GET /api/granth-category', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/granth-category'));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/granth-category/:categoryId/granths
  static Future<Map<String, dynamic>> getGranthsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    return _runGranthApi('GET /api/granth-category/:categoryId/granths', () async {
      final uri = Uri.parse('$baseUrl/api/granth-category/$categoryId/granths').replace(
        queryParameters: {'page': '$page', 'limit': '$limit'},
      );
      final response = await _safeGet(uri);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/granth
  static Future<Map<String, dynamic>> getGranthLibraryData({
    int page = 1,
    int limit = 10,
    String search = '',
    String categoryId = '',
    String language = '',
    String popular = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/granth', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (categoryId.trim().isNotEmpty) params['categoryId'] = categoryId.trim();
      if (language.trim().isNotEmpty) params['language'] = language.trim();
      if (popular.trim().isNotEmpty) params['popular'] = popular.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/granth').replace(queryParameters: params);
      final response = await _safeGet(uri);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/granth/:granthId
  static Future<Map<String, dynamic>> getGranthDetails(String granthId) async {
    return _runGranthApi('GET /api/granth/:granthId', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/granth/$granthId'));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/granth/:granthId/chapters
  static Future<List<dynamic>> getChaptersByGranth(String granthId) async {
    return _runGranthApi('GET /api/granth/:granthId/chapters', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/granth/$granthId/chapters'));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/chapter/:chapterId
  static Future<Map<String, dynamic>> getChapterDetails(String chapterId) async {
    return _runGranthApi('GET /api/chapter/:chapterId', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/chapter/$chapterId'));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/chapter/:chapterId/pages
  static Future<List<dynamic>> getPagesByChapter(String chapterId) async {
    return _runGranthApi('GET /api/chapter/:chapterId/pages', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/chapter/$chapterId/pages'));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/page/:pageId
  static Future<Map<String, dynamic>> getPageDetails(String pageId) async {
    return _runGranthApi('GET /api/page/:pageId', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/page/$pageId'));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/page/:pageId/shlokas
  static Future<List<dynamic>> getShlokasByPage(String pageId) async {
    return _runGranthApi('GET /api/page/:pageId/shlokas', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/page/$pageId/shlokas'));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/shloka/:shlokaId
  static Future<Map<String, dynamic>> getShlokaDetails(String shlokaId) async {
    return _runGranthApi('GET /api/shloka/:shlokaId', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/shloka/$shlokaId'));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/audio/chapter/:chapterId
  static Future<List<dynamic>> getAudioByChapter(String chapterId) async {
    return _runGranthApi('GET /api/audio/chapter/:chapterId', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/audio/chapter/$chapterId'));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/audio/:audioId
  static Future<Map<String, dynamic>> getAudioDetails(String audioId) async {
    return _runGranthApi('GET /api/audio/:audioId', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/audio/$audioId'));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/search
  static Future<Map<String, dynamic>> searchGranthGlobal({
    required String search,
    int page = 1,
    int limit = 10,
  }) async {
    return _runGranthApi('GET /api/search', () async {
      final uri = Uri.parse('$baseUrl/api/search').replace(
        queryParameters: {'search': search, 'page': '$page', 'limit': '$limit'},
      );
      final response = await _safeGet(uri);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/popular-searches
  static Future<List<dynamic>> getPopularGranthSearches() async {
    return _runGranthApi('GET /api/popular-searches', () async {
      final response = await _safeGet(Uri.parse('$baseUrl/api/popular-searches'));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // GET /api/recommended-granths
  static Future<List<dynamic>> getRecommendedGranths({String? token}) async {
    return _runGranthApi('GET /api/recommended-granths', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/recommended-granths'),
        headers: _optionalAuthHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // POST /api/recent-search
  static Future<Map<String, dynamic>> saveGranthRecentSearch(String token, String keyword) async {
    return _runGranthApi('POST /api/recent-search', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/recent-search'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({'keyword': keyword}),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/recent-search
  static Future<List<dynamic>> getGranthRecentSearches(String token) async {
    return _runGranthApi('GET /api/recent-search', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/recent-search'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  // DELETE /api/recent-search/:id
  static Future<Map<String, dynamic>> deleteGranthRecentSearch(String token, String id) async {
    return _runGranthApi('DELETE /api/recent-search/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/recent-search/$id'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // POST /api/reading-history
  static Future<Map<String, dynamic>> saveGranthReadingHistory(
    String token, {
    required String granthId,
    required String chapterId,
    required String pageId,
  }) async {
    return _runGranthApi('POST /api/reading-history', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/reading-history'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'granthId': granthId,
          'chapterId': chapterId,
          'pageId': pageId,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // GET /api/continue-reading
  static Future<Map<String, dynamic>> getGranthContinueReading(String token) async {
    return _runGranthApi('GET /api/continue-reading', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/continue-reading'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // ==========================================
  // Granth Flow APIs (Admin)
  // ==========================================

  // Granth Category (Admin)
  static Future<List<dynamic>> adminGetGranthCategoryDropdown(String adminToken) async {
    return _runGranthApi('GET /api/admin/granth-category/dropdown', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/granth-category/dropdown'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<Map<String, dynamic>> adminGetGranthCategories(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/admin/granth-category', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (status.trim().isNotEmpty) params['status'] = status.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/admin/granth-category').replace(queryParameters: params);
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminCreateGranthCategory(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('POST /api/admin/granth-category', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/granth-category'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUpdateGranthCategory(
    String adminToken,
    String categoryId,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PUT /api/admin/granth-category/:id', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/granth-category/$categoryId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeleteGranthCategory(String adminToken, String categoryId) async {
    return _runGranthApi('DELETE /api/admin/granth-category/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/granth-category/$categoryId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminToggleGranthCategoryStatus(String adminToken, String categoryId) async {
    return _runGranthApi('PATCH /api/admin/granth-category/status/:id', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/granth-category/status/$categoryId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // Granth (Admin)
  static Future<List<dynamic>> adminGetGranthDropdown(String adminToken) async {
    return _runGranthApi('GET /api/admin/granth/dropdown', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/granth/dropdown'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<Map<String, dynamic>> adminGetGranthStatistics(String adminToken) async {
    return _runGranthApi('GET /api/admin/granth/statistics', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/granth/statistics'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUploadGranthCover(String adminToken, File file) async {
    return _runGranthApi('POST /api/admin/granth/upload-cover', () async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/granth/upload-cover'))
        ..headers.addAll(_authHeaders(adminToken))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeleteGranthCover(String adminToken, String coverId) async {
    return _runGranthApi('DELETE /api/admin/granth/upload-cover/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/granth/upload-cover/$coverId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetGranthList(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String categoryId = '',
    String status = '',
    String popular = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/admin/granth', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (categoryId.trim().isNotEmpty) params['categoryId'] = categoryId.trim();
      if (status.trim().isNotEmpty) params['status'] = status.trim();
      if (popular.trim().isNotEmpty) params['popular'] = popular.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/admin/granth').replace(queryParameters: params);
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetGranthById(String adminToken, String granthId) async {
    return _runGranthApi('GET /api/admin/granth/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/granth/$granthId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminCreateGranth(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('POST /api/admin/granth', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/granth'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUpdateGranth(
    String adminToken,
    String granthId,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PUT /api/admin/granth/:id', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/granth/$granthId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeleteGranth(String adminToken, String granthId) async {
    return _runGranthApi('DELETE /api/admin/granth/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/granth/$granthId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminToggleGranthStatus(String adminToken, String granthId) async {
    return _runGranthApi('PATCH /api/admin/granth/status/:id', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/granth/status/$granthId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminToggleGranthPopular(String adminToken, String granthId) async {
    return _runGranthApi('PATCH /api/admin/granth/popular/:id', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/granth/popular/$granthId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // Chapter (Admin)
  static Future<List<dynamic>> adminGetChapterByGranth(String adminToken, String granthId) async {
    return _runGranthApi('GET /api/admin/chapter/by-granth/:granthId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/chapter/by-granth/$granthId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<List<dynamic>> adminGetChapterDropdown(String adminToken, {String? granthId}) async {
    return _runGranthApi('GET /api/admin/chapter/dropdown', () async {
      final path = granthId != null && granthId.trim().isNotEmpty
          ? '$baseUrl/api/admin/chapter/dropdown/${granthId.trim()}'
          : '$baseUrl/api/admin/chapter/dropdown';
      final response = await _safeGet(Uri.parse(path), headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<Map<String, dynamic>> adminGetChapterList(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String granthId = '',
    String status = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/admin/chapter', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (granthId.trim().isNotEmpty) params['granthId'] = granthId.trim();
      if (status.trim().isNotEmpty) params['status'] = status.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/admin/chapter').replace(queryParameters: params);
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetChapterById(String adminToken, String chapterId) async {
    return _runGranthApi('GET /api/admin/chapter/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/chapter/$chapterId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminCreateChapter(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('POST /api/admin/chapter', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/chapter'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUpdateChapter(
    String adminToken,
    String chapterId,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PUT /api/admin/chapter/:id', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/chapter/$chapterId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeleteChapter(String adminToken, String chapterId) async {
    return _runGranthApi('DELETE /api/admin/chapter/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/chapter/$chapterId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminToggleChapterStatus(String adminToken, String chapterId) async {
    return _runGranthApi('PATCH /api/admin/chapter/status/:id', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/chapter/status/$chapterId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // Page (Admin)
  static Future<List<dynamic>> adminGetPagesByChapter(String adminToken, String chapterId) async {
    return _runGranthApi('GET /api/admin/page/by-chapter/:chapterId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/page/by-chapter/$chapterId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<Map<String, dynamic>> adminReorderPages(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PATCH /api/admin/page/reorder', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/page/reorder'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetPagePreview(String adminToken, String pageId) async {
    return _runGranthApi('GET /api/admin/page/preview/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/page/preview/$pageId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetPageList(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String chapterId = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/admin/page', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (chapterId.trim().isNotEmpty) params['chapterId'] = chapterId.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/admin/page').replace(queryParameters: params);
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetPageById(String adminToken, String pageId) async {
    return _runGranthApi('GET /api/admin/page/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/page/$pageId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminCreatePage(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('POST /api/admin/page', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/page'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUpdatePage(
    String adminToken,
    String pageId,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PUT /api/admin/page/:id', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/page/$pageId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeletePage(String adminToken, String pageId) async {
    return _runGranthApi('DELETE /api/admin/page/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/page/$pageId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // Shloka (Admin)
  static Future<List<dynamic>> adminGetShlokasByPage(String adminToken, String pageId) async {
    return _runGranthApi('GET /api/admin/shloka/by-page/:pageId', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/shloka/by-page/$pageId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<Map<String, dynamic>> adminReorderShlokas(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PATCH /api/admin/shloka/reorder', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/shloka/reorder'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUploadShlokaImage(String adminToken, File file) async {
    return _runGranthApi('POST /api/admin/shloka/upload-image', () async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/shloka/upload-image'))
        ..headers.addAll(_authHeaders(adminToken))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUploadShlokaAudio(String adminToken, File file) async {
    return _runGranthApi('POST /api/admin/shloka/upload-audio', () async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/shloka/upload-audio'))
        ..headers.addAll(_authHeaders(adminToken))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetShlokaList(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String pageId = '',
    String status = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/admin/shloka', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (pageId.trim().isNotEmpty) params['pageId'] = pageId.trim();
      if (status.trim().isNotEmpty) params['status'] = status.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/admin/shloka').replace(queryParameters: params);
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetShlokaById(String adminToken, String shlokaId) async {
    return _runGranthApi('GET /api/admin/shloka/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/shloka/$shlokaId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminCreateShloka(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('POST /api/admin/shloka', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/shloka'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUpdateShloka(
    String adminToken,
    String shlokaId,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PUT /api/admin/shloka/:id', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/shloka/$shlokaId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeleteShloka(String adminToken, String shlokaId) async {
    return _runGranthApi('DELETE /api/admin/shloka/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/shloka/$shlokaId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminToggleShlokaStatus(String adminToken, String shlokaId) async {
    return _runGranthApi('PATCH /api/admin/shloka/status/:id', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/shloka/status/$shlokaId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // Audio (Admin)
  static Future<Map<String, dynamic>> adminPreviewAudio(String adminToken, String audioId) async {
    return _runGranthApi('GET /api/admin/audio/preview/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/audio/preview/$audioId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetAudioList(
    String adminToken, {
    int page = 1,
    int limit = 10,
    String search = '',
    String chapterId = '',
    String language = '',
    String status = '',
    String sortBy = '',
    String sortOrder = '',
  }) async {
    return _runGranthApi('GET /api/admin/audio', () async {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      if (chapterId.trim().isNotEmpty) params['chapterId'] = chapterId.trim();
      if (language.trim().isNotEmpty) params['language'] = language.trim();
      if (status.trim().isNotEmpty) params['status'] = status.trim();
      if (sortBy.trim().isNotEmpty) params['sortBy'] = sortBy.trim();
      if (sortOrder.trim().isNotEmpty) params['sortOrder'] = sortOrder.trim();

      final uri = Uri.parse('$baseUrl/api/admin/audio').replace(queryParameters: params);
      final response = await _safeGet(uri, headers: _authHeaders(adminToken));
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminGetAudioById(String adminToken, String audioId) async {
    return _runGranthApi('GET /api/admin/audio/:id', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/audio/$audioId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminCreateAudio(
    String adminToken,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('POST /api/admin/audio', () async {
      final response = await _safePost(
        Uri.parse('$baseUrl/api/admin/audio'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminUpdateAudio(
    String adminToken,
    String audioId,
    Map<String, dynamic> payload,
  ) async {
    return _runGranthApi('PUT /api/admin/audio/:id', () async {
      final response = await _safePut(
        Uri.parse('$baseUrl/api/admin/audio/$audioId'),
        headers: _jsonHeaders(token: adminToken),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminDeleteAudio(String adminToken, String audioId) async {
    return _runGranthApi('DELETE /api/admin/audio/:id', () async {
      final response = await _safeDelete(
        Uri.parse('$baseUrl/api/admin/audio/$audioId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  static Future<Map<String, dynamic>> adminToggleAudioStatus(String adminToken, String audioId) async {
    return _runGranthApi('PATCH /api/admin/audio/status/:id', () async {
      final response = await _safePatch(
        Uri.parse('$baseUrl/api/admin/audio/status/$audioId'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // Shared Admin Granth APIs
  static Future<List<dynamic>> adminGetLanguageDropdown(String adminToken) async {
    return _runGranthApi('GET /api/admin/language/dropdown', () async {
      final response = await _safeGet(
        Uri.parse('$baseUrl/api/admin/language/dropdown'),
        headers: _authHeaders(adminToken),
      );
      return _processResponse(response)['Data'] ?? [];
    });
  }

  static Future<Map<String, dynamic>> adminUploadCommonAudio(String adminToken, File file) async {
    return _runGranthApi('POST /api/admin/upload/audio', () async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/upload/audio'))
        ..headers.addAll(_authHeaders(adminToken))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response)['Data'] ?? {};
    });
  }

  // ==========================================
  // Yatra Flow APIs
  // ==========================================

  // ==========================================
  // Yatra Flow APIs (Repository Layer - Phase 1)
  // ==========================================

  // Memory cache for offline/instant fallback
  static Map<String, dynamic>? _popularCache;
  static Map<String, dynamic>? _continueCache;
  static DateTime? _popularCacheTime;

  /// GET /user/yatra/popular (Paginated Popular Yatras)
  static Future<ApiResponseModel<List<YatraModel>>> getPopularYatra({
    String? token,
    int page = 1,
    int limit = 10,
    String search = '',
    bool forceRefresh = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/user/yatra/popular').replace(queryParameters: queryParams);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    // Use memory cache if valid (< 5 mins), non-empty, and no search/refresh requested
    if (!forceRefresh && page == 1 && search.isEmpty && _popularCache != null && _popularCacheTime != null) {
      final cachedDocs = _popularCache!['Data']?['docs'] ?? _popularCache!['docs'];
      if (cachedDocs is List && cachedDocs.isNotEmpty) {
        if (DateTime.now().difference(_popularCacheTime!) < const Duration(minutes: 5)) {
          return ApiResponseModel<List<YatraModel>>.fromJson(_popularCache, (dataJson) {
            final docs = dataJson['docs'] is List ? (dataJson['docs'] as List) : [];
            return docs.map((d) => YatraModel.fromJson(d)).toList();
          });
        }
      }
    }

    try {
      final response = await _safeGet(uri, headers: headers);
      final jsonBody = _processResponse(response);

      final result = ApiResponseModel<List<YatraModel>>.fromJson(jsonBody, (dataJson) {
        final docs = dataJson['docs'] is List
            ? (dataJson['docs'] as List)
            : (dataJson is List ? dataJson : []);
        return docs.map((d) => YatraModel.fromJson(d)).toList();
      });

      if (page == 1 && search.isEmpty && result.data != null && result.data!.isNotEmpty) {
        _popularCache = jsonBody;
        _popularCacheTime = DateTime.now();
      } else if (page == 1 && search.isEmpty) {
        _popularCache = null;
        _popularCacheTime = null;
      }

      return result;
    } catch (e) {
      // Fallback to cache on network failure
      if (_popularCache != null) {
        return ApiResponseModel<List<YatraModel>>.fromJson(_popularCache, (dataJson) {
          final docs = dataJson['docs'] is List ? (dataJson['docs'] as List) : [];
          return docs.map((d) => YatraModel.fromJson(d)).toList();
        });
      }
      return ApiResponseModel<List<YatraModel>>(
        isSuccess: false,
        statusCode: 500,
        message: 'Failed to load Popular Yatras: ${e.toString().replaceAll("Exception: ", "")}',
        error: e.toString(),
      );
    }
  }

  /// Refetch Page 1 of Popular Yatras
  static Future<ApiResponseModel<List<YatraModel>>> refreshPopularYatra({
    String? token,
    int limit = 10,
  }) async {
    return getPopularYatra(token: token, page: 1, limit: limit, forceRefresh: true);
  }

  /// Search Popular Yatras with query
  static Future<ApiResponseModel<List<YatraModel>>> searchPopularYatra(
    String query, {
    String? token,
    int limit = 10,
  }) async {
    return getPopularYatra(token: token, page: 1, limit: limit, search: query, forceRefresh: true);
  }

  /// Load Next Page for Infinite Scroll
  static Future<ApiResponseModel<List<YatraModel>>> loadMorePopularYatra({
    required int nextPage,
    String? token,
    int limit = 10,
    String search = '',
  }) async {
    return getPopularYatra(token: token, page: nextPage, limit: limit, search: search);
  }

  /// GET /user/yatra/journey/current (Active Continue Yatra Progress)
  static Future<ApiResponseModel<ContinueYatraModel?>> getContinueYatra({
    String? token,
    bool forceRefresh = false,
  }) async {
    final uri = Uri.parse('$baseUrl/user/yatra/journey/current');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    if (!forceRefresh && _continueCache != null) {
      return ApiResponseModel<ContinueYatraModel?>.fromJson(_continueCache, (dataJson) {
        if (dataJson == null || dataJson == 0) return null;
        return ContinueYatraModel.fromJson(dataJson);
      });
    }

    try {
      final response = await _safeGet(uri, headers: headers);
      final jsonBody = _processResponse(response);
      _continueCache = jsonBody;

      return ApiResponseModel<ContinueYatraModel?>.fromJson(jsonBody, (dataJson) {
        if (dataJson == null || dataJson == 0) return null;
        return ContinueYatraModel.fromJson(dataJson);
      });
    } catch (e) {
      if (_continueCache != null) {
        return ApiResponseModel<ContinueYatraModel?>.fromJson(_continueCache, (dataJson) {
          if (dataJson == null || dataJson == 0) return null;
          return ContinueYatraModel.fromJson(dataJson);
        });
      }
      return ApiResponseModel<ContinueYatraModel?>(
        isSuccess: false,
        statusCode: 500,
        message: 'Failed to load active journey: ${e.toString().replaceAll("Exception: ", "")}',
        error: e.toString(),
      );
    }
  }

  // Legacy compatibility getters
  static Future<List<dynamic>> getPopularYatras(String token) async {
    final res = await getPopularYatra(token: token);
    if (res.isSuccess && res.data != null) {
      return res.data!.map((y) => y.toJson()).toList();
    }
    return [];
  }

  static Future<List<dynamic>> getContinueYatras(String token) async {
    final res = await getContinueYatra(token: token);
    if (res.isSuccess && res.data != null) {
      return [res.data!.toJson()];
    }
    return [];
  }

  // POST /user/yatra/journey/start
  static Future<Map<String, dynamic>> startYatra(String token, String yatraId) async {
    final response = await _safePost(
      Uri.parse('$baseUrl/user/yatra/journey/start'),
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
        Uri.parse('$baseUrl/user/yatra/progress/user'),
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
        Uri.parse('$baseUrl/user/yatra/group/$groupId/members'),
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
        Uri.parse('$baseUrl/user/yatra/group/start'),
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
        Uri.parse('$baseUrl/user/yatra/journey/resume'),
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
        Uri.parse('$baseUrl/user/yatra/journey/stop'),
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
        Uri.parse('$baseUrl/user/yatra/journey/complete'),
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
        Uri.parse('$baseUrl/user/yatra/journey/progress?journeyId=$journeyId'),
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
        Uri.parse('$baseUrl/user/yatra/journey/distance-remaining?journeyId=$journeyId'),
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
        Uri.parse('$baseUrl/user/yatra/journey/location'),
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
        Uri.parse('$baseUrl/user/yatra/solo/nearby'),
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
        Uri.parse('$baseUrl/user/yatra/group-chat/$groupId/messages'),
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
        Uri.parse('$baseUrl/user/yatra/personal-chat/$chatId/messages'),
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
        Uri.parse('$baseUrl/user/yatra/certificate/generate'),
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
        Uri.parse('$baseUrl/user/yatra/journey/summary'),
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
        Uri.parse('$baseUrl/user/yatra/journey/timeline'),
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

  // ==========================================
  // Phase 2: Create Yatra Group Flow APIs
  // ==========================================

  // GET /user/yatra-group/temples
  static Future<Map<String, dynamic>> getTemplesForGroup(String token, {String search = '', int page = 1}) async {
    try {
      final uri = Uri.parse('$baseUrl/user/yatra-group/temples').replace(
        queryParameters: {
          'search': search,
          'page': '$page',
          'limit': '20',
        },
      );
      final response = await _safeGet(uri, headers: _authHeaders(token));
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error fetching temples for group: $e');
      return {};
    }
  }

  // POST /user/yatra-group/calculate-distance
  static Future<Map<String, dynamic>> calculateTempleDistance(
    String token, {
    required String templeId,
    double? startLat,
    double? startLng,
  }) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/user/yatra-group/calculate-distance'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'templeId': templeId,
          if (startLat != null) 'startLat': startLat,
          if (startLng != null) 'startLng': startLng,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error calculating distance: $e');
      return {};
    }
  }

  // POST /user/yatra-group/contacts/sync
  static Future<Map<String, dynamic>> syncContacts(
    String token, {
    required List<dynamic> contacts,
    String? groupId,
  }) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/user/yatra-group/contacts/sync'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'contacts': contacts,
          if (groupId != null) 'groupId': groupId,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error syncing contacts: $e');
      return {};
    }
  }

  // GET /user/yatra-group/my-groups
  static Future<Map<String, dynamic>> getMyYatraGroups(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/user/yatra-group/my-groups'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error fetching my groups: $e');
      return {};
    }
  }

  // POST /user/yatra-group/create
  static Future<Map<String, dynamic>> createYatraGroup(String token, Map<String, dynamic> payload) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/user/yatra-group/create'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode(payload),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error creating Yatra group: $e');
      return {};
    }
  }

  // POST /user/yatra-group/invite/send
  static Future<Map<String, dynamic>> sendGroupInvitations(
    String token, {
    required String groupId,
    required List<String> inviteeIds,
  }) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/user/yatra-group/invite/send'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'groupId': groupId,
          'inviteeIds': inviteeIds,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error sending invitations: $e');
      return {};
    }
  }

  // GET /user/yatra-group/invitations
  static Future<List<dynamic>> getPendingInvitations(String token) async {
    try {
      final response = await _safeGet(
        Uri.parse('$baseUrl/user/yatra-group/invitations'),
        headers: _authHeaders(token),
      );
      return _processResponse(response)['Data'] ?? [];
    } catch (e) {
      print('Error fetching invitations: $e');
      return [];
    }
  }

  // POST /user/yatra-group/invite/accept
  static Future<Map<String, dynamic>> acceptGroupInvitation(
    String token, {
    String? groupId,
    String? inviteToken,
  }) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/user/yatra-group/invite/accept'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          if (groupId != null) 'groupId': groupId,
          if (inviteToken != null) 'inviteToken': inviteToken,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error accepting invitation: $e');
      return {};
    }
  }

  // POST /user/yatra-group/invite/reject
  static Future<Map<String, dynamic>> rejectGroupInvitation(
    String token, {
    String? groupId,
    String? inviteToken,
  }) async {
    try {
      final response = await _safePost(
        Uri.parse('$baseUrl/user/yatra-group/invite/reject'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          if (groupId != null) 'groupId': groupId,
          if (inviteToken != null) 'inviteToken': inviteToken,
        }),
      );
      return _processResponse(response)['Data'] ?? {};
    } catch (e) {
      print('Error rejecting invitation: $e');
      return {};
    }
  }
}

