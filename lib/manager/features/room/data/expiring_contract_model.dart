/// Model đại diện cho phòng có hợp đồng sắp hết hạn
class ExpiringContractInfo {
  final int tenantId;
  final String roomName;
  final String contractId;
  final int remainingDays;
  final String? endDate;

  const ExpiringContractInfo({
    required this.tenantId,
    required this.roomName,
    required this.contractId,
    required this.remainingDays,
    this.endDate,
  });

  factory ExpiringContractInfo.fromJson(
      Map<String, dynamic> json, int tenantId) {
    return ExpiringContractInfo(
      tenantId: tenantId,
      roomName: json['roomName']?.toString() ?? 'Phòng',
      contractId: json['contractId']?.toString() ?? '',
      remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
      endDate: json['endDate']?.toString(),
    );
  }
}
