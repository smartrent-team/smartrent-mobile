class TenantInvoice {
  final int id;
  final String invoiceCode;
  final num totalAmount;
  final String paymentStatus;
  final String? issuedAt;
  final String? createdAt;
  final num roomPrice;
  final num serviceCost;
  final num electricCost;
  final num waterCost;
  final num? electricOld;
  final num? electricNew;
  final num? waterOld;
  final num? waterNew;
  final String? roomCode;
  final String? branchName;
  final String? qrPayload;
  final String? checkoutUrl;
  final String? paymentAccountNumber;
  final String? paymentAccountName;
  final String? paymentBankBin;
  final String? paymentDescription;
  final bool isPaid;
  final bool hasQr;

  const TenantInvoice({
    required this.id,
    required this.invoiceCode,
    required this.totalAmount,
    required this.paymentStatus,
    this.issuedAt,
    this.createdAt,
    this.roomPrice = 0,
    this.serviceCost = 0,
    this.electricCost = 0,
    this.waterCost = 0,
    this.electricOld,
    this.electricNew,
    this.waterOld,
    this.waterNew,
    this.roomCode,
    this.branchName,
    this.qrPayload,
    this.checkoutUrl,
    this.paymentAccountNumber,
    this.paymentAccountName,
    this.paymentBankBin,
    this.paymentDescription,
    this.isPaid = false,
    this.hasQr = false,
  });

  factory TenantInvoice.fromJson(Map<String, dynamic> json) {
    return TenantInvoice(
      id: json['id'] as int,
      invoiceCode: json['invoiceCode'] as String? ?? json['invoice_code'] as String? ?? '',
      totalAmount: (json['totalAmount'] ?? json['total_amount'] ?? 0) as num,
      paymentStatus: json['paymentStatus'] as String? ?? json['payment_status'] as String? ?? 'unpaid',
      issuedAt: json['issuedAt'] as String? ?? json['issued_at'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      roomPrice: (json['roomPrice'] ?? json['room_price'] ?? 0) as num,
      serviceCost: (json['serviceCost'] ?? json['service_cost'] ?? 0) as num,
      electricCost: (json['electricCost'] ?? json['electric_cost'] ?? 0) as num,
      waterCost: (json['waterCost'] ?? json['water_cost'] ?? 0) as num,
      electricOld: json['electricOld'] as num? ?? json['electric_old'] as num?,
      electricNew: json['electricNew'] as num? ?? json['electric_new'] as num?,
      waterOld: json['waterOld'] as num? ?? json['water_old'] as num?,
      waterNew: json['waterNew'] as num? ?? json['water_new'] as num?,
      roomCode: json['roomCode'] as String? ?? json['room_code'] as String?,
      branchName: json['branchName'] as String?,
      qrPayload: json['qrPayload'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      paymentAccountNumber: json['paymentAccountNumber'] as String?,
      paymentAccountName: json['paymentAccountName'] as String?,
      paymentBankBin: json['paymentBankBin'] as String?,
      paymentDescription: json['paymentDescription'] as String?,
      isPaid: json['isPaid'] as bool? ?? (json['paymentStatus'] == 'paid' || json['payment_status'] == 'paid'),
      hasQr: json['hasQr'] as bool? ??
          _hasNonEmpty(json['qrPayload'] as String?),
    );
  }

  String get roomLabel {
    if (branchName != null && roomCode != null) {
      return '$branchName · Phòng $roomCode';
    }
    if (roomCode != null) return 'Phòng $roomCode';
    return 'SmartRent';
  }

  bool get canPay =>
      !isPaid &&
      (hasQr ||
          (checkoutUrl != null && checkoutUrl!.trim().isNotEmpty));

  static bool _hasNonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;
}
