import '../models/ticket_model.dart';

// data tiket masih hardcode dulu, belum dari backend

class TicketService {
  static Future<List<TicketModel>> getMyTickets() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      TicketModel(
        id: 'TIX-2026-000123',
        orderId: 'ORD-000045',
        eventTitle: 'Festival Musik Batam',
        eventImage: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800',
        eventDate: '20 Oktober 2026',
        eventTime: '19.00 WIB',
        eventLocation: 'Lapangan Engku Putri, Batam',
        ticketType: 'Reguler',
        price: 'Rp150.000',
        status: TicketStatus.aktif,
      ),
      TicketModel(
        id: 'TIX-2026-000124',
        orderId: 'ORD-000046',
        eventTitle: 'Seminar Teknologi',
        eventImage: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
        eventDate: '25 Oktober 2026',
        eventTime: '09.00 WIB',
        eventLocation: 'Aula Polibatam',
        ticketType: 'Gratis',
        price: 'Gratis',
        status: TicketStatus.aktif,
      ),
      TicketModel(
        id: 'TIX-2026-000098',
        orderId: 'ORD-000030',
        eventTitle: 'Turnamen Futsal Kampus',
        eventImage: 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=800',
        eventDate: '2 September 2026',
        eventTime: '13.00 WIB',
        eventLocation: 'GOR Kampus',
        ticketType: 'Reguler',
        price: 'Rp50.000',
        status: TicketStatus.digunakan,
      ),
    ];
  }
}