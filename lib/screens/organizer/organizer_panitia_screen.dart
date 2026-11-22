import 'package:flutter/material.dart';
import '../../models/panitia_model.dart';
import '../../services/panitia_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/organizer_event_store.dart';

// Tab Panitia penyelenggara: tambah panitia untuk satu event. Panitia menerima email berisi password awal acak,
// wajib menggantinya saat login pertama, lalu hanya bisa memindai tiket event itu.
class OrganizerPanitiaScreen extends StatefulWidget {
  const OrganizerPanitiaScreen({super.key});

  @override
  State<OrganizerPanitiaScreen> createState() => _OrganizerPanitiaScreenState();
}

class _OrganizerPanitiaScreenState extends State<OrganizerPanitiaScreen> {
  final _cari = TextEditingController();

  String? _eventId;
  bool? _filter; // null = semua, true = aktif, false = menunggu
  List<PanitiaModel> _panitia = [];
  bool _memuatEvent = true;
  bool _memuat = false;
  String? _galat;

  // Event yang bisa diberi panitia: bukan yang dibatalkan atau sudah selesai.
  List<OrganizerEvent> get _events => organizerEvents.value
      .where((e) => e.status != StatusEvent.dibatalkan && e.status != StatusEvent.selesai)
      .toList();

  OrganizerEvent? get _eventTerpilih {
    for (final e in _events) {
      if (e.id == _eventId) return e;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _muatEvent();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  Future<void> _muatEvent() async {
    try {
      if (organizerEvents.value.isEmpty) await muatEventSaya();
      final daftar = _events;
      if (mounted && daftar.isNotEmpty && _eventId == null) {
        setState(() => _eventId = daftar.first.id);
      }
      await _muatPanitia();
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    } finally {
      if (mounted) setState(() => _memuatEvent = false);
    }
  }

  Future<void> _muatPanitia() async {
    final id = int.tryParse(_eventId ?? '');
    if (id == null) return;

    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final data = await PanitiaService.daftar(id);
      if (mounted) setState(() => _panitia = data);
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _pesan(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  // =========================
  // AKSI
  // =========================

  Future<void> _tambah() async {
    final id = int.tryParse(_eventId ?? '');
    if (id == null) return;

    final pesan = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormPanitia(eventId: id, namaEvent: _eventTerpilih?.judul ?? ''),
    );

    if (pesan != null && mounted) {
      _pesan(pesan);
      _muatPanitia();
    }
  }

  Future<void> _kirimUlang(PanitiaModel p) async {
    final id = int.tryParse(_eventId ?? '');
    if (id == null) return;
    try {
      _pesan(await PanitiaService.kirimUlang(id, p.id));
      _muatPanitia();
    } catch (e) {
      _pesan('$e');
    }
  }

  Future<void> _hapus(PanitiaModel p) async {
    final id = int.tryParse(_eventId ?? '');
    if (id == null) return;

    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus panitia'),
        content: Text('Akun panitia ${p.nama} akan dihapus dan tidak bisa lagi memindai tiket. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (ya != true) return;

    try {
      await PanitiaService.hapus(id, p.id);
      _pesan('Panitia dihapus');
      _muatPanitia();
    } catch (e) {
      _pesan('$e');
    }
  }

  // =========================
  // TAMPILAN
  // =========================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OrganizerEvent>>(
      valueListenable: organizerEvents,
      builder: (context, _, _) {
        final adaEvent = _events.isNotEmpty;
        final kata = _cari.text.trim().toLowerCase();
        final tampil = _panitia.where((p) {
          if (_filter != null && p.aktif != _filter) return false;
          return kata.isEmpty || p.nama.toLowerCase().contains(kata) || p.email.toLowerCase().contains(kata);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: adaEvent
              ? FloatingActionButton.extended(
                  onPressed: _tambah,
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tambah panitia', style: TextStyle(fontWeight: FontWeight.w600)),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panitia',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_panitia.length} panitia',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    if (adaEvent) ...[
                      const SizedBox(height: 14),
                      _kolomCari(),
                      const SizedBox(height: 10),
                      _pemilihEvent(),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              if (adaEvent) _filterChips(),
              if (adaEvent) const SizedBox(height: 10),
              Expanded(child: _isi(adaEvent, tampil)),
            ],
          ),
        );
      },
    );
  }

  Widget _kolomCari() {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );

    return TextField(
      controller: _cari,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari nama atau email',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
        suffixIcon: _cari.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(_cari.clear),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: garis(const Color(0xFFE5EAF5)),
        enabledBorder: garis(const Color(0xFFE5EAF5)),
        focusedBorder: garis(AppColors.primaryBlue),
      ),
    );
  }

  Widget _pemilihEvent() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pilihEvent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EAF5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_outlined, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _eventTerpilih?.judul ?? 'Pilih event',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  void _pilihEvent() {
    final pilihan = _events;

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
                'Pilih event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in pilihan)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.judul, style: const TextStyle(fontSize: 14)),
                        trailing: _eventId == e.id
                            ? const Icon(Icons.check_rounded, color: AppColors.primaryBlue)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _eventId = e.id;
                            _panitia = [];
                            _filter = null;
                          });
                          _muatPanitia();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    int hitung(bool? aktif) => aktif == null ? _panitia.length : _panitia.where((p) => p.aktif == aktif).length;

    Widget chip(String label, bool? nilai) {
      final aktif = _filter == nilai;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _filter = nilai),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: aktif ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: aktif ? AppColors.primaryBlue : const Color(0xFFDCE7FB)),
            ),
            child: Text(
              '$label (${hitung(nilai)})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: aktif ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          chip('Semua', null),
          chip('Aktif', true),
          chip('Menunggu', false),
        ],
      ),
    );
  }

  Widget _isi(bool adaEvent, List<PanitiaModel> tampil) {
    if (_memuatEvent) return const Center(child: CircularProgressIndicator());

    if (!adaEvent) {
      return _kosong(
        Icons.event_busy_outlined,
        'Belum ada event',
        'Buat event dulu di tab Event, lalu tambahkan panitianya di sini.',
      );
    }

    if (_galat != null) {
      return _kosong(
        Icons.cloud_off_rounded,
        'Gagal memuat panitia',
        _galat!,
        aksi: TextButton(onPressed: _muatPanitia, child: const Text('Coba lagi')),
      );
    }

    if (_memuat && _panitia.isEmpty) return const Center(child: CircularProgressIndicator());

    if (tampil.isEmpty) {
      final belumAda = _panitia.isEmpty;
      return _kosong(
        Icons.groups_outlined,
        belumAda ? 'Belum ada panitia' : 'Panitia tidak ditemukan',
        belumAda
            ? 'Tambahkan panitia. Mereka menerima email berisi password awal untuk login.'
            : 'Coba kata kunci atau filter lain.',
      );
    }

    return RefreshIndicator(
      onRefresh: _muatPanitia,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
        itemCount: tampil.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _kartu(tampil[i]),
        ),
      ),
    );
  }

  Widget _badge(bool aktif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: aktif ? const Color(0xFFE8F7EE) : const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        aktif ? 'Aktif' : 'Menunggu',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: aktif ? const Color(0xFF145C33) : const Color(0xFF8A4B00),
        ),
      ),
    );
  }

  Widget _kartu(PanitiaModel p) {
    final inisial = p.nama.trim().isEmpty ? '?' : p.nama.trim().substring(0, 1).toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _detail(p),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE3EEFD),
                child: Text(
                  inisial,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _badge(p.aktif),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // DETAIL + AKSI
  // =========================

  void _detail(PanitiaModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.nama,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ),
                  _badge(p.aktif),
                ],
              ),
              const SizedBox(height: 10),
              _baris('Email', p.email),
              _baris('Telepon', (p.noHp == null || p.noHp!.isEmpty) ? '-' : p.noHp!),
              _baris('Event', _eventTerpilih?.judul ?? '-'),
              const SizedBox(height: 14),
              if (!p.aktif) ...[
                _tombol('Kirim ulang password', Icons.forward_to_inbox_rounded, AppColors.primaryBlue, () {
                  Navigator.pop(ctx);
                  _kirimUlang(p);
                }),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'Panitia ini belum mengganti password awal. Kirim ulang akan membuat password baru, dan password lama tidak berlaku.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
              ],
              _tombol('Hapus panitia', Icons.delete_outline_rounded, const Color(0xFFDC2626), () {
                Navigator.pop(ctx);
                _hapus(p);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombol(String label, IconData icon, Color warna, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: warna,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _kosong(IconData ikon, String judul, String sub, {Widget? aksi}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(judul, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            if (aksi != null) ...[const SizedBox(height: 8), aksi],
          ],
        ),
      ),
    );
  }
}

