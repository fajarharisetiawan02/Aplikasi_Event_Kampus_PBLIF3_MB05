import '../models/ticket_model.dart';
import 'api_client.dart';

class TicketService {
  static Future<List<TicketModel>> getMyTickets() async {
    final body = await ApiClient.get('/my-tickets');
    final list = body['data'] as List;
    return list.map((e) => TicketModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<TicketModel> register({required int eventId, int jumlah = 1}) async {
    final body = await ApiClient.post('/events/$eventId/register', body: {'jumlah': jumlah});
    return TicketModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  static Future<TicketModel> cancel(int registrationId) async {
    final body = await ApiClient.post('/tickets/$registrationId/cancel');
    return TicketModel.fromJson(Map<String, dynamic>.from(body['data']));
  }
}
