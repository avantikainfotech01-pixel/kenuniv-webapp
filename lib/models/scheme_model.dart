class Scheme {
  final String? id;
  final String schemeName;
  final String productName;
  final int points;
  final String? image;
  final DateTime? createdAt;
  final String? status;

  Scheme({
    this.id,
    required this.schemeName,
    required this.productName,
    required this.points,
    this.image,
    this.createdAt,
    this.status,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['_id'] as String?,
      schemeName: json['schemeName'] as String,
      productName: json['productName'] as String,
      points: (json['points'] as num).toInt(),
      image: json['image'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      status: json['status'] as String? ?? 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'schemeName': schemeName,
      'productName': productName,
      'points': points,
      if (image != null) 'image': image,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'status': status ?? 'inactive',
    };
  }
}
