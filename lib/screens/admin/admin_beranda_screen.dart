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
            final menunggu = pengajuan.where((p) => p.status == StatusPengajuan.menunggu).toList();
            final penyelenggara = pengguna.where((u) => u.peran == 'Penyelenggara').length;
            final event = daftarEventAdmin.take(3).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                _statistik(pengguna.length, penyelenggara, daftarEventAdmin.length, menunggu.length),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final tinjau = _perluDitinjau(menunggu);
                    final terbaru = _eventTerbaru(event);
                    if (c.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: tinjau),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: terbaru),
                        ],
                      );
                    }
                    return Column(children: [tinjau, const SizedBox(height: 16), terbaru]);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statistik(int pengguna, int penyelenggara, int event, int menunggu) {
    final kartu = <Widget>[
      AdminStatCard(
        ikon: Icons.people_outline_rounded,
        warna: AppColors.primaryBlue,
        label: 'Total pengguna',
        nilai: '$pengguna',
        ket: 'akun terdaftar',
      ),
      AdminStatCard(
        ikon: Icons.badge_outlined,
        warna: const Color(0xFF7C3AED),
        label: 'Penyelenggara',
        nilai: '$penyelenggara',
        ket: 'bisa membuat event',
      ),
      AdminStatCard(
        ikon: Icons.event_note_outlined,
        warna: const Color(0xFF16A34A),
        label: 'Total event',
        nilai: '$event',
        ket: 'semua status',
      ),
      AdminStatCard(
        ikon: Icons.hourglass_top_rounded,
        warna: AppColors.accentOrange,
        label: 'Pengajuan menunggu',
        nilai: '$menunggu',
        ket: 'perlu keputusan',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final kolom = c.maxWidth >= 760 ? 4 : 2;
        const jarak = 16.0;
        final lebar = (c.maxWidth - jarak * (kolom - 1)) / kolom;

        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: [for (final k in kartu) SizedBox(width: lebar, child: k)],
        );
      },
    );
  }

  Widget _kepala(String judul, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: adminGaris))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              judul,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
          Text(sub, style: const TextStyle(fontSize: 12.5, color: adminAbu)),
        ],
      ),
    );
  }

  // Pengajuan yang menunggu, dengan jalan pintas ke halaman Pengajuan.
  Widget _perluDitinjau(List<Pengajuan> menunggu) {
    final ada = menunggu.isNotEmpty;

    return AdminPanel(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _kepala(
              'Perlu ditinjau',
              ada ? '${menunggu.length} pengajuan penyelenggara menunggu' : 'Semua sudah ditinjau',
            ),
            if (!ada)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 40, color: Color(0xFF16A34A)),
                    SizedBox(height: 8),
                    Text(
                      'Tidak ada yang perlu ditindaklanjuti',
                      style: TextStyle(fontSize: 13, color: adminAbu),
                    ),
                  ],
                ),
              )
            else
              for (final p in menunggu.take(4))
                InkWell(
                  onTap: onBukaPengajuan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFBF2),
                      border: Border(
                        left: BorderSide(color: AppColors.accentOrange, width: 3),
                        bottom: BorderSide(color: Color(0xFFEEF1F6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        AdminAvatar(nama: p.nama, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${p.organisasi}, ${p.tanggal}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: adminAbu),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AdminTombolAksi(label: 'Tinjau', jenis: AdminAksi.detail, onTap: onBukaPengajuan),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _eventTerbaru(List<EventAdmin> event) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kepala('Event terbaru', '${daftarEventAdmin.length} event'),
          for (final e in event) _eventBaris(e),
        ],
      ),
    );
  }

  Widget _eventBaris(EventAdmin e) {
    final badge = switch (e.status) {
      'Terbit' => const AdminBadge.hijau('Terbit'),
      'Draft' => const AdminBadge.kuning('Draft'),
      _ => const AdminBadge.abu('Selesai'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF1F6)))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_rounded, size: 21, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text('${e.penyelenggara}, ${e.tanggal}', style: const TextStyle(fontSize: 12, color: adminAbu)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${e.terdaftar} / ${e.kuota}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(width: 12),
          badge,
        ],
      ),
    );
  }
}
