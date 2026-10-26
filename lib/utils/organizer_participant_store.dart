import 'package:flutter/foundation.dart';

// Data peserta untuk tampilan penyelenggara (belum terhubung ke backend).
// Dipakai bersama oleh layar Peserta dan layar Scan, jadi saat pembayaran
// diterima lewat scan, daftar peserta ikut berubah.

enum StatusPeserta { menunggu, lunas, hadir, batal }

String labelStatus(StatusPeserta s) {
  switch (s) {
    case StatusPeserta.menunggu:
      return 'Menunggu bayar';
    case StatusPeserta.lunas:
      return 'Lunas';
    case StatusPeserta.hadir:
      return 'Hadir';
    case StatusPeserta.batal:
      return 'Dibatalkan';
  }
}

class PesertaEvent {
  final String id;
  final String nama;
  final String nim;
  final String event;
  final int harga; // 0 = gratis
  final StatusPeserta status;

  const PesertaEvent({
    required this.id,
    required this.nama,
    required this.nim,
    required this.event,
    required this.harga,
    required this.status,
  });

  // Tiket yang belum lunas menampilkan QR bayar, sisanya QR masuk.
  String get kodeQr => status == StatusPeserta.menunggu ? 'PAY-$id' : 'IN-$id';

  PesertaEvent copyWith({StatusPeserta? status}) {
    return PesertaEvent(
      id: id,
      nama: nama,
      nim: nim,
      event: event,
      harga: harga,
      status: status ?? this.status,
    );
  }
}

final ValueNotifier<List<PesertaEvent>> daftarPeserta = ValueNotifier<List<PesertaEvent>>([
  const PesertaEvent(
    id: 'p1',
    nama: 'Andi Pratama',
    nim: '3312511101',
    event: 'Seminar Teknologi 2026',
    harga: 0,
    status: StatusPeserta.lunas,
  ),
  const PesertaEvent(
    id: 'p2',
    nama: 'Siti Aulia',
    nim: '3312511102',
    event: 'Festival Musik Batam',
    harga: 150000,
    status: StatusPeserta.hadir,
  ),
  const PesertaEvent(
    id: 'p3',
    nama: 'Rizky Ramadhan',
    nim: '3312511103',
    event: 'Festival Musik Batam',
    harga: 150000,
    status: StatusPeserta.menunggu,
  ),
  const PesertaEvent(
    id: 'p4',
    nama: 'Nadia Putri',
    nim: '3312511104',
    event: 'Seminar Teknologi 2026',
    harga: 0,
    status: StatusPeserta.hadir,
  ),
  const PesertaEvent(
    id: 'p5',
    nama: 'Budi Santoso',
    nim: '3312511105',
    event: 'Festival Musik Batam',
    harga: 150000,
    status: StatusPeserta.menunggu,
  ),
  const PesertaEvent(
    id: 'p6',
    nama: 'Dewi Lestari',
    nim: '3312511106',
    event: 'Festival Musik Batam',
    harga: 150000,
    status: StatusPeserta.lunas,
  ),
]);

PesertaEvent? cariPeserta(String id) {
  for (final p in daftarPeserta.value) {
    if (p.id == id) return p;
  }
  return null;
}

void ubahStatusPeserta(String id, StatusPeserta status) {
  daftarPeserta.value = [
    for (final p in daftarPeserta.value) p.id == id ? p.copyWith(status: status) : p,
  ];
}

List<String> daftarNamaEvent() {
  final hasil = <String>[];
  for (final p in daftarPeserta.value) {
    if (!hasil.contains(p.event)) hasil.add(p.event);
  }
  return hasil;
}

// Dipakai supaya halaman lain (misalnya dashboard) bisa meminta layar Peserta
// langsung memakai filter tertentu. Dibuat objek baru tiap kali agar selalu memicu.
class PermintaanFilter {
  final StatusPeserta? status;
  PermintaanFilter(this.status);
}

final ValueNotifier<PermintaanFilter?> permintaanFilterPeserta = ValueNotifier<PermintaanFilter?>(null);
