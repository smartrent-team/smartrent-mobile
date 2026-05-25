class RoomModel {
  final int id;
  final String roomCode;
  final int? floor;
  final double? area;
  final double basePrice;
  final double? electricPrice;
  final double? waterPrice;
  final String status;
  final dynamic branch;
  final Map<String, dynamic>? tenant;

  RoomModel({
    required this.id,
    required this.roomCode,
    this.floor,
    this.area,
    required this.basePrice,
    this.electricPrice,
    this.waterPrice,
    required this.status,
    this.branch,
    this.tenant,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: _toInt(json['id']),
      roomCode: json['roomCode']?.toString() ?? '',
      floor: _tryInt(json['floor']),
      area: _tryDouble(json['area']),
      basePrice: _tryDouble(json['basePrice']) ?? 0,
      electricPrice: _tryDouble(json['electricPrice']),
      waterPrice: _tryDouble(json['waterPrice']),
      status: json['status']?.toString() ?? 'available',
      branch: json['branch'],
      tenant: json['tenant'] is Map ? Map<String, dynamic>.from(json['tenant'] as Map) : null,
    );
  }

  static int _toInt(dynamic value) {
    return _tryInt(value) ?? 0;
  }

  static int? _tryInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _tryDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String get statusLabel {
    switch (status) {
      case 'occupied':
        return 'Đã thuê';
      case 'maintenance':
        return 'Bảo trì';
      default:
        return 'Trống';
    }
  }

  String get branchName {
    if (branch is Map && (branch as Map)['name'] != null) {
      return (branch as Map)['name'].toString();
    }
    return '';
  }

  RoomModel copyWith({
    int? id,
    String? roomCode,
    int? floor,
    double? area,
    double? basePrice,
    double? electricPrice,
    double? waterPrice,
    String? status,
    dynamic branch,
    Map<String, dynamic>? tenant,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      basePrice: basePrice ?? this.basePrice,
      electricPrice: electricPrice ?? this.electricPrice,
      waterPrice: waterPrice ?? this.waterPrice,
      status: status ?? this.status,
      branch: branch ?? this.branch,
      tenant: tenant ?? this.tenant,
    );
  }
}
