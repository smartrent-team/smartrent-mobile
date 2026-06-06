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
    // Supabase có thể trả về rooms là object hoặc array (khi có nhiều bản ghi)
    final roomsRaw = json['rooms'] ?? json['room'];
    Map<dynamic, dynamic>? rooms;
    if (roomsRaw is Map) {
      rooms = roomsRaw;
    } else if (roomsRaw is List && roomsRaw.isNotEmpty) {
      rooms = roomsRaw.first is Map ? roomsRaw.first as Map : null;
    }

    final roomCode = rooms?['room_code'] ?? rooms?['roomCode'] ?? json['roomName'] ?? json['room_name'];
    final floorRaw = rooms?['floor'] ?? json['floor'];

    return TicketModel(
      id: json['id'],
      title: json['title']?.toString(),
      roomName: roomCode?.toString(),
      floor: floorRaw?.toString(),
      status: json['status']?.toString(),
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
