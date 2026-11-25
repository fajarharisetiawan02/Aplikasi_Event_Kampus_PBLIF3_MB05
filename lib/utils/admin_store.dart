import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

// Pengajuan penyelenggara diambil dari backend. Pengguna dan event masih data contoh.

enum StatusPengajuan { menunggu, disetujui, ditolak, dicabut }

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _tanggalIndonesia(String? iso) {
  final t = DateTime.tryParse(iso ?? '')?.toLocal();
  if (t == null) return '-';
  return '${t.day} ${_bulan[t.month - 1]} ${t.year}';
}

class Pengajuan {
  final String id;
  final String nama;
  final String email;
  final String organisasi;
  final String jabatan;
  final String? buktiUrl;
  final String? alasan;
  final String tanggal;
  final StatusPengajuan status;

  const Pengajuan({
    required this.id,
    required this.nama,
    required this.email,
    required this.organisasi,
    required this.tanggal,
    required this.status,
    this.jabatan = '',
    this.buktiUrl,
    this.alasan,
  });

  factory Pengajuan.fromJson(Map<String, dynamic> json) {
    final pemohon = Map<String, dynamic>.from(json['pemohon'] ?? {});
    return Pengajuan(
      id: '${json['id']}',
      nama: pemohon['nama'] ?? '-',
      email: pemohon['email'] ?? '-',
      organisasi: json['organisasi'] ?? '-',
      jabatan: json['jabatan'] ?? '',
      buktiUrl: json['bukti_url'],
      alasan: json['alasan'],
      tanggal: _tanggalIndonesia(json['diajukan']),
      status: StatusPengajuan.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StatusPengajuan.menunggu,
      ),
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

final ValueNotifier<List<Pengajuan>> daftarPengajuan = ValueNotifier<List<Pengajuan>>([]);

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

// Mengambil semua pengajuan dari backend. Melempar AuthException kalau gagal.
Future<void> muatPengajuan() async {
  final body = await ApiClient.get('/pengajuan-penyelenggara');
  final data = (body['data'] as List? ?? []);
  daftarPengajuan.value = [
    for (final e in data) Pengajuan.fromJson(Map<String, dynamic>.from(e as Map)),
  ];
}

Future<void> setujuiPengajuan(String id) async {
  await ApiClient.put('/pengajuan-penyelenggara/$id/setujui');
  await muatPengajuan();
}

Future<void> tolakPengajuan(String id, String alasan) async {
  await ApiClient.put('/pengajuan-penyelenggara/$id/tolak', body: {'alasan': alasan});
  await muatPengajuan();
}

// Mencabut peran penyelenggara; akun kembali menjadi mahasiswa biasa.
Future<void> cabutPengajuan(String id, String alasan) async {
  await ApiClient.put('/pengajuan-penyelenggara/$id/cabut', body: {'alasan': alasan});
  await muatPengajuan();
}

void ubahAktifPengguna(String email) {
  daftarPengguna.value = [
    for (final u in daftarPengguna.value)
      if (u.email == email) u.copyWith(aktif: !u.aktif) else u,
  ];
}
