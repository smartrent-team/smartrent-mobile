import 'package:smartrent_mobile/core/contract/domain/contract_cancellation_request.dart';

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
  final ContractCancellationRequest? cancellationRequest;

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
    this.cancellationRequest,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final cancellationRaw = json['cancellationRequest'];
    return ContractModel(
      contractId: json['contractId']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      building: json['building']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? '',
      deposit: (json['deposit'] as num?)?.toInt() ?? 0,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
      contractImages: (json['contractImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((url) => url.isNotEmpty)
              .toList() ??
          const [],
      cancellationRequest: cancellationRaw is Map<String, dynamic>
          ? ContractCancellationRequest.fromJson(cancellationRaw)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get isActive => status == 'active';

  bool get isCancelled => status == 'cancelled' || status == 'terminated';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Đang hiệu lực';
      case 'expired':
        return 'Đã hết hạn';
      case 'cancelled':
        return 'Đã hủy';
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
