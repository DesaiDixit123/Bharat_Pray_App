import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/yatra_personal_chat_service.dart';
import 'document_selection_screen.dart';

enum YatraChatType { single, group }

class YatraChatMessage {
  YatraChatMessage({
    required this.senderName,
    required this.text,
    required this.time,
    required this.isCurrentUser,
    this.avatarAsset,
    this.readStatus = 'sent',
    this.messageId = '',
    this.tempId = '',
    this.reaction = '',
    this.isEdited = false,
    this.isDeleted = false,
    this.mediaPath,
  });

  final String senderName;
  String text;
  final String time;
  final bool isCurrentUser;
  final String? avatarAsset;
  final String readStatus;
  final String messageId;
  final String tempId;
  String reaction;
  bool isEdited;
  bool isDeleted;
  final String? mediaPath;

  Map<String, dynamic> toJson() => {
    'senderName': senderName,
    'text': text,
    'time': time,
    'isCurrentUser': isCurrentUser,
    'avatarAsset': avatarAsset,
    'readStatus': readStatus,
    'messageId': messageId,
    'tempId': tempId,
    'reaction': reaction,
    'isEdited': isEdited,
    'isDeleted': isDeleted,
    'mediaPath': mediaPath,
  };

  factory YatraChatMessage.fromJson(Map<String, dynamic> json) => YatraChatMessage(
    senderName: (json['senderName'] ?? '').toString(),
    text: (json['text'] ?? '').toString(),
    time: (json['time'] ?? '').toString(),
    isCurrentUser: json['isCurrentUser'] == true,
    avatarAsset: json['avatarAsset']?.toString(),
    readStatus: (json['readStatus'] ?? 'sent').toString(),
    messageId: (json['messageId'] ?? '').toString(),
    tempId: (json['tempId'] ?? '').toString(),
    reaction: (json['reaction'] ?? '').toString(),
    isEdited: json['isEdited'] == true,
    isDeleted: json['isDeleted'] == true,
    mediaPath: json['mediaPath']?.toString(),
  );
}

class YatraChatScreen extends StatefulWidget {
  const YatraChatScreen({
    super.key,
    required this.chatType,
    required this.title,
    required this.subtitle,
    required this.messages,
    this.targetUserId = '',
    this.phoneNumber = '',
    this.email = '',
    this.about = '',
    this.location = '',
    this.yatraId = '',
    this.journeyId = '',
    this.headerAvatarAsset,
    this.groupMembersText,
    this.members,
  });

  final YatraChatType chatType;
  final String title;
  final String subtitle;
  final List<YatraChatMessage> messages;
  final String targetUserId;
  final String phoneNumber;
  final String email;
  final String about;
  final String location;
  final String yatraId;
  final String journeyId;
  final String? headerAvatarAsset;
  final String? groupMembersText;
  final List<dynamic>? members;

  @override
  State<YatraChatScreen> createState() => _YatraChatScreenState();
}

class _YatraChatScreenState extends State<YatraChatScreen> {
  late List<YatraChatMessage> _messages;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final YatraPersonalChatService _chatService = YatraPersonalChatService();

  String _currentUserPic = '';
  String _currentUserName = 'You';

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _readSub;
  StreamSubscription? _presenceSub;
  bool _isTargetTyping = false;
  bool _isTargetOnline = false;

  bool _isSearching = false;
  String _chatSearchQuery = '';
  final TextEditingController _chatSearchController = TextEditingController();

  bool get _isLightTheme => true;

  Color get _backgroundColor => const Color(0xFFFFE8D6);
  Color get _subtitleColor => const Color(0xFF7A757F);
  Color get _leftBubbleColor => Colors.white;
  Color get _rightBubbleColor => Colors.white;
  Color get _bubbleBorderColor => const Color(0xFFE8D2B8);
  Color get _messageColor => const Color(0xFF2D2D2D);
  Color get _inputBorderColor => const Color(0xFFE8D2B8);
  Color get _inputHintColor => const Color(0xFFA88B6A);

  late List<Map<String, dynamic>> _groupMembers;
  bool _isUserAdmin = true;

  String get _chatStorageId => widget.chatType == YatraChatType.group
      ? (widget.yatraId.isNotEmpty ? widget.yatraId : widget.title)
      : (widget.targetUserId.isNotEmpty ? widget.targetUserId : widget.title);

  Future<void> _loadLocalMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'local_chat_msgs_$_chatStorageId';
      final stored = prefs.getString(key);
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        final loaded = decoded.map((e) => YatraChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (mounted && loaded.isNotEmpty) {
          setState(() {
            _messages = loaded;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } catch (e) {
      debugPrint("Error loading local messages: $e");
    }
  }

  Future<void> _saveLocalMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'local_chat_msgs_$_chatStorageId';
      final list = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint("Error saving local messages: $e");
    }
  }

  Future<void> _clearChatPermanently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = _chatStorageId;
      final isGroup = widget.chatType == YatraChatType.group;

      await prefs.remove('local_chat_msgs_$id');
      if (mounted) {
        setState(() {
          _messages.clear();
        });
      }

