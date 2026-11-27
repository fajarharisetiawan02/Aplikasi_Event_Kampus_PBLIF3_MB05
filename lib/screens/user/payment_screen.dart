import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/ticket_model.dart';
import '../../services/auth_service.dart';
import '../../services/ticket_service.dart';
import '../../utils/app_colors.dart';

// Halaman pembayaran QRIS: menampilkan QR, menghitung mundur, dan memeriksa status
// ke server secara berkala sampai pembayaran terdeteksi, dibatalkan, atau habis waktu.
class PaymentScreen extends StatefulWidget {
  final TicketModel ticket;

  const PaymentScreen({super.key, required this.ticket});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late TicketModel _ticket = widget.ticket;
  Timer? _poll;
  Timer? _tick;
  Duration _sisa = Duration.zero;
  bool _memeriksa = false;
  bool _membatalkan = false;

  bool get _menunggu => _ticket.status == TicketStatus.menunggu;

  @override
  void initState() {
    super.initState();
    _hitungSisa();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _detik());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _periksa());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _hitungSisa() {
    final batas = _ticket.expiresAt;
    _sisa = batas == null ? Duration.zero : batas.difference(DateTime.now());
    if (_sisa.isNegative) _sisa = Duration.zero;
  }

  void _detik() {
    if (!mounted) return;
    setState(_hitungSisa);
  }

  void _berhentiKalauSelesai() {
    if (_menunggu) return;
    _poll?.cancel();
    _tick?.cancel();
  }

  Future<void> _periksa({bool manual = false}) async {
    if (_memeriksa || !_menunggu) return;
    _memeriksa = true;
    if (manual) setState(() {});

    try {
      final baru = await TicketService.status(_ticket.registrationId);
      if (!mounted) return;
      setState(() {
        _ticket = baru;
        _hitungSisa();
      });
      _berhentiKalauSelesai();
      if (manual && _menunggu) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran belum terdeteksi')),
        );
      }
    } on AuthException catch (e) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      _memeriksa = false;
      if (manual && mounted) setState(() {});
    }
  }

  Future<void> _batalkan() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Pesanan'),
        content: const Text('Pesanan ini akan dibatalkan dan kuota dikembalikan. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Tidak')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    setState(() => _membatalkan = true);
    try {
      final baru = await TicketService.cancel(_ticket.registrationId);
      if (!mounted) return;
      setState(() => _ticket = baru);
      _berhentiKalauSelesai();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _membatalkan = false);
    }
  }

  String get _waktuLabel {
    final m = _sisa.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _sisa.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final Widget isi;
    if (_menunggu && _ticket.qris != null) {
      isi = _tampilQris();
    } else if (_ticket.status == TicketStatus.dibatalkan) {
      isi = _tampilHasil(
        ikon: Icons.priority_high_rounded,
        warna: const Color(0xFFDC2626),
        judul: 'Pesanan dibatalkan',
        keterangan: 'Waktu pembayaran habis atau pesanan dibatalkan. Kuota sudah dikembalikan.\nKamu bisa mendaftar lagi selama kuota masih ada.',
        tombol: 'Kembali ke event',
        hasil: false,
      );
    } else if (_menunggu) {
      isi = _tampilHasil(
        ikon: Icons.hourglass_top_rounded,
        warna: AppColors.accentOrange,
        judul: 'Menunggu pembayaran',
        keterangan: 'Data pembayaran belum tersedia. Buka lagi dari halaman tiket.',
        tombol: 'Kembali',
        hasil: false,
      );
    } else {
      isi = _tampilHasil(
        ikon: Icons.check_rounded,
        warna: const Color(0xFF16A34A),
        judul: 'Pembayaran berhasil',
        keterangan: 'Tiketmu sudah aktif dan siap dipindai panitia.',
        tombol: 'Lihat tiket',
        hasil: true,
        rincian: true,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_menunggu ? 'Scan untuk Bayar' : 'Pembayaran')),
      body: SafeArea(child: isi),
    );
  }

  Widget _tampilQris() {
    final habis = _sisa == Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
            child: Text(
              habis ? 'Memeriksa pembayaran...' : 'Bayar dalam $_waktuLabel',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text('Total pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  _ticket.payAmountLabel,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 14),
                QrImageView(
                  data: _ticket.qris!,
                  version: QrVersions.auto,
                  size: 230,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
                const SizedBox(height: 8),
                Text(
                  _ticket.eventTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '1. Buka aplikasi e-wallet atau m-banking\n'
              '2. Pilih Scan atau QRIS, lalu arahkan ke kode di atas\n'
              '3. Bayar sesuai nominal yang tertera. Status berubah otomatis setelah pembayaran terdeteksi.',
              style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _memeriksa ? null : () => _periksa(manual: true),
              child: _memeriksa
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Cek status pembayaran'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _membatalkan ? null : _batalkan,
            child: _membatalkan
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Batalkan pesanan'),
          ),
        ],
      ),
    );
  }

  Widget _tampilHasil({
    required IconData ikon,
    required Color warna,
    required String judul,
    required String keterangan,
    required String tombol,
    required bool hasil,
    bool rincian = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: warna.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(ikon, size: 44, color: warna),
          ),
          const SizedBox(height: 16),
          Text(judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(
            keterangan,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
          ),
          if (rincian) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _baris('Event', _ticket.eventTitle),
                  _baris('Total', _ticket.payAmountLabel),
                  _baris('Metode', 'QRIS'),
                  _baris('Status', 'Lunas'),
                  _baris('Kode tiket', _ticket.id),
                ],
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, hasil),
              child: Text(tombol, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
