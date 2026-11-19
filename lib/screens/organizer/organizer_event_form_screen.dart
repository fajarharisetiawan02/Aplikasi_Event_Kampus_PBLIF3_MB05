import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../widgets/event_image.dart';
import '../../utils/app_colors.dart';
import '../../utils/organizer_event_store.dart';

// Form buat/edit event dalam 3 langkah: Informasi, Tiket, Tinjau.
// Kalau [event] diisi, form dipakai untuk mengedit event itu.
class OrganizerEventFormScreen extends StatefulWidget {
  final OrganizerEvent? event;

  const OrganizerEventFormScreen({super.key, this.event});

  @override
  State<OrganizerEventFormScreen> createState() => _OrganizerEventFormScreenState();
}

class _OrganizerEventFormScreenState extends State<OrganizerEventFormScreen> {
  final _formInfo = GlobalKey<FormState>();
  final _formTiket = GlobalKey<FormState>();

  final _nama = TextEditingController();
  final _deskripsi = TextEditingController();
  final _lokasi = TextEditingController();
  final _alamat = TextEditingController();
  final _harga = TextEditingController();
  final _kuota = TextEditingController();

  int _langkah = 0;
  String? _kategori;
  DateTime? _tanggal;
  TimeOfDay? _waktu;
  bool _berbayar = false;
  bool _salahTanggal = false;
  bool _salahWaktu = false;
  bool _menyimpan = false;
  bool _mengunggah = false;
  String? _banner;

