import '../models/user_model.dart';

/// ============================================================
/// VERSI DUMMY — belum tersambung ke backend/database sungguhan.
/// Login akan berhasil untuk akun-akun di bawah (lihat _dummyUsers).
///
/// Nanti kalau backend sudah siap, tinggal aktifkan kembali versi
/// asli yang memanggil http.post() ke API (lihat contoh di README).
/// ============================================================
class AuthService {
  static const String baseUrl = "https://api.contoh-eventapp.com/v1";

  static final Map<String, _DummyAccount> _dummyUsers = {
    'user@kampus.ac.id': _DummyAccount(
      password: 'user123',
      user: UserModel(
        id: '1',
        nama: 'Budi Santoso',
        email: 'user@kampus.ac.id',
        noHp: '081234567890',
        nim: '21051234',
        roles: const ['user'],
        isAdmin: false,
        token: 'dummy-token-user',
      ),
    ),
    'eo@kampus.ac.id': _DummyAccount(
      password: 'eo123',
      user: UserModel(
        id: '2',
        nama: 'Siti Rahma (Event Organizer)',
        email: 'eo@kampus.ac.id',
        noHp: '081234567891',
        nim: '20051987',
        roles: const ['user', 'event_organizer'],
        isAdmin: false,
        token: 'dummy-token-eo',
      ),
    ),
    'admin@kampus.ac.id': _DummyAccount(
      password: 'admin123',
      user: UserModel(
        id: '3',
        nama: 'Admin Kampus',
        email: 'admin@kampus.ac.id',
        noHp: '081234567892',
        nim: null, // admin biasanya bukan mahasiswa aktif
        roles: const ['user'],
        isAdmin: true,
        token: 'dummy-token-admin',
      ),
    ),
  };

  /// Login dummy — cek ke daftar _dummyUsers di atas, tanpa panggil API.
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final account = _dummyUsers[email.trim().toLowerCase()];

    if (account == null) {
      throw AuthException('Email tidak terdaftar. Coba: user@kampus.ac.id');
    }
    if (account.password != password) {
      throw AuthException('Password salah.');
    }

    return account.user;
  }

  /// Register dummy — langsung "berhasil" tanpa disimpan ke server.
  /// Akun baru TIDAK benar-benar tersimpan (hilang lagi kalau app di-restart)
  /// karena memang belum ada database.
  static Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    required String nim,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_dummyUsers.containsKey(email.trim().toLowerCase())) {
      throw AuthException('Email sudah terdaftar. Gunakan email lain.');
    }

    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      email: email,
      noHp: noHp,
      nim: nim,
      roles: const ['user'],
      isAdmin: false,
      token: 'dummy-token-new-user',
    );
  }
}

class _DummyAccount {
  final String password;
  final UserModel user;
  _DummyAccount({required this.password, required this.user});
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}