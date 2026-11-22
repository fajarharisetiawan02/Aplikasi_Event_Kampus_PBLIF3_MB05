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
  final bool wajibGantiPassword; // akun panitia yang belum mengganti password awal dari email

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
    this.wajibGantiPassword = false,
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
      wajibGantiPassword: json['wajib_ganti_password'] == true,
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