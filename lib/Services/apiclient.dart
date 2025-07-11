import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Agrega esto

class ApiClient {
  final String baseUrl = 'http://:3000/api';

  // Obtiene el token guardado en SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Construye los headers incluyendo el token si existe
  Future<Map<String, String>> _buildHeaders([Map<String, String>? customHeaders]) async {
    final token = await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?customHeaders,
    };
    return headers;
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = '$baseUrl/$endpoint';
      print('POST: $url');
      final headers = await _buildHeaders(customHeaders);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error POST: $e');
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = '$baseUrl/$endpoint';
      print('GET: $url');
      final headers = await _buildHeaders(customHeaders);
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en la petición GET: $e');
    }
  }

  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = '$baseUrl/$endpoint';
      print('PATCH: $url');
      final headers = await _buildHeaders(customHeaders);
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error PATCH: $e');
    }
  }

  // Si usas postWithImage, también agrega el token:
 // Solo el método postWithImage, el resto igual
Future<dynamic> postWithImage(
  String endpoint,
  Map<String, dynamic> data,
  File image, {
  Map<String, String>? customHeaders,
}) async {
  try {
    final url = '$baseUrl/$endpoint';
    print('POST (multipart): $url');
    final headers = await _buildHeaders(customHeaders);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );
    request.headers.addAll(headers);

    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Siempre agrega la imagen como 'url_foto'
    var pic = await http.MultipartFile.fromPath(
      'urlFoto',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(pic);

    var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error en la petición con imagen: $e');
  }
}
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = '$baseUrl/$endpoint';
      print('DELETE: $url');
      final headers = await _buildHeaders(customHeaders);
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error DELETE: $e');
    }
  }
}