import 'package:flutter/material.dart';
import '../../utils/admin_store.dart';
import '../../utils/app_colors.dart';
import 'admin_beranda_screen.dart';
import 'admin_event_screen.dart';
import 'admin_login_screen.dart';
import 'admin_pengajuan_screen.dart';
import 'admin_pengguna_screen.dart';
import 'admin_widgets.dart';

// Kerangka admin: sidebar di layar lebar, drawer di layar sempit.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  // Menu yang halamannya belum dikerjakan (ditandai "Segera" di sidebar).
  static const _belum = {2, 3};

  static const _menu = [
    (Icons.dashboard_outlined, 'Beranda'),
    (Icons.how_to_reg_outlined, 'Pengajuan'),
    (Icons.people_outline_rounded, 'Pengguna'),
    (Icons.event_note_outlined, 'Event'),
  ];

  void _keluar() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  void _pilih(int i) {
    setState(() => _index = i);
  }

  Widget _sidebar({required bool drawer}) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 14),
              child: Center(child: Image.asset('assets/images/logo.png', width: 100, height: 100)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFEEF2FA)),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _menu.length; i++) _item(i, drawer),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const AdminAvatar(nama: 'Admin EventIn', radius: 17),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin EventIn',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Text('Administrator', style: TextStyle(fontSize: 11, color: adminAbu)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Keluar',
                    onPressed: _keluar,
                    icon: const Icon(Icons.logout_rounded, size: 19, color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(int i, bool drawer) {
    final aktif = _index == i;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: aktif ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _pilih(i);
            if (drawer) Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(_menu[i].$1, size: 21, color: aktif ? AppColors.primaryBlue : adminAbu),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _menu[i].$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: aktif ? FontWeight.bold : FontWeight.w500,
                      color: aktif ? AppColors.primaryBlue : AppColors.textDark,
                    ),
                  ),
                ),
                if (_belum.contains(i))
                  const Text('Segera', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                if (i == 1)
                  ValueListenableBuilder<List<Pengajuan>>(
                    valueListenable: daftarPengajuan,
                    builder: (_, data, _) {
                      final n = data.where((p) => p.status == StatusPengajuan.menunggu).length;
                      if (n == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$n',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final halaman = <Widget>[
      AdminBerandaScreen(onBukaPengajuan: () => _pilih(1)),
      const AdminPengajuanScreen(),
      const AdminPenggunaScreen(),
      const AdminEventScreen(),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final lebar = c.maxWidth >= 800;
        final isi = Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1700),
            child: IndexedStack(index: _index, children: halaman),
          ),
        );

        if (lebar) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _sidebar(drawer: false),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: isi,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(_menu[_index].$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          drawer: Drawer(child: _sidebar(drawer: true)),
          body: isi,
        );
      },
    );
  }
}