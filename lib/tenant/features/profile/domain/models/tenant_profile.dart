import 'package:smartrent_mobile/core/utils/vn_date.dart';

class TenantProfile {
  final int tenantId;
  final int userId;
  final String fullName;
  final String phone;
  final String email;
  final DateTime moveInDate;
  final DateTime? moveOutDate;
  final String status;
  final Room? room;
  final dynamic activeContract;
  final List<Invoice> recentInvoices;
  final List<MaintenanceTicket> maintenanceTickets;

  TenantProfile({
    required this.tenantId,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.moveInDate,
    this.moveOutDate,
    required this.status,
    this.room,
    this.activeContract,
    required this.recentInvoices,
    required this.maintenanceTickets,
  });

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      tenantId: (json['tenant_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? 'Chưa cập nhật',
      phone: json['phone'] as String? ?? 'Chưa cập nhật',
      email: json['email'] as String? ?? '',
      moveInDate: VnDate.parse(json['move_in_date']) ?? DateTime.now(),
      moveOutDate: VnDate.parse(json['move_out_date']),
      status: json['status'] as String? ?? 'active',
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
      activeContract: json['active_contract'],
      recentInvoices: (json['recent_invoices'] as List? ?? [])
          .map((i) => Invoice.fromJson(i as Map<String, dynamic>))
          .toList(),
      maintenanceTickets: (json['maintenance_tickets'] as List? ?? [])
          .map((i) => MaintenanceTicket.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Room {
  final int id;
  final String roomCode;
  final int basePrice;
  final int area;
  final int floor;
  final String branchName;

  Room({
    required this.id,
    required this.roomCode,
    required this.basePrice,
    required this.area,
    required this.floor,
    required this.branchName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roomCode: json['room_code'] as String? ?? 'N/A',
      basePrice: (json['base_price'] as num?)?.toInt() ?? 0,
      area: (json['area'] as num?)?.toInt() ?? 0,
      floor: (json['floor'] as num?)?.toInt() ?? 0,
      branchName: json['branch_name'] as String? ?? 'Chưa phân chi nhánh',
    );
  }
}

class Invoice {
  final int id;
  final DateTime issuedAt;
  final String invoiceCode;
  final int totalAmount;
  final String paymentStatus;

  Invoice({
    required this.id,
    required this.issuedAt,
    required this.invoiceCode,
    required this.totalAmount,
    required this.paymentStatus,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      issuedAt: json['issued_at'] != null
          ? DateTime.tryParse(json['issued_at']) ?? DateTime.now()
          : DateTime.now(),
      invoiceCode: json['invoice_code'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
    );
  }
}

class MaintenanceTicket {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime createdAt;

  MaintenanceTicket({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory MaintenanceTicket.fromJson(Map<String, dynamic> json) {
    return MaintenanceTicket(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
