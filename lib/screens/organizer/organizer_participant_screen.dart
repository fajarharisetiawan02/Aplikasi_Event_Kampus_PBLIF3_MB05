import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/organizer_participant_store.dart';

class OrganizerParticipantScreen extends StatefulWidget {
  const OrganizerParticipantScreen({super.key});

  @override
  State<OrganizerParticipantScreen> createState() => _OrganizerParticipantScreenState();
}

class _OrganizerParticipantScreenState extends State<OrganizerParticipantScreen> {
  final TextEditingController _searchController = TextEditingController();

  StatusPeserta? _status; // null = semua
  String? _event; // null = semua event

  @override
  void initState() {
    super.initState();
    permintaanFilterPeserta.addListener(_onPermintaanFilter);
  }

  @override
  void dispose() {
    permintaanFilterPeserta.removeListener(_onPermintaanFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _onPermintaanFilter() {
    final p = permintaanFilterPeserta.value;
    if (p == null) return;
    setState(() => _status = p.status);
  }

  void _pesan(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  // =========================
  // WARNA STATUS
  // =========================

  Color _warnaTeks(StatusPeserta s) {
    switch (s) {
      case StatusPeserta.menunggu:
        return const Color(0xFF8A4B00);
      case StatusPeserta.lunas:
        return const Color(0xFF145C33);
      case StatusPeserta.hadir:
        return const Color(0xFF0C447C);
      case StatusPeserta.batal:
        return const Color(0xFF64748B);
    }
  }

  Color _warnaLatar(StatusPeserta s) {
    switch (s) {
      case StatusPeserta.menunggu:
        return const Color(0xFFFFF4E0);
      case StatusPeserta.lunas:
        return const Color(0xFFE8F7EE);
      case StatusPeserta.hadir:
        return const Color(0xFFE3EEFD);
      case StatusPeserta.batal:
        return const Color(0xFFF1F5F9);
    }
  }

  Widget _badge(StatusPeserta s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: _warnaLatar(s), borderRadius: BorderRadius.circular(20)),
      child: Text(
        labelStatus(s),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _warnaTeks(s)),
      ),
    );
  }

  // =========================
  // TAMPILAN
  // =========================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PesertaEvent>>(
      valueListenable: daftarPeserta,
      builder: (context, semua, _) {
        final keyword = _searchController.text.trim().toLowerCase();
        final dalamEvent = semua.where((p) => _event == null || p.event == _event).toList();

        final tampil = dalamEvent.where((p) {
          if (_status != null && p.status != _status) return false;
          return keyword.isEmpty ||
              p.nama.toLowerCase().contains(keyword) ||
              p.nim.toLowerCase().contains(keyword);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peserta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dalamEvent.length} peserta',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  _kolomCari(),
                  const SizedBox(height: 10),
                  _pemilihEvent(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            _filterChips(dalamEvent),
            const SizedBox(height: 10),
            Expanded(
              child: tampil.isEmpty
                  ? const Center(
                      child: Text(
                        'Peserta tidak ditemukan.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: tampil.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _kartu(tampil[i]),
                      ),
                    ),
            ),
          ],
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
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari nama atau NIM',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(_searchController.clear),
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
                _event ?? 'Semua event',
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
                'Pilih event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              for (final e in pilihan)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e ?? 'Semua event', style: const TextStyle(fontSize: 14)),
                  trailing: _event == e
                      ? const Icon(Icons.check_rounded, color: AppColors.primaryBlue)
                      : null,
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

  Widget _filterChips(List<PesertaEvent> dalamEvent) {
    int hitung(StatusPeserta? s) =>
        s == null ? dalamEvent.length : dalamEvent.where((p) => p.status == s).length;

    Widget chip(String label, StatusPeserta? s) {
      final aktif = _status == s;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _status = s),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          chip('Semua', null),
          chip('Menunggu bayar', StatusPeserta.menunggu),
          chip('Lunas', StatusPeserta.lunas),
          chip('Hadir', StatusPeserta.hadir),
        ],
      ),
    );
  }

  Widget _kartu(PesertaEvent p) {
    final belumBayar = p.status == StatusPeserta.menunggu && p.harga > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _detail(p.id),
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
                  p.nama.substring(0, 1).toUpperCase(),
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
                      '${p.nim} · ${p.event}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badge(p.status),
                  if (belumBayar) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(p.harga),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentOrange),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // DETAIL + AKSI MANUAL
  // =========================

  void _detail(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final p = cariPeserta(id);
        if (p == null) return const SizedBox.shrink();

        return SafeArea(
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
                    _badge(p.status),
                  ],
                ),
                const SizedBox(height: 10),
                _baris('NIM', p.nim),
                _baris('Event', p.event),
                _baris('Tiket', p.harga == 0 ? 'Gratis' : formatRupiah(p.harga)),
                const SizedBox(height: 14),
                if (p.status == StatusPeserta.menunggu)
                  _tombol('Tandai lunas (tunai)', Icons.payments_outlined, () {
                    Navigator.pop(ctx);
                    ubahStatusPeserta(p.id, StatusPeserta.lunas);
                    _pesan('${p.nama} ditandai lunas');
                  }),
                if (p.status == StatusPeserta.lunas)
                  _tombol('Check-in manual', Icons.login_rounded, () {
                    Navigator.pop(ctx);
                    ubahStatusPeserta(p.id, StatusPeserta.hadir);
                    _pesan('${p.nama} tercatat hadir');
                  }),
                if (p.status == StatusPeserta.menunggu || p.status == StatusPeserta.lunas)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Gunakan aksi manual hanya jika QR peserta tidak bisa di-scan.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

  Widget _tombol(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
