class KycAdmin {
  final String id;
  final String userId;
  final String documentType;
  final String frontImage;
  final String backImage;
  final String status;

  KycAdmin({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.frontImage,
    required this.backImage,
    required this.status,
  });

  factory KycAdmin.fromJson(Map<String, dynamic> json) {
    return KycAdmin(
      id: json['_id'],
      userId: json['userId'],
      documentType: json['documentType'],
      frontImage: json['frontImage'],
      backImage: json['backImage'],
      status: json['status'] ?? 'pending',
    );
  }
}
