import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/event_image.dart';

// Data contoh untuk tampilan dashboard (belum terhubung ke backend).
class _EventRingkas {
  final String judul;
  final String tanggal;
  final String lokasi;
  final String? banner;
  final int terjual;
  final int kuota;
  final int harga;

  const _EventRingkas({
    required this.judul,
    required this.tanggal,
    required this.lokasi,
    required this.banner,
    required this.terjual,
    required this.kuota,
    required this.harga,
  });
}

const _eventTerbaru = [
  _EventRingkas(
    judul: 'Festival Musik Batam',
    tanggal: '20 Oktober 2026',
    lokasi: 'Lapangan Engku Putri, Batam',
    banner: 'assets/images/festival_musik.png',
    terjual: 128,
    kuota: 500,
    harga: 150000,
  ),
  _EventRingkas(
    judul: 'Seminar Teknologi 2026',
    tanggal: '25 Oktober 2026',
    lokasi: 'Aula Polibatam',
    banner: 'assets/images/seminar_teknologi.png',
    terjual: 187,
    kuota: 300,
    harga: 0,
  ),
];

class OrganizerDashboardScreen extends StatelessWidget {
  final VoidCallback onOpenEvent;
  final VoidCallback onOpenPeserta;

  const OrganizerDashboardScreen({
    super.key,
    required this.onOpenEvent,
    required this.onOpenPeserta,
  });

  void _soon(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = AuthService.currentUser?.nama ?? 'Nama Organisasi';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        _header(nama),
        const SizedBox(height: 16),
        _perluKonfirmasiCard(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard(Icons.event_note_rounded, AppColors.primaryBlue, '8', 'Total event')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.play_circle_outline_rounded, const Color(0xFF16A34A), '3', 'Event aktif')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _statCard(Icons.confirmation_num_outlined, AppColors.accentOrange, '412', 'Tiket terjual')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.groups_outlined, const Color(0xFF7C3AED), '386', 'Total peserta')),
          ],
        ),
        const SizedBox(height: 12),
        _pendapatanCard(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Event terbaru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            GestureDetector(
              onTap: onOpenEvent,
              child: const Text(
                'Lihat semua',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final e in _eventTerbaru)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _eventCard(context, e),
          ),
      ],
    );
  }

  // =========================
  // BAGIAN ATAS
  // =========================

  Widget _header(String nama) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard penyelenggara',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          nama,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  // Pembayaran tunai yang belum dikonfirmasi penyelenggara.
  Widget _perluKonfirmasiCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenPeserta,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 20, color: AppColors.accentOrange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '5 pembayaran menunggu konfirmasi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tandai lunas setelah menerima uang tunai',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
  // RINGKASAN
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

  Widget _statCard(IconData icon, Color color, String nilai, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nilai,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendapatanCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total pendapatan',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(38450000),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Semua event',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // EVENT TERBARU
  // =========================

  Widget _eventCard(BuildContext context, _EventRingkas e) {
    final gratis = e.harga == 0;
    final pendapatan = e.harga * e.terjual;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _soon(context, 'Detail event segera hadir'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: EventImage(url: e.banner, width: 72, height: 72),
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                e.tanggal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                e.lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Terbit',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${e.terjual} / ${e.kuota} tiket',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    gratis ? 'Gratis' : formatRupiah(pendapatan),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: gratis ? AppColors.accentOrange : AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}