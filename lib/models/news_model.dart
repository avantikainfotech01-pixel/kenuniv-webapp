class News {
  final String? id;
  final String title;
  final String description;
  final String? mediaUrl; // can be image or video
  final String? mediaType; // 'image' or 'video'
  final DateTime? createdAt;

  News({
    this.id,
    required this.title,
    required this.description,
    this.mediaUrl,
    this.mediaType,
    this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['_id'] as String?,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaUrl: json['mediaUrl'] ?? json['image'], // backward compatibility
      mediaType: json['mediaType'] ?? 'image',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'description': description,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'mediaType': mediaType ?? 'image',
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
