import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user = AuthService.currentUser;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final user = await AuthService.fetchProfile();
      if (mounted) setState(() => _user = user);
    } on AuthException {
      // pakai data terakhir yang tersimpan
    }
  }

  void _toLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (updated == true && mounted) {
      setState(() => _user = AuthService.currentUser);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) _toLogin();
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    String? error;
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hapus Akun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Akun dan seluruh datamu akan dihapus permanen. Masukkan password untuk melanjutkan.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: loading
                  ? null
                  : () async {
                      setDialogState(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        await AuthService.deleteAccount(password: passwordController.text);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) _toLogin();
                      } on AuthException catch (e) {
                        setDialogState(() {
                          loading = false;
                          error = e.message;
                        });
                      }
                    },
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );

    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return Center(
        child: TextButton(onPressed: _toLogin, child: const Text('Masuk untuk melihat profil')),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Profil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.email, style: const TextStyle(color: Colors.grey)),
                const Divider(height: 28),
                _infoRow(Icons.badge_outlined, 'NIM', user.nim ?? '-'),
                _infoRow(Icons.phone_outlined, 'No. HP', user.noHp ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _menuTile(Icons.edit_outlined, 'Edit Profil', _edit),
          _menuTile(Icons.logout, 'Keluar', _logout),
          _menuTile(Icons.delete_outline, 'Hapus Akun', _deleteAccount, color: Colors.red),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primaryBlue),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
