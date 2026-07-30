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
  });

  factory YatraModel.fromJson(Map<String, dynamic> json) {
    return YatraModel(
      id: json['_id'] ?? json['id'] ?? '',
      journeyId: json['journeyId'],
      title: json['title'] ?? 'Unknown Yatra',
      distance: json['distance']?.toString() ?? '0 KM',
      steps: json['steps']?.toString() ?? '0 Steps',
      duration: json['duration']?.toString() ?? '0 Days',
      groupSize: json['groupSize']?.toString() ?? '0',
      image: ApiService.resolveImageUrl(json['image'] ?? 'assets/images/somnath_temple_new.png'),
      tag: json['tag'] ?? 'Popular Yatra',
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
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
