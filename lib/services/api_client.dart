import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// Pembungkus request ke API untuk endpoint selain akun. Token diambil dari AuthService.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send((headers) => http.get(_uri(path, query), headers: headers));
  }

  static Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send((headers) => http.post(_uri(path), headers: headers, body: jsonEncode(body ?? {})));
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${AuthService.baseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final token = AuthService.token;
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final res = await request(headers).timeout(_timeout);
      final body = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw AuthException(_errorMessage(body, res.statusCode));
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw AuthException('Server tidak merespons. Coba lagi.');
    } on FormatException {
      throw AuthException('Respons server tidak valid.');
    } catch (_) {
      throw AuthException('Tidak dapat terhubung ke server.');
    }
  }

  static String _errorMessage(Map<String, dynamic> body, int status) {
    if (status == 401) return 'Sesi login habis. Silakan masuk lagi.';
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return body['message']?.toString() ?? 'Terjadi kesalahan.';
  }
}
