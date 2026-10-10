import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/yatra_personal_chat_service.dart';
import '../yatra_group/contact_sync_screen.dart';
import 'yatra_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'All'; // 'All', 'Personal', 'Yatra Groups'
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _yatraGroups = [];
  List<Map<String, dynamic>> _personalChats = [];

  final List<String> _tabs = ['All', 'Personal', 'Yatra Groups'];

  final YatraPersonalChatService _chatService = YatraPersonalChatService();
  final Set<String> _onlineUserIds = {};
  StreamSubscription? _presenceSub;
  StreamSubscription? _onlineListSub;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _fetchChatsAndGroups();
  }

  void _setupSocketListeners() {
    _presenceSub = _chatService.onUserPresence.listen((data) {
      final userId = data['userId']?.toString() ?? '';
      final isOnline = data['isOnline'] == true || data['status'] == 'online';
      if (userId.isNotEmpty && mounted) {
        setState(() {
          if (isOnline) {
            _onlineUserIds.add(userId);
          } else {
            _onlineUserIds.remove(userId);
          }
        });
      }
    });

    _onlineListSub = _chatService.onOnlineUsersList.listen((list) {
      if (mounted) {
        setState(() {
          _onlineUserIds.addAll(list);
        });
      }
    });

    _messageSub = _chatService.onNewMessage.listen((data) {
      if (!mounted) return;
      final senderId = data['senderId']?.toString() ?? '';
      final content = data['content']?.toString() ?? '';
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute.toString().padLeft(2, '0');
      final ampm = now.hour >= 12 ? 'pm' : 'am';
      final timeStr = '$hour:$minute $ampm';

      final idx = _personalChats.indexWhere((c) =>
        (c['userId']?.toString() == senderId) || (c['id']?.toString() == senderId)
      );

      if (idx != -1) {
        setState(() {
          final chat = Map<String, dynamic>.from(_personalChats[idx]);
          chat['lastMessage'] = content;
          chat['time'] = timeStr;
          _personalChats.removeAt(idx);
          _personalChats.insert(0, chat);
        });
      }
    });
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    _onlineListSub?.cancel();
    _messageSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChatsAndGroups() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Initialize socket and query live online devotees
      if (token.isNotEmpty) {
        _chatService.init(token);
        _chatService.getOnlineUsers();
      }

      // 1. Fetch user's yatra groups from API
      List<Map<String, dynamic>> groups = [];
      if (token.isNotEmpty) {
        try {
          final res = await ApiService.getMyYatraGroups(token);
          if (res is List) {
            groups = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        } catch (e) {
          debugPrint("Failed to fetch yatra groups: $e");
        }
      }

      // Merge locally created groups from SharedPreferences
      final localGroupsStr = prefs.getString('active_yatra_groups');
      if (localGroupsStr != null && localGroupsStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(localGroupsStr) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final id = map['_id']?.toString() ?? '';
              if (id.isNotEmpty && !groups.any((g) => g['_id']?.toString() == id)) {
                groups.add(map);
              }
            }
          }
        } catch (e) {
          debugPrint("Error parsing active_yatra_groups: $e");
        }
      }

      // 2. Personal 1-on-1 chats: fetch from API and merge with SharedPreferences
      List<Map<String, dynamic>> personal = [];
      if (token.isNotEmpty) {
        try {
          final apiConvs = await ApiService.getPersonalConversations(token);
          for (final c in apiConvs) {
            if (c is Map) {
              personal.add(Map<String, dynamic>.from(c));
            }
          }
        } catch (e) {
          debugPrint("Failed to fetch personal conversations from API: $e");
        }
      }

      final localPersonalStr = prefs.getString('active_personal_chats');
      if (localPersonalStr != null && localPersonalStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(localPersonalStr) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final uId = (map['userId'] ?? map['id'] ?? '').toString();
              if (uId.isNotEmpty) {
                final existingIdx = personal.indexWhere((p) => (p['userId'] ?? p['id'] ?? '').toString() == uId);
                if (existingIdx == -1) {
                  personal.add(map);
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Error parsing active_personal_chats: $e");
        }
      }

      if (mounted) {
        setState(() {
          _yatraGroups = groups;
          _personalChats = personal;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching chats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareWhatsAppInvite() {
    Share.share(
      "🙏 Jai Shree Ram!\n\n"
      "Join me on Bharat Pray - The Sacred Devotional App for Live Temple Darshans, Holy Yatras, Sangha Groups & Mantra Japs.\n\n"
      "Download now & connect with our Yatra Sangha: https://bharatpray.com/download",
    );
  }

  void _openContactSync() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactSyncScreen(
          selectedMembers: [],
          isGroupCreation: false,
        ),
      ),
    ).then((_) => _fetchChatsAndGroups());
  }

  void _openGroupChat(Map<String, dynamic> group) {
    final name = group['name']?.toString() ?? 'Yatra Group';
    final groupId = group['_id']?.toString() ?? '';
    final membersList = group['members'] is List ? (group['members'] as List) : null;
    final membersCount = group['memberCount'] ?? (membersList?.length ?? 4);
    final destination = group['destination']?.toString() ?? 'Holy Pilgrimage';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YatraChatScreen(
          chatType: YatraChatType.group,
          title: name,
          subtitle: "$membersCount Yatris active",
          headerAvatarAsset: group['avatar']?.toString() ?? 'assets/images/somnath.png',
          yatraId: groupId,
          members: membersList,
          groupMembersText: "$membersCount Yatris in this Yatra Sangha",
          about: "Official Yatra Sangha group for $destination. Co-yatri updates and prayer coordination.",
          location: destination,
          messages: const [],
        ),
      ),
    ).then((_) => _fetchChatsAndGroups());
  }

  void _openPersonalChat(Map<String, dynamic> chat) {
    final name = chat['name']?.toString() ?? 'Devotee';
    final userId = (chat['userId'] ?? chat['id'] ?? '').toString();
    final isOnline = _onlineUserIds.contains(userId);
    final phone = chat['phoneNumber']?.toString() ?? '+91 98765 43210';
    final email = chat['email']?.toString() ?? '';
    final about = chat['about']?.toString() ?? '';
    final location = chat['location']?.toString() ?? 'Gujarat, India';

    if (userId.isNotEmpty) {
      _chatService.markChatAsRead(userId);
      setState(() {
        chat['unread'] = 0;
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YatraChatScreen(
          chatType: YatraChatType.single,
          title: name,
          subtitle: isOnline ? "Online" : "Offline",
          targetUserId: userId,
          phoneNumber: phone,
          email: email,
          about: about,
          location: location,
          messages: const [],
        ),
      ),
    ).then((_) {
      _chatService.refreshUnreadCount();
      _fetchChatsAndGroups();
    });
  }

  Future<void> _persistActiveConversations(bool isGroup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isGroup) {
        await prefs.setString('active_yatra_groups', jsonEncode(_yatraGroups));
      } else {
        await prefs.setString('active_personal_chats', jsonEncode(_personalChats));
      }
    } catch (e) {
      debugPrint("Error persisting conversations: $e");
    }
  }

  void _showChatOptionsBottomSheet(Map<String, dynamic> item, {required bool isGroup}) {
    final name = (item['name'] ?? (isGroup ? 'Yatra Sangha' : 'Devotee')).toString();
    final isMuted = item['isMuted'] == true;
    final unread = (item['unread'] ?? 0) as int;
    final id = isGroup ? (item['_id']?.toString() ?? '') : (item['userId'] ?? item['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isGroup ? "Yatra Group" : "Yatri Chat",
                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFFFF7700), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE8D2B8)),
            const SizedBox(height: 6),

            // 1. Mark as Read / Unread
            _buildOptionTile(
              icon: unread > 0 ? Icons.mark_chat_read_rounded : Icons.mark_chat_unread_rounded,
              title: unread > 0 ? "Mark as Read" : "Mark as Unread",
              color: const Color(0xFF2E2A36),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  item['unread'] = unread > 0 ? 0 : 1;
                });
                _persistActiveConversations(isGroup);
                if (unread == 0 && id.isNotEmpty) {
                  _chatService.unreadMessageCount.value = (_chatService.unreadMessageCount.value + 1);
                } else if (unread > 0 && id.isNotEmpty) {
                  _chatService.markChatAsRead(id);
                }
              },
            ),

            // 2. Mute / Unmute Notifications
            _buildOptionTile(
              icon: isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              title: isMuted ? "Unmute Notifications" : "Mute Notifications",
              color: const Color(0xFF2E2A36),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  item['isMuted'] = !isMuted;
                });
                _persistActiveConversations(isGroup);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMuted ? "Notifications unmuted for $name" : "Notifications muted for $name"),
                    backgroundColor: const Color(0xFFFF7700),
                  ),
                );
              },
            ),

            // 3. Archive Chat
            _buildOptionTile(
              icon: Icons.archive_rounded,
              title: "Archive Chat",
              color: const Color(0xFF2E2A36),
              onTap: () async {
                Navigator.pop(ctx);
                final prefs = await SharedPreferences.getInstance();
                final archiveKey = isGroup ? 'archived_groups' : 'archived_personal_chats';
                final existArchiveStr = prefs.getString(archiveKey);
                List<dynamic> archList = existArchiveStr != null ? jsonDecode(existArchiveStr) : [];
                archList.insert(0, item);
                await prefs.setString(archiveKey, jsonEncode(archList));

                setState(() {
                  if (isGroup) {
                    _yatraGroups.removeWhere((g) => g['_id']?.toString() == id);
                  } else {
                    _personalChats.removeWhere((p) => ((p['userId'] ?? p['id'])?.toString() == id));
                  }
                });
                await _persistActiveConversations(isGroup);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Chat with $name moved to Archive"),
                      backgroundColor: const Color(0xFFFF7700),
                    ),
                  );
                }
              },
            ),

            // 4. Block Contact / Leave Group
            if (!isGroup)
              _buildOptionTile(
                icon: Icons.block_rounded,
                title: "Block $name",
                color: const Color(0xFF8A5A36),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBlockContact(item);
                },
              )
            else
              _buildOptionTile(
                icon: Icons.exit_to_app_rounded,
                title: "Exit Yatra Group",
                color: const Color(0xFF8A5A36),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmExitGroup(item);
                },
              ),

            // 5. Delete Chat
            _buildOptionTile(
              icon: Icons.delete_forever_rounded,
              title: "Delete Chat",
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteChat(item, isGroup: isGroup);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(Map<String, dynamic> item, {required bool isGroup}) {
    final name = (item['name'] ?? (isGroup ? 'Group' : 'Devotee')).toString();
    final id = isGroup ? (item['_id']?.toString() ?? '') : (item['userId'] ?? item['id'] ?? '').toString();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete Chat?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E2A36))),
        content: Text(
          "Are you sure you want to delete this conversation with $name? All messages will be permanently removed.",
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final prefs = await SharedPreferences.getInstance();

              if (id.isNotEmpty) {
                await prefs.remove('local_chat_msgs_$id');
              }

              setState(() {
                if (isGroup) {
                  _yatraGroups.removeWhere((g) => g['_id']?.toString() == id);
                } else {
                  _personalChats.removeWhere((p) => ((p['userId'] ?? p['id'])?.toString() == id));
                }
              });

              await _persistActiveConversations(isGroup);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Chat with $name deleted"),
                    backgroundColor: const Color(0xFFFF7700),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Delete", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmBlockContact(Map<String, dynamic> item) {
    final name = (item['name'] ?? 'Devotee').toString();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Block $name?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E2A36))),
        content: Text(
          "Blocked devotees will no longer be able to message or call you on Bharat Pray.",
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name blocked"),
                  backgroundColor: const Color(0xFFFF7700),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Block", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmExitGroup(Map<String, dynamic> item) {
    final name = (item['name'] ?? 'Yatra Sangha').toString();
    final id = item['_id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Exit $name?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E2A36))),
        content: Text(
          "You will no longer receive pilgrimage updates from this Yatra Sangha group.",
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              setState(() {
                _yatraGroups.removeWhere((g) => g['_id']?.toString() == id);
              });
              await _persistActiveConversations(true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Left $name"),
                    backgroundColor: const Color(0xFFFF7700),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Exit Group", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _yatraGroups.where((g) {
      final name = (g['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredPersonal = _personalChats.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D6),
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8D2B8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF2E2A36)),
            ),
          ),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        actions: [
          // WhatsApp Invite Action
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFFFF7700), size: 21),
            tooltip: "Invite on WhatsApp",
            onPressed: _shareWhatsAppInvite,
          ),
          // Sync Contacts Action
          IconButton(
            icon: const Icon(Icons.contacts_rounded, color: Color(0xFF2E2A36), size: 21),
            tooltip: "Contacts",
            onPressed: _openContactSync,
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF7700),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: _openContactSync,
        child: const Icon(Icons.chat_rounded, size: 24),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8D2B8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFFA88B6A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF2E2A36)),
                      decoration: InputDecoration(
                        hintText: "Search chats, groups, or yatris...",
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),

          // WhatsApp Style Filter Tabs Row
          _buildTabsRow(),

          // Chat List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
                : RefreshIndicator(
                    color: const Color(0xFFFF7700),
                    onRefresh: _fetchChatsAndGroups,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      children: [
                        // Personal Chats Section
                        if (_selectedTab == 'All' || _selectedTab == 'Personal') ...[
                          if (filteredPersonal.isNotEmpty) ...[
                            ...filteredPersonal.map((p) => _buildPersonalChatTile(p)),
                          ],
                        ],

                        // Yatra Group Chats Section
                        if (_selectedTab == 'All' || _selectedTab == 'Yatra Groups') ...[
                          if (filteredGroups.isNotEmpty) ...[
                            ...filteredGroups.map((g) => _buildGroupChatTile(g)),
                          ],
                        ],

                        if (filteredPersonal.isEmpty && filteredGroups.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 32, color: Color(0xFFFF7700)),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "No conversations yet",
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Connect with yatris or create a Yatra Sangha group to start chatting.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7A757F)),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _openContactSync,
                                    icon: const Icon(Icons.person_search_rounded, size: 16, color: Colors.white),
                                    label: Text("Find Yatris", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF7700),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // WhatsApp Invite Banner
                        const SizedBox(height: 12),
                        _buildWhatsAppInviteBanner(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _selectedTab == tab;

          return InkWell(
            onTap: () => setState(() => _selectedTab = tab),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7700) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF7700) : const Color(0xFFE8D2B8),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  tab,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF6B4226),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupChatTile(Map<String, dynamic> group) {
    final name = group['name']?.toString() ?? 'Yatra Sangha Group';
    final rawLastMsg = (group['lastMessage'] ?? '').toString();
    final lastMsg = rawLastMsg.isNotEmpty ? rawLastMsg : 'No messages yet';
    final hasNoMsg = rawLastMsg.isEmpty;
    final time = group['time']?.toString() ?? 'Active';
    final unread = group['unread'] is int ? group['unread'] as int : 0;
    final isMuted = group['isMuted'] == true;
    final membersCount = group['memberCount'] ?? (group['members'] is List ? (group['members'] as List).length : 4);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D2B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openGroupChat(group),
        onLongPress: () => _showChatOptionsBottomSheet(group, isGroup: true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(Icons.groups_rounded, color: Color(0xFFFF7700), size: 26),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.explore_rounded, size: 14, color: Color(0xFF0D9488)),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ),
            if (isMuted) ...[
              const Icon(Icons.volume_off_rounded, size: 14, color: Color(0xFF7A757F)),
              const SizedBox(width: 4),
            ],
            Text(
              time,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontStyle: hasNoMsg ? FontStyle.italic : FontStyle.normal,
                        color: hasNoMsg ? const Color(0xFFA88B6A) : const Color(0xFF2E2A36).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "🚩 Yatra Sangha • $membersCount Yatris",
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7700),
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7700),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalChatTile(Map<String, dynamic> chat) {
    final name = chat['name']?.toString() ?? 'Devotee';
    final rawLastMsg = (chat['lastMessage'] ?? '').toString();
    final lastMsg = rawLastMsg.isNotEmpty ? rawLastMsg : 'No messages yet';
    final hasNoMsg = rawLastMsg.isEmpty;
    final time = chat['time']?.toString() ?? '';
    final unread = chat['unread'] is int ? chat['unread'] as int : 0;
    final isMuted = chat['isMuted'] == true;
    final userId = (chat['userId'] ?? chat['id'] ?? '').toString();
    final isOnline = _onlineUserIds.contains(userId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D2B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openPersonalChat(chat),
        onLongPress: () => _showChatOptionsBottomSheet(chat, isGroup: false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8D6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF7700),
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ),
            if (isMuted) ...[
              const Icon(Icons.volume_off_rounded, size: 14, color: Color(0xFF7A757F)),
              const SizedBox(width: 4),
            ],
            Text(
              time,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontStyle: hasNoMsg ? FontStyle.italic : FontStyle.normal,
                    color: hasNoMsg ? const Color(0xFFA88B6A) : const Color(0xFF2E2A36).withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7700),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppInviteBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D2B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invite Friends on WhatsApp",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    Text(
                      "Share live darshans & create Yatra Sangha groups together",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openContactSync,
                  icon: const Icon(Icons.contacts_rounded, size: 16, color: Color(0xFFFF7700)),
                  label: Text("Sync Contacts", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFFF7700))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF7700)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareWhatsAppInvite,
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: Text("WhatsApp Invite", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
