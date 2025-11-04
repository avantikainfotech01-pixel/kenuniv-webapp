import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kenuniv/models/qr_model.dart';

// StateNotifier for managing QR list
class QrNotifier extends StateNotifier<List<QrData>> {
  QrNotifier() : super([]);

  Future<void> generateQrs({
    required int serialFrom,
    required int serialTo,
    required int points,
  }) async {
    final url = Uri.parse('http://localhost:3000/api/generate-qrs');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'serialFrom': serialFrom,
        'serialTo': serialTo,
        'points': points,
        'expiryYears': 1,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> qrsJson = jsonData['qrs'];
      final List<QrData> qrs = qrsJson.map((e) => QrData.fromJson(e)).toList();
      state = qrs;
    } else {
      throw Exception('Failed to generate QR codes');
    }
  }

  Future<void> activateQrs({
    required int serialFrom,
    required int serialTo,
  }) async {
    final url = Uri.parse('http://localhost:3000/api/activate-qr');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'serialFrom': serialFrom, 'serialTo': serialTo}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to activate QR codes');
    }
  }

  Future<void> inactivateQrs({
    required int serialFrom,
    required int serialTo,
  }) async {
    final url = Uri.parse('http://localhost:3000/api/deactivate-qr');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'serialFrom': serialFrom, 'serialTo': serialTo}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to inactivate QR codes');
    }
  }

  Future<void> fetchQrs() async {
    final url = Uri.parse('http://localhost3000/api/qrs');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> qrsJson = jsonData['qrs'];
      final List<QrData> qrs = qrsJson.map((e) => QrData.fromJson(e)).toList();
      state = qrs;
    } else {
      throw Exception('Failed to fetch QRs');
    }
  }

  Future<List<QrData>> fetchQrHistory() async {
    final url = Uri.parse('http://localhost:3000/api/qr-history');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> historyJson = jsonData['history'];
      return historyJson.map((e) => QrData.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch QR history');
    }
  }
}

// Provider registration
final qrProvider = StateNotifierProvider<QrNotifier, List<QrData>>((ref) {
  return QrNotifier();
});

/// Provider to fetch QR stats (activated, inactivated) from API
final qrStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final url = Uri.parse('http://localhost:3000/api/qr-stats');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    return {
      'active': jsonData['active'] as int,
      'inactive': jsonData['inactive'] as int,
    };
  } else {
    throw Exception('Failed to fetch QR stats');
  }
});
