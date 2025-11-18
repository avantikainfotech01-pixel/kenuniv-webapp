import 'scheme_model.dart';

class Stock {
  final String? id;
  final String itemName;
  final int quantity;
  final int minQty;
  final Scheme? schemeId;

  Stock({
    this.id,
    required this.itemName,
    required this.quantity,
    required this.minQty,
    this.schemeId,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    // Extract nested schemeId
    final schemeData = json['schemeId'];

    Scheme? parsedScheme;
    if (schemeData != null) {
      if (schemeData is Map<String, dynamic>) {
        // Case 1: populated or partial scheme object
        if (schemeData.containsKey('_id')) {
          parsedScheme = Scheme(
            id: schemeData['_id'] as String?,
            schemeName: schemeData['schemeName'] ?? '',
            productName: schemeData['productName'] ?? '',
            points: (schemeData['points'] ?? 0).toInt(),
          );
        } else {
          parsedScheme = Scheme.fromJson(schemeData);
        }
      } else if (schemeData is String) {
        // Case 2: plain string ID
        parsedScheme = Scheme(
          id: schemeData,
          schemeName: '',
          productName: '',
          points: 0,
        );
      }
    }

    return Stock(
      id: json['_id'] as String?,
      itemName: json['itemName'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      minQty: (json['minQty'] ?? 0).toInt(),
      schemeId: parsedScheme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'itemName': itemName,
      'quantity': quantity,
      'minQty': minQty,
      if (schemeId?.id != null) 'schemeId': schemeId!.id,
    };
  }
}
