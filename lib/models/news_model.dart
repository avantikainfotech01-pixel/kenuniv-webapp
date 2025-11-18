class News {
  final String? id;
  final String title;
  final String description;

  // unified media field (image or video)
  final String? mediaUrl;

  // image / video / null
  final String? mediaType;

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

      // accept: mediaUrl, media, image
      mediaUrl: json['mediaUrl'] ?? json['media'] ?? json['image'] ?? '',

      // safe mediaType
      mediaType: json['mediaType'] == 'video' ? 'video' : 'image',

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
      'mediaUrl': mediaUrl ?? '',
      'mediaType': mediaType ?? 'image',
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
