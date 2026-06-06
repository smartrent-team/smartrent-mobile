class MarketplaceItem {
  final String? id;
  final int? branchId;
  final String? title;
  final String? description;
  final num? price;
  final List<String>? images;
  final String? status;
  final String? createdAt;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerRoom;
  final String? ownerInitial;

  MarketplaceItem({
    this.id,
    this.branchId,
    this.title,
    this.description,
    this.price,
    this.images,
    this.status,
    this.createdAt,
    this.ownerName,
    this.ownerPhone,
    this.ownerRoom,
    this.ownerInitial,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id']?.toString(),
      branchId: json['branchId'] as int? ?? json['branch_id'] as int?,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      price: json['price'] as num?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: json['status']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      ownerName: json['ownerName']?.toString(),
      ownerPhone: json['ownerPhone']?.toString(),
      ownerRoom: json['ownerRoom']?.toString(),
      ownerInitial: json['ownerInitial']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'title': title,
      'description': description,
      'price': price,
      'images': images,
      'status': status,
      'createdAt': createdAt,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerRoom': ownerRoom,
      'ownerInitial': ownerInitial,
    };
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending_approval' || status == 'pending';
  bool get isRejected => status == 'rejected';
}
