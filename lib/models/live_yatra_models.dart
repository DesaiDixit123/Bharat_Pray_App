import 'dart:math' show sin, cos, sqrt, atan2, pi;

class LiveYatraState {
  final bool isTracking;
  final bool isLoading;
  final String? error;
  final String journeyId;
  final String title;
  final double totalDistanceKm;
  final double kmCompleted;
  final double kmRemaining;
  final double progressPercent;
  final int activeDevoteesCount;
  final List<LiveDevoteeModel> nearbyDevotees;
  final double? currentLatitude;
  final double? currentLongitude;
  final double speed;
  final double bearing;
  final double accuracy;
  final DateTime? lastUpdated;

  const LiveYatraState({
    this.isTracking = false,
    this.isLoading = false,
    this.error,
    this.journeyId = '',
    this.title = '',
    this.totalDistanceKm = 0.0,
    this.kmCompleted = 0.0,
    this.kmRemaining = 0.0,
    this.progressPercent = 0.0,
    this.activeDevoteesCount = 0,
    this.nearbyDevotees = const [],
    this.currentLatitude,
    this.currentLongitude,
    this.speed = 0.0,
    this.bearing = 0.0,
    this.accuracy = 0.0,
    this.lastUpdated,
  });

  LiveYatraState copyWith({
    bool? isTracking,
    bool? isLoading,
    String? error,
    String? journeyId,
    String? title,
    double? totalDistanceKm,
    double? kmCompleted,
    double? kmRemaining,
    double? progressPercent,
    int? activeDevoteesCount,
    List<LiveDevoteeModel>? nearbyDevotees,
    double? currentLatitude,
    double? currentLongitude,
    double? speed,
    double? bearing,
    double? accuracy,
    DateTime? lastUpdated,
  }) {
    return LiveYatraState(
      isTracking: isTracking ?? this.isTracking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      journeyId: journeyId ?? this.journeyId,
      title: title ?? this.title,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      kmCompleted: kmCompleted ?? this.kmCompleted,
      kmRemaining: kmRemaining ?? this.kmRemaining,
      progressPercent: progressPercent ?? this.progressPercent,
      activeDevoteesCount: activeDevoteesCount ?? this.activeDevoteesCount,
      nearbyDevotees: nearbyDevotees ?? this.nearbyDevotees,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LiveDevoteeModel {
  final String userId;
  final String name;
  final String profilePic;
  final double distanceKm;
  final String distanceText;
  final double kmCompleted;
  final double kmRemaining;
  final int steps;
  final String days;
  final bool isOnline;
  final double latitude;
  final double longitude;

  const LiveDevoteeModel({
    required this.userId,
    required this.name,
    required this.profilePic,
    required this.distanceKm,
    required this.distanceText,
    this.kmCompleted = 0.0,
    this.kmRemaining = 0.0,
    this.steps = 0,
    this.days = '1 Day',
    this.isOnline = true,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory LiveDevoteeModel.fromJson(Map<String, dynamic> json) {
    final dist = (json['distanceKm'] as num?)?.toDouble() ?? 0.0;
    return LiveDevoteeModel(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Devotee',
      profilePic: json['profilePic']?.toString() ?? '',
      distanceKm: dist,
      distanceText: json['distanceText']?.toString() ?? '${dist.toStringAsFixed(1)} km away',
      kmCompleted: (json['kmCompleted'] as num?)?.toDouble() ?? 0.0,
      kmRemaining: (json['kmRemaining'] as num?)?.toDouble() ?? 0.0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      days: json['days']?.toString() ?? '1 Day',
      isOnline: json['isOnline'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profilePic': profilePic,
      'distanceKm': distanceKm,
      'distanceText': distanceText,
      'kmCompleted': kmCompleted,
      'kmRemaining': kmRemaining,
      'steps': steps,
      'days': days,
      'isOnline': isOnline,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class RoutePolylinePoint {
  final double latitude;
  final double longitude;

  const RoutePolylinePoint(this.latitude, this.longitude);

  double distanceTo(RoutePolylinePoint other) {
    const double r = 6371000.0; // Earth radius in meters
    final dLat = (other.latitude - latitude) * pi / 180.0;
    final dLon = (other.longitude - longitude) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latitude * pi / 180.0) * cos(other.latitude * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
