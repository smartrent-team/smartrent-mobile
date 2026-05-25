class TenantDetailModel {
  final int id;
  final String identityNumber;
  final String? emergencyContact;
  final String? moveInDate;
  final String? moveOutDate;
  final dynamic room;
  final UserInfo? user;

  TenantDetailModel({
    required this.id,
    required this.identityNumber,
    this.emergencyContact,
    this.moveInDate,
    this.moveOutDate,
    this.room,
    this.user,
  });

  factory TenantDetailModel.fromJson(Map<String, dynamic> json) {
    return TenantDetailModel(
      id: _toInt(json['id']),
      identityNumber: json['identityNumber']?.toString() ?? '',
      emergencyContact: json['emergencyContact']?.toString(),
      moveInDate: json['moveInDate']?.toString(),
      moveOutDate: json['moveOutDate']?.toString(),
      room: json['room'],
      user: json['user'] is Map<String, dynamic>
          ? UserInfo.fromJson(json['user'] as Map<String, dynamic>)
          : json['user'] is Map
              ? UserInfo.fromJson(Map<String, dynamic>.from(json['user'] as Map))
              : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class UserInfo {
  final int id;
  final String? phone;
  final String? fullName;

  UserInfo({required this.id, this.phone, this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: TenantDetailModel._toInt(json['id']),
      phone: json['phone']?.toString(),
      fullName: json['fullName']?.toString(),
    );
  }
}
