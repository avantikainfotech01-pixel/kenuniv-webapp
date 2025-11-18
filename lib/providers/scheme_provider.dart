import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
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

  Future<void> fetchSchemes() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiService.getRequest(
        '$baseUrl/api/admin/fetch-schemes',
      );
      final List<dynamic> data = response['data'] ?? [];
      final schemes = data.map((e) => Scheme.fromJson(e)).toList();
      state = AsyncValue.data(schemes.cast<Scheme>());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addScheme({
    required Uint8List imageBytes,
    required String schemeName,
    required String productName,
    required int points,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('schemeName', schemeName),
        MapEntry('productName', productName),
        MapEntry('points', points.toString()),
        MapEntry('status', 'active'),
      ]);

      formData.files.add(
        MapEntry(
          'image',
          kIsWeb
              ? MultipartFile.fromBytes(
                  imageBytes,
                  filename: 'scheme_image.jpg',
                  contentType: MediaType('image', 'jpeg'),
                )
              : await MultipartFile.fromFile(
                  (imageBytes as File).path,
                  filename: 'scheme_image.jpg',
                ),
        ),
      );

      final dio = Dio();
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

  Future<void> deleteScheme(String id) async {
    try {
      await apiService.deleteRequest('$baseUrl/api/admin/schemes/$id');
      await fetchSchemes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> activateScheme(String id) async {
    try {
      final dio = Dio();
      final response = await dio.patch(
        '$baseUrl/api/admin/schemes/$id/status',
        data: {'status': 'active'},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('Activate response: ${response.data}');
      await fetchSchemes();
    } catch (e, st) {
      print('Activate error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deactivateScheme(String id) async {
    try {
      final dio = Dio();
      final response = await dio.patch(
        '$baseUrl/api/admin/schemes/$id/status',
        data: {'status': 'inactive'},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('Deactivate response: ${response.data}');
      await fetchSchemes();
    } catch (e, st) {
      print('Deactivate error: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final schemeProvider =
    StateNotifierProvider<SchemeNotifier, AsyncValue<List<Scheme>>>(
      (ref) => SchemeNotifier(ApiService(token: "")),
    );
