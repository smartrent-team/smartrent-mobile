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
    );
  }
}
