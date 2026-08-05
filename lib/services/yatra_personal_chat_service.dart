import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class YatraPersonalChatService {
  static final YatraPersonalChatService _instance = YatraPersonalChatService._();
  factory YatraPersonalChatService() => _instance;
  YatraPersonalChatService._();

  IO.Socket? _socket;
  bool _initialized = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTypingStatus => _typingController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt => _readReceiptController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void init(String token) {
    if (_initialized) return;

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
      debugPrint('💬 [YatraPersonalChatSocket] Connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('💬 [YatraPersonalChatSocket] Disconnected');
    });

    _socket!.on('new_personal_chat_message', (data) {
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('user_typing_status', (data) {
      if (data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('messages_read_receipt', (data) {
      if (data is Map) {
        _readReceiptController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
    _initialized = true;
  }

  void joinPersonalChat(String targetUserId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_personal_chat', {'targetUserId': targetUserId});
    }
  }

  void sendMessage({
    required String targetUserId,
    required String content,
    String yatraId = '',
    String journeyId = '',
    String messageType = 'text',
    String mediaUrl = '',
    String tempId = '',
  }) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_personal_chat_message', {
        'targetUserId': targetUserId,
        'content': content,
        'yatraId': yatraId,
        'journeyId': journeyId,
        'messageType': messageType,
        'mediaUrl': mediaUrl,
        'tempId': tempId,
      });
    }
  }

  void sendTypingIndicator(String targetUserId, bool isTyping) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('personal_chat_typing', {
        'targetUserId': targetUserId,
        'isTyping': isTyping,
      });
    }
  }

  void markMessagesRead(String targetUserId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_personal_messages_read', {
        'targetUserId': targetUserId,
      });
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
  }
}
