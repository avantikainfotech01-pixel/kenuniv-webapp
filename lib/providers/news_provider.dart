import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' hide MultipartFile;
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/utils/constant.dart';
import '../models/news_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';

class NewsNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final ApiService apiService;
  NewsNotifier(this.apiService) : super(const AsyncValue.loading()) {
    fetchNews();
  }

  Future<void> fetchNews() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiService.getRequest('$baseUrl/api/admin/news');
      final List<dynamic> data = response['news'] ?? [];
      final newsList = data.map((e) => News.fromJson(e)).toList();
      state = AsyncValue.data(newsList.cast<News>());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNews({
    required dynamic mediaFile, // File (mobile) or Uint8List (web)
    required String title,
    required String description,
    required String mediaType, // 'image' or 'video'
  }) async {
    try {
      final formData = FormData();

      formData.fields
        ..add(MapEntry('title', title))
        ..add(MapEntry('description', description))
        ..add(MapEntry('mediaType', mediaType));

      if (kIsWeb) {
        // ✅ Handle web upload (Uint8List)
        formData.files.add(
          MapEntry(
            'media',
            MultipartFile.fromBytes(
              mediaFile as Uint8List,
              filename: mediaType == 'video'
                  ? 'news_video.mp4'
                  : 'news_image.jpg',
              contentType: mediaType == 'video'
                  ? MediaType('video', 'mp4')
                  : MediaType('image', 'jpeg'),
            ),
          ),
        );
      } else {
        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(
              (mediaFile as File).path,
              filename: mediaType == 'video'
                  ? 'news_video.mp4'
                  : 'news_image.jpg',
            ),
          ),
        );
      }

      // ✅ Configure Dio for CORS-safe uploads
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Accept': '*/*',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          },
        ),
      );

      final response = await dio.post(
        '/api/admin/news',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print("✅ Upload success: ${response.data}");
      await fetchNews();
    } on DioException catch (dioErr) {
      print("❌ Dio Error: ${dioErr.message}");
      if (dioErr.response != null) {
        print("Server response: ${dioErr.response?.data}");
      }
      state = AsyncValue.error(dioErr, StackTrace.current);
    } catch (e, st) {
      print("❌ General Error: $e");
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      await apiService.deleteRequest('$baseUrl/api/admin/news/$id');
      await fetchNews();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final newsProvider =
    StateNotifierProvider<NewsNotifier, AsyncValue<List<News>>>(
      (ref) => NewsNotifier(ApiService(token: "")),
    );
