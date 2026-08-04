import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Model representing a User's Active Running Pilgrimage Journey (Continue Yatra)
@immutable
class ContinueYatraModel {
  final String journeyId;
  final String routeId;
  final String title;
  final String coverImage;
  final double totalDistanceMeters;
  final double accumulatedDistanceMeters;
  final double remainingDistanceMeters;
  final int accumulatedSteps;
  final double progressPercent;
  final int currentDay;
  final int estimatedDays;
  final String status;
  final DateTime? startedAt;
  final DateTime? lastUpdated;

  const ContinueYatraModel({
    required this.journeyId,
    required this.routeId,
    required this.title,
    required this.coverImage,
    this.totalDistanceMeters = 0.0,
    this.accumulatedDistanceMeters = 0.0,
    this.remainingDistanceMeters = 0.0,
    this.accumulatedSteps = 0,
    this.progressPercent = 0.0,
    this.currentDay = 1,
    this.estimatedDays = 1,
    this.status = 'STARTED',
    this.startedAt,
    this.lastUpdated,
  });

  factory ContinueYatraModel.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return ContinueYatraModel._fallback();
    }
    final json = Map<String, dynamic>.from(rawJson);

    final totalDist = _parseDouble(json['totalDistanceMeters'] ?? json['totalDistance']);
    final accumDist = _parseDouble(json['accumulatedDistanceMeters'] ?? json['distanceCovered']);
    final remainDist = json['remainingDistanceMeters'] != null
        ? _parseDouble(json['remainingDistanceMeters'])
        : _mathMax(0.0, totalDist - accumDist);

    final rawImg = json['coverImage'] ?? json['image'] ?? json['banner'] ?? 'assets/images/somnath_temple_new.png';

    return ContinueYatraModel(
      journeyId: json['journeyId']?.toString() ?? json['_id']?.toString() ?? '',
      routeId: json['routeId']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Active Yatra',
      coverImage: ApiService.resolveImageUrl(rawImg.toString()),
      totalDistanceMeters: totalDist,
      accumulatedDistanceMeters: accumDist,
      remainingDistanceMeters: remainDist,
      accumulatedSteps: _parseInt(json['accumulatedSteps'] ?? json['steps']),
      progressPercent: _parseDouble(json['progressPercent'] ?? json['progress']),
      currentDay: _parseInt(json['currentDay'], defaultVal: 1),
      estimatedDays: _parseInt(json['estimatedDays'] ?? json['totalDays'], defaultVal: 1),
      status: json['status']?.toString() ?? 'STARTED',
      startedAt: _parseDate(json['createdAt'] ?? json['startedAt']),
      lastUpdated: _parseDate(json['updatedAt'] ?? json['lastUpdated']),
    );
  }

  factory ContinueYatraModel._fallback() {
    return ContinueYatraModel(
      journeyId: '',
      routeId: '',
      title: 'Active Yatra',
      coverImage: ApiService.resolveImageUrl('assets/images/somnath_temple_new.png'),
    );
  }

  String get distanceCoveredKm => '${(accumulatedDistanceMeters / 1000).toStringAsFixed(1)} KM';
  String get remainingDistanceKm => '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} KM';
  String get totalDistanceKm => '${(totalDistanceMeters / 1000).toStringAsFixed(1)} KM';

  ContinueYatraModel copyWith({
    String? journeyId,
    String? routeId,
    String? title,
    String? coverImage,
    double? totalDistanceMeters,
    double? accumulatedDistanceMeters,
    double? remainingDistanceMeters,
    int? accumulatedSteps,
    double? progressPercent,
    int? currentDay,
    int? estimatedDays,
    String? status,
    DateTime? startedAt,
    DateTime? lastUpdated,
  }) {
    return ContinueYatraModel(
      journeyId: journeyId ?? this.journeyId,
      routeId: routeId ?? this.routeId,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      accumulatedDistanceMeters: accumulatedDistanceMeters ?? this.accumulatedDistanceMeters,
      remainingDistanceMeters: remainingDistanceMeters ?? this.remainingDistanceMeters,
      accumulatedSteps: accumulatedSteps ?? this.accumulatedSteps,
      progressPercent: progressPercent ?? this.progressPercent,
      currentDay: currentDay ?? this.currentDay,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'journeyId': journeyId,
        '_id': journeyId,
        'routeId': routeId,
        'title': title,
        'coverImage': coverImage,
        'totalDistanceMeters': totalDistanceMeters,
        'accumulatedDistanceMeters': accumulatedDistanceMeters,
        'remainingDistanceMeters': remainingDistanceMeters,
        'accumulatedSteps': accumulatedSteps,
        'progressPercent': progressPercent,
        'currentDay': currentDay,
        'estimatedDays': estimatedDays,
        'status': status,
        'startedAt': startedAt?.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  static double _mathMax(double a, double b) => a > b ? a : b;

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
