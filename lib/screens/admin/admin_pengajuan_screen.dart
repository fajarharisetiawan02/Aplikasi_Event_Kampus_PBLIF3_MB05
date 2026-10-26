import 'package:flutter/material.dart';
import '../../utils/admin_store.dart';
import '../../utils/app_colors.dart';
import 'admin_widgets.dart';

class AdminPengajuanScreen extends StatefulWidget {
  const AdminPengajuanScreen({super.key});

  @override
  State<AdminPengajuanScreen> createState() => _AdminPengajuanScreenState();
}

class _AdminPengajuanScreenState extends State<AdminPengajuanScreen> {
  final _cari = TextEditingController();
  int _tab = 0; // 0 menunggu, 1 disetujui, 2 ditolak, 3 semua

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  int _hitung(List<Pengajuan> d, StatusPengajuan s) => d.where((p) => p.status == s).length;

  List<Pengajuan> _saring(List<Pengajuan> d) {
    final q = _cari.text.trim().toLowerCase();
    return d.where((p) {
      final cocokTab = switch (_tab) {
        0 => p.status == StatusPengajuan.menunggu,
        1 => p.status == StatusPengajuan.disetujui,
        2 => p.status == StatusPengajuan.ditolak,
        _ => true,
      };
      final cocokCari = q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.organisasi.toLowerCase().contains(q);
      return cocokTab && cocokCari;
    }).toList();
  }

  void _ubah(Pengajuan p, StatusPengajuan s, String pesan) {
    ubahPengajuan(p.id, s);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _konfirmasiTolak(Pengajuan p) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak pengajuan?'),
        content: Text('Pengajuan ${p.nama} (${p.organisasi}) akan ditolak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak', style: TextStyle(color: Color(0xFF991B1B))),
          ),
        ],
      ),
    );
    if (ya == true) _ubah(p, StatusPengajuan.ditolak, 'Pengajuan ${p.nama} ditolak');
  }

  Widget _status(StatusPengajuan s) {
    return switch (s) {
      StatusPengajuan.menunggu => const AdminBadge.kuning('Menunggu'),
      StatusPengajuan.disetujui => const AdminBadge.hijau('Disetujui'),
      StatusPengajuan.ditolak => const AdminBadge.merah('Ditolak'),
    };
  }

  Widget _aksi(Pengajuan p) {
    if (p.status == StatusPengajuan.menunggu) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          AdminTombol(
            label: 'Setujui',
            utama: true,
            onTap: () => _ubah(p, StatusPengajuan.disetujui, '${p.nama} kini menjadi penyelenggara'),
          ),
          AdminTombol(label: 'Tolak', bahaya: true, onTap: () => _konfirmasiTolak(p)),
        ],
      );
    }
    return AdminTombol(
      label: 'Batalkan',
      onTap: () => _ubah(p, StatusPengajuan.menunggu, 'Pengajuan ${p.nama} dikembalikan ke menunggu'),
    );
  }

  Widget _orang(Pengajuan p) {
    return Row(
      children: [
        AdminAvatar(nama: p.nama),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.nama, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Text(p.email, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: adminAbu)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teks(String t) => Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textDark));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Pengajuan>>(
      valueListenable: daftarPengajuan,
      builder: (context, data, _) {
        final tampil = _saring(data);

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
          children: [
            const AdminHeader(judul: 'Pengajuan penyelenggara', sub: 'Tinjau pengguna yang ingin membuat event'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: AdminStatCard(ikon: Icons.hourglass_top_rounded, warna: AppColors.accentOrange, label: 'Menunggu', nilai: '${_hitung(data, StatusPengajuan.menunggu)}')),
                const SizedBox(width: 10),
                Expanded(child: AdminStatCard(ikon: Icons.check_circle_outline_rounded, warna: const Color(0xFF16A34A), label: 'Disetujui', nilai: '${_hitung(data, StatusPengajuan.disetujui)}')),
                const SizedBox(width: 10),
                Expanded(child: AdminStatCard(ikon: Icons.cancel_outlined, warna: const Color(0xFFDC2626), label: 'Ditolak', nilai: '${_hitung(data, StatusPengajuan.ditolak)}')),
              ],
            ),
            const SizedBox(height: 18),
            AdminChips(
              label: [
                'Menunggu (${_hitung(data, StatusPengajuan.menunggu)})',
                'Disetujui',
                'Ditolak',
                'Semua',
              ],
              terpilih: _tab,
              onPilih: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 12),
            AdminSearch(controller: _cari, hint: 'Cari nama, email, atau organisasi', onChanged: () => setState(() {})),
            const SizedBox(height: 14),
            AdminTable(
              kosong: 'Tidak ada pengajuan.',
              kolom: const [
                AdminKolom('Pemohon', 4),
                AdminKolom('Organisasi', 3),
                AdminKolom('Tanggal', 2),
                AdminKolom('Status', 2),
                AdminKolom('Aksi', 3, kanan: true),
              ],
              baris: [
                for (final p in tampil)
                  [_orang(p), _teks(p.organisasi), _teks(p.tanggal), _status(p.status), _aksi(p)],
              ],
              kartu: [
                for (final p in tampil)
                  AdminKartu(children: [
                    _orang(p),
                    const SizedBox(height: 10),
                    Text('${p.organisasi} · ${p.tanggal}', style: const TextStyle(fontSize: 12, color: adminAbu)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _status(p.status),
                        const Spacer(),
                        _aksi(p),
                      ],
                    ),
                  ]),
              ],
            ),
          ],
        );
      },
    );
  }
}
