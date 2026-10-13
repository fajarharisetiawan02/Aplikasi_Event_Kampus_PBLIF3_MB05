const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String formatRupiah(int value) {
  if (value == 0) return 'Gratis';
  final angka = value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return 'Rp$angka';
}

class EventModel {
  final int id;
  final String judul;
  final String deskripsi;
  final String kategori;
  final String? bannerUrl;
  final DateTime tanggal;
  final String? waktu;
  final String lokasi;
  final int harga;
  final int kuota;
  final int kuotaTerjual;
  final String organizer;

  EventModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.bannerUrl,
    required this.tanggal,
    required this.waktu,
    required this.lokasi,
    required this.harga,
    required this.kuota,
    required this.kuotaTerjual,
    required this.organizer,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final organizer = json['organizer'];
    return EventModel(
      id: json['id'] as int,
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      kategori: json['kategori'] ?? '',
      bannerUrl: json['banner_url'],
      tanggal: DateTime.parse(json['tanggal']),
      waktu: json['waktu'],
      lokasi: json['lokasi'] ?? '',
      harga: json['harga'] ?? 0,
      kuota: json['kuota'] ?? 0,
      kuotaTerjual: json['kuota_terjual'] ?? 0,
      organizer: organizer is Map ? (organizer['nama'] ?? '') : '',
    );
  }

  int get sisaKuota => kuota - kuotaTerjual;
  bool get isGratis => harga == 0;
  bool get isHabis => sisaKuota <= 0;
  bool get isLewat {
    final now = DateTime.now();
    return tanggal.isBefore(DateTime(now.year, now.month, now.day));
  }

  String get hargaLabel => formatRupiah(harga);
  String get tanggalLabel => formatTanggal(tanggal);
}
