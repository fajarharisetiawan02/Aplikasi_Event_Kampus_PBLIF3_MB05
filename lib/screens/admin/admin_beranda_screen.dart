import 'package:flutter/material.dart';
import '../../utils/admin_store.dart';
import '../../utils/app_colors.dart';
import 'admin_widgets.dart';

// Beranda admin: ringkasan platform dan jalan pintas ke pengajuan yang menunggu.
class AdminBerandaScreen extends StatelessWidget {
  final VoidCallback onBukaPengajuan;

  const AdminBerandaScreen({super.key, required this.onBukaPengajuan});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Pengajuan>>(
      valueListenable: daftarPengajuan,
      builder: (context, pengajuan, _) {
        return ValueListenableBuilder<List<PenggunaAdmin>>(
          valueListenable: daftarPengguna,
          builder: (context, pengguna, _) {
            final menunggu = pengajuan.where((p) => p.status == StatusPengajuan.menunggu).length;
            final penyelenggara = pengguna.where((u) => u.peran == 'Penyelenggara').length;
            final event = daftarEventAdmin.take(3).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
              children: [
                const AdminHeader(
                  judul: 'Beranda',
                  sub: 'Ringkasan platform EventIn',
                ),
                const SizedBox(height: 20),
                _perluDitinjau(menunggu),
                const SizedBox(height: 14),
                _statistik(pengguna.length, penyelenggara, daftarEventAdmin.length, menunggu),
                const SizedBox(height: 26),
                const Text(
                  'Event terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                for (final e in event) _eventBaris(e),
              ],
            );
          },
        );
      },
    );
  }

  Widget _perluDitinjau(int menunggu) {
    final ada = menunggu > 0;
    final warna = ada ? AppColors.accentOrange : const Color(0xFF16A34A);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: ada ? onBukaPengajuan : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: adminKartuDekor(),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ada ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded,
                  size: 22,
                  color: warna,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ada ? '$menunggu pengajuan penyelenggara menunggu' : 'Semua pengajuan sudah ditinjau',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ada ? 'Tinjau lalu setujui atau tolak' : 'Tidak ada yang perlu ditindaklanjuti',
                      style: const TextStyle(fontSize: 12, color: adminAbu),
                    ),
                  ],
                ),
              ),
              if (ada) const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statistik(int pengguna, int penyelenggara, int event, int menunggu) {
    final kartu = <Widget>[
      AdminStatCard(
        ikon: Icons.people_outline_rounded,
        warna: AppColors.primaryBlue,
        label: 'Total pengguna',
        nilai: '$pengguna',
      ),
      AdminStatCard(
        ikon: Icons.badge_outlined,
        warna: const Color(0xFF7C3AED),
        label: 'Penyelenggara',
        nilai: '$penyelenggara',
      ),
      AdminStatCard(
        ikon: Icons.event_note_outlined,
        warna: const Color(0xFF16A34A),
        label: 'Total event',
        nilai: '$event',
      ),
      AdminStatCard(
        ikon: Icons.hourglass_top_rounded,
        warna: AppColors.accentOrange,
        label: 'Pengajuan menunggu',
        nilai: '$menunggu',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final kolom = c.maxWidth >= 760 ? 4 : 2;
        const jarak = 10.0;
        final lebar = (c.maxWidth - jarak * (kolom - 1)) / kolom;

        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: [for (final k in kartu) SizedBox(width: lebar, child: k)],
        );
      },
    );
  }

  Widget _eventBaris(EventAdmin e) {
    final badge = switch (e.status) {
      'Terbit' => const AdminBadge.hijau('Terbit'),
      'Draft' => const AdminBadge.kuning('Draft'),
      _ => const AdminBadge.abu('Selesai'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: adminKartuDekor(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text('${e.penyelenggara} · ${e.tanggal}', style: const TextStyle(fontSize: 12, color: adminAbu)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${e.terdaftar} / ${e.kuota}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(width: 12),
          badge,
        ],
      ),
    );
  }
}
