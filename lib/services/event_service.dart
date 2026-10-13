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
}
