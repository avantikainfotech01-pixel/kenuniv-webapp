import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/utils/constant.dart';
import '../models/stock_model.dart';

final stockProvider = FutureProvider<List<Stock>>((ref) async {
  final response = await http.get(Uri.parse("$baseUrl/api/stocks"));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List stocks = data['stocks'];
    return stocks.map((s) => Stock.fromJson(s)).toList();
  } else {
    throw Exception("Failed to load stocks");
  }
});

Future<List<Stock>> fetchStocks() async {
  final response = await http.get(Uri.parse("$baseUrl/api/admin/stocks"));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List stocks = data['stocks'];
    return stocks.map((s) => Stock.fromJson(s)).toList();
  } else {
    throw Exception("Failed to fetch stocks");
  }
}

Future<Stock> createStock(Stock stock) async {
  final response = await http.post(
    Uri.parse("$baseUrl/api/admin/stocks"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(stock.toJson()),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return Stock.fromJson(data['stock']);
  } else {
    throw Exception("Failed to create stock");
  }
}
