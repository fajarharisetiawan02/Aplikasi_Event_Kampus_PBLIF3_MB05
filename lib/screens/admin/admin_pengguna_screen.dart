import 'package:flutter/material.dart';
import 'admin_widgets.dart';

// BELUM DIKERJAKAN. Isi halaman ini: daftar pengguna, filter peran, cari,
// dan tombol blokir/aktifkan. Data contoh tersedia di utils/admin_store.dart
// (daftarPengguna dan ubahAktifPengguna).
class AdminPenggunaScreen extends StatelessWidget {
  const AdminPenggunaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSegeraHadir(
      judul: 'Pengguna',
      sub: 'Kelola akun peserta, penyelenggara, dan admin',
      ikon: Icons.people_outline_rounded,
      berkas: 'screens/admin/admin_pengguna_screen.dart',
    );
  }
}
