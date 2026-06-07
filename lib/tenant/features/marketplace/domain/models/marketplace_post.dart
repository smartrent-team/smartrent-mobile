class MarketplacePost {
  final String id;
  final int branchId;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final String status; // 'active', 'pending_approval', 'rejected', 'sold'
  final DateTime createdAt;

  // Contact details of the seller (populated from join on backend)
  final String ownerName;
  final String ownerPhone;
  final String ownerRoom;
  final String ownerInitial;

  MarketplacePost({
    required this.id,
    required this.branchId,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.status,
    required this.createdAt,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerRoom,
    required this.ownerInitial,
  });

  factory MarketplacePost.fromJson(Map<String, dynamic> json) {
    return MarketplacePost(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId'] is int
          ? json['branchId'] as int
          : (int.tryParse(json['branchId']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : (double.tryParse(json['price']?.toString() ?? '') ?? 0.0),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status']?.toString() ?? 'pending_approval',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
      ownerName: json['ownerName']?.toString() ?? 'Người ẩn danh',
      ownerPhone: json['ownerPhone']?.toString() ?? 'Chưa có SĐT',
      ownerRoom: json['ownerRoom']?.toString() ?? 'Chưa rõ phòng',
      ownerInitial: json['ownerInitial']?.toString() ?? 'U',
    );
  }
}
