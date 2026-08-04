import 'prayer.dart';

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
}
