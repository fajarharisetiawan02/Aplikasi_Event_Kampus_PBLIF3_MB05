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

  // Data pembayaran QRIS (hanya ada untuk metode "qris").
  final int? payAmount;
  final String? qris;
  final DateTime? expiresAt;

  // Hanya untuk event tim: nama tim dan daftar anggotanya.
  final String? namaTim;
  final List<AnggotaTim> anggota;

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
    this.payAmount,
    this.qris,
    this.expiresAt,
    this.namaTim,
    this.anggota = const [],
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

    final bayar = json['pembayaran'] is Map ? Map<String, dynamic>.from(json['pembayaran']) : null;

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
      payAmount: bayar?['pay_amount'] as int?,
      qris: bayar?['qris'] as String?,
      expiresAt: bayar?['expires_at'] == null ? null : DateTime.tryParse(bayar!['expires_at'] as String)?.toLocal(),
      namaTim: json['nama_tim'] as String?,
      anggota: json['anggota'] is List
          ? (json['anggota'] as List)
              .map((a) => AnggotaTim.fromJson(Map<String, dynamic>.from(a)))
              .toList()
          : const [],
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

  bool get isTim => namaTim != null;

  String get totalLabel => formatRupiah(totalHarga);

  // Nominal yang harus dibayar lewat QRIS. Bisa berbeda beberapa rupiah dari harga tiket.
  String get payAmountLabel => formatRupiah(payAmount ?? totalHarga);

  String get metodeLabel {
    switch (metode) {
      case 'gratis':
        return 'Gratis';
      case 'qris':
        return 'QRIS';
      default:
        return 'Tunai ke panitia';
    }
  }

  bool get menungguQris => status == TicketStatus.menunggu && metode == 'qris' && qris != null;

  bool get bisaDibatalkan =>
      status == TicketStatus.menunggu ||
      (status == TicketStatus.aktif && metode == 'gratis');
}

class AnggotaTim {
  final String nama;
  final String? keterangan;

  const AnggotaTim({required this.nama, this.keterangan});

  factory AnggotaTim.fromJson(Map<String, dynamic> json) => AnggotaTim(
        nama: json['nama'] ?? '',
        keterangan: json['keterangan'] as String?,
      );

  Map<String, dynamic> toJson() => {'nama': nama, 'keterangan': keterangan};
}
