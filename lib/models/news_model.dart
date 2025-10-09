class News {
  final String id;
  final String image;
  final String title;
  final String description;

  News({
    required this.id,
    required this.image,
    required this.title,
    required this.description,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'description': description,
    };
  }
}
