import '../models/live_yatra_models.dart';
import '../services/api_service.dart';

class YatraRepository {
  Future<Map<String, dynamic>> startYatraSession({
    required String token,
    required String routeId,
  }) async {
    return await ApiService.startYatra(token, routeId);
  }

  Future<void> updateGPSLocation({
    required String token,
    required String journeyId,
    required double latitude,
    required double longitude,
    required int stepsIncrement,
    required double distanceIncrementMeters,
  }) async {
    await ApiService.updateJourneyLocation(
      token,
      journeyId,
      stepsIncrement,
      distanceIncrementMeters,
    );
  }

  Future<Map<String, dynamic>> getJourneyProgress({
    required String token,
    required String journeyId,
  }) async {
    return await ApiService.getJourneyProgress(token, journeyId);
  }

  Future<List<LiveDevoteeModel>> getNearbyDevotees({
    required String token,
    double? latitude,
    double? longitude,
  }) async {
    final rawList = await ApiService.getNearbyDevotees(token, latitude: latitude, longitude: longitude);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => LiveDevoteeModel.fromJson(item))
        .toList();
  }

  Future<void> stopYatraSession({
    required String token,
    required String journeyId,
  }) async {
    await ApiService.stopJourney(token, journeyId);
  }
}
