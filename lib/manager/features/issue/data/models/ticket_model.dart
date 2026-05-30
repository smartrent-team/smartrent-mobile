class TicketModel {
  final int? id;
  final String? title;
  final String? roomName;
  final String? floor;
  final String? status;
  final String? priority;
  final String? description;
  final String? createdAt;
  final List<dynamic>? images;

  TicketModel({
    this.id,
    this.title,
    this.roomName,
    this.floor,
    this.status,
    this.priority,
    this.description,
    this.createdAt,
    this.images,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final roomCode = json['rooms']?['room_code'];
    return TicketModel(
      id: json['id'],
      title: json['title']?.toString(),
      roomName: roomCode != null ? 'P.$roomCode' : 'N/A',
      floor: json['rooms']?['floor']?.toString() ?? 'N/A',
      status: json['status'],
      priority: json['priority']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString(),
      images: json['images'],
    );
  }

  bool get isOpen {
    final s = status?.toLowerCase();
    return s != 'resolved' && s != 'closed';
  }

  bool get isUrgent => priority == 'high';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'roomName': roomName,
      'floor': floor,
      'status': status,
      'priority': priority,
      'description': description,
      'createdAt': createdAt,
      'images': images,
    };
  }
}
