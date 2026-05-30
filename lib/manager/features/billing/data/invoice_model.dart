class Invoice {
  final int id;
  final String invoiceCode;
  final int roomId;
  final String roomCode;
  final int floor;
  final int? tenantId;
  final num roomPrice;
  final num serviceCost;
  final num electricCost;
  final num waterCost;
  final num? electricOld;
  final num? electricNew;
  final num? waterOld;
  final num? waterNew;
  final num totalAmount;
  final String paymentStatus;
  final String? issuedAt;
  final String? createdAt;
  final String? checkoutUrl;

  Invoice({
    required this.id,
    required this.invoiceCode,
    required this.roomId,
    required this.roomCode,
    required this.floor,
    this.tenantId,
    required this.roomPrice,
    required this.serviceCost,
    required this.electricCost,
    required this.waterCost,
    this.electricOld,
    this.electricNew,
    this.waterOld,
    this.waterNew,
    required this.totalAmount,
    required this.paymentStatus,
    this.issuedAt,
    this.createdAt,
    this.checkoutUrl,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? 0,
      invoiceCode: json['invoiceCode'] ?? '',
      roomId: json['roomId'] ?? 0,
      roomCode: json['roomCode'] ?? 'N/A',
      floor: json['floor'] ?? 0,
      tenantId: json['tenantId'],
      roomPrice: json['roomPrice'] ?? 0,
      serviceCost: json['serviceCost'] ?? 0,
      electricCost: json['electricCost'] ?? 0,
      waterCost: json['waterCost'] ?? 0,
      electricOld: json['electricOld'],
      electricNew: json['electricNew'],
      waterOld: json['waterOld'],
      waterNew: json['waterNew'],
      totalAmount: json['totalAmount'] ?? 0,
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      issuedAt: json['issuedAt'],
      createdAt: json['createdAt'],
      checkoutUrl: json['checkoutUrl'],
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isUnpaid => paymentStatus == 'unpaid';
}
