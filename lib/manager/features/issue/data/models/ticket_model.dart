class TicketModel {
  final int? id;
  final String? roomName;
  final String? floor;
  final String? status;
  final String? description;
  final String? createdAt;
  final List<dynamic>? images;

  TicketModel({
    this.id,
    this.roomName,
    this.floor,
    this.status,
    this.description,
    this.createdAt,
    this.images,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      roomName: json['rooms']?['room_code'] ?? 'N/A',
      floor: json['rooms']?['floor']?.toString() ?? 'N/A',
      status: json['status'],
      description: json['description'],
      createdAt: json['created_at'],
      images: json['images'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomName': roomName,
      'floor': floor,
      'status': status,
      'description': description,
      'createdAt': createdAt,
      'images': images,
    };
  }
}
