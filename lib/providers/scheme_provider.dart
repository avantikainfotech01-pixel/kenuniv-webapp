import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
  Future<void> addScheme({
    required dynamic imageData, // Uint8List (web) OR File (mobile)
    required String schemeName,
    required String productName,
    required int points,
  }) async {
    try {
      final dio = Dio();

      final formData = FormData.fromMap({
        'schemeName': schemeName,
        'productName': productName,
        'points': points.toString(),
        'status': 'active',
        'image': kIsWeb
            ? MultipartFile.fromBytes(
                imageData as Uint8List,
                filename: 'scheme.jpg',
                contentType: MediaType('image', 'jpeg'),
              )
            : await MultipartFile.fromFile(
                (imageData as File).path,
                filename: 'scheme.jpg',
              ),
      });

      await dio.post(
        '$baseUrl/api/admin/schemes',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      await fetchSchemes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ---------------- DELETE ----------------
  Future<void> deleteScheme(String id) async {
    try {
      await apiService.deleteRequest('/api/admin/schemes/$id');
      await fetchSchemes();
    } catch (e) {
      debugPrint('Delete scheme failed: $e');
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
