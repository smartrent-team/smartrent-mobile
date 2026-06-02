class ContractModel {
  final String contractId;
  final String roomName;
  final String building;
  final String status;
  final int deposit;
  final DateTime? startDate;
  final DateTime? endDate;
  final int remainingDays;
  final List<String> contractImages;

  const ContractModel({
    required this.contractId,
    required this.roomName,
    required this.building,
    required this.status,
    required this.deposit,
    this.startDate,
    this.endDate,
    required this.remainingDays,
    required this.contractImages,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      contractId: json['contractId']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      building: json['building']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      deposit: (json['deposit'] as num?)?.toInt() ?? 0,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
      contractImages: (json['contractImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((url) => url.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get isActive => status == 'active';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Đang hiệu lực';
      case 'expired':
        return 'Đã hết hạn';
      case 'terminated':
        return 'Đã chấm dứt';
      default:
        return status;
    }
  }

  double? get validityProgress {
    if (startDate == null || endDate == null) return null;
    final total = endDate!.difference(startDate!).inDays;
    if (total <= 0) return null;
    final elapsed = DateTime.now().difference(startDate!).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
