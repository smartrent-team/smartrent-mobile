import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TenantNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? userId;

  const TenantNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.userId,
  });

  factory TenantNotification.fromJson(Map<String, dynamic> json) {
    return TenantNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'created_at': createdAt?.toIso8601String(),
      'user_id': userId,
    };
  }

  String get timeLabel {
    final created = createdAt;
    if (created == null) {
      return 'Vừa xong';
    }

    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM HH:mm').format(created);
  }

  IconData get icon {
    switch (type) {
      case 'invoice':
      case 'payment':
        return Icons.receipt_long_rounded;
      case 'repair':
      case 'ticket':
        return Icons.build_circle_rounded;
      case 'analysis':
        return Icons.psychology_rounded;
      case 'contract':
        return Icons.event_busy_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'invoice':
      case 'payment':
        return const Color(0xFF2E7D32);
      case 'repair':
      case 'ticket':
        return const Color(0xFFE65100);
      case 'analysis':
        return const Color(0xFF5E35B1);
      case 'contract':
        return const Color(0xFFC62828);
      case 'system':
        return const Color(0xFF3949AB);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color get backgroundColor {
    switch (type) {
      case 'invoice':
      case 'payment':
        return const Color(0xFFE8F5E9);
      case 'repair':
      case 'ticket':
        return const Color(0xFFFFF3E0);
      case 'analysis':
        return const Color(0xFFF3E5F5);
      case 'contract':
        return const Color(0xFFFFEBEE);
      case 'system':
        return const Color(0xFFE8EAF6);
      default:
        return const Color(0xFFE8F5E9);
    }
  }
}
