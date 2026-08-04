import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

/// A long-lived singleton socket service that listens for yatra group
/// real-time events (invitation received, member joined, invitation
/// accepted/rejected) and broadcasts them to registered listeners.
///
/// Call [init] once after login with the user's auth token, and [dispose]
/// once on logout.
class YatraGroupSocketService {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final YatraGroupSocketService _instance = YatraGroupSocketService._();
  factory YatraGroupSocketService() => _instance;
  YatraGroupSocketService._();

  // ─── Socket ───────────────────────────────────────────────────────────────
  IO.Socket? _socket;
  bool _initialized = false;

  // ─── Stream controllers ───────────────────────────────────────────────────
  final _invitationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _memberJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _inviteResponseController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _memberUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // ─── Public streams ───────────────────────────────────────────────────────
  /// Fires when this user receives a new group invitation.
  Stream<Map<String, dynamic>> get onInvitationReceived =>
      _invitationController.stream;

  /// Fires when a new member joins a group this user is in.
  Stream<Map<String, dynamic>> get onMemberJoined =>
      _memberJoinedController.stream;

  /// Fires when a sent invitation is accepted or rejected.
  Stream<Map<String, dynamic>> get onInviteResponse =>
      _inviteResponseController.stream;

  /// Fires on any member list update for a group.
  Stream<Map<String, dynamic>> get onMemberUpdate =>
      _memberUpdateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  /// Initialise and connect the socket. Safe to call multiple times — it will
  /// disconnect the old socket first.
  void init(String token) {
    if (_initialized) {
      dispose(); // tear-down existing socket before re-init
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
      print('[YatraGroupSocket] Connected');
    });

    _socket!.onDisconnect((_) {
      print('[YatraGroupSocket] Disconnected');
    });

    _socket!.on('group_invitation_received', (data) {
      if (data is Map) {
        _invitationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('group_member_joined', (data) {
      if (data is Map) {
        _memberJoinedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('group_invitation_accepted', (data) {
      if (data is Map) {
        _inviteResponseController.add({
          ...Map<String, dynamic>.from(data),
          'action': 'accepted',
        });
      }
    });

    _socket!.on('group_invitation_rejected', (data) {
      if (data is Map) {
        _inviteResponseController.add({
          ...Map<String, dynamic>.from(data),
          'action': 'rejected',
        });
      }
    });

    _socket!.on('group_member_update', (data) {
      if (data is Map) {
        _memberUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
    _initialized = true;
  }

  /// Join a specific group room so the server can route events correctly.
  void joinGroup(String groupId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_yatra_group', {'groupId': groupId});
    }
  }

  /// Leave a specific group room.
  void leaveGroup(String groupId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_yatra_group', {'groupId': groupId});
    }
  }

  /// Tear-down the socket and reset state. Called on logout.
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
  }
}
