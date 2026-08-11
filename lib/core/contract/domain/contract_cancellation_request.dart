class ContractCancellationRequest {
  final String status;
  final String requestedBy;
  final String reason;
  final DateTime? requestedAt;

  const ContractCancellationRequest({
    required this.status,
    required this.requestedBy,
    required this.reason,
    this.requestedAt,
  });

  factory ContractCancellationRequest.fromJson(Map<String, dynamic> json) {
    return ContractCancellationRequest(
      status: json['status']?.toString() ?? '',
      requestedBy: json['requestedBy']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      requestedAt: _parseDate(json['requestedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get isPending => status == 'pending';

  bool isRequestedBy(String role) => requestedBy == role;

  String requesterLabel(String viewerRole) {
    if (requestedBy == viewerRole) return 'Bạn';
    return requestedBy == 'tenant' ? 'Cư dân' : 'Quản lý';
  }
}
