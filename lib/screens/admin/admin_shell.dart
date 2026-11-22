import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/admin_store.dart';
import '../../utils/app_colors.dart';
import 'admin_beranda_screen.dart';
import 'admin_event_screen.dart';
import 'admin_login_screen.dart';
import 'admin_pengajuan_screen.dart';
import 'admin_pengguna_screen.dart';
import 'admin_widgets.dart';

// Kerangka admin: sidebar navy setinggi layar di kiri, lalu topbar putih
// (judul halaman, lonceng, akun, keluar) dan isi di sebelah kanannya.
// Di layar sempit sidebar menjadi drawer.
const Color _sidebarNavy = Color(0xFF0B2C52);
const Color _sidebarGrup = Color(0xFF8FA7CB);
const Color _lencanaOranye = Color(0xFFE65100); // lebih tua dari oranye biasa agar angka putih terbaca
const Color _sidebarTeks = Color(0xFFE8EEF8);
const Color _sidebarIkon = Color(0xFFB4C6E2);
const Color _latar = Color(0xFFF1F4F9);
const double _tinggiTopbar = 72;

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  // (ikon, nama menu, judul topbar, keterangan di bawah judul)
  static const _menu = [
    (Icons.home_outlined, 'Beranda', 'Beranda', 'Ringkasan platform EventIn'),
    (Icons.how_to_reg_outlined, 'Pengajuan', 'Pengajuan', 'Tinjau pengguna yang ingin membuat event'),
    (Icons.event_note_outlined, 'Event', 'Event', 'Tinjau dan kelola event kampus'),
    (Icons.people_outline_rounded, 'Pengguna', 'Pengguna', 'Kelola akun mahasiswa, penyelenggara, dan admin'),
  ];

  Future<void> _keluar() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  void _pilih(int i) {
    setState(() => _index = i);
  }

  int _menunggu(List<Pengajuan> data) => data.where((p) => p.status == StatusPengajuan.menunggu).length;

  String get _nama => AuthService.currentUser?.nama ?? 'Admin EventIn';

  String get _inisial {
    final n = _nama.trim();
    return n.isEmpty ? 'A' : n.split(' ').take(2).map((x) => x[0].toUpperCase()).join();
  }

  // ---------- sidebar ----------
  // Logo di kiri atas, lalu garis pemisah yang tidak penuh (ada jarak di kedua sisi).
  Widget _logo() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Row(
            children: [
              Image.asset('assets/images/logo_ikon.png', width: 48, height: 48),
              const SizedBox(width: 16),
              const Text(
                'EventIn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.12)),
        ),
      ],
    );
  }

  Widget _grup(String teks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
      child: Text(teks, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sidebarGrup)),
    );
  }

  Widget _item(int i, bool drawer) {
    final aktif = _index == i;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: aktif ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: aktif
              ? [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            hoverColor: Colors.white.withValues(alpha: 0.06),
            onTap: () {
              _pilih(i);
              if (drawer) Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(_menu[i].$1, size: 21, color: aktif ? Colors.white : _sidebarIkon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _menu[i].$2,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: aktif ? FontWeight.bold : FontWeight.w500,
                        color: aktif ? Colors.white : _sidebarTeks,
                      ),
                    ),
                  ),
                  if (i == 1)
                    ValueListenableBuilder<List<Pengajuan>>(
                      valueListenable: daftarPengajuan,
                      builder: (_, data, _) => _lencana(_menunggu(data), 11),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Lencana oranye berisi angka; kosong kalau angkanya 0.
  Widget _lencana(int n, double ukuran) {
    if (n == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(color: _lencanaOranye, borderRadius: BorderRadius.circular(4)),
      child: Text('$n', style: TextStyle(fontSize: ukuran, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _sidebar({required bool drawer}) {
    return Container(
      width: 236,
      color: _sidebarNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _logo(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              children: [
                _grup('Utama'),
                _item(0, drawer),
                _grup('Kelola'),
                for (var i = 1; i < _menu.length; i++) _item(i, drawer),
              ],
            ),
          ),
          // Di drawer (layar sempit) topbar tidak memuat akun, jadi akun dan keluar ada di sini.
          if (drawer) _akunDrawer(),
        ],
      ),
    );
  }

  Widget _akunDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white,
            child: Text(_inisial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: adminNavy)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: _keluar,
            icon: const Icon(Icons.logout_rounded, size: 19, color: Color(0xFFFF9B9B)),
          ),
        ],
      ),
    );
  }

  // ---------- topbar ----------
  // Lonceng hanya tampilan: menunjukkan jumlah pengajuan yang menunggu.
  // Belum bisa diklik, karena fitur notifikasi dibuat nanti.
  Widget _lonceng() {
    return ValueListenableBuilder<List<Pengajuan>>(
      valueListenable: daftarPengajuan,
      builder: (_, data, _) {
        final n = _menunggu(data);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_rounded, size: 19, color: adminNavy),
            ),
            if (n > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: n > 9 ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: n > 9 ? BorderRadius.circular(10) : null,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    n > 99 ? '99+' : '$n',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _akun() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: adminNavy,
          child: Text(_inisial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const Text('Administrator', style: TextStyle(fontSize: 11, color: adminAbu)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tombolKeluar() {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: _keluar,
        icon: const Icon(Icons.logout_rounded, size: 16),
        label: const Text('Keluar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: adminMerah,
          side: const BorderSide(color: Color(0xFFF3C4C4)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _topbar() {
    return Container(
      height: _tinggiTopbar,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: adminGaris)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _menu[_index].$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  _menu[_index].$4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: adminAbu),
                ),
              ],
            ),
          ),
          _lonceng(),
          const SizedBox(width: 14),
          Container(width: 1, height: 30, color: adminGaris),
          const SizedBox(width: 14),
          _akun(),
          const SizedBox(width: 14),
          _tombolKeluar(),
        ],
      ),
    );
  }

  // ---------- footer ----------
  Widget _footer() {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: adminGaris)),
      ),
      child: const Text('© 2026 EventIn', style: TextStyle(fontSize: 12, color: adminAbu)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final halaman = <Widget>[
      AdminBerandaScreen(onBukaPengajuan: () => _pilih(1)),
      const AdminPengajuanScreen(),
      const AdminEventScreen(),
      const AdminPenggunaScreen(),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final lebar = c.maxWidth >= 900;
        final isi = Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1700),
            child: IndexedStack(index: _index, children: halaman),
          ),
        );

        if (lebar) {
          return Scaffold(
            backgroundColor: _latar,
            body: Row(
              children: [
                _sidebar(drawer: false),
                Expanded(
                  child: Column(
                    children: [
                      _topbar(),
                      Expanded(child: isi),
                      _footer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: _latar,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: const Border(bottom: BorderSide(color: adminGaris)),
            title: Text(_menu[_index].$3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            actions: [
              Padding(padding: const EdgeInsets.only(right: 18), child: Center(child: _lonceng())),
            ],
          ),
          drawer: Drawer(
            backgroundColor: _sidebarNavy,
            shape: const RoundedRectangleBorder(),
            child: SafeArea(child: _sidebar(drawer: true)),
          ),
          body: Column(
            children: [
              Expanded(child: isi),
              _footer(),
            ],
          ),
        );
      },
    );
  }
}
