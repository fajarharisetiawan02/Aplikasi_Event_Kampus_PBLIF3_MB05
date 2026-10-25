import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/event_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/organizer_participant_store.dart';

enum _Mode { bayar, masuk }

// Isi lembar hasil setelah QR dibaca.
class _Hasil {
  final IconData ikon;
  final Color warna;
  final Color latar;
  final String judul;
  final String sub;
  final List<MapEntry<String, String>> baris;
  final String aksi;
  final String? sekunder;
  final VoidCallback? onAksi;
  final VoidCallback? onSekunder;
  final _Hasil Function()? sesudah;
  final String? progresTeks;
  final double? progres;

  _Hasil({
    required this.ikon,
    required this.warna,
    required this.latar,
    required this.judul,
    required this.sub,
    this.baris = const [],
    required this.aksi,
    this.sekunder,
    this.onAksi,
    this.onSekunder,
    this.sesudah,
    this.progresTeks,
    this.progres,
  });
}

class OrganizerScanScreen extends StatefulWidget {
  // aktif: true saat tab Scan sedang dibuka, supaya kamera tidak menyala di tab lain.
  final bool aktif;
  final VoidCallback? onLihatPeserta;

  const OrganizerScanScreen({super.key, this.aktif = true, this.onLihatPeserta});

  @override
  State<OrganizerScanScreen> createState() => _OrganizerScanScreenState();
}

