import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/utils/constant.dart';
import '../models/scheme_model.dart';

class SchemeNotifier extends StateNotifier<AsyncValue<List<Scheme>>> {
  final ApiService apiService;

  SchemeNotifier(this.apiService) : super(const AsyncValue.loading()) {
    fetchSchemes();
  }

  // ---------------- FETCH ----------------
  Future<void> fetchSchemes() async {
    try {
      state = const AsyncValue.loading();
      final response = await apiService.getRequest(
        '$baseUrl/api/admin/fetch-schemes',
      );

      final List data = response['data'] ?? [];
      final schemes = data.map((e) => Scheme.fromJson(e)).toList();

      state = AsyncValue.data(schemes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ---------------- ADD ----------------
  // ---------------- ADD / EDIT ----------------
  Future<void> addScheme({
    String? id, // ✅ Added ID parameter for Editing
    dynamic imageData, // ✅ Made image optional for Editing
    required String schemeName,
    required String productName,
    required int points,
  }) async {
    try {
      final dio = Dio();

      // Dynamically build the form data
      final Map<String, dynamic> mapData = {
        if (id != null) 'id': id, // Send ID if editing
        'schemeName': schemeName,
        'productName': productName,
        'points': points.toString(),
        'status': 'active',
      };

      // Only attach image if a new one was selected
      if (imageData != null) {
        mapData['image'] = kIsWeb
            ? MultipartFile.fromBytes(
                imageData as Uint8List,
                filename: 'scheme.jpg',
                contentType: MediaType('image', 'jpeg'),
              )
            : await MultipartFile.fromFile(
                (imageData as File).path,
                filename: 'scheme.jpg',
              );
      }

      final formData = FormData.fromMap(mapData);

      await dio.post(
        '$baseUrl/api/admin/schemes',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      await fetchSchemes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      throw e;
    }
  }

  // ---------------- DELETE ----------------
  Future<void> deleteScheme(String id) async {
    try {
      // ✅ Added $baseUrl right before /api
      await apiService.deleteRequest('$baseUrl/api/admin/schemes/$id');
      await fetchSchemes();
    } catch (e) {
      debugPrint('Delete scheme failed: $e');
      // Optional: rethrow the error so your UI snackbar knows it failed
      throw e;
    }
  }

  // ---------------- ACTIVATE ----------------
  Future<void> activateScheme(String id) async {
    try {
      final dio = Dio();
      await dio.patch(
        '$baseUrl/api/admin/schemes/$id/status',
        data: {'status': 'active'},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      await fetchSchemes();
    } catch (e) {
      debugPrint('Activate failed: $e');
    }
  }

  // ---------------- DEACTIVATE ----------------
  Future<void> deactivateScheme(String id) async {
    try {
      final dio = Dio();
      await dio.patch(
        '$baseUrl/api/admin/schemes/$id/status',
        data: {'status': 'inactive'},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      await fetchSchemes();
    } catch (e) {
      debugPrint('Deactivate failed: $e');
    }
  }
}

// ---------------- PROVIDER ----------------
final schemeProvider =
    StateNotifierProvider<SchemeNotifier, AsyncValue<List<Scheme>>>(
      (ref) => SchemeNotifier(ApiService(token: "")),
    );
