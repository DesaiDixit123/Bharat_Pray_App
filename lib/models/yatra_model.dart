import '../services/api_service.dart';

class YatraModel {
  final String id;
  final String? journeyId;
  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String groupSize;
  final String image;
  final String tag;
  final double progress;
  final List<dynamic>? routeTemples;

  YatraModel({
    required this.id,
    this.journeyId,
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.groupSize,
    required this.image,
    required this.tag,
    required this.progress,
    this.routeTemples,
  });

  factory YatraModel.fromJson(Map<String, dynamic> json) {
    // Map real MongoDB field names to display strings
    // DB stores: distance (number km), walkingSteps (number), duration (number days), totalUsers (number)
    final rawDistance = json['distance'];
    final rawSteps    = json['walkingSteps'] ?? json['steps'];
    final rawDuration = json['duration'];
    final rawGroup    = json['totalUsers'] ?? json['groupSize'];

    final distanceStr = rawDistance != null
        ? '${_formatNum(rawDistance)} KM'
        : (json['distanceStr'] ?? '0 KM');

    final stepsStr = rawSteps != null
        ? '${_formatNum(rawSteps)} Steps'
        : (json['stepsStr'] ?? '0 Steps');

    final durationStr = rawDuration != null
        ? '$rawDuration ${rawDuration == 1 ? "Day" : "Days"}'
        : (json['durationStr'] ?? '0 Days');

    final groupStr = rawGroup != null
        ? _formatNum(rawGroup)
        : (json['groupSizeStr'] ?? '0');

    // Image: prefer DB image, fall back to local asset
    return YatraModel(
      id: json['_id'] ?? '1',
      journeyId: json['journeyId'],
      title: json['title'] ?? json['name'] ?? 'Yatra',
      distance: distanceStr,
      steps: stepsStr,
      duration: durationStr,
      groupSize: groupStr,
      image: ApiService.resolveImageUrl(json['image'] ?? 'assets/images/somnath_temple_new.png'),
      tag: json['category'] ?? "Popular Yatra",
      progress: (json['progress'] ?? 0.0).toDouble(),
      routeTemples: json['routeTemples'] as List<dynamic>?,
    );
  }

  /// Format a number: 12500 → "12.5 k", 450 → "450"
  static String _formatNum(dynamic val) {
    final n = (val is int) ? val.toDouble() : (val as num).toDouble();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} k';
    return n.toInt().toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journeyId': journeyId,
      'title': title,
      'distance': distance,
      'steps': steps,
      'duration': duration,
      'groupSize': groupSize,
      'image': image,
      'tag': tag,
      'progress': progress,
    };
  }
}
