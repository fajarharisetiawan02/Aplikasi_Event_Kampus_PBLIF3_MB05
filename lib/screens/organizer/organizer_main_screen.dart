import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'organizer_dashboard_screen.dart';
import 'organizer_event_screen.dart';

// Kerangka mode penyelenggara: bottom navigation 5 menu.
// Dashboard dan Event sudah dibuat, menu lain masih placeholder.
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
      _placeholder('Scan tiket', Icons.qr_code_scanner_rounded),
      _placeholder('Peserta', Icons.groups_outlined),
      _profilPlaceholder(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _placeholder(String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Halaman $label\nsegera hadir',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Sementara menu Profil hanya menyediakan tombol untuk kembali ke mode peserta.
  Widget _profilPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Halaman Profil\nsegera hadir',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Kembali ke mode peserta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BOTTOM NAVIGATION
  // =========================

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _navItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', 0),
              _navItem(Icons.event_note_outlined, Icons.event_note_rounded, 'Event', 1),
              _navItem(Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan', 2),
              _navItem(Icons.groups_outlined, Icons.groups_rounded, 'Peserta', 3),
              _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? AppColors.primaryBlue : const Color(0xFF94A3B8);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
