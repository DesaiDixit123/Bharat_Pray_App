import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String category; // 'darshan', 'jap', 'yatra', 'temple', 'general', 'system'
  final String type;
  final String target;
  final bool isRead;
  final String actionScreen;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.type = 'general',
    this.target = 'all',
    this.isRead = false,
    this.actionScreen = '',
    this.metadata = const {},
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      category: (json['category']?.toString() ?? 'general').toLowerCase(),
      type: json['type']?.toString() ?? 'general',
      target: json['target']?.toString() ?? 'all',
      isRead: json['is_read'] == true,
      actionScreen: json['action_screen']?.toString() ?? '',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : {},
      createdAt: parsedDate,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  IconData get icon {
    switch (category) {
      case 'darshan':
        return Icons.live_tv_rounded;
      case 'jap':
        return Icons.radio_button_checked_rounded;
      case 'yatra':
        return Icons.explore_rounded;
      case 'temple':
        return Icons.temple_hindu_rounded;
      case 'system':
        return Icons.shield_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get iconColor {
    switch (category) {
      case 'darshan':
        return const Color(0xFFE11D48); // Rose red
      case 'jap':
        return const Color(0xFFFF7700); // Saffron orange
      case 'yatra':
        return const Color(0xFF0D9488); // Teal
      case 'temple':
        return const Color(0xFFD97706); // Amber
      case 'system':
        return const Color(0xFF6366F1); // Indigo
      default:
        return const Color(0xFFFF7700);
    }
  }

  Color get iconBgColor {
    return iconColor.withValues(alpha: 0.12);
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      type: type,
      target: target,
      isRead: isRead ?? this.isRead,
      actionScreen: actionScreen,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
