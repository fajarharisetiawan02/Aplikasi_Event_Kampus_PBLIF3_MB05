import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_nav.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../organizer/organizer_main_screen.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  void _soon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _topBar(),
          const SizedBox(height: 18),
          _profileCard(user),
          const SizedBox(height: 14),
          _organizerCard(user),
          const SizedBox(height: 22),
          _sectionLabel('Aktivitas'),
          _card([
            _menuTile(
              icon: Icons.confirmation_num_outlined,
              title: 'Tiket Saya',
              onTap: () => AppNav.tabRequest.value = 2,
            ),
            _divider(),
            _menuTile(
              icon: Icons.favorite_border_rounded,
              title: 'Event Favorit',
              onTap: () => _soon('Event favorit segera hadir'),
            ),
            _divider(),
            _menuTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifikasi',
              onTap: () => _soon('Notifikasi segera hadir'),
            ),
          ]),
          const SizedBox(height: 22),
          _sectionLabel('Akun'),
          _card([
            _menuTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profil',
              onTap: _edit,
            ),
            _divider(),
            _menuTile(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus Akun',
              color: Colors.red,
              onTap: _deleteAccount,
            ),
            _divider(),
            _menuTile(
              icon: Icons.logout_rounded,
              title: 'Keluar',
              showArrow: false,
              onTap: _logout,
            ),
          ]),
        ],
      ),
    );
  }

  // =========================
  // BAGIAN ATAS
  // =========================

  Widget _topBar() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profil',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: IconButton(
            onPressed: () => _soon('Pengaturan segera hadir'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.textDark, size: 22),
          ),
        ),
      ],
    );
  }

  String _roleTitle(UserModel user) {
    if (user.isAdmin) return 'Admin';
    if (user.isEventOrganizer) return 'Event Organizer';
    return 'Mahasiswa';
  }

  Widget _profileCard(UserModel user) {
    final nim = (user.nim == null || user.nim!.isEmpty) ? null : user.nim;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  [_roleTitle(user), if (nim != null) 'NIM $nim'].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _edit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _organizerCard(UserModel user) {
    final bool isOrganizer = user.isEventOrganizer || user.isAdmin;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        // sementara semua akun bisa membuka mode penyelenggara untuk uji tampilan
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrganizerMainScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _iconBubble(Icons.storefront_outlined, AppColors.primaryBlue),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOrganizer ? 'Mode penyelenggara' : 'Jadi penyelenggara',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOrganizer
                          ? 'Kelola event yang kamu buat'
                          : 'Ajukan akunmu untuk membuat event',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // KOMPONEN
  // =========================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 70, endIndent: 16, color: Color(0xFFF1F5F9));
  }

  Widget _iconBubble(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBubble(icon, color ?? AppColors.primaryBlue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textDark,
                ),
              ),
            ),
            if (showArrow) const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}