      final key = isGroup ? 'active_yatra_groups' : 'active_personal_chats';
      final existingJson = prefs.getString(key);
      if (existingJson != null && existingJson.isNotEmpty) {
        final list = jsonDecode(existingJson) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            final itemId = (isGroup ? item['_id'] : item['userId'])?.toString() ?? '';
            if (itemId == id) {
              item['lastMessage'] = '';
              item['time'] = '';
            }
          }
        }
        await prefs.setString(key, jsonEncode(list));
      }
    } catch (e) {
      debugPrint("Error clearing chat permanently: $e");
    }
  }

  Future<void> _deleteChatPermanently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = _chatStorageId;
      final isGroup = widget.chatType == YatraChatType.group;

      await prefs.remove('local_chat_msgs_$id');

      final key = isGroup ? 'active_yatra_groups' : 'active_personal_chats';
      final existingJson = prefs.getString(key);
      if (existingJson != null && existingJson.isNotEmpty) {
        List<dynamic> list = jsonDecode(existingJson) as List<dynamic>;
        list.removeWhere((item) {
          if (item is Map) {
            final itemId = (isGroup ? item['_id'] : item['userId'])?.toString() ?? '';
            return itemId == id;
          }
          return false;
        });
        await prefs.setString(key, jsonEncode(list));
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error deleting chat permanently: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _isTargetOnline = widget.subtitle.toLowerCase().trim() == 'online';
    _messages = List<YatraChatMessage>.from(widget.messages);
    _chatService.currentActiveChatUserId = widget.targetUserId;
    if (widget.targetUserId.isNotEmpty) {
      _chatService.markChatAsRead(widget.targetUserId);
    }

    final initialMembers = widget.members;
    if (initialMembers != null && initialMembers.isNotEmpty) {
      _groupMembers = initialMembers.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'name': e.toString(), 'isAdmin': false}).toList();
    } else {
      _groupMembers = [
        {'name': 'You (Leader)', 'mobile': 'Admin', 'isAdmin': true},
        {'name': 'Ramesh Kumar', 'mobile': '+91 98765 43210', 'isAdmin': false},
        {'name': 'Suresh Sharma', 'mobile': '+91 98765 43211', 'isAdmin': false},
        {'name': 'Anita Verma', 'mobile': '+91 98765 43212', 'isAdmin': false},
      ];
    }
    if (!_groupMembers.any((m) => m['isAdmin'] == true)) {
      _groupMembers.first['isAdmin'] = true;
    }
    _isUserAdmin = _groupMembers.any((m) => (m['name']?.toString().contains('You') == true || m['isAdmin'] == true));

    _loadLocalMessages();
    _initSocketAndFetch();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _initSocketAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (mounted) {
      setState(() {
        _currentUserPic = prefs.getString('profile_pic') ?? prefs.getString('user_profile_pic') ?? '';
        _currentUserName = prefs.getString('name') ?? prefs.getString('fullName') ?? 'You';
      });
    }

    if (token.isNotEmpty && widget.targetUserId.isNotEmpty) {
      _chatService.init(token);
      _chatService.joinPersonalChat(widget.targetUserId);
      _chatService.markMessagesRead(widget.targetUserId);

      _msgSub = _chatService.onNewMessage.listen((data) {
        if (!mounted) return;
        final senderId = data['senderId']?.toString() ?? '';
        final text = data['content']?.toString() ?? '';
        final tempId = data['tempId']?.toString() ?? '';

        if (senderId == widget.targetUserId || data['receiverId']?.toString() == widget.targetUserId) {
          final isMe = senderId != widget.targetUserId;
          final existingIdx = _messages.indexWhere((m) => m.tempId.isNotEmpty && m.tempId == tempId);

          if (existingIdx != -1) {
            setState(() {
              _messages[existingIdx] = YatraChatMessage(
                senderName: isMe ? 'You' : widget.title,
                text: text,
                time: _formatTime(DateTime.now()),
                isCurrentUser: isMe,
                avatarAsset: isMe ? _currentUserPic : widget.headerAvatarAsset,
                readStatus: data['readStatus']?.toString() ?? 'sent',
                messageId: data['_id']?.toString() ?? '',
              );
            });
          } else {
            setState(() {
              _messages.add(
                YatraChatMessage(
                  senderName: isMe ? 'You' : widget.title,
                  text: text,
                  time: _formatTime(DateTime.now()),
                  isCurrentUser: isMe,
                  avatarAsset: isMe ? _currentUserPic : widget.headerAvatarAsset,
                  readStatus: data['readStatus']?.toString() ?? 'sent',
                  messageId: data['_id']?.toString() ?? '',
                ),
              );
            });
          }
          _saveLocalMessages();
          _recordActiveConversation(text);
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      });

      _typingSub = _chatService.onTypingStatus.listen((data) {
        if (!mounted) return;
        if (data['userId']?.toString() == widget.targetUserId) {
          setState(() {
            _isTargetTyping = data['isTyping'] as bool? ?? false;
          });
        }
      });

      _readSub = _chatService.onReadReceipt.listen((data) {
        if (!mounted) return;
        setState(() {
          _messages = _messages.map((m) {
            if (m.isCurrentUser) {
              return YatraChatMessage(
                senderName: m.senderName,
                text: m.text,
                time: m.time,
                isCurrentUser: true,
                avatarAsset: m.avatarAsset,
                readStatus: 'read',
                messageId: m.messageId,
              );
            }
            return m;
          }).toList();
        });
      });

      _presenceSub = _chatService.onUserPresence.listen((data) {
        if (!mounted) return;
        final uId = data['userId']?.toString() ?? '';
        if (uId == widget.targetUserId) {
          final isOnline = data['isOnline'] == true || data['status'] == 'online';
          setState(() {
            _isTargetOnline = isOnline;
          });
        }
      });
      _chatService.checkUserPresence(widget.targetUserId);
    }

    _fetchMessages();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $ampm';
  }

  Future<void> _fetchMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty || widget.targetUserId.isEmpty) return;

      final isGroup = widget.chatType == YatraChatType.group;
      final apiMessages = isGroup
          ? await ApiService.getGroupMessages(token, 'mock_group_id')
          : await ApiService.getPersonalMessages(token, widget.targetUserId);

      if (apiMessages.isNotEmpty && mounted) {
        setState(() {
          _messages = apiMessages.map((m) => YatraChatMessage(
            senderName: (m['isCurrentUser'] == true) ? 'You' : (m['senderName'] ?? widget.title),
            text: m['content'] ?? m['text'] ?? '',
            time: m['time'] ?? 'Now',
            isCurrentUser: m['isCurrentUser'] ?? false,
            avatarAsset: m['avatarUrl'] ?? widget.headerAvatarAsset,
            readStatus: m['readStatus'] ?? 'sent',
          )).toList();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      debugPrint('Error fetching chat messages: $e');
    }
  }

  @override
  void dispose() {
    if (_chatService.currentActiveChatUserId == widget.targetUserId) {
      _chatService.currentActiveChatUserId = null;
    }
    _chatService.refreshUnreadCount();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _presenceSub?.cancel();
    _messageController.dispose();
    _chatSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _messages.add(
        YatraChatMessage(
          senderName: 'You',
          text: text,
          time: _formatTime(DateTime.now()),
          isCurrentUser: true,
          avatarAsset: _currentUserPic,
          readStatus: 'sent',
          tempId: tempId,
        ),
      );
    });

    _recordActiveConversation(text);
    _saveLocalMessages();

    if (widget.targetUserId.isNotEmpty) {
      _chatService.sendMessage(
        targetUserId: widget.targetUserId,
        content: text,
        yatraId: widget.yatraId,
        journeyId: widget.journeyId,
        tempId: tempId,
      );
    }

    _messageController.clear();
    _chatService.sendTypingIndicator(widget.targetUserId, false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _recordActiveConversation(String lastMessage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGroup = widget.chatType == YatraChatType.group;
      final key = isGroup ? 'active_yatra_groups' : 'active_personal_chats';
      final existingJson = prefs.getString(key);
      List<dynamic> list = existingJson != null ? jsonDecode(existingJson) : [];

      final id = isGroup
          ? (widget.yatraId.isNotEmpty ? widget.yatraId : widget.title)
          : (widget.targetUserId.isNotEmpty ? widget.targetUserId : widget.title);

      list.removeWhere((item) {
        if (item is Map) {
          final itemId = (isGroup ? item['_id'] : item['userId'])?.toString() ?? '';
          return itemId == id;
        }
        return false;
      });

      final now = DateTime.now();
      final timeStr = _formatTime(now);

      final newEntry = isGroup
          ? {
              '_id': id,
              'name': widget.title,
              'destination': widget.location.isNotEmpty ? widget.location : 'Pilgrimage Yatra',
              'memberCount': (widget.members?.length ?? 4),
              'lastMessage': lastMessage,
              'time': timeStr,
              'unread': 0,
              'avatar': widget.headerAvatarAsset ?? 'assets/images/somnath.png',
              'members': widget.members ?? [],
              'updatedAt': now.millisecondsSinceEpoch,
            }
          : {
              'userId': widget.targetUserId.isNotEmpty ? widget.targetUserId : id,
              'name': widget.title,
              'phoneNumber': widget.phoneNumber,
              'email': widget.email,
              'about': widget.about,
              'location': widget.location,
              'lastMessage': lastMessage,
              'time': timeStr,
              'unread': 0,
              'isOnline': _isTargetOnline,
              'avatar': widget.headerAvatarAsset ?? '',
              'updatedAt': now.millisecondsSinceEpoch,
            };

      list.insert(0, newEntry);
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint("Error recording conversation: $e");
    }
  }

  void _showContactProfileSheet(BuildContext context) {
    final isGroup = widget.chatType == YatraChatType.group;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF6EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Top drag bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    // Profile Header (Avatar, Name, Phone / Subtitle)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9500), Color(0xFFFF5500)],
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isGroup
                                  ? const Icon(Icons.groups_rounded, size: 50, color: Colors.white)
                                  : Text(
                                      widget.title.isNotEmpty ? widget.title[0].toUpperCase() : 'U',
                                      style: GoogleFonts.outfit(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGroup
                                ? (widget.groupMembersText ?? widget.subtitle)
                                : (widget.phoneNumber.isNotEmpty ? widget.phoneNumber : "+91 98765 43210"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick Action Buttons Row (WhatsApp Style)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionCircle(
                                icon: Icons.chat_rounded,
                                label: "Message",
                                onTap: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 24),
                              _buildActionCircle(
                                icon: Icons.share_rounded,
                                label: "Share",
                                onTap: () {
                                  Share.share(
                                    "Devotee Contact: ${widget.title} (${widget.phoneNumber.isNotEmpty ? widget.phoneNumber : '+91 98765 43210'})\nBharat Pray Yatra Sangha Network",
                                  );
                                },
                              ),
                              const SizedBox(width: 24),
                              _buildActionCircle(
                                icon: Icons.copy_rounded,
                                label: "Copy",
                                onTap: () {
                                  final num = widget.phoneNumber.isNotEmpty ? widget.phoneNumber : "+91 98765 43210";
                                  Clipboard.setData(ClipboardData(text: num));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Contact number copied to clipboard")),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // WhatsApp-Style Info Card: About & Phone
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEFE6DB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGroup ? "Group Description" : "About & Spiritual Bio",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isGroup
                                ? "Official Yatra Sangha group on Bharat Pray. Coordinates live darshan schedules, group prayers, and holy pilgrimage waypoints."
                                : (widget.about.isNotEmpty ? widget.about : "Jai Shree Ram! 🙏 Devoted to Mahadev, sacred Yatras & Mantra Japs."),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF2E2A36),
                              height: 1.4,
                            ),
                          ),
                          const Divider(height: 24, color: Color(0xFFEFE6DB)),
                          Text(
                            isGroup ? "Yatris in Group" : "Phone & Contact",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isGroup
                                    ? "${_groupMembers.length} Yatris in this Yatra Sangha"
                                    : (widget.phoneNumber.isNotEmpty ? widget.phoneNumber : "+91 98765 43210"),
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFFF7700)),
                                    onPressed: () {
                                      final num = widget.phoneNumber.isNotEmpty ? widget.phoneNumber : "+91 98765 43210";
                                      Clipboard.setData(ClipboardData(text: num));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Contact copied")),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (isGroup) ...[
                      const SizedBox(height: 14),
                      StatefulBuilder(
                        builder: (ctx, setMemberState) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFEFE6DB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Group Members (${_groupMembers.length})",
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2E2A36),
                                      ),
                                    ),
                                    if (_isUserAdmin)
                                      TextButton.icon(
                                        onPressed: () {
                                          _showAddMemberDialog(setMemberState);
                                        },
                                        icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFFFF7700)),
                                        label: Text(
                                          "+ Add Yatri",
                                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF7700)),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ..._groupMembers.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final m = entry.value;
                                  final mName = (m['name'] ?? m['fullName'] ?? 'Yatri').toString();
                                  final mPhone = (m['mobile'] ?? m['phoneNumber'] ?? m['phone'] ?? '').toString();
                                  final mPic = (m['profilePic'] ?? m['profile_pic'] ?? '').toString();
                                  final isAdmin = m['isAdmin'] == true || m['role'] == 'leader' || m['role'] == 'admin';
                                  final isSelf = idx == 0 || mName.contains('(You)') || mName.contains('Leader');

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 19,
                                          backgroundColor: const Color(0xFFFFE8D6),
                                          backgroundImage: mPic.isNotEmpty ? NetworkImage(ApiService.resolveImageUrl(mPic)) : null,
                                          child: mPic.isEmpty
                                              ? Text(
                                                  mName.isNotEmpty ? mName[0].toUpperCase() : 'Y',
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFFF7700), fontSize: 14),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mName,
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: const Color(0xFF2E2A36)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (mPhone.isNotEmpty)
                                                Text(
                                                  mPhone,
                                                  style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7A757F)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isAdmin)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "Admin",
                                              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488)),
                                            ),
                                          ),
                                        if (_isUserAdmin && !isSelf) ...[
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onSelected: (val) {
                                              if (val == 'toggle_admin') {
                                                setMemberState(() {
                                                  m['isAdmin'] = !isAdmin;
                                                });
                                                setState(() {});
                                                _persistGroupMembers();
                                                _sendAttachmentMessage(isAdmin ? "$mName is no longer Admin" : "$mName is now Group Admin");
                                              } else if (val == 'remove') {
                                                _confirmRemoveMember(m, setMemberState);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'toggle_admin',
                                                child: Text(isAdmin ? "Dismiss Admin" : "Make Group Admin", style: GoogleFonts.outfit(fontSize: 13)),
                                              ),
                                              PopupMenuItem(
                                                value: 'remove',
                                                child: Text("Remove from Group", style: GoogleFonts.outfit(fontSize: 13, color: Colors.redAccent)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),

                                const Divider(height: 20, color: Color(0xFFEFE6DB)),

                                // Leave Group & Delete Group Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFE8D2B8)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _handleLeaveGroup(),
                                        icon: const Icon(Icons.exit_to_app_rounded, size: 16, color: Color(0xFF8A5A36)),
                                        label: Text("Leave Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF8A5A36))),
                                      ),
                                    ),
                                    if (_isUserAdmin) ...[
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: () => _handleDeleteGroup(),
                                          icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
                                          label: Text("Delete Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Additional Info: Location / Devotion
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEFE6DB)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.temple_hindu_rounded, size: 18, color: Color(0xFFFF7700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Devotional Status",
                                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      isGroup ? "Active Yatra Sangha" : "Verified Yatri",
                                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Color(0xFFEFE6DB)),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF0D9488)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Location / Route",
                                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      widget.location.isNotEmpty ? widget.location : "Gujarat, India",
                                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEFE6DB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFFFF7700), size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }

  void _initiateCall({required bool isVideo}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DevoteeCallDialog(
        callerName: widget.title,
        avatarAsset: widget.headerAvatarAsset,
        isVideo: isVideo,
        onCallEnd: (duration) {
          final m = (duration.inSeconds ~/ 60).toString();
          final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
          final durStr = duration.inSeconds > 0 ? '$m:$s' : 'Missed';
          final callRecord = isVideo ? "📹 Video Call • $durStr" : "📞 Voice Call • $durStr";

          _sendAttachmentMessage(callRecord);
        },
      ),
    );
  }

  Future<void> _persistGroupMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'group_members_${widget.yatraId.isNotEmpty ? widget.yatraId : widget.title}';
      await prefs.setString(key, jsonEncode(_groupMembers));

      final rawGroups = prefs.getString('active_yatra_groups');
      if (rawGroups != null) {
        List<dynamic> groups = jsonDecode(rawGroups);
        final gid = widget.yatraId.isNotEmpty ? widget.yatraId : widget.title;
        for (var g in groups) {
          if (g is Map && g['_id'] == gid) {
            g['memberCount'] = _groupMembers.length;
            g['members'] = _groupMembers;
          }
        }
        await prefs.setString('active_yatra_groups', jsonEncode(groups));
      }
    } catch (e) {
      debugPrint("Error persisting group members: $e");
    }
  }

  void _showAddMemberDialog(StateSetter setMemberState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFFF7700)),
            const SizedBox(width: 8),
            Text("Add Yatri to Sangha", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter devotee's name or phone number:", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "e.g., Harish Patel",
                filled: true,
                fillColor: const Color(0xFFFBF6EF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF7700), width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            Text("Quick Suggestions:", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text("+ Ramesh Patel"),
                  onPressed: () => controller.text = "Ramesh Patel",
                ),
                ActionChip(
                  label: const Text("+ Geeta Ben"),
                  onPressed: () => controller.text = "Geeta Ben",
                ),
                ActionChip(
                  label: const Text("+ Bhavesh Shah"),
                  onPressed: () => controller.text = "Bhavesh Shah",
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newMember = {
                  'name': name,
                  'avatar': '',
                  'role': 'Yatri',
                  'isAdmin': false,
                  'phone': '+91 98*** *****',
                };
                setMemberState(() {
                  _groupMembers.add(newMember);
                });
                setState(() {});
                _persistGroupMembers();
                Navigator.pop(ctx);
                _sendAttachmentMessage("🙏 $name joined the Yatra Sangha group");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$name added to Yatra Sangha")),
                );
              }
            },
            child: Text("Add Yatri", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(Map<String, dynamic> member, StateSetter setMemberState) {
    final mName = member['name']?.toString() ?? 'Yatri';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Remove from Sangha?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove $mName from this Yatra group?", style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setMemberState(() {
                _groupMembers.removeWhere((m) => m['name'] == member['name']);
              });
              setState(() {});
              _persistGroupMembers();
              Navigator.pop(ctx);
              _sendAttachmentMessage("⚠️ $mName was removed from this group");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$mName removed from group")),
              );
            },
            child: Text("Remove", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLeaveGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Leave Yatra Group?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          _isUserAdmin && _groupMembers.where((m) => m['isAdmin'] == true && m['isSelf'] != true).isEmpty
              ? "You are the only admin of this Sangha. Please appoint another Yatri as admin before leaving, or the group will remain without an admin."
              : "Are you sure you want to leave this Yatra Sangha group? You won't receive future announcements.",
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close profile sheet
              // Remove self from members
              _groupMembers.removeWhere((m) => m['isSelf'] == true || m['name'] == 'You' || m['name'] == _currentUserName);
              await _persistGroupMembers();
              _sendAttachmentMessage("🚪 $_currentUserName left the Yatra Sangha");
              if (mounted) {
                Navigator.pop(context); // Exit chat screen
              }
            },
            child: Text("Leave Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text("Delete Yatra Group?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          ],
        ),
        content: Text(
          "This will permanently delete '${widget.title}' group, its message history, and remove all Yatris. This action cannot be undone.",
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close bottom sheet
              await _deleteChatPermanently();
            },
            child: Text("Delete Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Center Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8D2B8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFF7700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Start Sacred Chat",
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No messages yet. Send a holy greeting to begin:",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),

            // Greeting Options Under Badge
            Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildGreetingChip("🙏 Jai Shree Ram!"),
                _buildGreetingChip("🔱 Har Har Mahadev!"),
                _buildGreetingChip("Radhe Radhe! ✨"),
                _buildGreetingChip("🚩 Jai Badri Vishal"),
                _buildGreetingChip("🙏 Namaste"),
                _buildGreetingChip("🛕 Darshan timings?"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingChip(String text) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE8D2B8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      label: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2E2A36),
        ),
      ),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8D6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC79A65).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Share in Chat",
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentIconItem(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  color: const Color(0xFFE11D48),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final picker = ImagePicker();
                      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 85);
                      if (photo != null) {
                        _sendAttachmentMessage("📷 Photo", mediaPath: photo.path);
                      }
                    } catch (e) {
                      debugPrint("Camera error: $e");
                    }
                  },
                ),
                _buildAttachmentIconItem(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  color: const Color(0xFF8B5CF6),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                      if (img != null) {
                        _sendAttachmentMessage("📷 Photo", mediaPath: img.path);
                      }
                    } catch (e) {
                      debugPrint("Gallery error: $e");
                    }
                  },
                ),
                _buildAttachmentIconItem(
                  icon: Icons.description_rounded,
                  label: "Document",
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentSelectionScreen(
                          onDocumentSelected: (docName, docPath, docSize) {
                            _sendAttachmentMessage("📄 Document: $docName", mediaPath: docPath);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentIconItem(
                  icon: Icons.location_on_rounded,
                  label: "Location",
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    _showLocationSelectorSheet();
                  },
                ),
                _buildAttachmentIconItem(
                  icon: Icons.audiotrack_rounded,
                  label: "Audio",
                  color: const Color(0xFFFF7700),
                  onTap: () {
                    Navigator.pop(context);
                    _showAudioSelectorSheet();
                  },
                ),
                _buildAttachmentIconItem(
                  icon: Icons.person_pin_rounded,
                  label: "Contact",
                  color: const Color(0xFF0D9488),
                  onTap: () {
                    Navigator.pop(context);
                    _showContactShareSheet();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationSelectorSheet() async {
    String? liveLoc;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 4));
        liveLoc = "Current Live Location (${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E)";
      }
    } catch (e) {
      debugPrint("Geolocator location error: $e");
    }

    final locations = [
      if (liveLoc != null) liveLoc,
      "Somnath Jyotirlinga, Gujarat (20.8880° N, 70.4012° E)",
      "Kedarnath Dham, Uttarakhand (30.7346° N, 79.0669° E)",
      "Kashi Vishwanath Dham, Varanasi (25.3109° N, 83.0107° E)",
      "Mahakaleshwar Temple, Ujjain (23.1827° N, 75.7682° E)",
    ];

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8D6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC79A65).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Share Sacred Location",
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 12),
            ...locations.map((loc) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 24),
              ),
              title: Text(loc, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
              trailing: const Icon(Icons.send_rounded, color: Color(0xFFFF7700), size: 18),
              onTap: () {
                Navigator.pop(ctx);
                _sendAttachmentMessage("📍 Holy Location: $loc");
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAudioSelectorSheet() {
    final tracks = [
      {'title': 'Gayatri Mantra (108 Sacred Jap Chanting).mp3', 'duration': '5:24'},
      {'title': 'Mahamrityunjaya Mantra Chanting.mp3', 'duration': '4:48'},
      {'title': 'Om Namah Shivaya Sacred Dhun.mp3', 'duration': '6:12'},
      {'title': 'Shri Hanuman Chalisa (Sacred Chanting).mp3', 'duration': '8:30'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8D6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC79A65).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Share Sacred Audio",
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 12),
            ...tracks.map((t) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFF7700).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.audiotrack_rounded, color: Color(0xFFFF7700), size: 24),
              ),
              title: Text(t['title']!, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
              subtitle: Text("Audio • ${t['duration']}", style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A757F))),
              trailing: const Icon(Icons.send_rounded, color: Color(0xFFFF7700), size: 18),
              onTap: () {
                Navigator.pop(ctx);
                _sendAttachmentMessage("🎵 Sacred Audio: ${t['title']}");
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showContactShareSheet() {
    final contacts = [
      {'name': 'Krish Panchal', 'phone': '+91 98765 43210'},
      {'name': 'Ramesh Kumar (Yatri)', 'phone': '+91 98251 12345'},
      {'name': 'Suresh Sharma (Sangha)', 'phone': '+91 98252 67890'},
      {'name': 'Anita Verma (Devotee)', 'phone': '+91 98253 11223'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8D6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC79A65).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Share Devotee Contact",
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 12),
            ...contacts.map((c) => ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0D9488),
                radius: 18,
                child: Text(c['name']![0], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(c['name']!, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
              subtitle: Text(c['phone']!, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A757F))),
              trailing: const Icon(Icons.send_rounded, color: Color(0xFFFF7700), size: 18),
              onTap: () {
                Navigator.pop(ctx);
                _sendAttachmentMessage("👤 Contact Card: ${c['name']} (${c['phone']})");
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecordSheet() {
    int recordSeconds = 0;
    Timer? recordTimer;
    bool isCancelled = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            recordTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (!isCancelled && mounted) {
                setSheetState(() {
                  recordSeconds++;
                });
              }
            });

            final secStr = (recordSeconds % 60).toString().padLeft(2, '0');
            final minStr = (recordSeconds ~/ 60).toString().padLeft(2, '0');

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8D6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC79A65).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Recording Voice Note... $minStr:$secStr",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(16, (i) {
                      final h = 10.0 + ((i * 7 + recordSeconds * 9) % 26);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 4,
                        height: h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7700),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          isCancelled = true;
                          recordTimer?.cancel();
                          Navigator.pop(sheetCtx);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                        label: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7700),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          isCancelled = true;
                          recordTimer?.cancel();
                          Navigator.pop(sheetCtx);
                          final dur = recordSeconds > 0 ? '$minStr:$secStr' : '0:05';
                          _sendAttachmentMessage("🎤 Voice Note ($dur)");
                        },
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        label: Text("Send", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttachmentIconItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }

  void _sendAttachmentMessage(String content, {String? mediaPath}) {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMsg = YatraChatMessage(
      senderName: 'You',
      text: content,
      time: _formatTime(DateTime.now()),
      isCurrentUser: true,
      avatarAsset: _currentUserPic,
      readStatus: 'sent',
      tempId: tempId,
      mediaPath: mediaPath,
    );

    setState(() {
      _messages.add(newMsg);
    });

    _recordActiveConversation(content);
    _saveLocalMessages();

    if (widget.targetUserId.isNotEmpty) {
      _chatService.sendMessage(
        targetUserId: widget.targetUserId,
        content: content,
        yatraId: widget.yatraId,
        journeyId: widget.journeyId,
        tempId: tempId,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleVoiceRecord() {
    _showVoiceRecordSheet();
  }

  void _onMessageLongPress(YatraChatMessage message, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8D6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC79A65).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // 1. WhatsApp-Style Emoji Reaction Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE8D2B8)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['🙏', '🔱', '🕉️', '❤️', '👍', '😂', '😮'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        message.reaction = (message.reaction == emoji) ? '' : emoji;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Action Options
            ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8D2B8)),
                ),
                child: const Icon(Icons.copy_rounded, color: Color(0xFF2E2A36), size: 18),
              ),
              title: Text("Copy Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: const Color(0xFF2E2A36))),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Message copied to clipboard"), duration: Duration(seconds: 2)),
                );
              },
            ),

            if (message.isCurrentUser && !message.isDeleted) ...[
              const Divider(height: 1, color: Color(0xFFE8D2B8)),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8D2B8)),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFFFF7700), size: 18),
                ),
                title: Text("Edit Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: const Color(0xFF2E2A36))),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(message);
                },
              ),
            ],

            const Divider(height: 1, color: Color(0xFFE8D2B8)),
            ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8D2B8)),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              ),
              title: Text("Delete Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteOptionsDialog(message, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(YatraChatMessage message) {
    final editController = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Edit Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF2E2A36))),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: GoogleFonts.outfit(fontSize: 14.5, color: const Color(0xFF2E2A36)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  message.text = newText;
                  message.isEdited = true;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Save", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteOptionsDialog(YatraChatMessage message, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete message?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E2A36))),
        content: Text(
          "Choose how you want to delete this message:",
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.75)),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          // 1. Delete for Everyone
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                message.isDeleted = true;
                message.text = message.isCurrentUser ? "🚫 You deleted this message" : "🚫 This message was deleted";
              });
            },
            child: Text(
              "Delete for Everyone",
              style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
          // 2. Delete for Me
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.removeAt(index);
              });
            },
            child: Text(
              "Delete for Me",
              style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontWeight: FontWeight.bold),
            ),
          ),
          // 3. Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Clear this chat?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E2A36))),
        content: Text(
          "All messages in this conversation will be permanently removed.",
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChatPermanently();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Chat cleared", style: GoogleFonts.outfit()),
                    backgroundColor: const Color(0xFFFF7700),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Clear Chat", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete this chat?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E2A36))),
        content: Text(
          "All messages and conversation history will be permanently deleted.",
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChatPermanently();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Delete Chat", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showGroupHeader = widget.chatType == YatraChatType.group;
    final displayedMessages = _chatSearchQuery.isEmpty
        ? _messages
        : _messages.where((m) => m.text.toLowerCase().contains(_chatSearchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Search mode vs Standard WhatsApp mode
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _isSearching = false;
                        _chatSearchQuery = '';
                        _chatSearchController.clear();
                      }),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _bubbleBorderColor, width: 1),
                        ),
                        child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF2E2A36)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: _bubbleBorderColor),
                        ),
                        child: TextField(
                          controller: _chatSearchController,
                          autofocus: true,
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                          decoration: InputDecoration(
                            hintText: "Search in messages...",
                            hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _chatSearchQuery = val.trim()),
                        ),
                      ),
                    ),
                    if (_chatSearchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                        onPressed: () {
                          _chatSearchController.clear();
                          setState(() => _chatSearchQuery = '');
                        },
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _bubbleBorderColor, width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Color(0xFF2E2A36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // WhatsApp style clickable header area: Avatar + Title + Status -> opens Profile & Contact Info
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showContactProfileSheet(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _bubbleBorderColor, width: 1),
                              ),
                              child: ClipOval(
                                child: showGroupHeader
                                    ? Container(
                                        color: Colors.white,
                                        child: const Icon(
                                          Icons.groups_rounded,
                                          color: Color(0xFFFF7700),
                                          size: 26,
                                        ),
                                      )
                                    : (widget.headerAvatarAsset != null && widget.headerAvatarAsset!.startsWith('http')
                                        ? Image.network(
                                            widget.headerAvatarAsset!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const ColoredBox(
                                              color: Color(0xFFFFE8D6),
                                            ),
                                          )
                                        : Image.asset(
                                            widget.headerAvatarAsset ?? 'assets/images/deity_shiva.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const ColoredBox(
                                              color: Color(0xFFFFE8D6),
                                            ),
                                          )),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2E2A36),
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _isTargetTyping
                                        ? 'Typing...'
                                        : (showGroupHeader
                                            ? (widget.groupMembersText ?? widget.subtitle)
                                            : (_isTargetOnline ? "Online" : "Offline")),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: _isTargetTyping
                                          ? const Color(0xFF2E8A3A)
                                          : (_isTargetOnline ? const Color(0xFF10B981) : _subtitleColor),
                                      fontSize: 12,
                                      fontWeight: (_isTargetTyping || _isTargetOnline) ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Video Call Button
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded, color: Color(0xFFFF7700), size: 24),
                      tooltip: "Video Call",
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _initiateCall(isVideo: true),
                    ),
                    const SizedBox(width: 2),

                    // Top Audio Call Button
                    IconButton(
                      icon: const Icon(Icons.call_rounded, color: Color(0xFFFF7700), size: 21),
                      tooltip: "Audio Call",
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _initiateCall(isVideo: false),
                    ),

                    // Top 3 Dots Menu Button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF2E2A36), size: 22),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) {
                        if (val == 'search') {
                          setState(() => _isSearching = true);
                        } else if (val == 'clear') {
                          _showClearChatConfirmation();
                        } else if (val == 'delete') {
                          _showDeleteChatConfirmation();
                        } else if (val == 'contact') {
                          _showContactProfileSheet(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'search',
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 20, color: Color(0xFFFF7700)),
                              const SizedBox(width: 10),
                              Text('Search', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36))),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.redAccent),
                              const SizedBox(width: 10),
                              Text('Clear all chat', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.redAccent),
                              const SizedBox(width: 10),
                              Text('Delete chat', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'contact',
                          child: Row(
                            children: [
                              const Icon(Icons.account_circle_outlined, size: 20, color: Color(0xFF2E2A36)),
                              const SizedBox(width: 10),
                              Text(widget.chatType == YatraChatType.group ? 'Group info' : 'View contact', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Expanded(
              child: displayedMessages.isEmpty
                  ? (_chatSearchQuery.isNotEmpty
                      ? Center(
                          child: Text(
                            "No matching messages found",
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        )
                      : _buildEmptyState())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      itemCount: displayedMessages.length,
                      itemBuilder: (context, index) {
                        final message = displayedMessages[index];
                        final originalIndex = _messages.indexOf(message);
                        return _ChatBubble(
                          message: message,
                          leftBubbleColor: _leftBubbleColor,
                          rightBubbleColor: _rightBubbleColor,
                          borderColor: _bubbleBorderColor,
                          messageColor: _messageColor,
                          useLightTheme: _isLightTheme,
                          fallbackAvatarAsset: widget.headerAvatarAsset,
                          currentUserPic: _currentUserPic,
                          currentUserName: _currentUserName,
                          senderColor: _senderColor(index),
                          onLongPress: () => _onMessageLongPress(message, originalIndex != -1 ? originalIndex : index),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _inputBorderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded, color: Color(0xFFFF7700), size: 22),
                            onPressed: _showAttachmentOptions,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: "Attach Media, Location, Document or Audio",
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: (val) {
                                setState(() {});
                                if (widget.targetUserId.isNotEmpty) {
                                  _chatService.sendTypingIndicator(widget.targetUserId, val.trim().isNotEmpty);
                                }
                              },
                              style: GoogleFonts.outfit(
                                color: _messageColor,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Type message here...',
                                hintStyle: GoogleFonts.outfit(
                                  color: _inputHintColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _messageController.text.trim().isEmpty ? _handleVoiceRecord : _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7700).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _messageController.text.trim().isEmpty ? Icons.mic_rounded : Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _senderColor(int index) {
    if (_messages[index].isCurrentUser) return const Color(0xFF0088FF);
    final palette = <Color>[
      const Color(0xFF2ECC40),
      const Color(0xFFFFB000),
      const Color(0xFFFF3B30),
    ];
    return palette[index % palette.length];
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.leftBubbleColor,
    required this.rightBubbleColor,
    required this.borderColor,
    required this.messageColor,
    required this.useLightTheme,
    required this.fallbackAvatarAsset,
    required this.senderColor,
    this.currentUserPic = '',
    this.currentUserName = 'You',
    this.onLongPress,
  });

  final YatraChatMessage message;
  final Color leftBubbleColor;
  final Color rightBubbleColor;
  final Color borderColor;
  final Color messageColor;
  final bool useLightTheme;
  final String? fallbackAvatarAsset;
  final Color senderColor;
  final String currentUserPic;
  final String currentUserName;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isCurrentUser;
    final isDeleted = message.isDeleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(
              imageSource: (message.avatarAsset != null && message.avatarAsset!.isNotEmpty)
                  ? message.avatarAsset
                  : fallbackAvatarAsset,
              senderName: message.senderName,
              lightTheme: useLightTheme,
              isMe: false,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: BoxDecoration(
                      color: isMe ? rightBubbleColor : leftBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMe ? 14 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 14),
                      ),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          Text(
                            message.senderName,
                            style: GoogleFonts.outfit(
                              color: senderColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        _buildBubbleBody(context, isDeleted ? Colors.grey[600]! : messageColor, isDeleted),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.isEdited && !isDeleted) ...[
                              Text(
                                "edited • ",
                                style: GoogleFonts.outfit(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            Text(
                              message.time,
                              style: GoogleFonts.outfit(
                                color: useLightTheme
                                    ? const Color(0xFF7A757F)
                                    : const Color(0xFFCFCFCF),
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (isMe && !isDeleted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.readStatus == 'read' ? Icons.done_all_rounded : Icons.done_rounded,
                                size: 13,
                                color: message.readStatus == 'read' ? const Color(0xFF0088FF) : const Color(0xFF8E8E93),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating Reaction Emoji badge
                  if (message.reaction.isNotEmpty)
                    Positioned(
                      bottom: -8,
                      right: isMe ? 6 : null,
                      left: isMe ? null : 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8D2B8), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message.reaction,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _Avatar(
              imageSource: (message.avatarAsset != null && message.avatarAsset!.isNotEmpty)
                  ? message.avatarAsset
                  : currentUserPic,
              senderName: currentUserName,
              lightTheme: useLightTheme,
              isMe: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubbleBody(BuildContext context, Color messageColor, bool isDeleted) {
    final isMe = message.isCurrentUser;
    if (isDeleted) {
      return Text(
        message.text,
        style: GoogleFonts.outfit(
          color: Colors.grey[600],
          fontSize: 13.5,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final text = message.text;

    // 1. Photo message
    if (message.mediaPath != null && message.mediaPath!.isNotEmpty) {
      final hasCustomCaption = text.isNotEmpty &&
          text != "📷 Photo" &&
          !text.startsWith("📷 Photo:") &&
          !text.startsWith("🖼️ Photo:");

      return GestureDetector(
        onTap: () {
          final file = File(message.mediaPath!);
          if (file.existsSync()) {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(file, fit: BoxFit.contain),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: File(message.mediaPath!).existsSync()
                  ? Image.file(
                      File(message.mediaPath!),
                      width: 220,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 220,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
                    ),
            ),
            if (hasCustomCaption) ...[
              const SizedBox(height: 6),
              Text(
                text,
                style: GoogleFonts.outfit(color: messageColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      );
    }

    if (text.startsWith("📷 Photo:") || text.startsWith("🖼️ Photo:")) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_rounded, size: 20, color: Color(0xFFFF7700)),
          const SizedBox(width: 6),
          Text(
            "Photo",
            style: GoogleFonts.outfit(color: messageColor, fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    // 2. Voice Note
    if (text.startsWith("🎤 Voice Note")) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFFF7700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: isMe ? Colors.white : const Color(0xFFFF7700),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(12, (i) {
                    final heights = [8.0, 14.0, 20.0, 10.0, 16.0, 22.0, 12.0, 18.0, 20.0, 10.0, 15.0, 8.0];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 2.8,
                      height: heights[i % heights.length],
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withValues(alpha: 0.85) : const Color(0xFFC79A65),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: GoogleFonts.outfit(color: messageColor, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 3. Location Pin
    if (text.startsWith("📍 Holy Location:")) {
      final locTitle = text.replaceFirst("📍 Holy Location:", "").trim();
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isMe ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFBBF7D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilgrimage Waypoint", style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  Text(locTitle, style: GoogleFonts.outfit(fontSize: 12.5, color: messageColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4. Document
    if (text.startsWith("📄 Document:")) {
      final docName = text.replaceFirst("📄 Document:", "").trim();
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFFFBF6EF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text("Document Viewer", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(docName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("Format: PDF Document • Verified", style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text("This document was shared in your sacred Bharat Pray Yatra chat.", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Close", style: GoogleFonts.outfit(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share("Document from Bharat Pray Yatra: $docName");
                  },
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text("Share Document", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isMe ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(docName, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: messageColor)),
                    Text("Sacred Document • PDF (Tap to open)", style: GoogleFonts.outfit(fontSize: 10.5, color: messageColor.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 5. Sacred Audio
    if (text.startsWith("🎵 Sacred Audio:")) {
      final audioTitle = text.replaceFirst("🎵 Sacred Audio:", "").trim();
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isMe ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFFED7AA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(audioTitle, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: messageColor)),
                  Text("Devotional Audio Track", style: GoogleFonts.outfit(fontSize: 10.5, color: messageColor.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 6. Contact Card
    if (text.startsWith("👤 Contact Card:")) {
      final contactInfo = text.replaceFirst("👤 Contact Card:", "").trim();
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isMe ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF99F6E4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Devotee Contact", style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                  Text(contactInfo, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: messageColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 7. Call Log
    if (text.contains("Voice Call •") || text.contains("Video Call •")) {
      final isVid = text.contains("Video Call");
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVid ? Icons.videocam_rounded : Icons.call_rounded,
              color: isMe ? Colors.white : const Color(0xFFFF7700),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: messageColor,
              ),
            ),
          ],
        ),
      );
    }

    // Default regular message
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: messageColor,
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageSource,
    required this.senderName,
    required this.lightTheme,
    required this.isMe,
  });

  final String? imageSource;
  final String senderName;
  final bool lightTheme;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final src = (imageSource ?? '').trim();
    final resolvedUrl = src.isNotEmpty ? ApiService.resolveImageUrl(src) : '';
    final initial = senderName.trim().isNotEmpty ? senderName.trim()[0].toUpperCase() : (isMe ? 'Y' : 'P');

    Widget fallbackInitial() => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isMe
                  ? [const Color(0xFFFF9500), const Color(0xFFFF5500)]
                  : [const Color(0xFFC79A65), const Color(0xFF916A40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

    Widget imageWidget;
    if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
      imageWidget = Image.network(
        resolvedUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallbackInitial(),
      );
    } else if (src.startsWith('assets/')) {
      imageWidget = Image.asset(
        src,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallbackInitial(),
      );
    } else {
      imageWidget = fallbackInitial();
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isMe ? const Color(0xFFFF9500) : (lightTheme ? const Color(0xFFCFA87B) : const Color(0xFFB1885A)),
          width: 1.5,
        ),
      ),
      child: ClipOval(child: imageWidget),
    );
  }
}

class DevoteeCallDialog extends StatefulWidget {
  final String callerName;
  final String? avatarAsset;
  final bool isVideo;
  final Function(Duration callDuration) onCallEnd;

  const DevoteeCallDialog({
    super.key,
    required this.callerName,
    this.avatarAsset,
    required this.isVideo,
    required this.onCallEnd,
  });

  @override
  State<DevoteeCallDialog> createState() => _DevoteeCallDialogState();
}

class _DevoteeCallDialogState extends State<DevoteeCallDialog> {
  String _status = "Calling...";
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    // Simulate real call lifecycle: Calling -> Ringing -> Connected
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _status = "Ringing...");
      }
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _status = "Connected");
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _endCall() {
    _timer?.cancel();
    widget.onCallEnd(Duration(seconds: _seconds));
    Navigator.of(context).pop();
  }

  String _formatDuration(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B2E), Color(0xFF2A1F3D), Color(0xFF161224)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Call Type Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: const Color(0xFFFF9500),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isVideo ? "BHARAT PRAY VIDEO" : "BHARAT PRAY AUDIO",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: const Color(0xFFFF9500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Caller Avatar with pulsing devotional halo
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.3), width: 3),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9500), Color(0xFFFF5500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : 'Y',
                      style: GoogleFonts.outfit(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Caller Name
            Text(
              widget.callerName,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Call Status / Elapsed Timer
            Text(
              _status == "Connected" ? _formatDuration(_seconds) : _status,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: _status == "Connected" ? FontWeight.w600 : FontWeight.w400,
                color: _status == "Connected" ? const Color(0xFF10B981) : Colors.white70,
                letterSpacing: _status == "Connected" ? 1.2 : 0.5,
              ),
            ),

            const SizedBox(height: 36),

            // Interactive Call Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Mic Toggle
                InkWell(
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isMuted ? Colors.white : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _isMuted ? Colors.black87 : Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Speaker Toggle
                InkWell(
                  onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isSpeaker ? Colors.white : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      color: _isSpeaker ? Colors.black87 : Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Video toggle if video call
                if (widget.isVideo) ...[
                  InkWell(
                    onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isVideoOff ? Colors.white : Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        color: _isVideoOff ? Colors.black87 : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // Red End Call Button
            InkWell(
              onTap: _endCall,
              borderRadius: BorderRadius.circular(36),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