  bool get _edit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _nama.text = e.judul;
      _deskripsi.text = e.deskripsi;
      _lokasi.text = e.lokasi;
      _alamat.text = e.alamat;
      _kategori = e.kategori;
      _tanggal = e.tanggal;
      _waktu = e.waktu;
      _berbayar = !e.gratis;
      _harga.text = e.gratis ? '' : e.harga.toString();
      _kuota.text = e.kuota.toString();
      _banner = e.banner;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _lokasi.dispose();
    _alamat.dispose();
    _harga.dispose();
    _kuota.dispose();
    super.dispose();
  }

  // =========================
  // AKSI
  // =========================

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (hasil != null) {
      setState(() {
        _tanggal = hasil;
        _salahTanggal = false;
      });
    }
  }

  Future<void> _pilihWaktu() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: _waktu ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (hasil != null) {
      setState(() {
        _waktu = hasil;
        _salahWaktu = false;
      });
    }
  }

  void _lanjut() {
    if (_langkah == 0) {
      final ok = _formInfo.currentState!.validate();
      setState(() {
        _salahTanggal = _tanggal == null;
        _salahWaktu = _waktu == null;
      });
      if (!ok || _tanggal == null || _waktu == null) return;
    } else if (_langkah == 1) {
      if (!_formTiket.currentState!.validate()) return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _langkah++);
  }

  void _kembali() {
    if (_langkah == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _langkah--);
    }
  }

  // Data harus lengkap sebelum disimpan, karena langsung masuk database.
  // Kalau ada yang kurang, kembali ke langkah yang bersangkutan.
  bool _lengkap() {
    final infoLengkap = _nama.text.trim().length >= 3 &&
        _kategori != null &&
        _deskripsi.text.trim().isNotEmpty &&
        _lokasi.text.trim().isNotEmpty &&
        _tanggal != null &&
        _waktu != null;

    if (!infoLengkap) {
      setState(() {
        _langkah = 0;
        _salahTanggal = _tanggal == null;
        _salahWaktu = _waktu == null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _formInfo.currentState?.validate());
      return false;
    }

    final kuota = int.tryParse(_kuota.text.trim()) ?? 0;
    final harga = int.tryParse(_harga.text.trim()) ?? 0;
    if (kuota < 1 || (_berbayar && harga < 1)) {
      setState(() => _langkah = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) => _formTiket.currentState?.validate());
      return false;
    }
    return true;
  }

  // status draft = simpan saja, menunggu = diajukan ke admin untuk disetujui.
  Future<void> _simpan(StatusEvent status) async {
    if (_menyimpan || !_lengkap()) return;

    final lama = widget.event;
    final harga = _berbayar ? (int.tryParse(_harga.text.trim()) ?? 0) : 0;
    final kuota = int.tryParse(_kuota.text.trim()) ?? 0;

    final baru = OrganizerEvent(
      id: lama?.id ?? '',
      judul: _nama.text.trim(),
      kategori: _kategori!,
      deskripsi: _deskripsi.text.trim(),
      tanggal: _tanggal!,
      waktu: _waktu!,
      lokasi: _lokasi.text.trim(),
      alamat: _alamat.text.trim(),
      banner: _banner,
      harga: harga,
      kuota: kuota,
      terjual: lama?.terjual ?? 0,
      status: status,
    );

    setState(() => _menyimpan = true);
    try {
      final hasil = await simpanEvent(baru);
      if (!mounted) return;
      Navigator.pop(
        context,
        hasil.status == StatusEvent.draft
            ? 'Draft disimpan'
            : hasil.status == StatusEvent.terbit
                ? 'Perubahan disimpan'
                : 'Event diajukan, menunggu persetujuan admin',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // =========================
  // TAMPILAN
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
          onPressed: _kembali,
        ),
        title: Text(
          _edit ? 'Edit event' : 'Buat event',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: Column(
        children: [
          _penunjukLangkah(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: [_langkahInfo, _langkahTiket, _langkahTinjau][_langkah](),
            ),
          ),
          _barBawah(),
        ],
      ),
    );
  }

  Widget _penunjukLangkah() {
    const judul = ['Informasi', 'Tiket', 'Tinjau'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= _langkah ? AppColors.primaryBlue : const Color(0xFFE3EEFD),
                  ),
                  child: i < _langkah
                      ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: i == _langkah ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  judul[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == _langkah ? FontWeight.w600 : FontWeight.normal,
                    color: i <= _langkah ? AppColors.primaryBlue : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
                  color: i < _langkah ? AppColors.primaryBlue : const Color(0xFFE3EEFD),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _barBawah() {
    final terakhir = _langkah == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5EAF5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _menyimpan ? null : () => _simpan(StatusEvent.draft),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Simpan draft', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _menyimpan ? null : (terakhir ? () => _simpan(StatusEvent.menunggu) : _lanjut),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  terakhir ? (_menyimpan ? 'Menyimpan...' : 'Ajukan ke Admin') : 'Lanjut',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Langkah 1: informasi ----

  Widget _langkahInfo() {
    return Form(
      key: _formInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bannerBox(),
          const SizedBox(height: 16),
          _label('Nama event'),
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: _dekor('Contoh: Seminar Teknologi 2026'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama event wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          _label('Kategori'),
          DropdownButtonFormField<String>(
            initialValue: _kategori,
            decoration: _dekor('Pilih kategori'),
            borderRadius: BorderRadius.circular(14),
            items: [for (final k in kategoriEvent) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (v) => setState(() => _kategori = v),
            validator: (v) => v == null ? 'Pilih kategori' : null,
          ),
          const SizedBox(height: 14),
          _label('Deskripsi'),
          TextFormField(
            controller: _deskripsi,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dekor('Ceritakan acaramu secara singkat'),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Tanggal'),
                    _kotakPilih(
                      icon: Icons.calendar_today_outlined,
                      teks: _tanggal == null ? 'Pilih tanggal' : tanggalEvent(_tanggal!),
                      terisi: _tanggal != null,
                      salah: _salahTanggal,
                      onTap: _pilihTanggal,
                    ),
                    if (_salahTanggal) _pesanSalah('Pilih tanggal'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Waktu'),
                    _kotakPilih(
                      icon: Icons.access_time_rounded,
                      teks: _waktu == null ? 'Pilih waktu' : waktuEvent(_waktu!),
                      terisi: _waktu != null,
                      salah: _salahWaktu,
                      onTap: _pilihWaktu,
                    ),
                    if (_salahWaktu) _pesanSalah('Pilih waktu'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label('Nama lokasi'),
          TextFormField(
            controller: _lokasi,
            textCapitalization: TextCapitalization.words,
            decoration: _dekor('Contoh: Aula Polibatam', icon: Icons.location_on_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lokasi wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          _label('Alamat'),
          TextFormField(
            controller: _alamat,
            textCapitalization: TextCapitalization.words,
            decoration: _dekor('Alamat lengkap (opsional)'),
          ),
        ],
      ),
    );
  }

  Future<void> _pilihBanner() async {
    if (_mengunggah) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _mengunggah = true);
      final url = await EventService.uploadBanner(await file.readAsBytes(), file.name);
      if (mounted) setState(() => _banner = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  Widget _bannerBox() {
    final ada = _banner != null && _banner!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pilihBanner,
      child: Container(
        height: ada ? 180 : 96,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.35)),
        ),
        child: _mengunggah
            ? const Center(child: CircularProgressIndicator())
            : ada
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      EventImage(url: _banner),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Row(
                          children: [
                            _tombolBanner(Icons.edit_outlined, _pilihBanner),
                            const SizedBox(width: 6),
                            _tombolBanner(Icons.delete_outline, () => setState(() => _banner = null)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.primaryBlue),
                      SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unggah banner event',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          SizedBox(height: 2),
                          Text('Disarankan rasio 16:9, maks. 2 MB', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _tombolBanner(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _kotakPilih({
    required IconData icon,
    required String teks,
    required bool terisi,
    required bool salah,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: salah ? const Color(0xFFDC2626) : const Color(0xFFE5EAF5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teks,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: terisi ? AppColors.textDark : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pesanSalah(String teks) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Text(teks, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
    );
  }

  // ---- Langkah 2: tiket ----

  Widget _langkahTiket() {
    return Form(
      key: _formTiket,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Jenis tiket'),
          Row(
            children: [
              Expanded(child: _pilihanJenis('Gratis', Icons.card_giftcard_rounded, !_berbayar)),
              const SizedBox(width: 12),
              Expanded(child: _pilihanJenis('Berbayar', Icons.payments_outlined, _berbayar)),
            ],
          ),
          if (_berbayar) ...[
            const SizedBox(height: 14),
            _label('Harga tiket'),
            TextFormField(
              controller: _harga,
              keyboardType: TextInputType.number,
              decoration: _dekor('Contoh: 50000').copyWith(prefixText: 'Rp '),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Isi harga lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF8A4B00)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran dilakukan tunai ke panitia. Tiket aktif setelah QR bayar di-scan.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A4B00)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _label('Kuota peserta'),
          TextFormField(
            controller: _kuota,
            keyboardType: TextInputType.number,
            decoration: _dekor('Contoh: 100').copyWith(suffixText: 'tiket'),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'Isi kuota lebih dari 0';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _pilihanJenis(String label, IconData icon, bool aktif) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _berbayar = label == 'Berbayar'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: aktif ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: aktif ? AppColors.primaryBlue : const Color(0xFFE5EAF5),
            width: aktif ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: aktif ? AppColors.primaryBlue : const Color(0xFF64748B)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: aktif ? AppColors.primaryBlue : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Langkah 3: tinjau ----

  Widget _langkahTinjau() {
    final harga = _berbayar ? int.tryParse(_harga.text.trim()) ?? 0 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nama.text.trim(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(_kategori ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _baris(Icons.calendar_today_outlined, 'Tanggal', _tanggal == null ? '-' : tanggalEvent(_tanggal!)),
          _baris(Icons.access_time_rounded, 'Waktu', _waktu == null ? '-' : waktuEvent(_waktu!)),
          _baris(Icons.location_on_outlined, 'Lokasi', _lokasi.text.trim().isEmpty ? '-' : _lokasi.text.trim()),
          if (_alamat.text.trim().isNotEmpty) _baris(Icons.map_outlined, 'Alamat', _alamat.text.trim()),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _baris(Icons.confirmation_num_outlined, 'Harga', harga == 0 ? 'Gratis' : formatRupiah(harga)),
          _baris(Icons.groups_outlined, 'Kuota', '${_kuota.text.trim()} tiket'),
          if (_deskripsi.text.trim().isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            Text(
              _deskripsi.text.trim(),
              style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF475569)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _baris(IconData icon, String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
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

  // ---- umum ----

  Widget _label(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
    );
  }

  InputDecoration _dekor(String hint, {IconData? icon}) {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: garis(const Color(0xFFE5EAF5)),
      enabledBorder: garis(const Color(0xFFE5EAF5)),
      focusedBorder: garis(AppColors.primaryBlue),
      errorBorder: garis(const Color(0xFFDC2626)),
      focusedErrorBorder: garis(const Color(0xFFDC2626)),
    );
  }
}
