enum TicketStatus { aktif, digunakan, kadaluarsa }

class TicketModel {
  final String id; // kode tiket unik, dipakai sebagai isi QR
  final String orderId;
  final String eventTitle;
  final String eventImage;
  final String eventDate;
  final String eventTime;
  final String eventLocation;
  final String ticketType; // Reguler / VIP / dll
  final String price;
  final TicketStatus status;

  TicketModel({
    required this.id,
    required this.orderId,
    required this.eventTitle,
    required this.eventImage,
    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.ticketType,
    required this.price,
    required this.status,
  });

  String get statusLabel {
    switch (status) {
      case TicketStatus.aktif:
        return 'Aktif';
      case TicketStatus.digunakan:
        return 'Sudah Digunakan';
      case TicketStatus.kadaluarsa:
        return 'Kadaluarsa';
    }
  }
}
