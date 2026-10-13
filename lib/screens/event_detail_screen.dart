import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/ticket_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_nav.dart';
import '../widgets/event_image.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _event = widget.event;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await EventService.getById(_event.id);
      if (mounted) setState(() => _event = fresh);
    } on AuthException {
      // tetap pakai data dari daftar
    }
  }

  bool get _bisaDaftar => !_event.isHabis && !_event.isLewat;

  // Konser dan pameran dipesan sebagai tiket; event lain berupa pendaftaran.
  bool get _pakaiTiket => _event.kategori == 'Musik' || _event.kategori == 'Seni';

  String get _kataKerja {
    if (!_pakaiTiket) return 'Daftar';
    return _event.isGratis ? 'Ambil Tiket' : 'Pesan Tiket';
  }

  String get _labelTombol {
    if (_event.isLewat) return _pakaiTiket ? 'Pemesanan Ditutup' : 'Pendaftaran Ditutup';
    if (_event.isHabis) return 'Kuota Habis';
    return _pakaiTiket ? _kataKerja : 'Daftar Sekarang';
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      EventImage(url: event.bannerUrl, height: 260, width: double.infinity),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.kategori,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.judul,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 18),
                          _infoCard(event),
                          const SizedBox(height: 22),
                          const Text(
                            'Tentang Event',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.deskripsi,
                            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _bottomBar(event),
        ],
      ),
    );
  }

  Widget _infoCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.calendar_today_outlined, 'Tanggal', event.tanggalLabel),
          _infoRow(Icons.access_time_rounded, 'Waktu', event.waktu ?? '-'),
          _infoRow(Icons.location_on_outlined, 'Lokasi', event.lokasi),
          _infoRow(Icons.person_outline_rounded, 'Penyelenggara', event.organizer.isEmpty ? '-' : event.organizer),
          _infoRow(
            Icons.event_seat_outlined,
            'Sisa kuota',
            event.isHabis ? 'Habis' : '${event.sisaKuota} dari ${event.kuota}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(EventModel event) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Harga', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  event.hargaLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: event.isGratis ? AppColors.accentOrange : AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _bisaDaftar ? _openRegisterSheet : null,
                  child: Text(_labelTombol, style: const TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRegisterSheet() async {
    if (AuthService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk dulu untuk melanjutkan.')),
      );
      return;
    }

    final maks = _event.sisaKuota < 5 ? _event.sisaKuota : 5;
    int jumlah = 1;
    bool loading = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          final total = _event.harga * jumlah;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(_pakaiTiket ? 'Konfirmasi Pemesanan' : 'Konfirmasi Pendaftaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_event.judul, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Text('Jumlah tiket', style: TextStyle(fontWeight: FontWeight.w600))),
                      IconButton(
                        onPressed: loading || jumlah <= 1 ? null : () => setSheet(() => jumlah--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text('$jumlah', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        onPressed: loading || jumlah >= maks ? null : () => setSheet(() => jumlah++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
                      Text(
                        formatRupiah(total),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            total == 0
                                ? 'Event ini gratis. Tiketmu langsung aktif.'
                                : 'Pembayaran dilakukan tunai ke panitia. Tiket aktif setelah panitia mengonfirmasi pembayaranmu.',
                            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              setSheet(() {
                                loading = true;
                                error = null;
                              });
                              try {
                                final ticket = await TicketService.register(eventId: _event.id, jumlah: jumlah);
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                if (mounted) _onRegistered(ticket);
                              } on AuthException catch (e) {
                                setSheet(() {
                                  loading = false;
                                  error = e.message;
                                });
                              }
                            },
                      child: loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(_kataKerja, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get _judulSukses {
    if (!_pakaiTiket) return 'Pendaftaran Berhasil';
    return _event.isGratis ? 'Tiket Berhasil Diambil' : 'Tiket Berhasil Dipesan';
  }

  Future<void> _onRegistered(TicketModel ticket) async {
    _refresh();

    final aktif = ticket.status == TicketStatus.aktif;

    final lihatTiket = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded, size: 52, color: Color(0xFF16A34A)),
        title: Text(_judulSukses),
        content: Text(
          aktif
              ? 'Tiketmu sudah aktif. Tunjukkan QR tiket ke panitia saat masuk acara.'
              : 'Silakan bayar ${ticket.totalLabel} secara tunai ke panitia. Tiket aktif setelah pembayaranmu dikonfirmasi.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Tutup')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Lihat Tiket')),
        ],
      ),
    );

    if (lihatTiket == true && mounted) {
      Navigator.pop(context);
      AppNav.tabRequest.value = 2;
    }
  }
}