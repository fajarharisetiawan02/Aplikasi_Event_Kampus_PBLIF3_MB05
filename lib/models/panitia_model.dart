// Akun panitia milik sebuah event (dilihat penyelenggara).
class PanitiaModel {
  final int id;
  final String nama;
  final String email;
  final String? noHp;
  final bool aktif; // false = undangan belum dipakai untuk membuat password

  PanitiaModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.aktif,
  });

  factory PanitiaModel.fromJson(Map<String, dynamic> json) {
    return PanitiaModel(
      id: json['id'] as int,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'],
      aktif: json['status'] == 'aktif',
    );
  }
}

// Event yang dijaga panitia + jumlah check-in.
class PanitiaRingkasan {
  final int eventId;
  final String judul;
  final String? tanggal;
  final String? waktu;
  final String lokasi;
  final int hadir;
  final int total;

  PanitiaRingkasan({
    required this.eventId,
    required this.judul,
    required this.tanggal,
    required this.waktu,
    required this.lokasi,
    required this.hadir,
    required this.total,
  });

  factory PanitiaRingkasan.fromJson(Map<String, dynamic> json) {
    final event = Map<String, dynamic>.from(json['event']);
    return PanitiaRingkasan(
      eventId: event['id'] as int,
      judul: event['judul'] ?? '',
      tanggal: event['tanggal'],
      waktu: event['waktu'],
      lokasi: event['lokasi'] ?? '',
      hadir: json['hadir'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

enum JenisScan { berhasil, sudahDipakai, belumLunas, dibatalkan, eventLain, tidakDikenali }

// Hasil memindai satu QR tiket.
class HasilScan {
  final JenisScan jenis;
  final String pesan;
  final String? nama;
  final String? nim;
  final String? kode;
  final PanitiaRingkasan? ringkasan;

  HasilScan({
    required this.jenis,
    required this.pesan,
    this.nama,
    this.nim,
    this.kode,
    this.ringkasan,
  });

  factory HasilScan.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final peserta = data is Map ? data['peserta'] : null;
    final ringkasan = json['ringkasan'];

    return HasilScan(
      jenis: switch (json['hasil']) {
        'berhasil' => JenisScan.berhasil,
        'sudah_dipakai' => JenisScan.sudahDipakai,
        'belum_lunas' => JenisScan.belumLunas,
        'dibatalkan' => JenisScan.dibatalkan,
        'event_lain' => JenisScan.eventLain,
        _ => JenisScan.tidakDikenali,
      },
      pesan: json['message'] ?? '',
      nama: peserta is Map ? peserta['nama'] : null,
      nim: peserta is Map ? peserta['nim'] : null,
      kode: data is Map ? data['kode'] : null,
      ringkasan: ringkasan is Map ? PanitiaRingkasan.fromJson(Map<String, dynamic>.from(ringkasan)) : null,
    );
  }
}

// Peserta yang sudah check-in.
class PesertaHadir {
  final String nama;
  final String? nim;
  final String kode;

  PesertaHadir({required this.nama, required this.nim, required this.kode});

  factory PesertaHadir.fromJson(Map<String, dynamic> json) {
    final peserta = json['peserta'];
    return PesertaHadir(
      nama: peserta is Map ? (peserta['nama'] ?? '') : '',
      nim: peserta is Map ? peserta['nim'] : null,
      kode: json['kode'] ?? '',
    );
  }
}
