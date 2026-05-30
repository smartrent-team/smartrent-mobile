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
      tenantId: json['tenant_id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
      moveInDate: DateTime.parse(json['move_in_date']),
      moveOutDate: json['move_out_date'] != null ? DateTime.parse(json['move_out_date']) : null,
      status: json['status'],
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
      activeContract: json['active_contract'],
      recentInvoices: (json['recent_invoices'] as List)
          .map((i) => Invoice.fromJson(i))
          .toList(),
      maintenanceTickets: (json['maintenance_tickets'] as List)
          .map((i) => MaintenanceTicket.fromJson(i))
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
      id: json['id'],
      roomCode: json['room_code'],
      basePrice: json['base_price'],
      area: json['area'],
      floor: json['floor'],
      branchName: json['branch_name'],
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
      id: json['id'],
      issuedAt: DateTime.parse(json['issued_at']),
      invoiceCode: json['invoice_code'],
      totalAmount: json['total_amount'],
      paymentStatus: json['payment_status'],
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
