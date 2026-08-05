import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class YatraSocketService {
  static final YatraSocketService _instance = YatraSocketService._();
  factory YatraSocketService() => _instance;
  YatraSocketService._();

  IO.Socket? _socket;
  bool _initialized = false;

  final _liveSanghaController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _nearbyDevoteesController = StreamController<List<dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onLiveSanghaUpdate => _liveSanghaController.stream;
  Stream<Map<String, dynamic>> get onLocationUpdate => _locationUpdateController.stream;
  Stream<List<dynamic>> get onNearbyDevoteesUpdate => _nearbyDevoteesController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void init(String token) {
    if (_initialized) {
      dispose();
    }

    final baseUrl = ApiService.baseUrl;
    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[YatraLiveSocket] Connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[YatraLiveSocket] Disconnected');
    });

    _socket!.on('group_member_location_updated', (data) {
      if (data is Map) {
        _locationUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('live_sangha_update', (data) {
      if (data is Map) {
        _liveSanghaController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('nearby_devotees_update', (data) {
      if (data is List) {
        _nearbyDevoteesController.add(List<dynamic>.from(data));
      }
    });

    _socket!.connect();
    _initialized = true;
  }

  void joinLiveYatra(String journeyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_group_tracking', {'groupId': journeyId});
      _socket!.emit('join_yatra_tracking', {'journeyId': journeyId});
    }
  }

  void shareLocation({
    required String journeyId,
    required double latitude,
    required double longitude,
    required double accumulatedDistance,
    required int steps,
    double progressPercent = 0.0,
  }) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('share_my_yatra_location', {
        'groupId': journeyId,
        'latitude': latitude,
        'longitude': longitude,
        'accumulatedDistance': accumulatedDistance,
        'steps': steps,
        'progressPercent': progressPercent,
      });

      _socket!.emit('update_yatra_location', {
        'journeyId': journeyId,
        'latitude': latitude,
        'longitude': longitude,
        'distanceCompletedKm': accumulatedDistance / 1000.0,
        'progressPercent': progressPercent,
      });
    }
  }

  void updateYatraLocation({
    required String journeyId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    required double heading,
    required double distanceCompletedKm,
    required double progressPercent,
    bool isOfflineSync = false,
  }) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('update_yatra_location', {
        'journeyId': journeyId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'distanceCompletedKm': distanceCompletedKm,
        'progressPercent': progressPercent,
        'isOfflineSync': isOfflineSync,
      });
    }
  }

  void pauseYatraTracking(String journeyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('pause_yatra_tracking', {'journeyId': journeyId});
    }
  }

  void resumeYatraTracking(String journeyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('resume_yatra_tracking', {'journeyId': journeyId});
    }
  }

  void stopYatraTracking(String journeyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('stop_yatra_tracking', {'journeyId': journeyId});
    }
  }

  void leaveLiveYatra(String journeyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_group_tracking', {'groupId': journeyId});
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
  }
}
