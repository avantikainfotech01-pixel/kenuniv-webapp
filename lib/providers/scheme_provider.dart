import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' hide MultipartFile;
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/utils/constant.dart';
import '../models/scheme_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';

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

      // ✅ API returns { success: true, schemes: [...] }
      final List<dynamic> data = response['schemes'] ?? [];
      final schemes = data.map((e) => Scheme.fromJson(e)).toList();
      state = AsyncValue.data(schemes.cast<Scheme>());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addScheme({
    required dynamic imageFile, // File on mobile, Uint8List on web
    required String schemeName,
    required String productName,
    required int points,
  }) async {
    try {
      final formData = FormData();

      formData.fields
        ..add(MapEntry('schemeName', schemeName))
        ..add(MapEntry('productName', productName))
        ..add(MapEntry('points', points.toString()))
        ..add(MapEntry('status', 'active'));

      if (kIsWeb) {
        // On web, imageFile is Uint8List
        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              imageFile as Uint8List,
              filename: 'scheme_image.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      } else {
        // On mobile, imageFile is File
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              (imageFile as File).path,
              filename: 'scheme_image.jpg',
            ),
          ),
        );
      }

      // Use Dio directly for multipart upload
      final dio = Dio();
      await dio.post(
        '$baseUrl/api/admin/schemes',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${apiService.token}',
            'Content-Type': 'multipart/form-data',
          },
        ),
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
      await apiService.patchRequest('$baseUrl/api/admin/schemes/$id/status', {
        'status': 'active',
      });
      await fetchSchemes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deactivateScheme(String id) async {
    try {
      await apiService.patchRequest('$baseUrl/api/admin/schemes/$id/status', {
        'status': 'inactive',
      });
      await fetchSchemes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final schemeProvider =
    StateNotifierProvider<SchemeNotifier, AsyncValue<List<Scheme>>>(
      (ref) => SchemeNotifier(ApiService(token: "")),
    );