class _OrganizerScanScreenState extends State<OrganizerScanScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _sibuk = false;
  _Mode _mode = _Mode.bayar;
  String? _event; // null = semua event

  static const _hijau = Color(0xFF145C33);
  static const _hijauMuda = Color(0xFFE8F7EE);
  static const _merah = Color(0xFF991B1B);
  static const _merahMuda = Color(0xFFFDECEC);
  static const _kuning = Color(0xFF8A4B00);
  static const _kuningMuda = Color(0xFFFFF4E0);

  @override
  void didUpdateWidget(covariant OrganizerScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aktif && !widget.aktif) {
      _controller.stop().catchError((_) {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =========================
  // PROSES QR
  // =========================

  void _onDetect(BarcodeCapture capture) {
    if (_sibuk) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _proses(value);
        break;
      }
    }
  }

  Future<void> _proses(String kode) async {
    if (_sibuk) return;
    _sibuk = true;
    _controller.stop().catchError((_) {});

    await _jalankan(_nilai(kode));

    _sibuk = false;
    if (mounted && widget.aktif) {
      _controller.start().catchError((_) {});
    }
  }

  Future<void> _jalankan(_Hasil h) async {
    final pilih = await _sheet(h);

    if (pilih == 'aksi') {
      h.onAksi?.call();
      final lanjut = h.sesudah?.call();
      if (lanjut != null) await _jalankan(lanjut);
    } else if (pilih == 'sekunder') {
      h.onSekunder?.call();
    }
  }

  List<MapEntry<String, String>> _baris(PesertaEvent p) => [
        MapEntry('Nama', p.nama),
        MapEntry('NIM', p.nim),
        MapEntry('Event', p.event),
        MapEntry('Tiket', p.harga == 0 ? 'Gratis' : formatRupiah(p.harga)),
      ];

  _Hasil _gagal(String judul, String sub, {bool peringatan = false, PesertaEvent? p}) {
    return _Hasil(
      ikon: peringatan ? Icons.error_outline_rounded : Icons.close_rounded,
      warna: peringatan ? _kuning : _merah,
      latar: peringatan ? _kuningMuda : _merahMuda,
      judul: judul,
      sub: sub,
      baris: p == null ? const [] : _baris(p),
      aksi: 'Scan lagi',
    );
  }

  _Hasil _nilai(String kode) {
    final strip = kode.indexOf('-');
    final jenis = strip < 0 ? '' : kode.substring(0, strip);
    final p = strip < 0 ? null : cariPeserta(kode.substring(strip + 1));

    if (p == null || (jenis != 'PAY' && jenis != 'IN')) {
      return _gagal('QR tidak dikenali', 'Kode ini tidak cocok dengan tiket peserta mana pun.');
    }

    if (_event != null && p.event != _event) {
      return _gagal('Tiket event lain', 'Tiket ini untuk ${p.event}.', peringatan: true, p: p);
    }

    if (p.status == StatusPeserta.batal) {
      return _gagal('Tiket dibatalkan', 'Pendaftaran peserta ini sudah dibatalkan.', p: p);
    }

    if (_mode == _Mode.bayar) {
      if (p.status != StatusPeserta.menunggu) {
        return _gagal('Sudah lunas', 'Tiket ini tidak perlu dibayar lagi.', peringatan: true, p: p);
      }
      if (jenis != 'PAY') {
        return _gagal('QR tidak sesuai', 'Pakai QR pembayaran milik peserta.', p: p);
      }
      return _Hasil(
        ikon: Icons.payments_outlined,
        warna: _kuning,
        latar: _kuningMuda,
        judul: 'Terima pembayaran',
        sub: 'Pastikan uang tunai sudah diterima.',
        baris: _baris(p),
        aksi: 'Terima tunai ${formatRupiah(p.harga)}',
        sekunder: 'Batal',
        onAksi: () => ubahStatusPeserta(p.id, StatusPeserta.lunas),
        sesudah: () => _suksesBayar(p.id),
      );
    }

    // Mode masuk
    if (p.status == StatusPeserta.menunggu) {
      return _gagal(
        'Belum bayar',
        jenis == 'PAY'
            ? 'Ini QR pembayaran. Arahkan peserta ke meja pembayaran.'
            : 'Arahkan peserta ke meja pembayaran.',
        p: p,
      );
    }
    if (p.status == StatusPeserta.hadir) {
      return _gagal('Sudah dipakai', 'Tiket ini sudah check-in sebelumnya.', peringatan: true, p: p);
    }
    return _Hasil(
      ikon: Icons.check_rounded,
      warna: _hijau,
      latar: _hijauMuda,
      judul: 'Tiket valid',
      sub: 'Konfirmasi untuk mencatat kehadiran.',
      baris: _baris(p),
      aksi: 'Konfirmasi check-in',
      sekunder: 'Batal',
      onAksi: () => ubahStatusPeserta(p.id, StatusPeserta.hadir),
      sesudah: () => _suksesMasuk(p.id),
    );
  }

  _Hasil _suksesBayar(String id) {
    final p = cariPeserta(id)!;
    return _Hasil(
      ikon: Icons.check_circle_outline_rounded,
      warna: _hijau,
      latar: _hijauMuda,
      judul: 'Pembayaran diterima',
      sub: 'Tiket ${p.nama} kini lunas dan QR masuk sudah aktif.',
      baris: _baris(p),
      aksi: 'Scan berikutnya',
      sekunder: 'Lihat daftar peserta',
      onSekunder: widget.onLihatPeserta,
    );
  }

  _Hasil _suksesMasuk(String id) {
    final p = cariPeserta(id)!;
    final satuEvent = daftarPeserta.value.where((x) => x.event == p.event && x.status != StatusPeserta.batal);
    final hadir = satuEvent.where((x) => x.status == StatusPeserta.hadir).length;
    final total = satuEvent.length;

    return _Hasil(
      ikon: Icons.check_circle_outline_rounded,
      warna: _hijau,
      latar: _hijauMuda,
      judul: 'Check-in berhasil',
      sub: '${p.nama} tercatat hadir.',
      baris: _baris(p),
      progresTeks: '$hadir dari $total peserta sudah check-in',
      progres: total == 0 ? 0 : hadir / total,
      aksi: 'Scan berikutnya',
      sekunder: 'Lihat daftar peserta',
      onSekunder: widget.onLihatPeserta,
    );
  }

  Future<String?> _sheet(_Hasil h) {
    if (!mounted) return Future.value(null);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: h.latar, shape: BoxShape.circle),
                child: Icon(h.ikon, size: 28, color: h.warna),
              ),
              const SizedBox(height: 12),
              Text(
                h.judul,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                h.sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              if (h.baris.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      for (final b in h.baris)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  b.key,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  b.value,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (h.progresTeks != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.progresTeks!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: h.progres,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE3EEFD),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'aksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(h.aksi, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              if (h.sekunder != null) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 'sekunder'),
                    child: Text(h.sekunder!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // TAMPILAN
  // =========================

  @override
  Widget build(BuildContext context) {
    final warnaBingkai = _mode == _Mode.bayar ? AppColors.accentYellow : AppColors.lightBlue;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.aktif)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Container(
                  color: const Color(0xFFF4F7FC),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_outlined, size: 60, color: Colors.blueGrey),
                        const SizedBox(height: 16),
                        const Text(
                          'Kamera tidak dapat dibuka',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.errorCode.message,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _controller.start(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Bingkai panduan QR.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: warnaBingkai, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          // Judul, mode, dan pemilih event.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              color: Colors.black.withValues(alpha: 0.6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan tiket',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _pilihanMode(),
                  const SizedBox(height: 10),
                  _chipEvent(),
                ],
              ),
            ),
          ),

          // Petunjuk dan tombol uji.
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _mode == _Mode.bayar
                        ? 'Scan QR bayar di HP peserta untuk menerima pembayaran tunai'
                        : 'Scan QR masuk di HP peserta untuk check-in',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _ujiTanpaKamera,
                  child: const Text(
                    'Uji tanpa kamera',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihanMode() {
    Widget item(String label, _Mode m) {
      final aktif = _mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = m),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: aktif ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: aktif ? AppColors.primaryBlue : Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          item('Pembayaran', _Mode.bayar),
          item('Masuk', _Mode.masuk),
        ],
      ),
    );
  }

  Widget _chipEvent() {
    return GestureDetector(
      onTap: _pilihEvent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _event ?? 'Semua event',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _pilihEvent() {
    final pilihan = <String?>[null, ...daftarNamaEvent()];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan untuk event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              for (final e in pilihan)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e ?? 'Semua event', style: const TextStyle(fontSize: 14)),
                  trailing: _event == e ? const Icon(Icons.check_rounded, color: AppColors.primaryBlue) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _event = e);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Untuk menguji alur tanpa kamera (emulator atau tanpa tiket sungguhan).
  void _ujiTanpaKamera() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uji tanpa kamera',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const Text(
                  'Pilih peserta untuk meniru hasil scan QR-nya.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in daftarPeserta.value)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${p.kodeQr} · ${labelStatus(p.status)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _proses(p.kodeQr);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
