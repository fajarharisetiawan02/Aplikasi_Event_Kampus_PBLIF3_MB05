
import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/event_image.dart';
import 'admin_widgets.dart';

class AdminEventScreen extends StatefulWidget {
  const AdminEventScreen({super.key});

  @override
  State<AdminEventScreen> createState() => _AdminEventScreenState();
}

class _AdminEventScreenState extends State<AdminEventScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _filter = 'Semua';
  String _kategori = 'Semua kategori';
  String _cariAktif = ''; // kata pencarian yang sudah diterapkan (tombol Filter atau Enter)
  int _hal = 0;
  int _perHal = 10;
  int? _urut; // nomor kolom yang dipakai untuk mengurutkan
  bool _naik = true;

  // Diambil dari API (database), bukan data contoh.
  List<Map<String, dynamic>> _events = [];
  bool _memuat = true;
  String? _galat;

  static const _warna = [0xFF7C3AED, 0xFF2563EB, 0xFF059669, 0xFFEA580C, 0xFFDB2777];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final data = await EventService.getMine();
      final hasil = <Map<String, dynamic>>[];
      for (final e in data) {
        final status = _labelStatus(e['status'] as String?);
        if (status == null) continue; // draft penyelenggara belum perlu dilihat admin
        hasil.add({
          'id': e['id'],
          'judul': e['judul'] ?? '',
          'kategori': e['kategori'] ?? '',
          'tanggal': formatTanggal(DateTime.parse(e['tanggal'] as String)),
          'tglRaw': e['tanggal'],
          'lokasi': e['lokasi'] ?? '',
          'harga': e['harga'] ?? 0,
          'kuota': e['kuota'] ?? 0,
          'terjual': e['kuota_terjual'] ?? 0,
          'banner': e['banner_url'],
          'status': status,
          'penyelenggara': (e['organizer'] is Map ? e['organizer']['nama'] : null) ?? '-',
          'alasan': e['alasan_penolakan'],
          'warna': _warna[(e['id'] as int) % _warna.length],
        });
      }
      if (!mounted) return;
      setState(() {
        _events = hasil;
        _galat = null;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = '$e';
        _memuat = false;
      });
    }
  }

  String? _labelStatus(String? status) {
    switch (status) {
      case 'published':
        return 'Dipublikasikan';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEvents {
    final keyword = _cariAktif;

    return _events.where((event) {
      final cocokNama =
          event['judul'].toString().toLowerCase().contains(keyword) ||
          event['kategori'].toString().toLowerCase().contains(keyword);

      final cocokStatus =
          _filter == 'Semua' || event['status'] == _filter;

      final cocokKategori =
          _kategori == 'Semua kategori' || event['kategori'] == _kategori;

      return cocokNama && cocokStatus && cocokKategori;
    }).toList();
  }

  List<String> get _opsiKategori {
    final k = _events
        .map((e) => e['kategori'].toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua kategori', ...k];
  }

  void _klikUrut(int i) {
    setState(() {
      if (_urut == i) {
        // naik -> turun -> kembali ke urutan awal
        if (_naik) {
          _naik = false;
        } else {
          _urut = null;
          _naik = true;
        }
      } else {
        _urut = i;
        _naik = true;
      }
      _hal = 0;
    });
  }

  List<Map<String, dynamic>> _urutkan(List<Map<String, dynamic>> d) {
    if (_urut == null) return d;
    int banding(Map<String, dynamic> a, Map<String, dynamic> b) {
      switch (_urut) {
        case 1:
          return a['judul'].toString().toLowerCase().compareTo(b['judul'].toString().toLowerCase());
        case 2:
          return DateTime.parse(a['tglRaw'] as String).compareTo(DateTime.parse(b['tglRaw'] as String));
        case 3:
          return (a['terjual'] as num).toInt().compareTo((b['terjual'] as num).toInt());
        case 4:
          return a['status'].toString().compareTo(b['status'].toString());
        default:
          return 0;
      }
    }

    final hasil = [...d]..sort(banding);
    return _naik ? hasil : hasil.reversed.toList();
  }

  int _count(String status) {
    if (status == 'Semua') return _events.length;
    return _events.where((e) => e['status'] == status).length;
  }

  String _rupiah(int harga) {
    if (harga == 0) return 'Gratis';
    final angka = harga.toString();
    final hasil = StringBuffer();

    for (int i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) {
        hasil.write('.');
      }
      hasil.write(angka[i]);
    }

    return 'Rp$hasil';
  }

  static const _daftarFilter = ['Semua', 'Menunggu Verifikasi', 'Dipublikasikan', 'Ditolak', 'Dibatalkan'];

  static const _labelStatus2 = {
    'Semua': 'Semua',
    'Menunggu Verifikasi': 'Menunggu',
    'Dipublikasikan': 'Dipublikasikan',
    'Ditolak': 'Ditolak',
    'Dibatalkan': 'Dibatalkan',
  };

  @override
  Widget build(BuildContext context) {
    if (_memuat) return const Center(child: CircularProgressIndicator());

    final events = _urutkan(_filteredEvents);
    final jumlahHal = adminJumlahHalaman(events.length, _perHal);
    final hal = _hal >= jumlahHal ? jumlahHal - 1 : _hal;
    final tampil = events.skip(hal * _perHal).take(_perHal).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        if (_galat != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _galat!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                ),
                TextButton(onPressed: _muat, child: const Text('Coba lagi')),
              ],
            ),
          ),
        AdminDuaKolom(
          rail: (horizontal) => AdminDaftarStatus(
            horizontal: horizontal,
            item: [
              for (final f in _daftarFilter)
                AdminStatusItem(_labelStatus2[f]!, _count(f), sorot: f == 'Menunggu Verifikasi'),
            ],
            terpilih: _daftarFilter.indexOf(_filter),
            onPilih: (i) => setState(() {
              _filter = _daftarFilter[i];
              _hal = 0;
            }),
          ),
          isi: AdminTabelBaru(
            atas: AdminBarisCari(
              controller: _searchController,
              hint: 'Cari judul atau kategori',
              onChanged: () => setState(() {}),
              onCari: () => setState(() {
                _cariAktif = _searchController.text.trim().toLowerCase();
                _hal = 0;
              }),
              onReset: () => setState(() {
                _searchController.clear();
                _cariAktif = '';
                _kategori = 'Semua kategori';
                _filter = 'Semua';
                _urut = null;
                _naik = true;
                _hal = 0;
              }),
              filter: [
                AdminPilihan(
                  nilai: _kategori,
                  opsi: _opsiKategori,
                  onUbah: (v) => setState(() {
                    _kategori = v;
                    _hal = 0;
                  }),
                ),
              ],
              kanan: AdminPilihPerHal(
                nilai: _perHal,
                onUbah: (v) => setState(() {
                  _perHal = v;
                  _hal = 0;
                }),
              ),
            ),
            urutKolom: _urut,
            urutNaik: _naik,
            onUrut: _klikUrut,
            kolom: const [
              AdminKol('No', 1, tengah: true),
              AdminKol('Event', 6, urut: true),
              AdminKol('Tanggal dan harga', 3, urut: true),
              AdminKol('Peserta', 3, tengah: true, urut: true),
              AdminKol('Status', 3, tengah: true, urut: true),
              AdminKol('Aksi', 4, tengah: true),
            ],
            baris: [
              for (var i = 0; i < tampil.length; i++) _baris(tampil[i], hal * _perHal + i + 1),
            ],
            kosong: 'Event tidak ditemukan',
            info: AdminInfoJumlah(
              mulai: events.isEmpty ? 0 : hal * _perHal + 1,
              sampai: hal * _perHal + tampil.length,
              total: events.length,
              label: 'event',
            ),
            paging: AdminPaging(halaman: hal, jumlah: jumlahHal, onPilih: (i) => setState(() => _hal = i)),
          ),
        ),
      ],
    );
  }

  Widget _thumb(Map<String, dynamic> event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: EventImage(url: event['banner'] as String?, width: 40, height: 40),
    );
  }

  Widget _badgeStatus(String status) {
    switch (status) {
      case 'Dipublikasikan':
        return const AdminBadge.hijau('Dipublikasikan');
      case 'Ditolak':
        return const AdminBadge.merah('Ditolak');
      case 'Dibatalkan':
        return const AdminBadge.abu('Dibatalkan');
      default:
        return const AdminBadge.kuning('Menunggu');
    }
  }

  AdminBaris _baris(Map<String, dynamic> event, int no) {
    final status = event['status'] as String;
    final menunggu = status == 'Menunggu Verifikasi';
    final terjual = (event['terjual'] as num?)?.toInt() ?? 0;
    final kuota = (event['kuota'] as num?)?.toInt() ?? 0;

    final aksi = <Widget>[];
    if (menunggu) {
      aksi.add(AdminTombolAksi(label: 'Setujui', jenis: AdminAksi.setujui, onTap: () => _ubahStatus(event, 'Dipublikasikan')));
      aksi.add(AdminTombolAksi(label: 'Tolak', jenis: AdminAksi.tolak, onTap: () => _ubahStatus(event, 'Ditolak')));
    } else if (status == 'Ditolak') {
      aksi.add(AdminTombolAksi(label: 'Setujui', jenis: AdminAksi.setujui, onTap: () => _ubahStatus(event, 'Dipublikasikan')));
    } else {
      aksi.add(AdminTombolAksi(label: 'Detail', jenis: AdminAksi.detail, onTap: () => _showDetail(event)));
    }

    return AdminBaris(
      sorot: menunggu,
      onTap: () => _showDetail(event),
      sel: [
        Text('$no', style: const TextStyle(fontSize: 12.5, color: Color(0xFF667085))),
        Row(
          children: [
            _thumb(event),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['judul'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    '${event['kategori']}, ${event['lokasi']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: adminAbu),
                  ),
                  Text(
                    'Oleh ${event['penyelenggara']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: adminAbu),
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              adminTanggalPendek(DateTime.parse(event['tglRaw'] as String)),
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
            Text(_rupiah(event['harga'] as int), style: const TextStyle(fontSize: 11.5, color: adminAbu)),
          ],
        ),
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$terjual / $kuota', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: kuota > 0 ? (terjual / kuota).clamp(0.0, 1.0) : 0,
                  minHeight: 5,
                  backgroundColor: adminGaris,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        _badgeStatus(status),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: aksi),
      ],
    );
  }

  Future<String?> _tanyaAlasan() {
    final kontrol = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak event'),
        content: TextField(
          controller: kontrol,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Alasan penolakan (akan dilihat penyelenggara)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final teks = kontrol.text.trim();
              if (teks.length >= 3) Navigator.pop(dialogContext, teks);
            },
            child: const Text('Tolak', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  // Setujui / tolak langsung ke server; daftar dimuat ulang dari database.
  Future<void> _ubahStatus(Map<String, dynamic> event, String statusBaru) async {
    final id = event['id'] as int;
    try {
      if (statusBaru == 'Dipublikasikan') {
        await EventService.approve(id);
      } else {
        final alasan = await _tanyaAlasan();
        if (alasan == null) return;
        await EventService.reject(id, alasan);
      }
      await _muat();
      if (!mounted) return;
      adminPesan(
        context,
        statusBaru == 'Dipublikasikan'
            ? '${event['judul']} berhasil dipublikasikan'
            : '${event['judul']} ditolak',
      );
    } catch (e) {
      if (!mounted) return;
      adminPesan(context, '$e', galat: true);
    }
  }

  void _showDetail(Map<String, dynamic> event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text('Detail Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['judul'] as String,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Kategori', event['kategori'].toString()),
            _detailRow('Tanggal', event['tanggal'].toString()),
            _detailRow('Lokasi', event['lokasi'].toString()),
            _detailRow(
              'Harga',
              _rupiah(event['harga'] as int),
            ),
            _detailRow(
              'Kuota',
              '${event['kuota']} peserta',
            ),
            _detailRow('Penyelenggara', event['penyelenggara'].toString()),
            _detailRow('Status', event['status'].toString()),
            if ((event['alasan'] ?? '').toString().isNotEmpty)
              _detailRow('Alasan penolakan', event['alasan'].toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF172554),
            ),
          ),
        ],
      ),
    );
  }
}
