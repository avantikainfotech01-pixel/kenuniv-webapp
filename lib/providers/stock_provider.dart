import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kenuniv/utils/constant.dart';
import '../models/stock_model.dart';

class StockNotifier extends StateNotifier<AsyncValue<List<Stock>>> {
  StockNotifier() : super(const AsyncValue.loading()) {
    fetchStocks();
  }

  Future<void> fetchStocks() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/admin/stocks"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List stocksData = data['stocks'] ?? [];
        final stocks = stocksData.map((s) => Stock.fromJson(s)).toList();
        state = AsyncValue.data(stocks.cast<Stock>());
      } else {
        throw Exception("Failed to load stocks");
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStock(Stock stock) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/stocks"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(stock.toJson()),
      );
      if (response.statusCode == 200) {
        await fetchStocks();
      } else {
        throw Exception("Failed to add stock");
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final stockProvider =
    StateNotifierProvider<StockNotifier, AsyncValue<List<Stock>>>(
      (ref) => StockNotifier(),
    );
