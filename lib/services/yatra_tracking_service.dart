import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_yatra_models.dart';

enum LocationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class YatraTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<Position>.broadcast();
  bool _isTracking = false;

  Stream<Position> get locationStream => _locationController.stream;
  bool get isTracking => _isTracking;

  /// Check and request location permission.
  Future<LocationPermissionState> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionState.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionState.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.permanentlyDenied;
    }

    return LocationPermissionState.granted;
  }

  /// Get current one-time position
  Future<Position?> getCurrentPosition() async {
    try {
      final permState = await checkAndRequestPermission();
      if (permState != LocationPermissionState.granted) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Start continuous background location stream
  Future<bool> startTracking({
    required Function(Position position) onLocationChanged,
    int distanceFilterMeters = 10,
  }) async {
    if (_isTracking) return true;

    final permState = await checkAndRequestPermission();
    if (permState != LocationPermissionState.granted) {
      return false;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      // Filter out inaccurate GPS readings (> 50m) for battery & accuracy optimization
      if (position.accuracy > 50.0) {
        debugPrint('⚠️ [YatraTrackingService] Skipped inaccurate GPS fix (${position.accuracy.toStringAsFixed(1)}m > 50m)');
        return;
      }
      _locationController.add(position);
      onLocationChanged(position);
    }, onError: (err) {
      debugPrint('GPS Tracking stream error: $err');
    });

    _isTracking = true;
    return true;
  }

  /// Stop continuous location stream
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  /// Dispose service resources
  void dispose() {
    stopTracking();
    _locationController.close();
  }

  /// Project user GPS coordinate onto route polyline and return accumulated route distance in KM
  static double calculateRouteProgressKm({
    required double userLat,
    required double userLng,
    required List<RoutePolylinePoint> polyline,
    required double fallbackTotalKm,
  }) {
    if (polyline.isEmpty) return 0.0;
    if (polyline.length == 1) return 0.0;

    double bestDistanceMeters = double.infinity;
    double progressKmAtBestPoint = 0.0;
    double accumulatedDistanceBeforeSegment = 0.0;

    final userPoint = RoutePolylinePoint(userLat, userLng);

    for (int i = 0; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];
      final segmentLengthMeters = p1.distanceTo(p2);

      // Project user point onto segment (p1, p2)
      final proj = _projectPointToSegment(userPoint, p1, p2);
      final distToSegment = userPoint.distanceTo(proj.point);

      if (distToSegment < bestDistanceMeters) {
        bestDistanceMeters = distToSegment;
        progressKmAtBestPoint = (accumulatedDistanceBeforeSegment + (segmentLengthMeters * proj.fraction)) / 1000.0;
      }

      accumulatedDistanceBeforeSegment += segmentLengthMeters;
    }

    return progressKmAtBestPoint.clamp(0.0, fallbackTotalKm);
  }

  static _ProjectionResult _projectPointToSegment(
    RoutePolylinePoint p,
    RoutePolylinePoint a,
    RoutePolylinePoint b,
  ) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;

    if (dx == 0 && dy == 0) {
      return _ProjectionResult(a, 0.0);
    }

    final t = (((p.longitude - a.longitude) * dx) + ((p.latitude - a.latitude) * dy)) / ((dx * dx) + (dy * dy));
    final fraction = t.clamp(0.0, 1.0);

    final projLat = a.latitude + (fraction * dy);
    final projLng = a.longitude + (fraction * dx);

    return _ProjectionResult(RoutePolylinePoint(projLat, projLng), fraction);
  }
}

class _ProjectionResult {
  final RoutePolylinePoint point;
  final double fraction;
  _ProjectionResult(this.point, this.fraction);
}
