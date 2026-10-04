import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// masih dummy, belum konek backend. akun baru dari register disimpan ke
// SharedPreferences (local storage HP) biar tetap ada walau app ditutup
// total, bukan cuma selama app lagi jalan.

class AuthService {
  static const String baseUrl = "https://api.contoh-eventapp.com/v1";
  static const String _prefsKey = 'registered_accounts';
  static bool _loaded = false;

  static final Map<String, _DummyAccount> _dummyUsers = {
    'user@kampus.ac.id': _DummyAccount(
      password: 'user123',
      user: UserModel(
        id: '1',
        nama: 'Fajar Hari Setiawan',
        email: 'user@kampus.ac.id',
        noHp: '081234567890',
        nim: '21051234',
        roles: const ['user'],
        isAdmin: false,
        token: 'dummy-token-user',
      ),
    ),
    'eo@kampus.ac.id': _DummyAccount(
      password: 'event123',
      user: UserModel(
        id: '2',
        nama: 'Muhammad Rafie (Event Organizer)',
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
        nim: null,
        roles: const ['user'],
        isAdmin: true,
        token: 'dummy-token-admin',
      ),
    ),
  };

  // ambil akun hasil register sebelumnya dari local storage, sekali aja.
  static Future<void> _loadPersistedAccounts() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    final Map<String, dynamic> decoded = jsonDecode(raw);
    decoded.forEach((email, value) {
      final data = Map<String, dynamic>.from(value);
      _dummyUsers[email] = _DummyAccount(
        password: data['password'],
        user: UserModel.fromJson(Map<String, dynamic>.from(data['user'])),
      );
    });
  }

  static Future<void> _persistAccount(String email, _DummyAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final Map<String, dynamic> decoded = raw != null ? jsonDecode(raw) : {};

    decoded[email] = {
      'password': account.password,
      'user': {
        ...account.user.toJson(),
        'token': account.user.token,
      },
    };

    await prefs.setString(_prefsKey, jsonEncode(decoded));
  }

  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await _loadPersistedAccounts();
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

  static Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    required String nim,
  }) async {
    await _loadPersistedAccounts();
    await Future.delayed(const Duration(milliseconds: 800));

    final emailKey = email.trim().toLowerCase();
    if (_dummyUsers.containsKey(emailKey)) {
      throw AuthException('Email sudah terdaftar. Gunakan email lain.');
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      email: email,
      noHp: noHp,
      nim: nim,
      roles: const ['user'],
      isAdmin: false,
      token: 'dummy-token-new-user',
    );

    final account = _DummyAccount(password: password, user: newUser);
    _dummyUsers[emailKey] = account;
    await _persistAccount(emailKey, account);

    return newUser;
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