import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/organizer_event_store.dart';
import '../../widgets/event_image.dart';
import 'organizer_event_form_screen.dart';

// Tab Event penyelenggara: daftar event miliknya + tempat membuat event baru.
class OrganizerEventScreen extends StatefulWidget {
  const OrganizerEventScreen({super.key});

  @override
  State<OrganizerEventScreen> createState() => _OrganizerEventScreenState();
}

class _OrganizerEventScreenState extends State<OrganizerEventScreen> {
  final _cari = TextEditingController();
  StatusEvent? _filter; // null = semua

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  void _pesan(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _buka(OrganizerEvent? event) async {
    final hasil = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => OrganizerEventFormScreen(event: event)),
    );
    if (hasil != null && mounted) _pesan(hasil);
  }

  Future<void> _hapus(OrganizerEvent e) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus event'),
        content: Text('Event "${e.judul}" akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (ya == true) {
      hapusEvent(e.id);
      _pesan('Event dihapus');
    }
  }

  void _menu(OrganizerEvent e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
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
              Text(
                e.judul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              if (e.status != StatusEvent.selesai)
                _menuItem(Icons.edit_outlined, 'Edit event', AppColors.textDark, () {
                  Navigator.pop(ctx);
                  _buka(e);
                }),
              if (e.status == StatusEvent.draft)
                _menuItem(Icons.publish_rounded, 'Terbitkan', AppColors.primaryBlue, () {
                  Navigator.pop(ctx);
                  simpanEvent(e.copyWith(status: StatusEvent.terbit));
                  _pesan('Event diterbitkan');
                }),
              _menuItem(Icons.delete_outline_rounded, 'Hapus event', const Color(0xFFDC2626), () {
                Navigator.pop(ctx);
                _hapus(e);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buka(null),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat event', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ValueListenableBuilder<List<OrganizerEvent>>(
        valueListenable: organizerEvents,
        builder: (context, semua, _) {
          final kata = _cari.text.trim().toLowerCase();
          final tampil = semua.where((e) {
            if (_filter != null && e.status != _filter) return false;
            return kata.isEmpty || e.judul.toLowerCase().contains(kata);
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            children: [
              const Text(
                'Event saya',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                '${semua.length} event',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              _kolomCari(),
              const SizedBox(height: 12),
              _filterChips(semua),
              const SizedBox(height: 14),
              if (tampil.isEmpty)
                _kosong(semua.isEmpty)
              else
                for (final e in tampil)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _kartu(e),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _kolomCari() {
    return TextField(
      controller: _cari,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari nama event',
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5EAF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5EAF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _filterChips(List<OrganizerEvent> semua) {
    int hitung(StatusEvent? s) => s == null ? semua.length : semua.where((e) => e.status == s).length;

    Widget chip(String label, StatusEvent? s) {
      final aktif = _filter == s;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _filter = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: aktif ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: aktif ? AppColors.primaryBlue : const Color(0xFFDCE7FB)),
            ),
            child: Text(
              '$label (${hitung(s)})',
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
      child: Row(
        children: [
          chip('Semua', null),
          chip('Terbit', StatusEvent.terbit),
          chip('Draft', StatusEvent.draft),
          chip('Selesai', StatusEvent.selesai),
        ],
      ),
    );
  }

  Widget _kosong(bool belumAdaEvent) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            belumAdaEvent ? 'Belum ada event' : 'Event tidak ditemukan',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            belumAdaEvent ? 'Mulai dengan membuat event pertamamu.' : 'Coba kata kunci atau filter lain.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _badge(StatusEvent s) {
    late final String teks;
    late final Color warna;
    switch (s) {
      case StatusEvent.terbit:
        teks = 'Terbit';
        warna = const Color(0xFF16A34A);
      case StatusEvent.draft:
        teks = 'Draft';
        warna = AppColors.accentOrange;
      case StatusEvent.selesai:
        teks = 'Selesai';
        warna = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(teks, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: warna)),
    );
  }

  Widget _kartu(OrganizerEvent e) {
    final persen = e.kuota == 0 ? 0.0 : (e.terjual / e.kuota).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _menu(e),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: EventImage(url: e.banner, width: 64, height: 64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.judul,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _badge(e.status),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text(
                              tanggalEvent(e.tanggal),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: persen,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE3EEFD),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${e.terjual} / ${e.kuota} tiket',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    e.gratis ? 'Gratis' : formatRupiah(e.harga),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: e.gratis ? AppColors.accentOrange : AppColors.primaryBlue,
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
