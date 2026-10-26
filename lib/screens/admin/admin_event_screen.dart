import 'package:flutter/material.dart';
import 'admin_widgets.dart';

// BELUM DIKERJAKAN. Isi halaman ini: daftar semua event di platform,
// filter status, dan cari. Data contoh tersedia di utils/admin_store.dart
// (daftarEventAdmin).
class AdminEventScreen extends StatelessWidget {
  const AdminEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSegeraHadir(
      judul: 'Event',
      sub: 'Pantau semua event di platform',
      ikon: Icons.event_note_outlined,
      berkas: 'screens/admin/admin_event_screen.dart',
    );
  }
}
