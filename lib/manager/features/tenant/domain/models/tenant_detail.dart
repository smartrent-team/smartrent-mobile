class TenantDetail {
  final int id;
  final int userId;
  final int? activeContractId;
  final String name;
  final String phone;
  final String? email;
  final String checkInDate;
  final String? moveOutDate;
  final String? contractSignDate;
  final bool isRoomHead;
  final String initial;
  final int? roomId;
  final String? roomCode;
  final int? floor;
  final String roomLabel;
  final bool isActive;
  final String statusLabel;
  final String? identityNumber;
  final List<String> contractImages;
  final String? checkoutRequestStatus;
  final bool checkoutPaymentBlocked;
  final int checkoutUnpaidInvoiceCount;
  final int checkoutUnpaidInvoiceTotal;
  final String? checkoutLatestUnpaidInvoiceCode;
  final int? remainingContractDays;
  final String? contractEndDate;

  const TenantDetail({
    required this.id,
    required this.userId,
    this.activeContractId,
    required this.name,
    required this.phone,
    this.email,
    required this.checkInDate,
    this.moveOutDate,
    this.contractSignDate,
    required this.isRoomHead,
    required this.initial,
    this.roomId,
    this.roomCode,
    this.floor,
    required this.roomLabel,
    required this.isActive,
    required this.statusLabel,
    this.identityNumber,
    required this.contractImages,
    this.checkoutRequestStatus,
    this.checkoutPaymentBlocked = false,
    this.checkoutUnpaidInvoiceCount = 0,
    this.checkoutUnpaidInvoiceTotal = 0,
    this.checkoutLatestUnpaidInvoiceCode,
    this.remainingContractDays,
    this.contractEndDate,
  });

  factory TenantDetail.fromJson(Map<String, dynamic> json) {
    final images = json['contractImages'];
    return TenantDetail(
      id: json['id'] as int,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      activeContractId: (json['activeContractId'] as num?)?.toInt(),
      name: json['name']?.toString() ?? 'Không tên',
      phone: json['phone']?.toString() ?? 'Chưa cập nhật',
      email: json['email']?.toString(),
      checkInDate: json['checkInDate']?.toString() ?? 'Chưa cập nhật',
      moveOutDate: json['moveOutDate']?.toString(),
      contractSignDate: json['contractSignDate']?.toString(),
      isRoomHead: json['isRoomHead'] == true,
      initial: json['initial']?.toString() ?? 'C',
      roomId: json['roomId'] as int?,
      roomCode: json['roomCode']?.toString(),
      floor: json['floor'] as int?,
      roomLabel: json['roomLabel']?.toString() ?? 'Chưa có phòng',
      isActive: json['isActive'] != false,
      statusLabel: json['statusLabel']?.toString() ?? 'Đang thuê',
      identityNumber: () {
        final raw = json['identityNumber']?.toString();
        if (raw == null || raw.isEmpty || raw == '000000000000') return null;
        return raw;
      }(),
      contractImages: images is List
          ? images.map((e) => e.toString()).where((u) => u.isNotEmpty).toList()
          : const [],
      checkoutRequestStatus: json['checkoutRequestStatus']?.toString(),
      checkoutPaymentBlocked: json['checkoutPaymentBlocked'] == true,
      checkoutUnpaidInvoiceCount: (json['checkoutUnpaidInvoiceCount'] as num?)?.toInt() ?? 0,
      checkoutUnpaidInvoiceTotal: (json['checkoutUnpaidInvoiceTotal'] as num?)?.toInt() ?? 0,
      checkoutLatestUnpaidInvoiceCode: json['checkoutLatestUnpaidInvoiceCode']?.toString(),
      remainingContractDays: (json['remainingContractDays'] as num?)?.toInt(),
      contractEndDate: json['contractEndDate']?.toString(),
    );
  }

  TenantDetail copyWith({
    int? roomId,
    String? roomCode,
    int? floor,
    String? roomLabel,
    String? checkInDate,
    String? contractSignDate,
    List<String>? contractImages,
  }) {
    return TenantDetail(
      id: id,
      userId: userId,
      activeContractId: activeContractId,
      name: name,
      phone: phone,
      email: email,
      checkInDate: checkInDate ?? this.checkInDate,
      moveOutDate: moveOutDate,
      contractSignDate: contractSignDate ?? this.contractSignDate,
      isRoomHead: isRoomHead,
      initial: initial,
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      floor: floor ?? this.floor,
      roomLabel: roomLabel ?? this.roomLabel,
      isActive: isActive,
      statusLabel: statusLabel,
      identityNumber: identityNumber,
      contractImages: contractImages ?? this.contractImages,
      checkoutRequestStatus: checkoutRequestStatus,
      checkoutPaymentBlocked: checkoutPaymentBlocked,
      checkoutUnpaidInvoiceCount: checkoutUnpaidInvoiceCount,
      checkoutUnpaidInvoiceTotal: checkoutUnpaidInvoiceTotal,
      checkoutLatestUnpaidInvoiceCode: checkoutLatestUnpaidInvoiceCode,
      remainingContractDays: remainingContractDays,
      contractEndDate: contractEndDate,
    );
  }
}
