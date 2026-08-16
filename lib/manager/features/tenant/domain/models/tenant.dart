class Tenant {
  final int id;
  final int? userId;
  final String name;
  final String phone;
  final String? email;
  final String checkInDate;
  final bool isRoomHead;
  final String initial;
  final bool isActive;
  final String userStatus; // 'active' | 'locked'

  const Tenant({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.email,
    required this.checkInDate,
    required this.isRoomHead,
    required this.initial,
    this.isActive = true,
    this.userStatus = 'active',
  });
}
