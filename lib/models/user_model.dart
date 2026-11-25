// Pengajuan menjadi penyelenggara milik akun ini (yang terakhir).
class PengajuanSaya {
  final String status; // menunggu, disetujui, ditolak, dicabut
  final String organisasi;
  final String jabatan;
  final String? alasan;

  PengajuanSaya({
    required this.status,
    required this.organisasi,
    required this.jabatan,
    this.alasan,
  });

  factory PengajuanSaya.fromJson(Map<String, dynamic> json) {
    return PengajuanSaya(
      status: json['status'] ?? 'menunggu',
      organisasi: json['organisasi'] ?? '',
      jabatan: json['jabatan'] ?? '',
      alasan: json['alasan'],
    );
  }

  bool get menunggu => status == 'menunggu';
  bool get bisaMengajukanLagi => status == 'ditolak' || status == 'dicabut';
}

class UserModel {
  final String id;
  final String nama;
  final String email;
  final String? noHp;
  final String? nim; // Nomor Induk Mahasiswa
  final List<String> roles; // contoh: ["user"], atau ["user", "event_organizer"]
  final bool isAdmin;
  final String? token;
  final String? panitiaEvent; // judul event yang dijaga, hanya untuk akun panitia
  final PengajuanSaya? pengajuan;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
    this.nim,
    this.roles = const ["user"],
    this.isAdmin = false,
    this.token,
    this.panitiaEvent,
    this.pengajuan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'],
      nim: json['nim'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : ["user"],
      isAdmin: json['is_admin'] ?? false,
      token: json['token'],
      panitiaEvent: json['panitia_event'] is Map ? json['panitia_event']['judul'] : null,
      pengajuan: json['pengajuan_penyelenggara'] is Map
          ? PengajuanSaya.fromJson(Map<String, dynamic>.from(json['pengajuan_penyelenggara']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'nim': nim,
      'roles': roles,
      'is_admin': isAdmin,
    };
  }

  bool get isEventOrganizer => roles.contains('event_organizer');
  bool get isPanitia => roles.contains('panitia');
}