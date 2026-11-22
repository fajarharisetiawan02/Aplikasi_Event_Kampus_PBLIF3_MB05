import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class PanitiaService {
  static Future<void> tambahPanitia({
    required String nama,
    required String email,
    required String noHp,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/panitia'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'no_hp': noHp,
        'password': password,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception('Gagal menambah panitia');
    }
  }
}