import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class GlobalSocketService {
  GlobalSocketService._privateConstructor();
  static final GlobalSocketService instance = GlobalSocketService._privateConstructor();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream controllers for real-time app events
  final _announcementController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get announcementStream => _announcementController.stream;

  final _contentPublishedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get contentPublishedStream => _contentPublishedController.stream;

  final _japPulseController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get japPulseStream => _japPulseController.stream;

  /// Connect to backend Socket.IO server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      final socketUri = ApiService.baseUrl;

      debugPrint('🔌 [GlobalSocketService] Connecting to $socketUri...');

      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(10)
            .setAuth({'token': token})
            .setQuery({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('✅ [GlobalSocketService] Connected successfully! Socket ID: ${_socket?.id}');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('🔌 [GlobalSocketService] Disconnected');
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        debugPrint('⚠️ [GlobalSocketService] Connection Error: $err');
      });

      // ── Listeners for Admin & Real-time Broadcast Events ──
      _socket!.on('flash_temple_announcement', (data) {
        debugPrint('🛕 [GlobalSocketService] Flash Announcement Received: $data');
        if (data is Map<String, dynamic>) {
          _announcementController.add(data);
        }
      });

      _socket!.on('event_new_jap_added', (data) {
        debugPrint('📿 [GlobalSocketService] New Jap Added Event: $data');
        if (data is Map<String, dynamic>) {
          _contentPublishedController.add({'type': 'jap', ...data});
        }
      });

      _socket!.on('event_new_yatra_added', (data) {
        debugPrint('🚩 [GlobalSocketService] New Yatra Added Event: $data');
        if (data is Map<String, dynamic>) {
          _contentPublishedController.add({'type': 'yatra', ...data});
        }
      });

      _socket!.on('event_new_darshan_added', (data) {
        debugPrint('🛕 [GlobalSocketService] New Darshan Added Event: $data');
        if (data is Map<String, dynamic>) {
          _contentPublishedController.add({'type': 'darshan', ...data});
        }
      });

      _socket!.on('global_jap_counter_pulse', (data) {
        if (data is Map<String, dynamic>) {
          _japPulseController.add(data);
        }
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('⚠️ [GlobalSocketService] Init error: $e');
    }
  }

  /// Emit user engagement (like, share, comment, interaction) so Admin sees it live
  void emitUserEngagement({
    required String action, // 'like', 'share', 'comment', 'jap_increment'
    required String targetType, // 'darshan', 'jap', 'yatra', 'bhajan'
    required String targetId,
    Map<String, dynamic>? metadata,
  }) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('user_engagement', {
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'metadata': metadata ?? {},
    });
  }

  /// Disconnect socket cleanly on logout
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
