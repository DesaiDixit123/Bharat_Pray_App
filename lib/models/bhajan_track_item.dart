import 'prayer.dart';
import '../core/localization/localized_api_helper.dart';
import '../services/api_service.dart';

class BhajanTrackItem {
  const BhajanTrackItem({
    required this.id,
    required this.title,
    required this.singer,
    required this.imagePath,
    this.audioUrl,
    this.duration,
    this.lyrics,
    this.categoryId,
    this.isLiked = false,
    this.isDownloaded = false,
    this.isFavourite = false,
    this.linkedPrayer,
  });

  final String id;
  final String title;
  final String singer;
  final String imagePath;
  final String? audioUrl;
  final String? duration;
  final String? lyrics;
  final String? categoryId;
  final bool isLiked;
  final bool isDownloaded;
  final bool isFavourite;
  final Prayer? linkedPrayer;

  BhajanTrackItem copyWith({
    String? id,
    String? title,
    String? singer,
    String? imagePath,
    String? audioUrl,
    String? duration,
    String? lyrics,
    String? categoryId,
    bool? isLiked,
    bool? isDownloaded,
    bool? isFavourite,
    Prayer? linkedPrayer,
  }) {
    return BhajanTrackItem(
      id: id ?? this.id,
      title: title ?? this.title,
      singer: singer ?? this.singer,
      imagePath: imagePath ?? this.imagePath,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      lyrics: lyrics ?? this.lyrics,
      categoryId: categoryId ?? this.categoryId,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavourite: isFavourite ?? this.isFavourite,
      linkedPrayer: linkedPrayer ?? this.linkedPrayer,
    );
  }

  factory BhajanTrackItem.fromJson(Map<String, dynamic> raw) {
    final bhajanMap = (raw['bhajanId'] is Map<String, dynamic>)
        ? (raw['bhajanId'] as Map<String, dynamic>)
        : raw;

    final id = (bhajanMap['_id'] ?? bhajanMap['id'] ?? raw['_id'] ?? raw['id'] ?? '').toString();
    final title = LocalizedApiHelper.parse(
      bhajanMap['title'] ?? bhajanMap['name'],
      defaultValue: 'Devotional Bhajan',
    );
    final singer = LocalizedApiHelper.parse(
      bhajanMap['artist'] ?? bhajanMap['singer'],
      defaultValue: 'Devotional Artist',
    );
    final rawImg =
        (bhajanMap['coverImage'] ?? bhajanMap['image'] ?? '').toString();
    final imagePath = ApiService.resolveImageUrl(rawImg);

    final durationRaw = bhajanMap['duration'];
    String? formattedDuration;
    if (durationRaw != null) {
      if (durationRaw is String && durationRaw.contains(':')) {
        formattedDuration = durationRaw;
      } else {
        final sec = durationRaw is int
            ? durationRaw
            : int.tryParse(durationRaw.toString()) ?? 0;
        if (sec > 0) {
          final m = (sec ~/ 60).toString().padLeft(2, '0');
          final s = (sec % 60).toString().padLeft(2, '0');
          formattedDuration = '$m:$s';
        }
      }
    }

    final isLiked =
        (raw['isLiked'] ?? raw['liked'] ?? bhajanMap['isLiked'] ?? false) ==
            true;
    final isDownloaded =
        (raw['isDownloaded'] ?? bhajanMap['isDownloaded'] ?? false) == true;

    return BhajanTrackItem(
      id: id,
      title: title,
      singer: singer,
      imagePath: imagePath,
      audioUrl: (bhajanMap['audioUrl'] ?? bhajanMap['audio'] ?? '').toString(),
      duration: formattedDuration,
      lyrics: LocalizedApiHelper.parse(bhajanMap['lyrics']),
      categoryId: (bhajanMap['categoryId'] is Map
              ? bhajanMap['categoryId']['_id']
              : bhajanMap['categoryId'])
          ?.toString(),
      isLiked: isLiked,
      isDownloaded: isDownloaded,
    );
  }
}
