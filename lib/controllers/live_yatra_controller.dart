import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/live_yatra_models.dart';
import '../repositories/yatra_repository.dart';
import '../services/offline_location_queue_service.dart';
import '../services/yatra_socket_service.dart';
import '../services/yatra_tracking_service.dart';

class LiveYatraController extends ChangeNotifier {
  final YatraTrackingService _trackingService = YatraTrackingService();
  final YatraSocketService _socketService = YatraSocketService();
  final YatraRepository _repository = YatraRepository();

  LiveYatraState _state = const LiveYatraState();
  LiveYatraState get state => _state;

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Map<String, dynamic>>? _sanghaSubscription;
  StreamSubscription<List<dynamic>>? _nearbySubscription;

  DateTime? _lastApiUpdateTime;
  Position? _lastPosition;
  List<RoutePolylinePoint> _routePolyline = [];

  void setInitialParams({
    required String journeyId,
    required String title,
    required String totalDistanceStr,
  }) {
    double totalKm = 450.0;
    final match = RegExp(r'([\d\.]+)').firstMatch(totalDistanceStr);
    if (match != null) {
      totalKm = double.tryParse(match.group(1)!) ?? 450.0;
    }

    _state = _state.copyWith(
      journeyId: journeyId,
      title: title,
      totalDistanceKm: totalKm,
      kmRemaining: totalKm,
      activeDevoteesCount: 1, // Dynamic online count (starts at 1 for current user)
    );
    notifyListeners();
  }

  void setRoutePolyline(List<RoutePolylinePoint> polyline) {
    _routePolyline = polyline;
  }

  Future<bool> startTracking() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Initialize Socket connection
      _socketService.init(token);
      _socketService.joinLiveYatra(_state.journeyId);

      // Socket Listeners
      _sanghaSubscription = _socketService.onLiveSanghaUpdate.listen((data) {
        final count = (data['onlineDevotees'] as num?)?.toInt() ?? 1;
        _state = _state.copyWith(activeDevoteesCount: count);
        notifyListeners();
      });

      _nearbySubscription = _socketService.onNearbyDevoteesUpdate.listen((rawList) {
        final devotees = rawList
            .whereType<Map>()
            .map((item) => LiveDevoteeModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        _state = _state.copyWith(nearbyDevotees: devotees);
        notifyListeners();
      });

      // Start GPS Tracking
      final success = await _trackingService.startTracking(
        onLocationChanged: _onPositionUpdate,
      );

      if (!success) {
        _state = _state.copyWith(
          isLoading: false,
          error: 'Location permission denied or service disabled.',
        );
        notifyListeners();
        return false;
      }

      // Fetch initial nearby list
      _fetchNearbyDevotees(token);

      _state = _state.copyWith(
        isTracking: true,
        isLoading: false,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  void _onPositionUpdate(Position position) {
    double completedKm = _state.kmCompleted;

    if (_routePolyline.isNotEmpty) {
      completedKm = YatraTrackingService.calculateRouteProgressKm(
        userLat: position.latitude,
        userLng: position.longitude,
        polyline: _routePolyline,
        fallbackTotalKm: _state.totalDistanceKm,
      );
    } else if (_lastPosition != null) {
      final deltaMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      completedKm += (deltaMeters / 1000.0);
    }

    final remainingKm = (_state.totalDistanceKm - completedKm).clamp(0.0, _state.totalDistanceKm);
    final progress = _state.totalDistanceKm > 0
        ? (completedKm / _state.totalDistanceKm * 100).clamp(0.0, 100.0)
        : 0.0;

    _lastPosition = position;

    _state = _state.copyWith(
      currentLatitude: position.latitude,
      currentLongitude: position.longitude,
      speed: position.speed,
      bearing: position.heading,
      accuracy: position.accuracy,
      kmCompleted: completedKm,
      kmRemaining: remainingKm,
      progressPercent: progress,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();

    _maybeSyncWithBackend(position, completedKm);
  }

  void _maybeSyncWithBackend(Position position, double completedKm) async {
    final now = DateTime.now();
    if (_lastApiUpdateTime != null && now.difference(_lastApiUpdateTime!).inSeconds < 5) {
      return;
    }
    _lastApiUpdateTime = now;

    final offlineQueue = OfflineLocationQueueService();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty || !_socketService.isConnected) {
        await offlineQueue.enqueueLocation(
          journeyId: _state.journeyId,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          distanceCompletedKm: completedKm,
          progressPercent: _state.progressPercent,
        );
        return;
      }

      await offlineQueue.flushQueue((items) async {
        for (final item in items) {
          _socketService.updateYatraLocation(
            journeyId: item['journeyId'] ?? _state.journeyId,
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            accuracy: (item['accuracy'] as num?)?.toDouble() ?? 0.0,
            speed: (item['speed'] as num?)?.toDouble() ?? 0.0,
            heading: (item['heading'] as num?)?.toDouble() ?? 0.0,
            distanceCompletedKm: (item['distanceCompletedKm'] as num?)?.toDouble() ?? completedKm,
            progressPercent: (item['progressPercent'] as num?)?.toDouble() ?? _state.progressPercent,
            isOfflineSync: true,
          );
        }
        return true;
      });

      final distMeters = completedKm * 1000.0;
      await _repository.updateGPSLocation(
        token: token,
        journeyId: _state.journeyId,
        latitude: position.latitude,
        longitude: position.longitude,
        stepsIncrement: 15,
        distanceIncrementMeters: distMeters,
      );

      _socketService.updateYatraLocation(
        journeyId: _state.journeyId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        distanceCompletedKm: completedKm,
        progressPercent: _state.progressPercent,
      );
    } catch (e) {
      debugPrint('Backend location sync error: $e');
      await offlineQueue.enqueueLocation(
        journeyId: _state.journeyId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        distanceCompletedKm: completedKm,
        progressPercent: _state.progressPercent,
      );
    }
  }

  Future<void> pauseTracking() async {
    _socketService.pauseYatraTracking(_state.journeyId);
    _state = _state.copyWith(isTracking: false);
    notifyListeners();
  }

  Future<void> resumeTracking() async {
    _socketService.resumeYatraTracking(_state.journeyId);
    _state = _state.copyWith(isTracking: true);
    notifyListeners();
  }

  Future<void> _fetchNearbyDevotees(String token) async {
    try {
      final devotees = await _repository.getNearbyDevotees(
        token: token,
        latitude: _state.currentLatitude,
        longitude: _state.currentLongitude,
      );
      if (devotees.isNotEmpty) {
        _state = _state.copyWith(nearbyDevotees: devotees);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching nearby devotees: $e');
    }
  }

  Future<void> stopTracking() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      await _trackingService.stopTracking();
      _socketService.stopYatraTracking(_state.journeyId);
      _socketService.leaveLiveYatra(_state.journeyId);
      _socketService.dispose();

      if (token.isNotEmpty && _state.journeyId.isNotEmpty) {
        await _repository.stopYatraSession(token: token, journeyId: _state.journeyId);
      }

      _sanghaSubscription?.cancel();
      _nearbySubscription?.cancel();
      _locationSubscription?.cancel();

      _state = _state.copyWith(
        isTracking: false,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isTracking: false,
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _trackingService.dispose();
    _socketService.dispose();
    _sanghaSubscription?.cancel();
    _nearbySubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
