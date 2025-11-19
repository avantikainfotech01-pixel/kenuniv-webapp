import 'dart:io';
import 'dart:typed_data';
import 'package:dio/browser.dart' show BrowserHttpClientAdapter;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constant.dart';

final newsProvider =
    StateNotifierProvider<NewsNotifier, List<Map<String, dynamic>>>(
      (ref) => NewsNotifier(ref),
    );

class NewsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  late Dio dio;

  NewsNotifier(this.ref) : super([]) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // ❌ DO NOT SET content-type here for multipart on web
        headers: {'Accept': '*/*'},
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    if (kIsWeb) {
      dio.httpClientAdapter = BrowserHttpClientAdapter();
    }

    fetchNews();
  }

  // --------------------- FETCH NEWS ------------------------
  Future<void> fetchNews() async {
    try {
      final res = await dio.get('/api/admin/news');
      if (res.data['success'] == true) {
        state = List<Map<String, dynamic>>.from(res.data['news']);
      }
    } catch (e) {
      print("Fetch News Error: $e");
    }
  }

  // --------------------- ADD NEWS ------------------------
  Future<void> addNews({
    required dynamic mediaFile, // Uint8List for web
    required String mediaType,
    required String title,
    required String description,
    Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData();

      // WEB UPLOAD (Uint8List)
      if (kIsWeb) {
        formData.files.add(
          MapEntry(
            'media',
            MultipartFile.fromBytes(
              mediaFile,
              filename: mediaType == 'video'
                  ? 'news_video.mp4'
                  : 'news_image.jpg',
              // ❌ DO NOT SET contentType
            ),
          ),
        );
      } else {
        // MOBILE UPLOAD
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

      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('description', description));
      formData.fields.add(MapEntry('mediaType', mediaType));

      final res = await dio.post(
        '/api/admin/news',
        data: formData,
        // ❌ Do NOT manually set content-type; browser will break
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
        onSendProgress: onProgress,
      );

      if (res.data['success'] == true) {
        await fetchNews();
      } else {
        throw res.data['message'] ?? "Upload failed";
      }
    } catch (e) {
      print("Upload Error => $e");
      rethrow;
    }
  }

  // --------------------- DELETE NEWS ------------------------
  Future<void> deleteNews(String id) async {
    try {
      await dio.delete('/api/admin/news/$id');
      await fetchNews();
    } catch (e) {
      print("Delete error: $e");
    }
  }

  // ---------------- reorder local (UI only) ----------------
  Future<void> reorderLocal(int oldIndex, int newIndex) async {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  // move to top
  Future<void> moveToTop(String id) async {
    final list = [...state];
    final index = list.indexWhere((e) => e['_id'] == id);
    if (index > 0) {
      final item = list.removeAt(index);
      list.insert(0, item);
      state = list;
    }
  }
}
