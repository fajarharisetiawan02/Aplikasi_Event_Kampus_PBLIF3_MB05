import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/panitia_model.dart';
import '../../services/auth_service.dart';
import '../../services/panitia_service.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';

// Satu-satunya layar akun panitia: memindai QR tiket untuk event yang dijaga.
class PanitiaScanScreen extends StatefulWidget {
  const PanitiaScanScreen({super.key});

  @override
  State<PanitiaScanScreen> createState() => _PanitiaScanScreenState();
}

class _PanitiaScanScreenState extends State<PanitiaScanScreen> {
  static const _hijau = Color(0xFF145C33);
  static const _hijauMuda = Color(0xFFE8F7EE);
  static const _merah = Color(0xFF991B1B);
  static const _merahMuda = Color(0xFFFDECEC);
  static const _kuning = Color(0xFF8A4B00);
  static const _kuningMuda = Color(0xFFFFF4E0);

  final MobileScannerController _controller = MobileScannerController();

  bool _sibuk = false;
  PanitiaRingkasan? _ringkasan;
  String? _galatMuat;

  @override
  void initState() {
    super.initState();
    _muatRingkasan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _muatRingkasan() async {
    try {
      final data = await PanitiaService.infoEvent();
      if (mounted) {
        setState(() {
          _ringkasan = data;
          _galatMuat = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _galatMuat = '$e');
    }
  }

  Future<void> _keluar() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

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

    HasilScan? hasil;
    String? galat;
    try {
      hasil = await PanitiaService.scan(kode);
      final baru = hasil.ringkasan;
      if (baru != null && mounted) setState(() => _ringkasan = baru);
    } catch (e) {
      galat = '$e';
    }

    if (mounted) await _tampilkan(hasil, galat);

    _sibuk = false;
    if (mounted) _controller.start().catchError((_) {});
  }

  Future<void> _kodeManual() async {
    final isi = TextEditingController();
    final kode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan kode tiket'),
        content: TextField(
          controller: isi,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'EVT-XXXXXXXX'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, isi.text), child: const Text('Cek')),
        ],
      ),
    );
    isi.dispose();

    if (kode != null && kode.trim().isNotEmpty) _proses(kode.trim());
  }

  void _daftarHadir() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _DaftarHadirScreen()));
  }

  // ===== Hasil scan =====

  ({IconData ikon, Color warna, Color latar, String judul}) _gaya(JenisScan j) {
    switch (j) {
      case JenisScan.berhasil:
        return (ikon: Icons.check_rounded, warna: _hijau, latar: _hijauMuda, judul: 'Check-in berhasil');
      case JenisScan.sudahDipakai:
        return (ikon: Icons.error_outline_rounded, warna: _kuning, latar: _kuningMuda, judul: 'Tiket sudah dipakai');
      case JenisScan.belumLunas:
        return (ikon: Icons.payments_outlined, warna: _kuning, latar: _kuningMuda, judul: 'Belum lunas');
      case JenisScan.eventLain:
        return (ikon: Icons.event_busy_outlined, warna: _kuning, latar: _kuningMuda, judul: 'Tiket event lain');
      case JenisScan.dibatalkan:
        return (ikon: Icons.close_rounded, warna: _merah, latar: _merahMuda, judul: 'Tiket dibatalkan');
      case JenisScan.tidakDikenali:
        return (ikon: Icons.close_rounded, warna: _merah, latar: _merahMuda, judul: 'QR tidak dikenali');
    }
  }

  Future<void> _tampilkan(HasilScan? h, String? galat) {
    final gaya = h == null
        ? (ikon: Icons.cloud_off_rounded, warna: _merah, latar: _merahMuda, judul: 'Gagal memproses')
        : _gaya(h.jenis);
    final pesan = h?.pesan ?? galat ?? '';
    final baris = <MapEntry<String, String>>[
      if (h?.nama != null) MapEntry('Nama', h!.nama!),
      if (h?.nim != null && h!.nim!.isNotEmpty) MapEntry('NIM', h.nim!),
      if (h?.kode != null) MapEntry('Tiket', h!.kode!),
    ];
    final r = h?.jenis == JenisScan.berhasil ? h!.ringkasan : null;

    return showModalBottomSheet<void>(
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
                decoration: BoxDecoration(color: gaya.latar, shape: BoxShape.circle),
                child: Icon(gaya.ikon, size: 28, color: gaya.warna),
              ),
              const SizedBox(height: 12),
              Text(gaya.judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              if (baris.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF5F8FF), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      for (final b in baris)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 52, child: Text(b.key, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                              Expanded(
                                child: Text(
                                  b.value,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (r != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF5F8FF), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.hadir} dari ${r.total} peserta sudah check-in',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.total == 0 ? 0 : r.hadir / r.total,
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
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Scan berikutnya', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Tampilan =====

  @override
  Widget build(BuildContext context) {
    final r = _ringkasan;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                      const Text('Kamera tidak dapat dibuka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(error.errorCode.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => _controller.start(), child: const Text('Coba Lagi')),
                      TextButton(onPressed: _kodeManual, child: const Text('Masukkan kode manual')),
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
                  border: Border.all(color: AppColors.lightBlue, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          // Event yang dijaga + menu.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 8, 14),
              color: Colors.black.withValues(alpha: 0.6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scan tiket', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          r?.judul ?? AuthService.currentUser?.panitiaEvent ?? 'Memuat event...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (r != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${r.hadir} dari ${r.total} peserta sudah check-in',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ] else if (_galatMuat != null) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _muatRingkasan,
                            child: const Text('Gagal memuat event. Ketuk untuk coba lagi.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onSelected: (v) {
                      if (v == 'hadir') {
                        _daftarHadir();
                      } else {
                        _keluar();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'hadir', child: Text('Daftar hadir')),
                      PopupMenuItem(value: 'keluar', child: Text('Keluar')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Petunjuk.
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(16)),
                    child: const Text(
                      'Arahkan kamera ke QR tiket di HP peserta untuk check-in',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _kodeManual,
                    child: const Text('Masukkan kode manual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Daftar peserta yang sudah check-in.
class _DaftarHadirScreen extends StatefulWidget {
  const _DaftarHadirScreen();

  @override
  State<_DaftarHadirScreen> createState() => _DaftarHadirScreenState();
}

class _DaftarHadirScreenState extends State<_DaftarHadirScreen> {
  List<PesertaHadir> _data = [];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final data = await PanitiaService.daftarHadir();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Sudah check-in (${_data.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _galat != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_galat!, style: const TextStyle(color: Color(0xFF64748B))),
                      TextButton(onPressed: _muat, child: const Text('Coba lagi')),
                    ],
                  ),
                )
              : _data.isEmpty
                  ? const Center(child: Text('Belum ada peserta yang check-in', style: TextStyle(color: Color(0xFF64748B))))
                  : RefreshIndicator(
                      onRefresh: _muat,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _data.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = _data[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                      if (p.nim != null && p.nim!.isNotEmpty)
                                        Text(p.nim!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                Text(p.kode, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
