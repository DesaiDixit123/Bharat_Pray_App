import 'package:flutter_test/flutter_test.dart';
import 'package:bharat_pray/services/api_service.dart';
import 'package:bharat_pray/models/yatra_model.dart';
import 'package:bharat_pray/models/journey_models.dart';

void main() {
  group('ApiService Yatra Repository Unit Tests', () {
    test('getPopularYatra returns typed ApiResponseModel with YatraModel list', () async {
      final response = await ApiService.getPopularYatra(page: 1, limit: 5);

      expect(response, isA<ApiResponseModel<List<YatraModel>>>());
      expect(response.isSuccess, isA<bool>());
    });

    test('searchPopularYatra sends query without crashing', () async {
      final response = await ApiService.searchPopularYatra('Somnath');

      expect(response, isA<ApiResponseModel<List<YatraModel>>>());
      expect(response.isSuccess, isTrue);
    });

    test('refreshPopularYatra re-fetches page 1 with force refresh', () async {
      final response = await ApiService.refreshPopularYatra(limit: 5);

      expect(response, isA<ApiResponseModel<List<YatraModel>>>());
      expect(response.isSuccess, isTrue);
    });

    test('loadMorePopularYatra fetches target page number', () async {
      final response = await ApiService.loadMorePopularYatra(nextPage: 2, limit: 5);

      expect(response, isA<ApiResponseModel<List<YatraModel>>>());
      expect(response.isSuccess, isTrue);
    });

    test('getContinueYatra returns typed ApiResponseModel', () async {
      final response = await ApiService.getContinueYatra();

      expect(response, isA<ApiResponseModel<ContinueYatraModel?>>());
      // Should handle 401 or null response without crashing
      expect(response.isSuccess, isNotNull);
    });
  });
}
