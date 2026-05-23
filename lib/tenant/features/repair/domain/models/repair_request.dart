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
