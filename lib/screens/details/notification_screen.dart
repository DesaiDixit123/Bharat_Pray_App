import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import 'jap_counter_screen.dart';
import 'live_darshan_screen.dart';
import 'yatra_screen.dart';
import 'granth_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String? _error;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Unread',
    'Darshan',
    'Jap',
    'Yatra',
    'Temple',
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      final res = await ApiService.getNotifications(
        token,
        category: (_selectedCategory == 'All' || _selectedCategory == 'Unread')
            ? 'All'
            : _selectedCategory,
        unreadOnly: _selectedCategory == 'Unread',
      );

      final rawList = res['notifications'] as List? ?? [];
      final parsed = rawList
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _notifications = parsed;
          _unreadCount = res['unread_count'] is int
              ? res['unread_count'] as int
              : parsed.where((n) => !n.isRead).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead({String? notificationId, bool markAll = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      await ApiService.markNotificationAsRead(
        token,
        notificationId: notificationId,
        markAll: markAll,
      );

      if (mounted) {
        setState(() {
          if (markAll) {
            _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
            _unreadCount = 0;
          } else if (notificationId != null) {
            final index = _notifications.indexWhere((n) => n.id == notificationId);
            if (index != -1 && !_notifications[index].isRead) {
              _notifications[index] = _notifications[index].copyWith(isRead: true);
              _unreadCount = (_unreadCount - 1).clamp(0, 9999);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> _clearNotification({String? notificationId, bool clearAll = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      await ApiService.clearNotification(
        token,
        notificationId: notificationId,
        clearAll: clearAll,
      );

      if (mounted) {
        setState(() {
          if (clearAll) {
            _notifications.clear();
            _unreadCount = 0;
          } else if (notificationId != null) {
            _notifications.removeWhere((n) => n.id == notificationId);
          }
        });
      }
    } catch (e) {
      debugPrint("Error clearing notification: $e");
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _markAsRead(notificationId: notification.id);
    }

    final screen = notification.actionScreen.toLowerCase();
    final cat = notification.category.toLowerCase();

    if (screen == 'darshan' || cat == 'darshan') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LiveDarshanScreen(
            templeName: "Live Temple Darshan",
            imageUrl: "assets/images/somnath.png",
          ),
        ),
      );
    } else if (screen == 'jap' || cat == 'jap') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const JapCounterScreen(),
        ),
      );
    } else if (screen == 'yatra' || cat == 'yatra') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const YatraScreen()),
      );
    } else if (screen == 'granth' || cat == 'temple') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GranthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EF),
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
                border: Border.all(color: const Color(0xFFEFE6DB)),
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
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount New',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF2E2A36)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            onSelected: (val) {
              if (val == 'mark_all') {
                _markAsRead(markAll: true);
              } else if (val == 'clear_all') {
                _clearNotification(clearAll: true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all',
                child: Row(
                  children: [
                    const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFFFF7700)),
                    const SizedBox(width: 10),
                    Text('Mark all as read', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text('Clear all', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildCategoryFilterRow(),

          // Notification List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7700)),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFFFF7700),
                            onRefresh: _fetchNotifications,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _notifications.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                return _buildNotificationCard(notif);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
              _fetchNotifications();
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7700) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF7700) : const Color(0xFFEFE6DB),
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
                  cat,
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

  Widget _buildNotificationCard(AppNotification notif) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        _clearNotification(notificationId: notif.id);
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notif),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFFFF9EE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notif.isRead
                  ? const Color(0xFFEFE6DB)
                  : const Color(0xFFFF7700).withValues(alpha: 0.35),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notif.iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(notif.icon, color: notif.iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Title & Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7700),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.75),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif.timeAgo,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
                          ),
                        ),
                        if (notif.actionScreen.isNotEmpty)
                          Row(
                            children: [
                              Text(
                                "Open",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF7700),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFFF7700)),
                            ],
                          ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: Color(0xFFFF7700),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "No Notifications Yet 🙏",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You are all caught up! Updates regarding live aarti, Jap milestones, and yatra will appear here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFFF7700)),
              label: Text("Refresh", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFFF7700))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF7700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              "Could not load notifications",
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Please check connection',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
