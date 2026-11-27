import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_model.dart';
import '../../models/ticket_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/ticket_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_nav.dart';
import 'payment_screen.dart';
import '../../widgets/event_image.dart';

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

  // Tipe ditentukan penyelenggara: tiket, pendaftaran perorangan, atau pendaftaran tim.
  bool get _pakaiTiket => _event.isTiket;
  bool get _tim => _event.isTim;

  String get _kataKerja {
    if (_tim) return 'Daftarkan Tim';
    if (!_pakaiTiket) return 'Daftar';
    return _event.isGratis ? 'Ambil Tiket' : 'Pesan Tiket';
  }

  String get _labelTombol {
    if (_event.isLewat) return _pakaiTiket ? 'Pemesanan Ditutup' : 'Pendaftaran Ditutup';
    if (_event.isHabis) return 'Kuota Habis';
    if (_tim) return 'Daftarkan Tim';
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
                      EventImage(
                        url: event.bannerUrl,
                        height: (MediaQuery.of(context).size.width * 9 / 16).clamp(200.0, 340.0),
                        width: double.infinity,
                      ),
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
          if (event.punyaNarahubung) _narahubungRow(event),
        ],
      ),
    );
  }

  // Nomor WhatsApp dalam format internasional: 0812... menjadi 62812...
  String _nomorWa(String raw) {
    var n = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.startsWith('0')) n = '62${n.substring(1)}';
    return n;
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _chatWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/${_nomorWa(_event.narahubungTelepon)}'
      '?text=${Uri.encodeComponent('Halo, saya mau bertanya tentang event ${_event.judul}.')}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _pesan('Tidak dapat membuka WhatsApp.');
    } catch (_) {
      _pesan('Tidak dapat membuka WhatsApp.');
    }
  }

  Future<void> _salinNomor() async {
    await Clipboard.setData(ClipboardData(text: _event.narahubungTelepon));
    _pesan('Nomor narahubung disalin.');
  }

  Widget _narahubungRow(EventModel event) {
    final ada = event.narahubungTelepon.trim().isNotEmpty;
    final nama = event.narahubung.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_outlined, size: 19, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              const Text('Narahubung', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (nama.isNotEmpty)
                      Text(
                        nama,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    if (ada)
                      Text(
                        event.narahubungTelepon,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (ada)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _chatWhatsApp,
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                    label: const Text('Chat WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _salinNomor,
                    tooltip: 'Salin nomor',
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryBlue),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
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

    // Satu akun hanya dapat satu tiket atau satu pendaftaran per event.
    const jumlah = 1;
    bool loading = false;
    String? error;
    const metode = 'qris';

    // Data tim (hanya dipakai untuk event tim). Baris anggota awal sebanyak batas minimal.
    final namaTim = TextEditingController();
    final anggota = <TextEditingController>[
      for (var i = 0; i < (_event.minAnggota ?? 1).clamp(1, 50); i++) TextEditingController(),
    ];
    final minAnggota = _event.minAnggota ?? 1;
    final maxAnggota = _event.maxAnggota ?? 50;

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
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
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
                  Text(_pakaiTiket ? 'Konfirmasi Pemesanan' : (_tim ? 'Pendaftaran Tim' : 'Konfirmasi Pendaftaran'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_event.judul, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 20),
                  Text(
                    _pakaiTiket
                        ? 'Satu akun hanya dapat memesan satu tiket untuk event ini.'
                        : (_tim
                            ? 'Kamu mendaftar sebagai perwakilan tim. Satu akun hanya dapat mendaftarkan satu tim.'
                            : 'Satu akun hanya dapat mendaftar satu kali untuk event ini.'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const Divider(height: 24),
                  if (_tim) ...[
                    const Text('Nama tim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: namaTim,
                      enabled: !loading,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      decoration: const InputDecoration(hintText: 'Contoh: Garuda FC', counterText: ''),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Anggota tim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          '${anggota.length} dari $minAnggota-$maxAnggota orang',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < anggota.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: anggota[i],
                                enabled: !loading,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: i == 0 ? 'Nama lengkap (ketua tim)' : 'Nama lengkap anggota ${i + 1}',
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (anggota.length > minAnggota && i > 0)
                              IconButton(
                                tooltip: 'Hapus anggota',
                                onPressed: loading
                                    ? null
                                    : () => setSheet(() => anggota.removeAt(i)),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                          ],
                        ),
                      ),
                    if (anggota.length < maxAnggota)
                      TextButton.icon(
                        onPressed: loading ? null : () => setSheet(() => anggota.add(TextEditingController())),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Tambah anggota'),
                      ),
                    const Divider(height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(child: Text(_tim ? 'Biaya per tim' : 'Total', style: const TextStyle(fontWeight: FontWeight.w600))),
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
                                ? (_tim ? 'Event ini gratis. Tim langsung terdaftar.' : 'Event ini gratis. Tiketmu langsung aktif.')
                                : (_tim
                                    ? 'Bayar lewat e-wallet atau m-banking dengan scan QRIS. Tim terdaftar otomatis setelah pembayaran terdeteksi.'
                                    : 'Bayar lewat e-wallet atau m-banking dengan scan QRIS. Tiket aktif otomatis setelah pembayaran terdeteksi.'),
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
                              // Periksa data tim di perangkat dulu sebelum dikirim.
                              if (_tim) {
                                final isi = anggota.map((c) => c.text.trim()).toList();
                                String? salah;
                                if (namaTim.text.trim().length < 2) {
                                  salah = 'Isi nama tim.';
                                } else if (isi.any((n) => n.length < 2)) {
                                  salah = 'Nama semua anggota harus diisi.';
                                } else if (isi.length < minAnggota) {
                                  salah = 'Jumlah anggota minimal $minAnggota orang.';
                                }
                                if (salah != null) {
                                  setSheet(() => error = salah);
                                  return;
                                }
                              }
                              setSheet(() {
                                loading = true;
                                error = null;
                              });
                              try {
                                final ticket = await TicketService.register(
                                  eventId: _event.id,
                                  jumlah: jumlah,
                                  metode: total == 0 ? 'cash' : metode,
                                  namaTim: _tim ? namaTim.text.trim() : null,
                                  anggota: _tim
                                      ? anggota.map((c) => AnggotaTim(nama: c.text.trim())).toList()
                                      : null,
                                );
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                if (!mounted) return;
                                if (ticket.menungguQris) {
                                  _bukaPembayaran(ticket);
                                } else {
                                  _onRegistered(ticket);
                                }
                              } on AuthException catch (e) {
                                setSheet(() {
                                  loading = false;
                                  error = e.message;
                                });
                              }
                            },
                      child: loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              total > 0 && metode == 'qris' ? 'Bayar dengan QRIS' : _kataKerja,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          );
        },
      ),
    );

    namaTim.dispose();
    for (final c in anggota) {
      c.dispose();
    }
  }

  Future<void> _bukaPembayaran(TicketModel ticket) async {
    _refresh();

    final lihatTiket = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(ticket: ticket)),
    );

    if (!mounted) return;
    _refresh();

    if (lihatTiket == true) {
      Navigator.pop(context);
      AppNav.tabRequest.value = 2;
    }
  }

  String get _judulSukses {
    if (_tim) return 'Tim Berhasil Terdaftar';
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
              ? (_tim
                  ? 'Timmu sudah terdaftar. Tunjukkan QR ke panitia saat tim hadir.'
                  : 'Tiketmu sudah aktif. Tunjukkan QR tiket ke panitia saat masuk acara.')
              : 'Silakan selesaikan pembayaran ${ticket.totalLabel}. Pendaftaran aktif setelah pembayaranmu dikonfirmasi.',
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