// Form tambah panitia (bottom sheet). Menutup dengan pesan sukses dari server.
class _FormPanitia extends StatefulWidget {
  final int eventId;
  final String namaEvent;
  const _FormPanitia({required this.eventId, required this.namaEvent});

  @override
  State<_FormPanitia> createState() => _FormPanitiaState();
}

class _FormPanitiaState extends State<_FormPanitia> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _noHp = TextEditingController();
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _noHp.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      final hasil = await PanitiaService.tambah(
        eventId: widget.eventId,
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        noHp: _noHp.text.trim(),
      );
      if (mounted) Navigator.pop(context, hasil.pesan);
    } catch (e) {
      if (mounted) {
        setState(() {
          _kirim = false;
          _galat = '$e';
        });
      }
    }
  }

  InputDecoration _dekor(String label, IconData ikon) {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(ikon, size: 20, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: garis(const Color(0xFFE5EAF5)),
      enabledBorder: garis(const Color(0xFFE5EAF5)),
      focusedBorder: garis(AppColors.primaryBlue),
      errorBorder: garis(const Color(0xFFDC2626)),
      focusedErrorBorder: garis(const Color(0xFFDC2626)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tambah panitia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Untuk ${widget.namaEvent}. Email berisi password awal acak, dan panitia diminta menggantinya saat login pertama.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nama,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: _dekor('Nama', Icons.person_outline_rounded),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Nama minimal 3 karakter' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration: _dekor('Email', Icons.mail_outline_rounded),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noHp,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14),
                  decoration: _dekor('Nomor telepon', Icons.phone_outlined),
                  validator: (v) => RegExp(r'^[0-9]{9,13}$').hasMatch(v?.trim() ?? '') ? null : 'Nomor telepon harus 9-13 angka',
                ),
                if (_galat != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                    child: Text(_galat!, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _kirim ? null : _simpan,
                    icon: _kirim
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Kirim undangan', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
