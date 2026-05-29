import 'package:flutter/material.dart';

enum RepairStatus {
  received,
  processing,
  completed,
}

class RepairRequest {
  final String id;
  final String title;
  final String category;
  final DateTime dateTime;
  final RepairStatus status;
  final IconData icon;

  RepairRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.dateTime,
    required this.status,
    required this.icon,
  });

  factory RepairRequest.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? '';
    String category = 'Khác';
    IconData icon = Icons.build_rounded;

    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('điện') || lowerTitle.contains('đèn') || lowerTitle.contains('bóng') || lowerTitle.contains('phích') || lowerTitle.contains('ổ cắm')) {
      category = 'Điện';
      icon = Icons.flash_on_rounded;
    } else if (lowerTitle.contains('nước') || lowerTitle.contains('vòi') || lowerTitle.contains('ống') || lowerTitle.contains('rò') || lowerTitle.contains('bồn')) {
      category = 'Nước';
      icon = Icons.water_drop_rounded;
    } else if (lowerTitle.contains('điều hòa') || lowerTitle.contains('lạnh') || lowerTitle.contains('máy lạnh') || lowerTitle.contains('quạt')) {
      category = 'Điều hòa';
      icon = Icons.air_rounded;
    } else if (lowerTitle.contains('khóa') || lowerTitle.contains('cửa') || lowerTitle.contains('chốt') || lowerTitle.contains('bản lề') || lowerTitle.contains('tay nắm')) {
      category = 'Cửa / Khóa';
      icon = Icons.lock_rounded;
    }

    RepairStatus status = RepairStatus.received;
    final statusStr = json['status'] ?? 'pending';
    if (statusStr == 'in-progress') {
      status = RepairStatus.processing;
    } else if (statusStr == 'resolved') {
      status = RepairStatus.completed;
    }

    final createdAtStr = json['created_at'] ?? '';
    DateTime dateTime = DateTime.now();
    if (createdAtStr.isNotEmpty) {
      try {
        dateTime = DateTime.parse(createdAtStr).toLocal();
      } catch (e) {
        // Fallback to now
      }
    }

    return RepairRequest(
      id: "RQ-2026-${json['id'].toString().padLeft(3, '0')}",
      title: title,
      category: category,
      dateTime: dateTime,
      status: status,
      icon: icon,
    );
  }
}

final List<RepairRequest> fakeRepairRequests = [
  RepairRequest(
    id: "RQ-2025-015",
    title: "Mất điện toàn phòng",
    category: "Điện",
    dateTime: DateTime(2025, 5, 20, 21, 34),
    status: RepairStatus.received,
    icon: Icons.flash_on_rounded,
  ),
  RepairRequest(
    id: "RQ-2025-016",
    title: "Vòi nước nhà tắm rò rỉ",
    category: "Nước",
    dateTime: DateTime(2025, 5, 15, 9, 12),
    status: RepairStatus.processing,
    icon: Icons.water_drop_rounded,
  ),
  RepairRequest(
    id: "RQ-2025-017",
    title: "Điều hòa không lạnh",
    category: "Điều hòa",
    dateTime: DateTime(2025, 5, 10, 14, 05),
    status: RepairStatus.processing,
    icon: Icons.air_rounded,
  ),
  RepairRequest(
    id: "RQ-2025-018",
    title: "Khóa cửa phòng bị hỏng",
    category: "Cửa / Khóa",
    dateTime: DateTime(2025, 5, 3, 8, 47),
    status: RepairStatus.completed,
    icon: Icons.lock_rounded,
  ),
  RepairRequest(
    id: "RQ-2025-019",
    title: "Đường ống nước bị rò",
    category: "Nước",
    dateTime: DateTime(2025, 4, 18, 11, 22),
    status: RepairStatus.completed,
    icon: Icons.water_drop_rounded,
  ),
];
