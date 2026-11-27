import '../models/ticket_model.dart';
import 'api_client.dart';

class TicketService {
  static Future<List<TicketModel>> getMyTickets() async {
    final body = await ApiClient.get('/my-tickets');
    final list = body['data'] as List;
    return list.map((e) => TicketModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // metode: "cash" (bayar tunai ke panitia) atau "qris". Event gratis mengabaikannya.
  // Untuk event tim, kirim [namaTim] dan [anggota] (ketua ikut dihitung sebagai anggota).
  static Future<TicketModel> register({
    required int eventId,
    int jumlah = 1,
    String metode = 'cash',
    String? namaTim,
    List<AnggotaTim>? anggota,
  }) async {
    final body = await ApiClient.post('/events/$eventId/register', body: {
      'jumlah': jumlah,
      'metode': metode,
      if (namaTim != null) 'nama_tim': namaTim,
      if (anggota != null) 'anggota': anggota.map((a) => a.toJson()).toList(),
    });
    return TicketModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  static Future<TicketModel> cancel(int registrationId) async {
    final body = await ApiClient.post('/tickets/$registrationId/cancel');
    return TicketModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  // Status terbaru satu tiket. Untuk QRIS, server mencocokkannya dengan PayKita.
  static Future<TicketModel> status(int registrationId) async {
    final body = await ApiClient.get('/tickets/$registrationId/status');
    return TicketModel.fromJson(Map<String, dynamic>.from(body['data']));
  }
}
