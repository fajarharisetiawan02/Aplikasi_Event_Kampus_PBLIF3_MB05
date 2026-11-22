import '../models/panitia_model.dart';
import 'api_client.dart';

class PanitiaService {
  // ===== Penyelenggara =====

  static Future<List<PanitiaModel>> daftar(int eventId) async {
    final body = await ApiClient.get('/events/$eventId/panitia');
    final list = body['data'] as List;
    return list.map((e) => PanitiaModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // Mengembalikan pesan dari server dan apakah email undangan berhasil terkirim.
  static Future<({String pesan, bool emailTerkirim})> tambah({
    required int eventId,
    required String nama,
    required String email,
    required String noHp,
  }) async {
    final body = await ApiClient.post(
      '/events/$eventId/panitia',
      body: {'nama': nama, 'email': email, 'no_hp': noHp},
    );
    return (pesan: '${body['message']}', emailTerkirim: body['email_terkirim'] == true);
  }

  static Future<String> kirimUlang(int eventId, int panitiaId) async {
    final body = await ApiClient.post('/events/$eventId/panitia/$panitiaId/kirim-ulang');
    return '${body['message']}';
  }

  static Future<void> hapus(int eventId, int panitiaId) async {
    await ApiClient.delete('/events/$eventId/panitia/$panitiaId');
  }

  // ===== Panitia =====

  static Future<PanitiaRingkasan> infoEvent() async {
    final body = await ApiClient.get('/panitia/event');
    return PanitiaRingkasan.fromJson(Map<String, dynamic>.from(body['data']));
  }

  static Future<HasilScan> scan(String kode) async {
    final body = await ApiClient.post('/panitia/scan', body: {'kode': kode});
    return HasilScan.fromJson(body);
  }

  static Future<List<PesertaHadir>> daftarHadir() async {
    final body = await ApiClient.get('/panitia/hadir');
    final list = body['data'] as List;
    return list.map((e) => PesertaHadir.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
