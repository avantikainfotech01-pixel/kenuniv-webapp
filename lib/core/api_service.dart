import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File, Platform;
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String token;

  ApiService({required this.token});

  // --- Common headers ---
  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // --- GET Request ---
  Future<dynamic> getRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("GET request failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("GET error: $e");
    }
  }

  // --- PATCH Request ---
  Future<dynamic> patchRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("PATCH request failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("PATCH error: $e");
    }
  }

  // --- POST Request ---
  Future<dynamic> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(Uri.parse(url), body: json.encode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception("POST request failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("POST error: $e");
    }
  }

  // --- PUT Request ---
  Future<dynamic> putRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("PUT request failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("PUT error: $e");
    }
  }

  // --- DELETE Request ---
  Future<dynamic> deleteRequest(String url) async {
    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("DELETE request failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("DELETE error: $e");
    }
  }

  // --- Multipart POST Request (for file upload like image) ---
  Future<dynamic> postMultipartRequest(
    String url,
    Map<String, String> fields,
    String fileField,
    dynamic file,
  ) async {
    final dio = Dio();
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: use http.MultipartRequest
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll(headers);
        request.fields.addAll(fields);
        if (file is File) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, file.path),
          );
        } else {
          throw Exception('For Mobile, file must be a File instance');
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          throw Exception("Multipart POST failed: ${response.body}");
        }
      } else {
        // Web: use Dio with FormData
        if (file is Uint8List) {
          FormData formData = FormData.fromMap({
            ...fields,
            fileField: MultipartFile.fromBytes(file, filename: "upload_file"),
          });

          final response = await dio.post(
            url,
            data: formData,
            options: Options(
              headers: {
                "Authorization": "Bearer $token",
                // Remove content-type to let Dio set it as multipart/form-data
              },
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            return response.data;
          } else {
            throw Exception("Multipart POST failed: ${response.statusMessage}");
          }
        } else {
          throw Exception('For Web, file must be a Uint8List instance');
        }
      }
    } catch (e) {
      throw Exception("Multipart POST error: $e");
    }
  }
}
