import 'event_model.dart';

enum TicketStatus { menunggu, aktif, digunakan, kadaluarsa, dibatalkan }

class TicketModel {
  final int registrationId;
  final String id; // kode tiket, dipakai sebagai isi QR
  final int eventId;
  final String eventTitle;
  final String? eventImage;
  final String eventDate;
  final String eventTime;
  final String eventLocation;
  final int jumlah;
  final int totalHarga;
  final String metode;
  final TicketStatus status;

  TicketModel({
    required this.registrationId,
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventImage,
    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.jumlah,
    required this.totalHarga,
    required this.metode,
    required this.status,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final event = EventModel.fromJson(Map<String, dynamic>.from(json['event']));

    TicketStatus status;
    switch (json['status']) {
      case 'menunggu_pembayaran':
        status = TicketStatus.menunggu;
        break;
      case 'hadir':
        status = TicketStatus.digunakan;
        break;
      case 'dibatalkan':
        status = TicketStatus.dibatalkan;
        break;
      default:
        status = event.isLewat ? TicketStatus.kadaluarsa : TicketStatus.aktif;
    }

    return TicketModel(
      registrationId: json['id'] as int,
      id: json['kode'] ?? '',
      eventId: event.id,
      eventTitle: event.judul,
      eventImage: event.bannerUrl,
      eventDate: event.tanggalLabel,
      eventTime: event.waktu ?? '-',
      eventLocation: event.lokasi,
      jumlah: json['jumlah'] ?? 1,
      totalHarga: json['total_harga'] ?? 0,
      metode: json['metode'] ?? 'gratis',
      status: status,
    );
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.menunggu:
        return 'Menunggu Pembayaran';
      case TicketStatus.aktif:
        return 'Aktif';
      case TicketStatus.digunakan:
        return 'Sudah Digunakan';
      case TicketStatus.kadaluarsa:
        return 'Kadaluarsa';
      case TicketStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  String get totalLabel => formatRupiah(totalHarga);

  bool get bisaDibatalkan =>
      status == TicketStatus.menunggu ||
      (status == TicketStatus.aktif && metode == 'gratis');
}
