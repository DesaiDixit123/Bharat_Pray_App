import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UtsavService {
  // Shared Admin Utsav Initial Data
  static const List<Map<String, dynamic>> _kInitialFestivals = [
    {
      '_id': 'fest-002',
      'name': 'Maha Navratri Garba Utsav 2026',
      'slogan': '9 Divine Nights of Mataji Bhakti & Raas Garba Mandal Competition',
      'banner': 'assets/images/devotional/navratri_garba_festival.jpg',
      'isDateRange': true,
      'startDate': '2026-10-11',
      'endDate': '2026-10-20',
      'formattedDate': '11 Oct 2026 - 20 Oct 2026',
      'regStartDate': '2026-09-20',
      'regEndDate': '2026-10-10',
      'formattedRegDate': '20 Sep 2026 - 10 Oct 2026',
      'status': 'Upcoming',
      'isPopular': true,
      'description': 'Nine nights of divine devotion to Maa Durga. Pandals compete for best traditional Garba costume, decor, and Aarti bhajan setup.',
      'timing': 'Daily Raas Garba & Aarti: 7:00 PM - 12:00 AM',
      'rewards': {
        'first': 'Grand Garba Trophy & Golden Winner Certificate',
        'second': 'Silver Shield & Runner-up Certificate',
        'third': 'Bronze Medal & Excellence Certificate',
      },
      'participantCount': 0,
      'totalVotes': 0,
    },
    {
      '_id': 'fest-003',
      'name': 'Diwali Deepotsav 2026',
      'slogan': 'Festival of Lights, Deepavali Aarti & Rangoli Mandal Competition',
      'banner': 'assets/images/devotional/diwali_festival.png',
      'isDateRange': true,
      'startDate': '2026-11-08',
      'endDate': '2026-11-12',
      'formattedDate': '08 Nov 2026 - 12 Nov 2026',
      'regStartDate': '2026-10-15',
      'regEndDate': '2026-11-05',
      'formattedRegDate': '15 Oct 2026 - 05 Nov 2026',
      'status': 'Upcoming',
      'isPopular': true,
      'description': 'Festival of lights across India. Grand temple illumination and Lakshmi Puja pandals.',
      'timing': 'Deepotsav & Lakshmi Aarti: 6:00 PM - 11:00 PM',
      'rewards': {
        'first': 'Deepotsav Grand Trophy & Golden Certificate',
        'second': 'Silver Shield & Runner-up Certificate',
        'third': 'Bronze Medal & Excellence Certificate',
      },
      'participantCount': 0,
      'totalVotes': 0,
    },
    {
      '_id': 'fest-001',
      'name': 'Ganesh Chaturthi Mahotsav 2026',
      'slogan': 'Divya Lalbaugcha Raja & Grand City Mandals Competition',
      'banner': 'assets/images/devotional/ganesh_festival.png',
      'isDateRange': true,
      'startDate': '2026-09-07',
      'endDate': '2026-09-17',
      'formattedDate': '07 Sep 2026 - 17 Sep 2026',
      'regStartDate': '2026-08-01',
      'regEndDate': '2026-08-31',
      'formattedRegDate': '01 Aug 2026 - 31 Aug 2026',
      'status': 'Completed',
      'isPopular': false,
      'description': 'Eco-friendly idols, grand pandal decorations, and cultural performances.',
      'timing': 'Daily Ganesh Aarti & Darshan: 6:00 AM - 11:00 PM',
      'rewards': {
        'first': '₹1,00,000 Grand Trophy & Golden Certificate',
        'second': '₹50,000 Silver Shield & Winner Certificate',
        'third': '₹25,000 Bronze Medal & Excellence Certificate',
      },
      'participantCount': 0,
      'totalVotes': 0,
    }
  ];

  // ─── Dynamic Date Calculation ──────────────────────────────────────────────

  static DateTime? _parseDate(String? str) {
    if (str == null || str.trim().isEmpty) return null;
    str = str.trim();
    try {
      return DateTime.parse(str);
    } catch (_) {}

    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    final parts = str.split(RegExp(r'[\s\-/,]+'));
    if (parts.length >= 3) {
      int? day = int.tryParse(parts[0]);
      int? month = months[parts[1].toLowerCase().substring(0, 3)];
      int? year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
      year = int.tryParse(parts[0]);
      month = months[parts[1].toLowerCase().substring(0, 3)] ?? int.tryParse(parts[1]);
      day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null && year > 1000) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  static String computeFestivalStatus(String? startDateStr, String? endDateStr, String fallbackStatus, {String? festivalName}) {
    if (festivalName != null) {
      final nameLower = festivalName.toLowerCase();
      if (nameLower.contains('ganesh') || nameLower.contains('chaturthi')) {
        return 'Completed';
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = _parseDate(startDateStr);
    final end = _parseDate(endDateStr);

    if (end != null) {
      final endDay = DateTime(end.year, end.month, end.day);
      if (today.isAfter(endDay)) return 'Completed';
    }

    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day);
      if (today.isBefore(startDay)) return 'Upcoming';
      if (end != null) {
        final endDay = DateTime(end.year, end.month, end.day);
        if (today.isAfter(endDay)) return 'Completed';
      }
      return 'Active';
    }

    return fallbackStatus;
  }

  static String computeRegistrationStatus(
    String? regStartDateStr,
    String? regEndDateStr,
    String? fallbackStatus, {
    String? festivalStatus,
    String? festivalName,
  }) {
    if (festivalName != null && (festivalName.toLowerCase().contains('ganesh') || festivalName.toLowerCase().contains('chaturthi'))) {
      return 'closed';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final regStart = _parseDate(regStartDateStr);
    final regEnd = _parseDate(regEndDateStr);

    if (regStart != null && regEnd != null) {
      final startDay = DateTime(regStart.year, regStart.month, regStart.day);
      final endDay = DateTime(regEnd.year, regEnd.month, regEnd.day);

      if (today.isBefore(startDay)) {
        return 'coming_soon';
      } else if (today.isAfter(endDay)) {
        return 'closed';
      } else {
        return 'open';
      }
    }

    if (festivalName != null && festivalName.toLowerCase().contains('navratri')) {
      final nStart = DateTime(2026, 9, 20);
      final nEnd = DateTime(2026, 10, 10);
      if ((today.isAfter(nStart) || today.isAtSameMomentAs(nStart)) && (today.isBefore(nEnd) || today.isAtSameMomentAs(nEnd))) {
        return 'open';
      } else if (today.isBefore(nStart)) {
        return 'coming_soon';
      } else {
        return 'closed';
      }
    }

    if (festivalName != null && festivalName.toLowerCase().contains('diwali')) {
      final dStart = DateTime(2026, 10, 15);
      final dEnd = DateTime(2026, 11, 5);
      if (today.isBefore(dStart)) {
        return 'coming_soon';
      } else if (today.isAfter(dEnd)) {
        return 'closed';
      } else {
        return 'open';
      }
    }

    if (fallbackStatus != null && fallbackStatus.isNotEmpty && fallbackStatus != 'open') {
      return fallbackStatus;
    }

    return 'coming_soon';
  }

  static Future<bool> isRegistrationActive(Map<String, dynamic>? reg) async {
    if (reg == null) return false;
    if (reg['status']?.toString().toLowerCase() == 'deleted') return false;
    final festName = (reg['festival'] ?? reg['festivalName'] ?? '').toString();
    if (festName.isEmpty) return false;
    if (festName.toLowerCase().contains('ganesh') || festName.toLowerCase().contains('chaturthi')) {
      return false;
    }
    final fest = await getFestivalByName(festName);
    if (fest != null) {
      final status = fest['status']?.toString();
      if (status == 'Completed') return false;
      return true;
    }
    return true;
  }

  static Map<String, dynamic> _withDynamicStatus(Map<String, dynamic> f) {
    final copy = Map<String, dynamic>.from(f);
    final name = copy['name']?.toString() ?? '';
    if (name.toLowerCase().contains('ganesh') || name.toLowerCase().contains('chaturthi')) {
      copy['status'] = 'Completed';
      copy['registrationStatus'] = 'closed';
      return copy;
    }
    copy['status'] = computeFestivalStatus(
      copy['startDate']?.toString(),
      copy['endDate']?.toString(),
      copy['status']?.toString() ?? 'Upcoming',
      festivalName: name,
    );
    copy['registrationStatus'] = computeRegistrationStatus(
      copy['regStartDate']?.toString(),
      copy['regEndDate']?.toString(),
      copy['status'] == 'Active' ? 'open' : 'coming_soon',
      festivalStatus: copy['status']?.toString(),
      festivalName: name,
    );
    return copy;
  }

  // ─── Festivals ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFestivals({String status = 'ALL'}) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/utsav/festivals?status=$status');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['IsSuccess'] == true && data['Data'] is List) {
          final list = (data['Data'] as List).cast<Map<String, dynamic>>();
          final clean = list.where((f) => !(f['name'] ?? '').toString().toLowerCase().contains('ganesh')).toList();
          final computed = clean.map(_withDynamicStatus).toList();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('utsav_cached_festivals', jsonEncode(clean));
          if (status == 'ALL') return computed;
          return computed.where((f) => (f['status'] ?? '').toString().toLowerCase() == status.toLowerCase()).toList();
        }
      }
    } catch (_) {}

    // Fallback to unified data
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('utsav_cached_festivals');
    List<Map<String, dynamic>> all = _kInitialFestivals;
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List;
        final list = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((f) => !(f['name'] ?? '').toString().toLowerCase().contains('ganesh'))
            .toList();
        if (list.isNotEmpty) {
          all = list;
        }
      } catch (_) {}
    }

    final computedAll = all.map(_withDynamicStatus).toList();
    if (status == 'ALL') return computedAll;
    return computedAll.where((f) => (f['status'] ?? '').toString().toLowerCase() == status.toLowerCase()).toList();
  }

  static Future<String> getUpcomingRegistrationFestivalName() async {
    try {
      final upcoming = await getFestivals(status: 'Upcoming');
      final openFest = upcoming.firstWhere(
        (f) => f['registrationStatus'] == 'open',
        orElse: () => upcoming.isNotEmpty ? upcoming.first : <String, dynamic>{},
      );
      if (openFest.isNotEmpty && openFest['name'] != null) {
        return openFest['name'].toString();
      }
    } catch (_) {}
    return "Maha Navratri Garba Utsav 2026";
  }

  // ─── Mandals ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMandals({String? festivalId, String? status}) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/utsav/mandals${festivalId != null ? '?festivalId=$festivalId' : ''}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['IsSuccess'] == true && data['Data'] is List) {
          final list = (data['Data'] as List).cast<Map<String, dynamic>>();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('utsav_cached_mandals');
    List<Map<String, dynamic>> all = [];
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List;
        final list = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        // Purge mock mandals (only keep real registered mandals)
        final realOnly = list.where((m) {
          final n = (m['name'] ?? '').toString();
          return !n.contains('United Way') &&
              !n.contains('Ambaji') &&
              !n.contains('Lalbaug') &&
              !n.contains('Surat Sarvajanik') &&
              !n.contains('Shakti Mahotsav') &&
              m['_id'] != 'mandal-101' &&
              m['_id'] != 'mandal-201' &&
              m['_id'] != 'mandal-202' &&
              m['_id'] != 'mandal-203' &&
              m['_id'] != 'mandal-204';
        }).toList();
        all = realOnly;
      } catch (_) {}
    }

    // Always include the user's registered mandal if available
    final myReg = await getMyMandalRegistration();
    if (myReg != null && (myReg['mandalName']?.toString().trim().isNotEmpty ?? false)) {
      final myMandalName = myReg['mandalName'].toString().trim();
      if (!all.any((m) => (m['name'] ?? '').toString().trim().toLowerCase() == myMandalName.toLowerCase())) {
        all.add({
          '_id': 'mandal_my_${myReg['registrationId'] ?? 'user'}',
          'registrationId': myReg['registrationId'],
          'festivalId': myReg['festivalId'] ?? 'fest-002',
          'name': myMandalName,
          'city': myReg['address'] ?? myReg['city'] ?? 'Gujarat, India',
          'regNo': myReg['registrationId'] ?? 'REG-001',
          'rank': 1,
          'votes': 0,
          'likes': '0',
          'shares': '0',
          'views': 0,
          'postsCount': 0,
          'status': myReg['status'] ?? 'Approved',
          'imageUrl': myReg['cover'] ?? myReg['coverUrl'] ?? myReg['logo'] ?? myReg['logoUrl'] ?? 'assets/images/devotional/navratri_garba_festival.jpg',
          'logo': myReg['logo'] ?? myReg['logoUrl'] ?? 'assets/images/devotional/navratri_garba_festival.jpg',
          'description': 'Devotional Mandal in ${myReg['address'] ?? 'Gujarat'}.',
          'leader': {
            'name': myReg['leaderName'] ?? '',
            'role': 'Leader',
            'phone': myReg['mobile'] ?? '',
          },
          'leaderName': myReg['leaderName'] ?? '',
          'phone': myReg['mobile'] ?? '',
          'createdAt': myReg['createdAt'] ?? myReg['updatedAt'],
          'updatedAt': myReg['updatedAt'] ?? myReg['createdAt'],
        });
      }
    }

    if (festivalId != null && festivalId.isNotEmpty) {
      all = all.where((m) => m['festivalId'] == festivalId).toList();
    }
    if (status != null && status.isNotEmpty) {
      all = all.where((m) => (m['status'] ?? '').toString().toLowerCase() == status.toLowerCase()).toList();
    }

    // Rank strictly based on real votes, then real likes
    all.sort((a, b) {
      final vA = a['votes'] is num ? (a['votes'] as num).toInt() : int.tryParse(a['votes']?.toString() ?? '0') ?? 0;
      final vB = b['votes'] is num ? (b['votes'] as num).toInt() : int.tryParse(b['votes']?.toString() ?? '0') ?? 0;
      if (vB != vA) return vB.compareTo(vA);
      final lA = int.tryParse(a['likes']?.toString() ?? '0') ?? 0;
      final lB = int.tryParse(b['likes']?.toString() ?? '0') ?? 0;
      return lB.compareTo(lA);
    });

    for (int i = 0; i < all.length; i++) {
      all[i]['rank'] = i + 1;
      all[i]['badge'] = i == 0 ? '🏆 #1' : (i == 1 ? '🥈 #2' : (i == 2 ? '🥉 #3' : '#${i + 1}'));
    }

    return all;
  }

  static Future<Map<String, dynamic>?> getFestivalByName(String name) async {
    final list = await getFestivals();
    final lower = name.toLowerCase().trim();
    for (final f in list) {
      final fName = (f['name'] ?? '').toString().toLowerCase();
      if (fName == lower || fName.contains(lower) || lower.contains(fName)) {
        return f;
      }
    }
    return list.isNotEmpty ? list.first : null;
  }

  static Future<Map<String, dynamic>?> getMandalByName(String name) async {
    final list = await getMandals();
    final lower = name.toLowerCase().trim();
    for (final m in list) {
      final mName = (m['name'] ?? '').toString().toLowerCase();
      if (mName == lower || mName.contains(lower) || lower.contains(mName)) {
        return m;
      }
    }
    return null;
  }

  // ─── Festival Active / Started Check ───────────────────────────────────────

  static Future<Map<String, dynamic>> checkFestivalStartedForMandal({
    String? mandalName,
    String? festivalName,
    String? festivalId,
  }) async {
    Map<String, dynamic>? fest;
    String targetFestName = festivalName ?? '';
    String targetFestId = festivalId ?? '';

    if (targetFestName.isEmpty && targetFestId.isEmpty) {
      if (mandalName != null && mandalName.isNotEmpty) {
        final m = await getMandalByName(mandalName);
        if (m != null) {
          targetFestId = (m['festivalId'] ?? '').toString();
          targetFestName = (m['festival'] ?? m['festivalName'] ?? m['category'] ?? '').toString();
        }
      }
    }

    if (targetFestName.isEmpty && targetFestId.isEmpty) {
      final myReg = await getMyMandalRegistration();
      if (myReg != null) {
        targetFestId = (myReg['festivalId'] ?? '').toString();
        targetFestName = (myReg['festival'] ?? myReg['festivalName'] ?? myReg['category'] ?? '').toString();
      }
    }

    final allFestivals = await getFestivals();

    if (targetFestId.isNotEmpty) {
      fest = allFestivals.firstWhere(
        (f) => f['_id']?.toString() == targetFestId || f['customId']?.toString() == targetFestId,
        orElse: () => <String, dynamic>{},
      );
      if (fest.isEmpty) fest = null;
    }

    if (fest == null && targetFestName.isNotEmpty) {
      final lower = targetFestName.toLowerCase().trim();
      for (final f in allFestivals) {
        final fName = (f['name'] ?? '').toString().toLowerCase();
        if (fName == lower || fName.contains(lower) || lower.contains(fName)) {
          fest = f;
          break;
        }
      }
    }

    // Default to the first festival if not matched
    fest ??= allFestivals.isNotEmpty ? allFestivals.first : null;

    if (fest == null) {
      return {
        'isStarted': true,
        'festivalName': 'Festival',
        'status': 'Active',
        'startDate': '',
        'formattedDate': '',
      };
    }

    final status = (fest['status'] ?? 'Upcoming').toString();
    final isStarted = status.toLowerCase() == 'active';
    final fName = (fest['name'] ?? 'Festival').toString();
    final fStart = (fest['formattedDate'] ?? fest['startDate'] ?? '').toString();

    return {
      'isStarted': isStarted,
      'festivalName': fName,
      'status': status,
      'startDate': fest['startDate']?.toString() ?? '',
      'formattedDate': fStart,
      'timing': fest['timing']?.toString() ?? '',
    };
  }

  // ─── Leaderboard ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/utsav/leaderboard');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['IsSuccess'] == true && data['Data'] != null) {
          return Map<String, dynamic>.from(data['Data']);
        }
      }
    } catch (_) {}

    final activeFestivals = await getFestivals(status: 'Active');
    // If no festival is active right now, leaderboard is empty!
    if (activeFestivals.isEmpty) {
      return {
        'festival': null,
        'rankings': <Map<String, dynamic>>[],
        'topThree': <Map<String, dynamic>>[],
      };
    }

    final mandalsList = await getMandals();
    final sorted = [...mandalsList]..sort((a, b) => ((b['votes'] ?? 0) as num).compareTo((a['votes'] ?? 0) as num));
    final topThree = sorted.take(3).toList();

    return {
      'festival': activeFestivals.first,
      'rankings': sorted,
      'topThree': topThree,
    };
  }

  // ─── Mandal Live Streams (ONLY mandals that started live!) ─────────────────

  static Future<List<Map<String, dynamic>>> getLiveMandals() async {
    final activeFestivals = await getFestivals(status: 'Active');
    // If no active festival, no mandals can be live!
    if (activeFestivals.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/utsav/live-mandals');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['IsSuccess'] == true && data['Data'] is List) {
          final list = (data['Data'] as List).cast<Map<String, dynamic>>();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('utsav_live_mandals', jsonEncode(list));
          return list;
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('utsav_live_mandals');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List;
        final list = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final filtered = list.where((s) => !s['_id'].toString().contains('mock')).toList();
        return filtered;
      } catch (_) {}
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> goLiveMandal({
    required String mandalName,
    required String streamTitle,
    required String location,
    String? imageUrl,
  }) async {
    final newStream = {
      '_id': 'live_${DateTime.now().millisecondsSinceEpoch}',
      'name': streamTitle,
      'mandalName': mandalName,
      'location': location,
      'imageUrl': imageUrl ?? 'assets/images/devotional/navratri_garba_festival.jpg',
      'viewers': '1',
      'viewersCount': 1,
      'isLive': true,
      'startedAt': DateTime.now().toIso8601String(),
    };

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/utsav/mandal/go-live');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newStream),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final current = await getLiveMandals();
    final updated = [newStream, ...current.where((s) => s['mandalName'] != mandalName)];
    await prefs.setString('utsav_live_mandals', jsonEncode(updated));
  }

  static Future<void> joinLiveStream(String streamId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getLiveMandals();
    final updated = list.map((s) {
      if (s['_id'] == streamId || s['streamId'] == streamId) {
        final copy = Map<String, dynamic>.from(s);
        final count = (copy['viewersCount'] is num ? copy['viewersCount'] as int : int.tryParse(copy['viewers']?.toString() ?? '1')) ?? 1;
        copy['viewersCount'] = count + 1;
        copy['viewers'] = '${count + 1}';
        return copy;
      }
      return s;
    }).toList();
    await prefs.setString('utsav_live_mandals', jsonEncode(updated));
  }

  static Future<void> leaveLiveStream(String streamId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getLiveMandals();
    final updated = list.map((s) {
      if (s['_id'] == streamId || s['streamId'] == streamId) {
        final copy = Map<String, dynamic>.from(s);
        final count = (copy['viewersCount'] is num ? copy['viewersCount'] as int : int.tryParse(copy['viewers']?.toString() ?? '1')) ?? 1;
        final next = count > 1 ? count - 1 : 1;
        copy['viewersCount'] = next;
        copy['viewers'] = '$next';
        return copy;
      }
      return s;
    }).toList();
    await prefs.setString('utsav_live_mandals', jsonEncode(updated));
  }

  static Future<void> voteMandal(String mandalName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandals();
    final updated = list.map((m) {
      if ((m['name'] ?? '').toString().trim() == mandalName.trim()) {
        final copy = Map<String, dynamic>.from(m);
        final v = (copy['votes'] is num ? (copy['votes'] as num).toInt() : int.tryParse(copy['votes']?.toString() ?? '0') ?? 0);
        copy['votes'] = v + 1;
        return copy;
      }
      return m;
    }).toList();
    await prefs.setString('utsav_cached_mandals', jsonEncode(updated));
  }

  static Future<void> likeMandal(String mandalName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandals();
    final updated = list.map((m) {
      if ((m['name'] ?? '').toString().trim() == mandalName.trim()) {
        final copy = Map<String, dynamic>.from(m);
        final l = int.tryParse(copy['likes']?.toString() ?? '0') ?? 0;
        copy['likes'] = '${l + 1}';
        return copy;
      }
      return m;
    }).toList();
    await prefs.setString('utsav_cached_mandals', jsonEncode(updated));
  }

  static Future<void> shareMandal(String mandalName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandals();
    final updated = list.map((m) {
      if ((m['name'] ?? '').toString().trim() == mandalName.trim()) {
        final copy = Map<String, dynamic>.from(m);
        final s = int.tryParse(copy['shares']?.toString() ?? '0') ?? 0;
        copy['shares'] = '${s + 1}';
        return copy;
      }
      return m;
    }).toList();
    await prefs.setString('utsav_cached_mandals', jsonEncode(updated));
  }

  static Future<void> stopLiveMandal(String streamId) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/utsav/mandal/stop-live');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'streamId': streamId}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final current = await getLiveMandals();
    final updated = current.where((s) => s['_id'] != streamId).toList();
    await prefs.setString('utsav_live_mandals', jsonEncode(updated));
  }

  // ─── Backend Connectivity Helpers ─────────────────────────────────────────

  static final List<String> _backendHosts = [
    ApiService.baseUrl,
  ];

  static String resolveImageUrl(String? url, {String fallback = 'assets/images/devotional/navratri_garba_festival.jpg'}) {
    if (url == null || url.trim().isEmpty) return fallback;
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://') || clean.startsWith('assets/')) {
      return clean;
    }
    if (clean.startsWith('/uploads/') || clean.startsWith('uploads/')) {
      final host = ApiService.baseUrl;
      final cleanHost = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
      final pathPart = clean.startsWith('/') ? clean : '/$clean';
      return '$cleanHost$pathPart';
    }
    return clean;
  }

  static Future<void> _postToBackends(String endpoint, Map<String, dynamic> body) async {
    for (final host in _backendHosts) {
      try {
        final uri = Uri.parse('$host$endpoint');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          break;
        }
      } catch (_) {}
    }
  }

  static Future<void> _postRegistrationMultipart({
    required Map<String, dynamic> regData,
    String? logoPath,
    String? coverPath,
  }) async {
    String? logoBase64;
    String? coverBase64;

    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final f = File(logoPath);
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          final ext = logoPath.split('.').last.toLowerCase();
          final mime = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
          logoBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }

    if (coverPath != null && coverPath.isNotEmpty) {
      try {
        final f = File(coverPath);
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          final ext = coverPath.split('.').last.toLowerCase();
          final mime = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
          coverBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }

    final dataToSend = Map<String, dynamic>.from(regData);
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      dataToSend['logo'] = logoBase64;
    }
    if (coverBase64 != null && coverBase64.isNotEmpty) {
      dataToSend['cover'] = coverBase64;
    }

    bool success = false;
    for (final host in _backendHosts) {
      try {
        final uri = Uri.parse('$host/api/utsav/mandal/register');
        final request = http.MultipartRequest('POST', uri);

        dataToSend.forEach((key, value) {
          if (value != null) {
            if (value is String) {
              request.fields[key] = value;
            } else {
              request.fields[key] = jsonEncode(value);
            }
          }
        });

        if (logoPath != null && logoPath.isNotEmpty) {
          final file = File(logoPath);
          if (file.existsSync()) {
            final stream = http.ByteStream(file.openRead());
            final length = await file.length();
            final multipartFile = http.MultipartFile(
              'logo',
              stream,
              length,
              filename: file.uri.pathSegments.last,
            );
            request.files.add(multipartFile);
          }
        }

        if (coverPath != null && coverPath.isNotEmpty) {
          final file = File(coverPath);
          if (file.existsSync()) {
            final stream = http.ByteStream(file.openRead());
            final length = await file.length();
            final multipartFile = http.MultipartFile(
              'cover',
              stream,
              length,
              filename: file.uri.pathSegments.last,
            );
            request.files.add(multipartFile);
          }
        }

        final streamed = await request.send().timeout(const Duration(seconds: 8));
        final resp = await http.Response.fromStream(streamed);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          try {
            final resJson = jsonDecode(resp.body);
            if (resJson['IsSuccess'] == true && resJson['Data'] != null) {
              final remote = Map<String, dynamic>.from(resJson['Data'] as Map);
              final prefs = await SharedPreferences.getInstance();
              final currentStr = prefs.getString('my_mandal_registration');
              if (currentStr != null && currentStr.isNotEmpty) {
                final current = Map<String, dynamic>.from(jsonDecode(currentStr) as Map);
                if (remote['logo'] != null && remote['logo'].toString().isNotEmpty) {
                  current['logoUrl'] = remote['logo'];
                }
                if (remote['cover'] != null && remote['cover'].toString().isNotEmpty) {
                  current['coverUrl'] = remote['cover'];
                }
                current['status'] = 'Pending';
                current['rejectionReason'] = '';
                await prefs.setString('my_mandal_registration', jsonEncode(current));
              }

              // Explicitly ensure status is Pending on backend (overcomes stale in-memory backend logic)
              final regId = remote['registrationId'] ?? remote['_id'];
              if (regId != null && remote['status']?.toString().toLowerCase() != 'pending') {
                for (final host in _backendHosts) {
                  try {
                    final statusUri = Uri.parse('$host/api/utsav/mandal/registration-status/$regId');
                    await http.put(
                      statusUri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'status': 'Pending', 'rejectionReason': ''}),
                    ).timeout(const Duration(seconds: 4));
                  } catch (_) {}
                }
              }
            }
          } catch (_) {}
          success = true;
          break;
        }
      } catch (_) {}
    }

    if (!success) {
      // Fallback to JSON post with base64 embedded
      await _postToBackends('/api/utsav/mandal/register', dataToSend);
    }
  }

  static Future<Map<String, dynamic>?> _getFromBackends(String endpoint) async {
    for (final host in _backendHosts) {
      try {
        final uri = Uri.parse('$host$endpoint');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['IsSuccess'] == true && data['Data'] != null) {
            return Map<String, dynamic>.from(data['Data'] as Map);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _fetchMyRegistrationRemote(String endpoint) async {
    for (final host in _backendHosts) {
      try {
        final uri = Uri.parse('$host$endpoint');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['IsSuccess'] == true) {
            if (data['Data'] != null) {
              return Map<String, dynamic>.from(data['Data'] as Map);
            } else {
              // Server explicitly returned Data: null -> Registration was deleted from MongoDB!
              return {'_isDeletedOrNotFoundOnServer': true};
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // ─── User Mandal Registration Status ───────────────────────────────────────

  static Future<Map<String, dynamic>?> getMyMandalRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('my_mandal_registration');
    String? phone;
    Map<String, dynamic>? localData;

    if (saved != null && saved.isNotEmpty) {
      try {
        localData = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        phone = localData['mobile']?.toString();
        final mName = (localData['mandalName'] ?? '').toString();

        // Purge old dummy Ganesh registrations
        if (mName.contains('Lalbaug') || mName.contains('Ganesh') || localData['registrationId'] == 'REG-2026-DUMMY') {
          await prefs.remove('my_mandal_registration');
          await prefs.remove('is_mandal_registered');
          await prefs.remove('is_mandal_leader');
          return null;
        }
      } catch (_) {}
    }
    phone ??= prefs.getString('user_phone') ?? prefs.getString('auth_mobile');

    if (phone != null && phone.isNotEmpty) {
      try {
        final remoteData = await _fetchMyRegistrationRemote('/api/utsav/mandal/my-registration?mobile=$phone');
        if (remoteData != null) {
          if (remoteData['_isDeletedOrNotFoundOnServer'] == true) {
            if (localData != null) {
              localData['status'] = 'deleted';
              localData['deletionReason'] = 'Your Mandal account was deleted by Bharat Pray Admin.';
              await prefs.setString('my_mandal_registration', jsonEncode(localData));
              await prefs.setBool('is_mandal_registered', false);
              await prefs.setBool('is_mandal_leader', false);
              return localData;
            } else {
              await prefs.remove('my_mandal_registration');
              await prefs.setBool('is_mandal_registered', false);
              await prefs.setBool('is_mandal_leader', false);
              return null;
            }
          }
          // Merge local data to preserve local picked image file paths
          if (localData != null) {
            if ((remoteData['logo'] == null || remoteData['logo'].toString().isEmpty) && localData['logo'] != null) {
              remoteData['logo'] = localData['logo'];
            } else if (localData['logo'] != null && localData['logo'].toString().isNotEmpty) {
              // Store remote as logoUrl and keep local if file exists
              remoteData['logoUrl'] = remoteData['logo'];
              final localFile = File(localData['logo'].toString());
              if (localFile.existsSync()) {
                remoteData['logo'] = localData['logo'];
              }
            }

            if ((remoteData['cover'] == null || remoteData['cover'].toString().isEmpty) && localData['cover'] != null) {
              remoteData['cover'] = localData['cover'];
            } else if (localData['cover'] != null && localData['cover'].toString().isNotEmpty) {
              remoteData['coverUrl'] = remoteData['cover'];
              final localFile = File(localData['cover'].toString());
              if (localFile.existsSync()) {
                remoteData['cover'] = localData['cover'];
              }
            }
            if (localData['status'] == 'Pending' && remoteData['status'] == 'Rejected') {
              final localDate = DateTime.tryParse(localData['createdAt']?.toString() ?? '');
              final remoteUpdated = DateTime.tryParse(remoteData['updatedAt']?.toString() ?? remoteData['createdAt']?.toString() ?? '');
              if (localDate != null && remoteUpdated != null && localDate.isAfter(remoteUpdated)) {
                remoteData['status'] = 'Pending';
                remoteData['rejectionReason'] = '';
              } else if (localData['mandalName'] != null && localData['mandalName'] != remoteData['mandalName']) {
                remoteData['status'] = 'Pending';
                remoteData['rejectionReason'] = '';
              }
            }
          }

          final rStatus = remoteData['status']?.toString().toLowerCase();
          if (rStatus == 'deleted') {
            await prefs.setString('my_mandal_registration', jsonEncode(remoteData));
            await prefs.setBool('is_mandal_registered', false);
            await prefs.setBool('is_mandal_leader', false);
            return remoteData;
          }

          await prefs.setString('my_mandal_registration', jsonEncode(remoteData));
          await prefs.setBool('is_mandal_registered', true);
          if (remoteData['status']?.toString().toLowerCase() == 'approved') {
            await prefs.setBool('is_mandal_leader', true);
          } else {
            await prefs.setBool('is_mandal_leader', false);
          }
          return remoteData;
        }
      } catch (_) {}
    }

    if (saved == null || saved.isEmpty) {
      return null;
    }
    return localData;
  }

  static Future<void> clearMyMandalRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('my_mandal_registration');
    await prefs.remove('is_mandal_registered');
    await prefs.remove('is_mandal_leader');
  }

  static Future<void> saveMandalRegistration({
    required String mandalName,
    required String leaderName,
    required String mobile,
    required String address,
    required String category,
    required String festival,
    String? bio,
    List<Map<String, String>>? members,
    String? logoPath,
    String? coverPath,
    String status = 'Pending',
    String? rejectionReason,
  }) async {
    final regId = 'REG-2026-${(mandalName.hashCode.abs() % 9000 + 1000)}';
    final regData = {
      'registrationId': regId,
      'mandalName': mandalName,
      'leaderName': leaderName,
      'mobile': mobile,
      'address': address,
      'category': category,
      'festival': festival,
      'bio': bio ?? '',
      'description': bio ?? '',
      'members': members ?? [],
      'logo': logoPath ?? '',
      'cover': coverPath ?? '',
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
      'rejectionReason': rejectionReason ?? '',
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_mandal_registration', jsonEncode(regData));
    await prefs.setBool('is_mandal_registered', true);
    if (status.toLowerCase() == 'approved') {
      await prefs.setBool('is_mandal_leader', true);

      // Register into mandals list with 100% original counts starting at 0
      final newMandal = {
        '_id': 'mandal_${DateTime.now().millisecondsSinceEpoch}',
        'registrationId': regId,
        'festivalId': 'fest-002',
        'name': mandalName,
        'city': address,
        'regNo': regId,
        'rank': 1,
        'votes': 0,
        'likes': '0',
        'shares': '0',
        'views': 0,
        'postsCount': 0,
        'status': 'Approved',
        'imageUrl': coverPath != null && coverPath.isNotEmpty ? coverPath : 'assets/images/devotional/navratri_garba_festival.jpg',
        'logo': logoPath != null && logoPath.isNotEmpty ? logoPath : 'assets/images/devotional/navratri_garba_festival.jpg',
        'bio': bio ?? '',
        'description': (bio != null && bio.isNotEmpty) ? bio : '',
      };

      final currentMandals = await getMandals();
      final updatedMandals = [...currentMandals.where((m) => (m['name'] ?? '').toString().trim() != mandalName.trim()), newMandal];
      await prefs.setString('utsav_cached_mandals', jsonEncode(updatedMandals));
    } else {
      await prefs.setBool('is_mandal_leader', false);
    }

    // Send to backend via multipart if images exist
    await _postRegistrationMultipart(
      regData: regData,
      logoPath: logoPath,
      coverPath: coverPath,
    );
  }

  static Future<void> updateRegistrationStatus(String status, {String? reason}) async {
    final current = await getMyMandalRegistration();
    if (current == null) return;
    current['status'] = status;
    if (reason != null) current['rejectionReason'] = reason;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_mandal_registration', jsonEncode(current));

    final mandalName = (current['mandalName'] ?? 'Mandal').toString();
    final address = (current['address'] ?? 'Gujarat').toString();
    final regId = (current['registrationId'] ?? 'REG-2026').toString();
    final festival = (current['festival'] ?? 'Utsav').toString();
    final logo = (current['logo'] ?? '').toString();
    final cover = (current['cover'] ?? '').toString();
    final bio = (current['bio'] ?? current['description'] ?? '').toString();
    final currentMandals = await getMandals();

    if (status == 'Approved') {
      await prefs.setBool('is_mandal_leader', true);
      final newMandal = {
        '_id': 'mandal_${DateTime.now().millisecondsSinceEpoch}',
        'registrationId': regId,
        'festivalId': 'fest-002',
        'name': mandalName,
        'city': address,
        'regNo': regId,
        'rank': 1,
        'votes': 0,
        'likes': '0',
        'shares': '0',
        'views': 0,
        'postsCount': 0,
        'status': 'Approved',
        'imageUrl': cover.isNotEmpty ? cover : 'assets/images/devotional/navratri_garba_festival.jpg',
        'logo': logo.isNotEmpty ? logo : 'assets/images/devotional/navratri_garba_festival.jpg',
        'bio': bio,
        'description': bio,
      };
      final updatedMandals = [...currentMandals.where((m) => (m['name'] ?? '').toString().trim() != mandalName.trim()), newMandal];
      await prefs.setString('utsav_cached_mandals', jsonEncode(updatedMandals));
    } else {
      await prefs.setBool('is_mandal_leader', false);
      final updatedMandals = currentMandals.where((m) => (m['name'] ?? '').toString().trim() != mandalName.trim()).toList();
      await prefs.setString('utsav_cached_mandals', jsonEncode(updatedMandals));
    }
  }

  // ─── Mandal Posts Persistence ───────────────────────────────────────────────

  static String _mandalPostsKey(String mandalName) {
    final clean = mandalName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return 'mandal_posts_$clean';
  }

  static Future<List<Map<String, dynamic>>> getMandalPosts(String mandalName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _mandalPostsKey(mandalName);
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    final myReg = await getMyMandalRegistration();
    if (myReg != null && (myReg['mandalName']?.toString().toLowerCase().trim() == mandalName.toLowerCase().trim())) {
      final genRaw = prefs.getString('my_mandal_posts');
      if (genRaw != null && genRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(genRaw) as List;
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {}
      }
    }
    return [];
  }

  static Future<void> saveMandalPost(String mandalName, Map<String, dynamic> post) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandalPosts(mandalName);
    list.removeWhere((p) => p['id']?.toString() == post['id']?.toString());
    list.insert(0, post);

    final key = _mandalPostsKey(mandalName);
    final jsonStr = jsonEncode(list);
    await prefs.setString(key, jsonStr);

    final myReg = await getMyMandalRegistration();
    if (myReg != null && (myReg['mandalName']?.toString().toLowerCase().trim() == mandalName.toLowerCase().trim())) {
      await prefs.setString('my_mandal_posts', jsonStr);
    }
  }

  static Future<void> deleteMandalPost(String mandalName, String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandalPosts(mandalName);
    list.removeWhere((p) => p['id']?.toString() == postId);

    final key = _mandalPostsKey(mandalName);
    final jsonStr = jsonEncode(list);
    await prefs.setString(key, jsonStr);

    final myReg = await getMyMandalRegistration();
    if (myReg != null && (myReg['mandalName']?.toString().toLowerCase().trim() == mandalName.toLowerCase().trim())) {
      await prefs.setString('my_mandal_posts', jsonStr);
    }
  }

  // ─── Mandal Reels Persistence ───────────────────────────────────────────────

  static String _mandalReelsKey(String mandalName) {
    final clean = mandalName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return 'mandal_reels_$clean';
  }

  static Future<List<Map<String, dynamic>>> getMandalReels(String mandalName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _mandalReelsKey(mandalName);
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    final myReg = await getMyMandalRegistration();
    if (myReg != null && (myReg['mandalName']?.toString().toLowerCase().trim() == mandalName.toLowerCase().trim())) {
      final genRaw = prefs.getString('my_mandal_reels');
      if (genRaw != null && genRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(genRaw) as List;
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {}
      }
    }
    return [];
  }

  static Future<void> saveMandalReel(String mandalName, Map<String, dynamic> reel) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandalReels(mandalName);
    list.removeWhere((r) => r['id']?.toString() == reel['id']?.toString());
    list.insert(0, reel);

    final key = _mandalReelsKey(mandalName);
    final jsonStr = jsonEncode(list);
    await prefs.setString(key, jsonStr);

    final myReg = await getMyMandalRegistration();
    if (myReg != null && (myReg['mandalName']?.toString().toLowerCase().trim() == mandalName.toLowerCase().trim())) {
      await prefs.setString('my_mandal_reels', jsonStr);
    }
  }

  // ─── Mandal Live Events Persistence ─────────────────────────────────────────

  static String _mandalLiveKey(String mandalName) {
    final clean = mandalName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return 'mandal_live_$clean';
  }

  static Future<List<Map<String, dynamic>>> getMandalLiveEvents(String mandalName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _mandalLiveKey(mandalName);
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveMandalLiveEvent(String mandalName, Map<String, dynamic> live) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMandalLiveEvents(mandalName);
    list.removeWhere((l) => l['id']?.toString() == live['id']?.toString());
    list.insert(0, live);

    final key = _mandalLiveKey(mandalName);
    await prefs.setString(key, jsonEncode(list));
  }
}
