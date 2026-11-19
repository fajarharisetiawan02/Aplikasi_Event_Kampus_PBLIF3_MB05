import '../models/event_model.dart';
import 'api_client.dart';

class EventService {
  static Future<List<EventModel>> getEvents() async {
    final body = await ApiClient.get('/events');
    final list = body['data'] as List;
    return list.map((e) => EventModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<EventModel> getById(int id) async {
    final body = await ApiClient.get('/events/$id');
    return EventModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  // Penyelenggara: event miliknya semua status. Admin: semua event (bisa disaring status).
  static Future<List<Map<String, dynamic>>> getMine({String? status}) async {
    final body = await ApiClient.get(
      '/my-events',
      query: status == null ? null : {'status': status},
    );
    return _daftar(body);
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final body = await ApiClient.post('/events', body: data);
    return Map<String, dynamic>.from(body['data']);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final body = await ApiClient.put('/events/$id', body: data);
    return Map<String, dynamic>.from(body['data']);
  }

  static Future<void> delete(int id) async {
    await ApiClient.delete('/events/$id');
  }

  // Mengembalikan URL banner yang dikirim lagi lewat banner_url saat simpan event.
  static Future<String> uploadBanner(List<int> bytes, String filename) async {
    final body = await ApiClient.upload('/events/banner', 'banner', bytes, filename);
    return body['data']['banner_url'] as String;
  }

  // Admin
  static Future<Map<String, dynamic>> approve(int id) async {
    final body = await ApiClient.put('/events/$id/approve');
    return Map<String, dynamic>.from(body['data']);
  }

  static Future<Map<String, dynamic>> reject(int id, String alasan) async {
    final body = await ApiClient.put('/events/$id/reject', body: {'alasan': alasan});
    return Map<String, dynamic>.from(body['data']);
  }

  static List<Map<String, dynamic>> _daftar(Map<String, dynamic> body) {
    return (body['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
