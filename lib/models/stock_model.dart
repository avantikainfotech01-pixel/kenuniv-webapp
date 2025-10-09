class Stock {
  final String id;
  final String itemName;
  final int quantity;
  final int minQty;
  final String? schemeId;

  Stock({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.minQty,
    this.schemeId,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['_id'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      minQty: json['minQty'] ?? 0,
      schemeId: json['schemeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'minQty': minQty,
      'schemeId': schemeId,
    };
  }
}
