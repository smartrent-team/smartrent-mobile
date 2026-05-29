class Tenant {
  final String name;
  final String phone;
  final String? email;
  final String checkInDate;
  final bool isRoomHead;
  final String initial;

  const Tenant({
    required this.name,
    required this.phone,
    this.email,
    required this.checkInDate,
    required this.isRoomHead,
    required this.initial,
  });
}
