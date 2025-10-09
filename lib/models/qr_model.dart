// Data model for QR
class QrData {
  final int serial;
  final int points;
  final String uniqueCode;
  final String qrImage;

  QrData({
    required this.serial,
    required this.points,
    required this.uniqueCode,
    required this.qrImage,
  });

  factory QrData.fromJson(Map<String, dynamic> json) {
    return QrData(
      serial: json['serial'],
      points: json['points'],
      uniqueCode: json['uniqueCode'],
      qrImage: json['qrImage'],
    );
  }
}
