import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class YatraPersonalChatService {
  static final YatraPersonalChatService _instance = YatraPersonalChatService._();
  factory YatraPersonalChatService() => _instance;
  YatraPersonalChatService._();

  IO.Socket? _socket;
  bool _initialized = false;

  final ValueNotifier<int> unreadMessageCount = ValueNotifier<int>(0);
  String? currentActiveChatUserId;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineUsersController = StreamController<List<String>>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTypingStatus => _typingController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get onUserPresence => _presenceController.stream;
  Stream<List<String>> get onOnlineUsersList => _onlineUsersController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<int> refreshUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPersonalStr = prefs.getString('active_personal_chats');
      int total = 0;
      if (localPersonalStr != null && localPersonalStr.isNotEmpty) {
        final decoded = jsonDecode(localPersonalStr) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map) {
            final unread = item['unread'] is int ? item['unread'] as int : 0;
            total += unread;
          }
        }
      }
      unreadMessageCount.value = total;
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markChatAsRead(String targetUserId) async {
    markMessagesRead(targetUserId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPersonalStr = prefs.getString('active_personal_chats');
      if (localPersonalStr != null && localPersonalStr.isNotEmpty) {
        final decoded = jsonDecode(localPersonalStr) as List<dynamic>;
        bool changed = false;
        for (final item in decoded) {
          if (item is Map) {
            final uId = (item['userId'] ?? item['id'] ?? '').toString();
            if (uId == targetUserId) {
              if (item['unread'] != 0) {
                item['unread'] = 0;
                changed = true;
              }
            }
          }
        }
        if (changed) {
          await prefs.setString('active_personal_chats', jsonEncode(decoded));
        }
      }
      await refreshUnreadCount();
    } catch (e) {
      debugPrint("Error marking chat as read: $e");
    }
  }

  Future<void> clearAllUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPersonalStr = prefs.getString('active_personal_chats');
      if (localPersonalStr != null && localPersonalStr.isNotEmpty) {
        final decoded = jsonDecode(localPersonalStr) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map) {
            item['unread'] = 0;
          }
        }
        await prefs.setString('active_personal_chats', jsonEncode(decoded));
      }
      unreadMessageCount.value = 0;
    } catch (e) {
      unreadMessageCount.value = 0;
    }
  }

  void init(String token) {
    refreshUnreadCount();

    if (_initialized && _socket != null) {
      if (!_socket!.connected) {
        _socket!.connect();
      } else {
        _socket!.emit('get_online_users');
      }
      return;
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
      debugPrint('💬 [YatraPersonalChatSocket] Connected');
      _socket!.emit('get_online_users');
      refreshUnreadCount();
    });

    _socket!.onDisconnect((_) {
      debugPrint('💬 [YatraPersonalChatSocket] Disconnected');
    });

    _socket!.on('new_personal_chat_message', (data) async {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _messageController.add(map);

        final senderId = map['senderId']?.toString() ?? '';
        if (currentActiveChatUserId != null && currentActiveChatUserId == senderId) {
          markMessagesRead(senderId);
        } else if (senderId.isNotEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final localPersonalStr = prefs.getString('active_personal_chats');
            List<dynamic> list = [];
            if (localPersonalStr != null && localPersonalStr.isNotEmpty) {
              list = jsonDecode(localPersonalStr) as List<dynamic>;
            }
            final idx = list.indexWhere((c) =>
              c is Map && ((c['userId']?.toString() == senderId) || (c['id']?.toString() == senderId))
            );

            final now = DateTime.now();
            final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
            final minute = now.minute.toString().padLeft(2, '0');
            final ampm = now.hour >= 12 ? 'pm' : 'am';
            final timeStr = '$hour:$minute $ampm';

            if (idx != -1) {
              final chat = Map<String, dynamic>.from(list[idx]);
              final curUnread = chat['unread'] is int ? chat['unread'] as int : 0;
              chat['unread'] = curUnread + 1;
              chat['lastMessage'] = map['content']?.toString() ?? '';
              chat['time'] = timeStr;
              list.removeAt(idx);
              list.insert(0, chat);
            } else {
              list.insert(0, {
                'userId': senderId,
                'name': map['senderName']?.toString() ?? 'Devotee',
                'lastMessage': map['content']?.toString() ?? '',
                'time': timeStr,
                'unread': 1,
                'isOnline': true,
                'avatar': map['senderProfilePic']?.toString() ?? '',
              });
            }
            await prefs.setString('active_personal_chats', jsonEncode(list));
            await refreshUnreadCount();
          } catch (e) {
            unreadMessageCount.value = unreadMessageCount.value + 1;
          }
        }
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

    _socket!.on('user_presence', (data) {
      if (data is Map) {
        _presenceController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('online_users_list', (data) {
      if (data is List) {
        final list = data.map((e) => e.toString()).toList();
        _onlineUsersController.add(list);
      }
    });

    _socket!.connect();
    _initialized = true;
  }

  void getOnlineUsers() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('get_online_users');
    }
  }

  void checkUserPresence(String targetUserId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('check_user_presence', {'userId': targetUserId});
    }
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
