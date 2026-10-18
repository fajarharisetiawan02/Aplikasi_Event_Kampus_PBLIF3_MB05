import 'package:flutter/material.dart';

// Data event penyelenggara untuk tampilan (belum terhubung ke backend).
// Daftar disimpan di memori, jadi hilang saat aplikasi ditutup.

enum StatusEvent { draft, terbit, selesai }

class OrganizerEvent {
  final String id;
  final String judul;
  final String kategori;
  final String deskripsi;
  final DateTime tanggal;
  final TimeOfDay waktu;
  final String lokasi;
  final String alamat;
  final String? banner;
  final int harga; // 0 = gratis
  final int kuota;
  final int terjual;
  final StatusEvent status;

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
  });

  bool get gratis => harga == 0;

  OrganizerEvent copyWith({
    String? judul,
    String? kategori,
    String? deskripsi,
    DateTime? tanggal,
    TimeOfDay? waktu,
    String? lokasi,
    String? alamat,
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
      banner: banner,
      harga: harga ?? this.harga,
      kuota: kuota ?? this.kuota,
      terjual: terjual,
      status: status ?? this.status,
    );
  }
}

const kategoriEvent = ['Seminar', 'Workshop', 'Musik', 'Olahraga', 'Lomba', 'Lainnya'];

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

final ValueNotifier<List<OrganizerEvent>> organizerEvents = ValueNotifier<List<OrganizerEvent>>([
  OrganizerEvent(
    id: 'e1',
    judul: 'Festival Musik Batam',
    kategori: 'Musik',
    deskripsi: 'Festival musik tahunan dengan penampil band lokal dan nasional.',
    tanggal: DateTime(2026, 10, 20),
    waktu: const TimeOfDay(hour: 16, minute: 0),
    lokasi: 'Lapangan Engku Putri',
    alamat: 'Jl. Engku Putri, Batam Centre, Batam',
    banner: 'assets/images/festival_musik.png',
    harga: 150000,
    kuota: 500,
    terjual: 128,
    status: StatusEvent.terbit,
  ),
  OrganizerEvent(
    id: 'e2',
    judul: 'Seminar Teknologi 2026',
    kategori: 'Seminar',
    deskripsi: 'Seminar tentang tren teknologi dan peluang karier bagi mahasiswa.',
    tanggal: DateTime(2026, 10, 25),
    waktu: const TimeOfDay(hour: 9, minute: 0),
    lokasi: 'Aula Polibatam',
    alamat: 'Jl. Ahmad Yani, Batam Centre, Batam',
    banner: 'assets/images/seminar_teknologi.png',
    harga: 0,
    kuota: 300,
    terjual: 187,
    status: StatusEvent.terbit,
  ),
  OrganizerEvent(
    id: 'e3',
    judul: 'Workshop UI/UX untuk Pemula',
    kategori: 'Workshop',
    deskripsi: 'Belajar dasar desain antarmuka langsung dengan praktik.',
    tanggal: DateTime(2026, 11, 8),
    waktu: const TimeOfDay(hour: 13, minute: 0),
    lokasi: 'Lab Multimedia',
    alamat: 'Gedung Teknik Informatika, Polibatam',
    banner: null,
    harga: 25000,
    kuota: 40,
    terjual: 0,
    status: StatusEvent.draft,
  ),
  OrganizerEvent(
    id: 'e4',
    judul: 'Lomba Futsal Antar Jurusan',
    kategori: 'Olahraga',
    deskripsi: 'Turnamen futsal tahunan antar jurusan.',
    tanggal: DateTime(2026, 9, 12),
    waktu: const TimeOfDay(hour: 8, minute: 0),
    lokasi: 'Lapangan Futsal Kampus',
    alamat: 'Area olahraga Polibatam',
    banner: null,
    harga: 50000,
    kuota: 80,
    terjual: 76,
    status: StatusEvent.selesai,
  ),
]);

int _urut = 100;
String idBaru() => 'e${_urut++}';

void simpanEvent(OrganizerEvent e) {
  final list = List<OrganizerEvent>.from(organizerEvents.value);
  final i = list.indexWhere((x) => x.id == e.id);
  if (i >= 0) {
    list[i] = e;
  } else {
    list.insert(0, e);
  }
  organizerEvents.value = list;
}

void hapusEvent(String id) {
  organizerEvents.value = organizerEvents.value.where((e) => e.id != id).toList();
}
