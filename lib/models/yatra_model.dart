import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Null-safe Temple Location Model
@immutable
class TempleLocationModel {
  final double latitude;
  final double longitude;
  final String address;

  const TempleLocationModel({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
  });

  factory TempleLocationModel.fromJson(dynamic json) {
    if (json is! Map) {
      return const TempleLocationModel();
    }
    return TempleLocationModel(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  TempleLocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return TempleLocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

/// Enhanced YatraModel for Popular Yatras & Route Feed
@immutable
class YatraModel {
  final String id;
  final String? journeyId;
  final String title;
  final String slug;
  final String description;
  final String distance;
  final String steps;
  final String duration;
  final String groupSize;
  final String image;
  final String bannerImage;
  final String coverImage;
  final String tag;
  final double progress;
  final String? templeId;
  final String? templeName;
  final int estimatedStepsNum;
  final int estimatedDaysNum;
  final int followersCountNum;
  final int priority;
  final int displayOrder;
  final bool status;
  final bool isPopular;
  final TempleLocationModel? templeLocation;
  final List<dynamic>? routeTemples;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const YatraModel({
    required this.id,
    this.journeyId,
    required this.title,
    this.slug = '',
    this.description = '',
    required this.distance,
    required this.steps,
    required this.duration,
    required this.groupSize,
    required this.image,
    this.bannerImage = '',
    this.coverImage = '',
    required this.tag,
    required this.progress,
    this.templeId,
    this.templeName,
    this.estimatedStepsNum = 0,
    this.estimatedDaysNum = 1,
    this.followersCountNum = 0,
    this.priority = 0,
    this.displayOrder = 0,
    this.status = true,
    this.isPopular = false,
    this.templeLocation,
    this.routeTemples,
    this.createdAt,
    this.updatedAt,
  });

  factory YatraModel.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return YatraModel._fallback();
    }
    final json = Map<String, dynamic>.from(rawJson);

    final rawDistance = json['distance'];
    final rawSteps = json['estimatedSteps'] ?? json['walkingSteps'] ?? json['steps'];
    final rawDuration = json['estimatedDays'] ?? json['duration'];
    final rawGroup = json['followersCount'] ?? json['totalUsers'] ?? json['groupSize'];

    final distanceStr = rawDistance != null
        ? '${_formatNum(rawDistance)} KM'
        : (json['distanceStr']?.toString() ?? '0 KM');

    final stepsStr = rawSteps != null
        ? '${_formatNum(rawSteps)} Steps'
        : (json['stepsStr']?.toString() ?? '0 Steps');

    final durationStr = rawDuration != null
        ? '$rawDuration ${rawDuration == 1 ? "Day" : "Days"}'
        : (json['durationStr']?.toString() ?? '1 Day');

    final groupStr = rawGroup != null
        ? _formatNum(rawGroup)
        : (json['groupSizeStr']?.toString() ?? '0');

    final rawImg = json['image'] ?? json['thumbnail'] ?? json['coverImage'] ?? 'assets/images/somnath_temple_new.png';
    final resolvedImg = ApiService.resolveImageUrl(rawImg.toString());
    final rawBanner = json['banner'] ?? json['bannerImage'] ?? rawImg;
    final resolvedBanner = ApiService.resolveImageUrl(rawBanner.toString());

    return YatraModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? 'yatra_${DateTime.now().millisecondsSinceEpoch}',
      journeyId: json['journeyId']?.toString(),
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Devotional Yatra',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      distance: distanceStr,
      steps: stepsStr,
      duration: durationStr,
      groupSize: groupStr,
      image: resolvedImg,
      bannerImage: resolvedBanner,
      coverImage: resolvedImg,
      tag: json['category']?.toString() ?? "Popular Yatra",
      progress: _parseDouble(json['progress']),
      templeId: (json['startTemple'] is Map) ? json['startTemple']['_id']?.toString() : json['startTemple']?.toString(),
      templeName: (json['startTemple'] is Map) ? json['startTemple']['name']?.toString() : json['templeName']?.toString(),
      estimatedStepsNum: _parseInt(rawSteps),
      estimatedDaysNum: _parseInt(rawDuration, defaultVal: 1),
      followersCountNum: _parseInt(rawGroup),
      priority: _parseInt(json['priority']),
      displayOrder: _parseInt(json['displayOrder']),
      status: json['status'] == null ? true : (json['status'] == true || json['status'] == 'true'),
      isPopular: json['isPopular'] == true || json['isPopular'] == 'true',
      templeLocation: json['templeLocation'] != null ? TempleLocationModel.fromJson(json['templeLocation']) : null,
      routeTemples: json['routeTemples'] is List ? (json['routeTemples'] as List) : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  factory YatraModel._fallback() {
    return YatraModel(
      id: 'yatra_fallback',
      title: 'Devotional Yatra',
      distance: '0 KM',
      steps: '0 Steps',
      duration: '1 Day',
      groupSize: '0',
      image: ApiService.resolveImageUrl('assets/images/somnath_temple_new.png'),
      tag: 'Popular Yatra',
      progress: 0.0,
    );
  }

  YatraModel copyWith({
    String? id,
    String? journeyId,
    String? title,
    String? slug,
    String? description,
    String? distance,
    String? steps,
    String? duration,
    String? groupSize,
    String? image,
    String? bannerImage,
    String? coverImage,
    String? tag,
    double? progress,
    String? templeId,
    String? templeName,
    int? estimatedStepsNum,
    int? estimatedDaysNum,
    int? followersCountNum,
    int? priority,
    int? displayOrder,
    bool? status,
    bool? isPopular,
    TempleLocationModel? templeLocation,
    List<dynamic>? routeTemples,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return YatraModel(
      id: id ?? this.id,
      journeyId: journeyId ?? this.journeyId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      distance: distance ?? this.distance,
      steps: steps ?? this.steps,
      duration: duration ?? this.duration,
      groupSize: groupSize ?? this.groupSize,
      image: image ?? this.image,
      bannerImage: bannerImage ?? this.bannerImage,
      coverImage: coverImage ?? this.coverImage,
      tag: tag ?? this.tag,
      progress: progress ?? this.progress,
      templeId: templeId ?? this.templeId,
      templeName: templeName ?? this.templeName,
      estimatedStepsNum: estimatedStepsNum ?? this.estimatedStepsNum,
      estimatedDaysNum: estimatedDaysNum ?? this.estimatedDaysNum,
      followersCountNum: followersCountNum ?? this.followersCountNum,
      priority: priority ?? this.priority,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
      isPopular: isPopular ?? this.isPopular,
      templeLocation: templeLocation ?? this.templeLocation,
      routeTemples: routeTemples ?? this.routeTemples,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'journeyId': journeyId,
      'title': title,
      'slug': slug,
      'description': description,
      'distance': distance,
      'steps': steps,
      'duration': duration,
      'groupSize': groupSize,
      'image': image,
      'bannerImage': bannerImage,
      'coverImage': coverImage,
      'tag': tag,
      'progress': progress,
      'templeId': templeId,
      'templeName': templeName,
      'estimatedSteps': estimatedStepsNum,
      'estimatedDays': estimatedDaysNum,
      'followersCount': followersCountNum,
      'priority': priority,
      'displayOrder': displayOrder,
      'status': status,
      'isPopular': isPopular,
      'templeLocation': templeLocation?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _formatNum(dynamic val) {
    if (val == null) return '0';
    final n = (val is int) ? val.toDouble() : (double.tryParse(val.toString()) ?? 0.0);
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} k';
    return n.toInt().toString();
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val, {int defaultVal = 0}) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultVal;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }
}

/// Null-safe Pagination Model
@immutable
class PaginationModel {
  final int page;
  final int limit;
  final int totalDocs;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const PaginationModel({
    this.page = 1,
    this.limit = 10,
    this.totalDocs = 0,
    this.totalPages = 1,
    this.hasNextPage = false,
    this.hasPrevPage = false,
  });

  factory PaginationModel.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return const PaginationModel();
    }
    final json = Map<String, dynamic>.from(rawJson);
    final currentPage = _parseInt(json['page'], defaultVal: 1);
    final maxPages = _parseInt(json['totalPages'], defaultVal: 1);

    return PaginationModel(
      page: currentPage,
      limit: _parseInt(json['limit'], defaultVal: 10),
      totalDocs: _parseInt(json['totalDocs'] ?? json['total']),
      totalPages: maxPages,
      hasNextPage: json['hasNextPage'] ?? (currentPage < maxPages),
      hasPrevPage: json['hasPrevPage'] ?? (currentPage > 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'totalDocs': totalDocs,
        'totalPages': totalPages,
        'hasNextPage': hasNextPage,
        'hasPrevPage': hasPrevPage,
      };

  static int _parseInt(dynamic val, {int defaultVal = 0}) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultVal;
  }
}

/// Universal Null-safe API Response Wrapper
@immutable
class ApiResponseModel<T> {
  final bool isSuccess;
  final int statusCode;
  final String message;
  final T? data;
  final PaginationModel? pagination;
  final String? error;

  const ApiResponseModel({
    required this.isSuccess,
    required this.statusCode,
    required this.message,
    this.data,
    this.pagination,
    this.error,
  });

  factory ApiResponseModel.fromJson(
    dynamic rawJson,
    T Function(dynamic dataJson) parser,
  ) {
    if (rawJson is! Map) {
      return ApiResponseModel<T>(
        isSuccess: false,
        statusCode: 500,
        message: 'Invalid server response',
        error: 'Response body is not a JSON object',
      );
    }
    final json = Map<String, dynamic>.from(rawJson);
    final isSuccess = json['IsSuccess'] == true || json['success'] == true;
    final status = json['Status'] is int ? json['Status'] : (isSuccess ? 200 : 400);
    final msg = json['Message']?.toString() ?? json['message']?.toString() ?? '';

    dynamic rawData = json['Data'] ?? json['data'];
    PaginationModel? pageModel;

    if (rawData is Map && (rawData.containsKey('docs') || rawData.containsKey('items'))) {
      pageModel = PaginationModel.fromJson(rawData);
    }

    T? parsedData;
    if (rawData != null) {
      try {
        parsedData = parser(rawData);
      } catch (e, stackTrace) {
        print('[ApiResponseModel PARSER ERROR] $e\n$stackTrace');
        parsedData = null;
      }
    }

    return ApiResponseModel<T>(
      isSuccess: isSuccess,
      statusCode: status,
      message: msg,
      data: parsedData,
      pagination: pageModel,
      error: json['Error']?.toString() ?? json['error']?.toString(),
    );
  }
}
