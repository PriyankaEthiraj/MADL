import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // localtunnel may show an interstitial unless this header is present
        if (baseUrl.contains('loca.lt') || baseUrl.contains('localtunnel.me'))
          'bypass-tunnel-reminder': 'true',
        if (token != null) 'Authorization': 'Bearer $token'
      };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response format');
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response format');
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response format');
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String path,
    required String filePath,
    String fieldName = 'proof',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

      if (baseUrl.contains('loca.lt') || baseUrl.contains('localtunnel.me')) {
        request.headers['bypass-tunnel-reminder'] = 'true';
      }
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final lowerPath = filePath.toLowerCase();
      MediaType? mediaType;
      if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
        mediaType = MediaType('image', 'jpeg');
      } else if (lowerPath.endsWith('.png')) {
        mediaType = MediaType('image', 'png');
      } else if (lowerPath.endsWith('.webp')) {
        mediaType = MediaType('image', 'webp');
      } else if (lowerPath.endsWith('.gif')) {
        mediaType = MediaType('image', 'gif');
      } else if (lowerPath.endsWith('.mp4')) {
        mediaType = MediaType('video', 'mp4');
      } else if (lowerPath.endsWith('.mov')) {
        mediaType = MediaType('video', 'quicktime');
      } else if (lowerPath.endsWith('.webm')) {
        mediaType = MediaType('video', 'webm');
      } else if (lowerPath.endsWith('.pdf')) {
        mediaType = MediaType('application', 'pdf');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          contentType: mediaType,
        ),
      );

      final response = await request.send().timeout(const Duration(seconds: 30));
      return _decodeStreamed(response);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response format');
    }
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final rawBody = response.body.trim();

    if (rawBody.isEmpty) {
      throw Exception('Empty response from server (HTTP ${response.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException {
      throw Exception(
        'Server returned non-JSON response (HTTP ${response.statusCode}). Check API URL/tunnel.'
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected server response format');
    }

    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request failed (HTTP ${response.statusCode})');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _decodeStreamed(http.StreamedResponse response) async {
    final rawBody = (await response.stream.bytesToString()).trim();

    if (rawBody.isEmpty) {
      throw Exception('Empty response from server (HTTP ${response.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException {
      throw Exception('Server returned non-JSON response (HTTP ${response.statusCode}).');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected server response format');
    }

    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request failed (HTTP ${response.statusCode})');
    }

    return decoded;
  }
}
