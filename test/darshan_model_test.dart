import 'package:flutter_test/flutter_test.dart';
import 'package:bharat_pray/models/darshan_model.dart';

void main() {
  group('Phase 12: Darshan Management & Multi-Type Cascade Tests', () {
    test('1. Parse IMAGE Darshan Config', () {
      final json = {
        '_id': 'darshan_shiva_image_1',
        'god_category_id': 'god_shiva_108',
        'name': 'Kashi Vishwanath Jyotirlinga',
        'type': 'image',
        'image': 'https://cdn.example.com/kashi.jpg',
        'thumbnail': 'https://cdn.example.com/kashi_thumb.jpg',
        'status': true,
      };

      final config = DarshanConfig.fromJson(json);
      expect(config.id, 'darshan_shiva_image_1');
      expect(config.godCategoryId, 'god_shiva_108');
      expect(config.name, 'Kashi Vishwanath Jyotirlinga');
      expect(config.type, DarshanType.image);
      expect(config.imageUrl, 'https://cdn.example.com/kashi.jpg');
      expect(config.thumbnailUrl, 'https://cdn.example.com/kashi_thumb.jpg');
      expect(config.status, isTrue);

      final activeUrl = config.resolveActiveMediaUrl();
      expect(activeUrl, 'https://cdn.example.com/kashi.jpg');
    });

    test('2. Parse VIDEO Darshan Config with Fallback Image', () {
      final json = {
        '_id': 'darshan_mahakal_video_2',
        'god_category_id': 'god_shiva_108',
        'name': 'Mahakaleshwar Bhasma Aarti',
        'type': 'video',
        'video_url': 'https://cdn.example.com/aarti.mp4',
        'image': 'https://cdn.example.com/mahakal_main.jpg',
        'fallback_image': 'https://cdn.example.com/mahakal_fallback.jpg',
        'status': true,
      };

      final config = DarshanConfig.fromJson(json);
      expect(config.type, DarshanType.video);
      expect(config.videoUrl, 'https://cdn.example.com/aarti.mp4');

      // Online video
      expect(
        config.resolveActiveMediaUrl(isVideoUnavailable: false),
        'https://cdn.example.com/aarti.mp4',
      );

      // Offline video -> Falls back to fallback image
      expect(
        config.resolveActiveMediaUrl(isVideoUnavailable: true),
        'https://cdn.example.com/mahakal_fallback.jpg',
      );
    });

    test(
      '3. Parse LIVE Darshan Config with Complete Fallback Cascade (LIVE -> VIDEO -> IMAGE)',
      () {
        final json = {
          '_id': 'darshan_somnath_live_3',
          'god_category_id': 'god_shiva_108',
          'name': 'Somnath 24x7 Live Darshan',
          'type': 'live',
          'live_stream_url': 'https://stream.example.com/somnath/live.m3u8',
          'fallback_type': 'video',
          'fallback_video_url': 'https://cdn.example.com/somnath_recorded.mp4',
          'fallback_image': 'https://cdn.example.com/somnath_poster.jpg',
          'image': 'https://cdn.example.com/somnath_main.jpg',
          'status': true,
        };

        final config = DarshanConfig.fromJson(json);
        expect(config.type, DarshanType.live);
        expect(config.fallbackType, DarshanFallbackType.video);

        // 1. Live stream online -> Returns live HLS stream URL
        final onlineUrl = config.resolveActiveMediaUrl(
          isLiveStreamUnavailable: false,
        );
        expect(onlineUrl, 'https://stream.example.com/somnath/live.m3u8');

        // 2. Live stream offline -> Falls back to recorded video
        final fallbackVideo = config.resolveActiveMediaUrl(
          isLiveStreamUnavailable: true,
          isVideoUnavailable: false,
        );
        expect(fallbackVideo, 'https://cdn.example.com/somnath_recorded.mp4');

        // 3. Both stream and video offline -> Cascades to fallback image
        final fallbackImg = config.resolveActiveMediaUrl(
          isLiveStreamUnavailable: true,
          isVideoUnavailable: true,
        );
        expect(fallbackImg, 'https://cdn.example.com/somnath_poster.jpg');
      },
    );

    test('4. JSON Serialization & Roundtrip', () {
      final original = DarshanConfig(
        id: 'darshan_ganesha_1',
        godCategoryId: 'god_ganesha_108',
        name: 'Siddhivinayak Live',
        type: DarshanType.live,
        liveStreamUrl: 'https://stream.example.com/siddhivinayak.m3u8',
        fallbackType: DarshanFallbackType.image,
        fallbackImageUrl: 'https://cdn.example.com/siddhivinayak.jpg',
        imageUrl: 'https://cdn.example.com/siddhivinayak.jpg',
      );

      final json = original.toJson();
      final restored = DarshanConfig.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.liveStreamUrl, original.liveStreamUrl);
      expect(restored.fallbackImageUrl, original.fallbackImageUrl);
    });
  });
}
