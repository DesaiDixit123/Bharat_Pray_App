enum DarshanType { image, video, live }

enum DarshanFallbackType { image, video, none }

/// Configurable Darshan entity supporting IMAGE, VIDEO, LIVE, and fallback cascades.
class DarshanConfig {
  final String id;
  final String godCategoryId;
  final String? templeId;
  final String name;
  final DarshanType type;
  final String imageUrl;
  final String thumbnailUrl;
  final String videoUrl;
  final String liveStreamUrl;
  final DarshanFallbackType fallbackType;
  final String fallbackImageUrl;
  final String fallbackVideoUrl;
  final String shortDesc;
  final String description;
  final bool status;

  DarshanConfig({
    required this.id,
    required this.godCategoryId,
    this.templeId,
    required this.name,
    this.type = DarshanType.image,
    this.imageUrl = '',
    this.thumbnailUrl = '',
    this.videoUrl = '',
    this.liveStreamUrl = '',
    this.fallbackType = DarshanFallbackType.image,
    this.fallbackImageUrl = '',
    this.fallbackVideoUrl = '',
    this.shortDesc = '',
    this.description = '',
    this.status = true,
  });

  factory DarshanConfig.fromJson(Map<String, dynamic> json) {
    DarshanType parseType(String? t) {
      switch (t?.toLowerCase()) {
        case 'video':
          return DarshanType.video;
        case 'live':
          return DarshanType.live;
        case 'image':
        default:
          return DarshanType.image;
      }
    }

    DarshanFallbackType parseFallback(String? fb) {
      switch (fb?.toLowerCase()) {
        case 'video':
          return DarshanFallbackType.video;
        case 'none':
          return DarshanFallbackType.none;
        case 'image':
        default:
          return DarshanFallbackType.image;
      }
    }

    return DarshanConfig(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      godCategoryId:
          json['god_category_id']?.toString() ??
          json['godCategoryId']?.toString() ??
          '',
      templeId: json['temple_id']?.toString() ?? json['templeId']?.toString(),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      type: parseType(json['type']?.toString()),
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      thumbnailUrl:
          json['thumbnail']?.toString() ?? json['image']?.toString() ?? '',
      videoUrl:
          json['video_url']?.toString() ?? json['videoUrl']?.toString() ?? '',
      liveStreamUrl:
          json['live_stream_url']?.toString() ??
          json['liveStreamUrl']?.toString() ??
          '',
      fallbackType: parseFallback(
        json['fallback_type']?.toString() ?? json['fallbackType']?.toString(),
      ),
      fallbackImageUrl:
          json['fallback_image']?.toString() ??
          json['fallbackImageUrl']?.toString() ??
          '',
      fallbackVideoUrl:
          json['fallback_video_url']?.toString() ??
          json['fallbackVideoUrl']?.toString() ??
          '',
      shortDesc:
          json['short_desc']?.toString() ?? json['shortDesc']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status:
          json['status'] == true ||
          json['status'] == 1 ||
          json['status'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'god_category_id': godCategoryId,
      if (templeId != null) 'temple_id': templeId,
      'name': name,
      'type': type.name,
      'image': imageUrl,
      'thumbnail': thumbnailUrl,
      'video_url': videoUrl,
      'live_stream_url': liveStreamUrl,
      'fallback_type': fallbackType.name,
      'fallback_image': fallbackImageUrl,
      'fallback_video_url': fallbackVideoUrl,
      'short_desc': shortDesc,
      'description': description,
      'status': status,
    };
  }

  /// Resolves the primary URL or gracefully cascades to fallback when stream/video is offline
  String resolveActiveMediaUrl({
    bool isLiveStreamUnavailable = false,
    bool isVideoUnavailable = false,
  }) {
    if (type == DarshanType.live) {
      if (!isLiveStreamUnavailable && liveStreamUrl.isNotEmpty) {
        return liveStreamUrl;
      }
      // Fallback cascade for LIVE
      if (fallbackType == DarshanFallbackType.video &&
          fallbackVideoUrl.isNotEmpty &&
          !isVideoUnavailable) {
        return fallbackVideoUrl;
      }
      return fallbackImageUrl.isNotEmpty ? fallbackImageUrl : imageUrl;
    } else if (type == DarshanType.video) {
      if (!isVideoUnavailable && videoUrl.isNotEmpty) {
        return videoUrl;
      }
      return fallbackImageUrl.isNotEmpty ? fallbackImageUrl : imageUrl;
    }
    return imageUrl;
  }
}
