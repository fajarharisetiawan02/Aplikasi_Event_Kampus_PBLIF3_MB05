import 'api_client.dart';

// Pengajuan menjadi penyelenggara (sisi mahasiswa).
class PengajuanService {
  // Mengembalikan URL bukti yang dikirim lagi lewat bukti_url saat mengajukan.
  static Future<String> uploadBukti(List<int> bytes, String filename) async {
    final body = await ApiClient.upload('/pengajuan-penyelenggara/bukti', 'bukti', bytes, filename);
    return body['data']['bukti_url'] as String;
  }

  static Future<String> ajukan({
    required String organisasi,
    required String jabatan,
    String? buktiUrl,
  }) async {
    final body = await ApiClient.post('/pengajuan-penyelenggara', body: {
      'organisasi': organisasi,
      'jabatan': jabatan,
      'bukti_url': ?buktiUrl,
    });
    return '${body['message']}';
  }
}
