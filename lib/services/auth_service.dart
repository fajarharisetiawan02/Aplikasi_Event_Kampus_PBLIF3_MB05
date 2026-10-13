import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class AuthService {
  // Diisi saat run di HP asli: --dart-define=API_HOST=IP-LAPTOP
  static const String _host = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_host.isNotEmpty) return 'http://$_host:8000/api'; // HP asli
    if (kIsWeb) return 'http://localhost:8000/api'; // Chrome
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api'; // emulator
    }
    return 'http://localhost:8000/api';
  }

  static const Duration _timeout = Duration(seconds: 15);

  static UserModel? currentUser;
  static String? _token;
  static String? get token => _token;

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final res = await request().timeout(_timeout);
      final body = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw AuthException(_errorMessage(body));
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

  static String _errorMessage(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return body['message']?.toString() ?? 'Terjadi kesalahan.';
  }

  static UserModel _parseUser(Map<String, dynamic> body) =>
      UserModel.fromJson(Map<String, dynamic>.from(body['data']));

  // CREATE
  static Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    required String nim,
  }) async {
    final body = await _send(
      () => http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'password': password,
          'no_hp': noHp,
          'nim': nim,
        }),
      ),
    );
    return _parseUser(body);
  }

  // READ
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _send(
      () => http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    final user = _parseUser(body);
    _token = user.token;
    currentUser = user;
    return user;
  }

  static Future<UserModel> fetchProfile() async {
    final body = await _send(
      () => http.get(Uri.parse('$baseUrl/profile'), headers: _headers),
    );
    return currentUser = _parseUser(body);
  }

  // UPDATE
  static Future<UserModel> updateProfile({
    required String nama,
    required String nim,
    required String noHp,
  }) async {
    final body = await _send(
      () => http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: jsonEncode({'nama': nama, 'nim': nim, 'no_hp': noHp}),
      ),
    );
    return currentUser = _parseUser(body);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _send(
      () => http.put(
        Uri.parse('$baseUrl/password'),
        headers: _headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ),
    );
  }

  // DELETE
  static Future<void> deleteAccount({required String password}) async {
    await _send(
      () => http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: jsonEncode({'password': password}),
      ),
    );
    _clearSession();
  }

  static Future<void> logout() async {
    try {
      await _send(
        () => http.post(Uri.parse('$baseUrl/logout'), headers: _headers),
      );
    } on AuthException {
      // token sudah tidak valid di server, tetap keluar di sisi aplikasi
    }
    _clearSession();
  }

  static void _clearSession() {
    _token = null;
    currentUser = null;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}