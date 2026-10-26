import 'package:flutter/foundation.dart';

// Data contoh untuk tampilan admin (belum terhubung ke backend).

enum StatusPengajuan { menunggu, disetujui, ditolak }

class Pengajuan {
  final String id;
  final String nama;
  final String email;
  final String organisasi;
  final String tanggal;
  final StatusPengajuan status;

  const Pengajuan({
    required this.id,
    required this.nama,
    required this.email,
    required this.organisasi,
    required this.tanggal,
    required this.status,
  });

  Pengajuan copyWith({StatusPengajuan? status}) {
    return Pengajuan(
      id: id,
      nama: nama,
      email: email,
      organisasi: organisasi,
      tanggal: tanggal,
      status: status ?? this.status,
    );
  }
}

class PenggunaAdmin {
  final String nama;
  final String email;
  final String peran; // Peserta, Penyelenggara, Admin
  final String bergabung;
  final bool aktif;

  const PenggunaAdmin({
    required this.nama,
    required this.email,
    required this.peran,
    required this.bergabung,
    required this.aktif,
  });

  PenggunaAdmin copyWith({String? peran, bool? aktif}) {
    return PenggunaAdmin(
      nama: nama,
      email: email,
      peran: peran ?? this.peran,
      bergabung: bergabung,
      aktif: aktif ?? this.aktif,
    );
  }
}

class EventAdmin {
  final String judul;
  final String penyelenggara;
  final String tanggal;
  final int terdaftar;
  final int kuota;
  final String status; // Terbit, Draft, Selesai

  const EventAdmin({
    required this.judul,
    required this.penyelenggara,
    required this.tanggal,
    required this.terdaftar,
    required this.kuota,
    required this.status,
  });
}

final ValueNotifier<List<Pengajuan>> daftarPengajuan =
    ValueNotifier<List<Pengajuan>>([
      const Pengajuan(
        id: 'a1',
        nama: 'Muhammad Rafie',
        email: 'Rafie@gmail.com',
        organisasi: 'BEM Polibatam',
        tanggal: '20 Okt 2026',
        status: StatusPengajuan.menunggu,
      ),
      const Pengajuan(
        id: 'a2',
        nama: 'Fajar Hari Setiawan',
        email: 'Fajar@gmail.com',
        organisasi: 'HIMA Informatika',
        tanggal: '20 Okt 2026',
        status: StatusPengajuan.menunggu,
      ),
      const Pengajuan(
        id: 'a3',
        nama: 'Ferli Saputra',
        email: 'Ferli@gmail.com',
        organisasi: 'UKM Musik',
        tanggal: '19 Okt 2026',
        status: StatusPengajuan.menunggu,
      ),
      const Pengajuan(
        id: 'a4',
        nama: 'Siti Aminah',
        email: 'siti.a@gmail.com',
        organisasi: 'Komunitas Fotografi',
        tanggal: '17 Okt 2026',
        status: StatusPengajuan.disetujui,
      ),
      const Pengajuan(
        id: 'a5',
        nama: 'Andi Wijaya',
        email: 'andi.w@gmail.com',
        organisasi: '-',
        tanggal: '15 Okt 2026',
        status: StatusPengajuan.ditolak,
      ),
    ]);

final ValueNotifier<List<PenggunaAdmin>> daftarPengguna =
    ValueNotifier<List<PenggunaAdmin>>([
      const PenggunaAdmin(
        nama: 'Admin EventIn',
        email: 'admin@eventin.test',
        peran: 'Admin',
        bergabung: '1 Okt 2026',
        aktif: true,
      ),
      const PenggunaAdmin(
        nama: 'Budi Santoso',
        email: 'budi.s@gmail.com',
        peran: 'Peserta',
        bergabung: '3 Okt 2026',
        aktif: true,
      ),
      const PenggunaAdmin(
        nama: 'Dewi Lestari',
        email: 'dewi.l@gmail.com',
        peran: 'Peserta',
        bergabung: '4 Okt 2026',
        aktif: true,
      ),
      const PenggunaAdmin(
        nama: 'Rafi Pratama',
        email: 'rafi.p@gmail.com',
        peran: 'Peserta',
        bergabung: '5 Okt 2026',
        aktif: true,
      ),
      const PenggunaAdmin(
        nama: 'Siti Aminah',
        email: 'siti.a@gmail.com',
        peran: 'Penyelenggara',
        bergabung: '6 Okt 2026',
        aktif: true,
      ),
      const PenggunaAdmin(
        nama: 'Andi Wijaya',
        email: 'andi.w@gmail.com',
        peran: 'Peserta',
        bergabung: '8 Okt 2026',
        aktif: true,
      ),
      const PenggunaAdmin(
        nama: 'Rizky Ramadhan',
        email: 'rizky.r@gmail.com',
        peran: 'Peserta',
        bergabung: '10 Okt 2026',
        aktif: false,
      ),
      const PenggunaAdmin(
        nama: 'Nadia Putri',
        email: 'nadia.p@gmail.com',
        peran: 'Peserta',
        bergabung: '12 Okt 2026',
        aktif: true,
      ),
    ]);

const daftarEventAdmin = [
  EventAdmin(
    judul: 'Festival Musik Batam',
    penyelenggara: 'Siti Aminah',
    tanggal: '20 Okt 2026',
    terdaftar: 128,
    kuota: 500,
    status: 'Terbit',
  ),
  EventAdmin(
    judul: 'Seminar Teknologi 2026',
    penyelenggara: 'Siti Aminah',
    tanggal: '25 Okt 2026',
    terdaftar: 187,
    kuota: 300,
    status: 'Terbit',
  ),
  EventAdmin(
    judul: 'Workshop UI/UX untuk Pemula',
    penyelenggara: 'Siti Aminah',
    tanggal: '8 Nov 2026',
    terdaftar: 0,
    kuota: 40,
    status: 'Draft',
  ),
  EventAdmin(
    judul: 'Lomba Futsal Antar Jurusan',
    penyelenggara: 'Siti Aminah',
    tanggal: '12 Sep 2026',
    terdaftar: 76,
    kuota: 80,
    status: 'Selesai',
  ),
];

// Menyetujui pengajuan juga mengubah peran penggunanya menjadi Penyelenggara.
// Mengembalikan ke "menunggu" mengembalikan perannya menjadi Peserta.
void ubahPengajuan(String id, StatusPengajuan status) {
  final lama = daftarPengajuan.value;
  final i = lama.indexWhere((p) => p.id == id);
  if (i < 0) return;

  final email = lama[i].email;
  final baru = List<Pengajuan>.from(lama);
  baru[i] = lama[i].copyWith(status: status);
  daftarPengajuan.value = baru;

  if (status == StatusPengajuan.ditolak) return;

  final peranBaru = status == StatusPengajuan.disetujui
      ? 'Penyelenggara'
      : 'Peserta';
  daftarPengguna.value = [
    for (final u in daftarPengguna.value)
      if (u.email == email && u.peran != 'Admin')
        u.copyWith(peran: peranBaru)
      else
        u,
  ];
}

void ubahAktifPengguna(String email) {
  daftarPengguna.value = [
    for (final u in daftarPengguna.value)
      if (u.email == email) u.copyWith(aktif: !u.aktif) else u,
  ];
}
