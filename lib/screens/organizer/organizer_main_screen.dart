import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';
import 'organizer_dashboard_screen.dart';
import 'organizer_event_screen.dart';
import 'organizer_panitia_screen.dart';
import 'organizer_participant_screen.dart';

class OrganizerMainScreen extends StatefulWidget {
  const OrganizerMainScreen({super.key});

  @override
  State<OrganizerMainScreen> createState() => _OrganizerMainScreenState();
}

class _OrganizerMainScreenState extends State<OrganizerMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      OrganizerDashboardScreen(
        onOpenEvent: () => setState(() => _selectedIndex = 1),
        onOpenPeserta: () => setState(() => _selectedIndex = 3),
      ),
      const OrganizerEventScreen(),
      const OrganizerPanitiaScreen(),
      const OrganizerParticipantScreen(),
      _profil(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // =========================
  // PROFIL
  // =========================

  Future<void> _keluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk mengelola event.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (yakin != true) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _profilBaris(IconData ikon, String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(nilai, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profil() {
    final user = AuthService.currentUser;
    final nama = user?.nama ?? '-';
    final organisasi = user?.pengajuan?.organisasi ?? '';
    final jabatan = user?.pengajuan?.jabatan ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE3EEFD),
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 10),
              Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F7EE), borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'Penyelenggara',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF145C33)),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFF1F5F9)),
              _profilBaris(Icons.mail_outline_rounded, 'Email', user?.email ?? '-'),
              if (organisasi.isNotEmpty) _profilBaris(Icons.groups_outlined, 'Organisasi', organisasi),
              if (jabatan.isNotEmpty) _profilBaris(Icons.badge_outlined, 'Jabatan', jabatan),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _keluar,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Keluar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF991B1B),
            side: const BorderSide(color: Color(0xFFF3C5C5)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // =========================
  // BOTTOM NAVIGATION
  // =========================

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Row(
            children: [
              _navItem(
                Icons.dashboard_outlined,
                Icons.dashboard_rounded,
                'Dashboard',
                0,
              ),
              _navItem(
                Icons.event_note_outlined,
                Icons.event_note_rounded,
                'Event',
                1,
              ),
              _navItem(
                Icons.badge_outlined,
                Icons.badge_rounded,
                'Panitia',
                2,
              ),
              _navItem(
                Icons.groups_outlined,
                Icons.groups_rounded,
                'Peserta',
                3,
              ),
              _navItem(
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profil',
                4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected
        ? AppColors.primaryBlue
        : const Color(0xFF94A3B8);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 23,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
