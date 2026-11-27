import 'package:flutter/material.dart';
import '../services/event_service.dart';

// Data event penyelenggara, diambil dari API (database).
// draft = belum diajukan, menunggu = menunggu persetujuan admin,
// terbit = sudah disetujui dan tampil ke mahasiswa, ditolak = ditolak admin.

enum StatusEvent { draft, menunggu, terbit, ditolak, selesai, dibatalkan }

class OrganizerEvent {
  final String id;
  final String judul;
  final String kategori;
  final String deskripsi;
  final DateTime tanggal;
  final TimeOfDay waktu;
  final String lokasi;
  final String alamat;
  final String narahubung;
  final String narahubungTelepon;
  final String tipe; // tiket, daftar, atau tim
  final int? minAnggota;
  final int? maxAnggota;
  final String? banner;
  final int harga; // 0 = gratis
  final int kuota;
  final int terjual;
  final StatusEvent status;
  final String? alasanPenolakan;

  const OrganizerEvent({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.deskripsi,
    required this.tanggal,
    required this.waktu,
    required this.lokasi,
    required this.alamat,
    required this.banner,
    required this.harga,
    required this.kuota,
    required this.terjual,
    required this.status,
    this.narahubung = '',
    this.narahubungTelepon = '',
    this.tipe = 'daftar',
    this.minAnggota,
    this.maxAnggota,
    this.alasanPenolakan,
  });

  bool get gratis => harga == 0;

  factory OrganizerEvent.fromApi(Map<String, dynamic> j) {
    final tanggal = DateTime.parse(j['tanggal'] as String);
    final hariIni = DateTime.now();
    final lewat = tanggal.isBefore(DateTime(hariIni.year, hariIni.month, hariIni.day));

    final StatusEvent status;
    switch (j['status']) {
      case 'draft':
        status = StatusEvent.draft;
      case 'pending':
        status = StatusEvent.menunggu;
      case 'rejected':
        status = StatusEvent.ditolak;
      case 'cancelled':
        status = StatusEvent.dibatalkan;
      default:
        status = lewat ? StatusEvent.selesai : StatusEvent.terbit;
    }

    return OrganizerEvent(
      id: '${j['id']}',
      judul: j['judul'] ?? '',
      kategori: j['kategori'] ?? '',
      deskripsi: j['deskripsi'] ?? '',
      tanggal: tanggal,
      waktu: _bacaWaktu(j['waktu'] as String?),
      lokasi: j['lokasi'] ?? '',
      alamat: j['alamat'] ?? '',
      narahubung: j['narahubung'] ?? '',
      narahubungTelepon: j['narahubung_telepon'] ?? '',
      tipe: j['tipe'] ?? 'daftar',
      minAnggota: j['min_anggota'] as int?,
      maxAnggota: j['max_anggota'] as int?,
      banner: j['banner_url'] as String?,
      harga: j['harga'] ?? 0,
      kuota: j['kuota'] ?? 0,
      terjual: j['kuota_terjual'] ?? 0,
      status: status,
      alasanPenolakan: j['alasan_penolakan'] as String?,
    );
  }

  // Yang dikirim ke API. Status hanya "draft" atau "diajukan" (pending);
  // persetujuan sepenuhnya urusan admin di server.
  Map<String, dynamic> toApi() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'banner_url': banner,
      'tanggal': '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
      'waktu': waktuEvent(waktu),
      'lokasi': lokasi,
      'alamat': alamat.isEmpty ? null : alamat,
      'narahubung': narahubung.isEmpty ? null : narahubung,
      'narahubung_telepon': narahubungTelepon.isEmpty ? null : narahubungTelepon,
      'harga': harga,
      'kuota': kuota,
      'tipe': tipe,
      'min_anggota': tipe == 'tim' ? minAnggota : null,
      'max_anggota': tipe == 'tim' ? maxAnggota : null,
      'status': status == StatusEvent.draft ? 'draft' : 'pending',
    };
  }

  OrganizerEvent copyWith({
    String? judul,
    String? kategori,
    String? deskripsi,
    DateTime? tanggal,
    TimeOfDay? waktu,
    String? lokasi,
    String? alamat,
    String? narahubung,
    String? narahubungTelepon,
    String? tipe,
    int? minAnggota,
    int? maxAnggota,
    int? harga,
    int? kuota,
    StatusEvent? status,
  }) {
    return OrganizerEvent(
      id: id,
      judul: judul ?? this.judul,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      lokasi: lokasi ?? this.lokasi,
      alamat: alamat ?? this.alamat,
      narahubung: narahubung ?? this.narahubung,
      narahubungTelepon: narahubungTelepon ?? this.narahubungTelepon,
      tipe: tipe ?? this.tipe,
      minAnggota: minAnggota ?? this.minAnggota,
      maxAnggota: maxAnggota ?? this.maxAnggota,
      banner: banner,
      harga: harga ?? this.harga,
      kuota: kuota ?? this.kuota,
      terjual: terjual,
      status: status ?? this.status,
      alasanPenolakan: alasanPenolakan,
    );
  }
}

// "09.00 WIB" atau "19.00 WIB - Selesai" -> 09:00 / 19:00
TimeOfDay _bacaWaktu(String? teks) {
  final m = RegExp(r'(\d{1,2})[.:](\d{2})').firstMatch(teks ?? '');
  if (m == null) return const TimeOfDay(hour: 9, minute: 0);
  return TimeOfDay(hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
}

const kategoriEvent = ['Musik', 'Olahraga', 'Seminar', 'Seni', 'Teknologi'];

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String tanggalEvent(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String waktuEvent(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h.$m WIB';
}

final ValueNotifier<List<OrganizerEvent>> organizerEvents = ValueNotifier<List<OrganizerEvent>>([]);

Future<void> muatEventSaya() async {
  final data = await EventService.getMine();
  organizerEvents.value = data.map(OrganizerEvent.fromApi).toList();
}

// Id kosong = event baru. Mengembalikan event hasil simpan dari server.
Future<OrganizerEvent> simpanEvent(OrganizerEvent e) async {
  final id = int.tryParse(e.id);
  final hasil = id == null
      ? await EventService.create(e.toApi())
      : await EventService.update(id, e.toApi());
  final baru = OrganizerEvent.fromApi(hasil);

  final list = List<OrganizerEvent>.from(organizerEvents.value);
  final i = list.indexWhere((x) => x.id == baru.id);
  if (i >= 0) {
    list[i] = baru;
  } else {
    list.insert(0, baru);
  }
  organizerEvents.value = list;
  return baru;
}

Future<void> hapusEvent(String id) async {
  final angka = int.tryParse(id);
  if (angka != null) await EventService.delete(angka);
  organizerEvents.value = organizerEvents.value.where((e) => e.id != id).toList();
}
