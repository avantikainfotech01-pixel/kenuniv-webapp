class WalletHistoryModel {
  final String? id;
  final String userName;
  final String userMobile;
  final int points;
  final String type;
  final int balanceAfter;
  final String description;
  final DateTime date;

  WalletHistoryModel({
    this.id,
    required this.userName,
    required this.userMobile,
    required this.points,
    required this.type,
    required this.balanceAfter,
    required this.description,
    required this.date,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    return WalletHistoryModel(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userMobile: json['userMobile'] ?? 'N/A',
      points: (json['points'] ?? 0).toInt(),
      type: json['type'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0).toInt(),
      description: json['description'] ?? '-',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userName': userName,
      'userMobile': userMobile,
      'points': points,
      'type': type,
      'balanceAfter': balanceAfter,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
