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
  final String? relatedId;

  const TenantNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.userId,
    this.relatedId,
  });

  factory TenantNotification.fromJson(Map<String, dynamic> json) {
    return TenantNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'])?.toString() ?? ''),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      relatedId: (json['relatedId'] ?? json['related_id'])?.toString(),
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
      'related_id': relatedId,
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
      case 'invoice_overdue':
        return Icons.warning_amber_rounded;
      case 'invoice':
      case 'payment':
        return Icons.receipt_long_rounded;
      case 'repair':
      case 'ticket':
        return Icons.build_circle_rounded;
      case 'analysis':
        return Icons.psychology_rounded;
      case 'contract':
      case 'contract_expired':
        return Icons.event_busy_rounded;
      case 'contract_expiring_7d':
        return Icons.local_fire_department_rounded;
      case 'contract_expiring_30d':
        return Icons.access_time_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'invoice_overdue':
        return const Color(0xFFC62828);
      case 'invoice':
      case 'payment':
        return const Color(0xFF2E7D32);
      case 'repair':
      case 'ticket':
        return const Color(0xFFE65100);
      case 'analysis':
        return const Color(0xFF5E35B1);
      case 'contract':
      case 'contract_expired':
        return const Color(0xFFC62828);
      case 'contract_expiring_7d':
        return const Color(0xFFD32F2F);
      case 'contract_expiring_30d':
        return const Color(0xFFE64A19);
      case 'system':
        return const Color(0xFF3949AB);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color get backgroundColor {
    switch (type) {
      case 'invoice_overdue':
        return const Color(0xFFFFEBEE);
      case 'invoice':
      case 'payment':
        return const Color(0xFFE8F5E9);
      case 'repair':
      case 'ticket':
        return const Color(0xFFFFF3E0);
      case 'analysis':
        return const Color(0xFFF3E5F5);
      case 'contract':
      case 'contract_expired':
        return const Color(0xFFFFEBEE);
      case 'contract_expiring_7d':
        return const Color(0xFFFFEBEE);
      case 'contract_expiring_30d':
        return const Color(0xFFFFF3E0);
      case 'system':
        return const Color(0xFFE8EAF6);
      default:
        return const Color(0xFFE8F5E9);
    }
  }
}
