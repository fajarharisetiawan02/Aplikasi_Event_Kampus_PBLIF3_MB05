
import 'package:flutter/material.dart';

class AdminEventScreen extends StatefulWidget {
  const AdminEventScreen({super.key});

  @override
  State<AdminEventScreen> createState() => _AdminEventScreenState();
}

class _AdminEventScreenState extends State<AdminEventScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _filter = 'Semua';

  final List<Map<String, dynamic>> _events = [
    {
      'judul': 'Festival Musik Batam',
      'kategori': 'Musik',
      'tanggal': '20 Okt 2026',
      'lokasi': 'Batam',
      'harga': 150000,
      'status': 'Dipublikasikan',
      'kuota': 100,
      'warna': 0xFF7C3AED,
    },
    {
      'judul': 'Seminar Teknologi 2026',
      'kategori': 'Seminar',
      'tanggal': '25 Okt 2026',
      'lokasi': 'Politeknik Negeri Batam',
      'harga': 0,
      'status': 'Dipublikasikan',
      'kuota': 100,
      'warna': 0xFF2563EB,
    },
    {
      'judul': 'Turnamen Futsal Kampus',
      'kategori': 'Olahraga',
      'tanggal': '2 Nov 2026',
      'lokasi': 'Batam',
      'harga': 50000,
      'status': 'Menunggu Verifikasi',
      'kuota': 50,
      'warna': 0xFF059669,
    },
    {
      'judul': 'Workshop UI/UX Design',
      'kategori': 'Teknologi',
      'tanggal': '5 Nov 2026',
      'lokasi': 'Politeknik Negeri Batam',
      'harga': 25000,
      'status': 'Menunggu Verifikasi',
      'kuota': 40,
      'warna': 0xFFEA580C,
    },
    {
      'judul': 'Pameran Seni Mahasiswa',
      'kategori': 'Seni',
      'tanggal': '10 Nov 2026',
      'lokasi': 'Batam',
      'harga': 0,
      'status': 'Ditolak',
      'kuota': 75,
      'warna': 0xFFDB2777,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEvents {
    final keyword = _searchController.text.toLowerCase();

    return _events.where((event) {
      final cocokNama =
          event['judul'].toString().toLowerCase().contains(keyword) ||
          event['kategori'].toString().toLowerCase().contains(keyword);

      final cocokStatus =
          _filter == 'Semua' || event['status'] == _filter;

      return cocokNama && cocokStatus;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;
    final lebar = MediaQuery.of(context).size.width;
    final desktop = lebar >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Manajemen Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(desktop ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1D4ED8),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelola Event Kampus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pantau event, periksa pengajuan, '
                            'dan kelola publikasi EventIn.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_events.length} event terdaftar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Ringkasan Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172554),
                ),
              ),
              const SizedBox(height: 14),

              // STATISTIK
              LayoutBuilder(
                builder: (context, constraints) {
                  final kolom = constraints.maxWidth >= 650 ? 3 : 2;

                  return GridView.count(
                    crossAxisCount: kolom,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: kolom == 3 ? 1.7 : 1.5,
                    children: [
                      _statCard(
                        'Total Event',
                        _events.length.toString(),
                        Icons.event_note_outlined,
                        const Color(0xFF2563EB),
                      ),
                      _statCard(
                        'Dipublikasikan',
                        _count('Dipublikasikan').toString(),
                        Icons.check_circle_outline,
                        const Color(0xFF059669),
                      ),
                      _statCard(
                        'Menunggu Verifikasi',
                        _count('Menunggu Verifikasi').toString(),
                        Icons.pending_actions_outlined,
                        const Color(0xFFEA580C),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                  ),
                  Text(
                    '${events.length} event',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // PENCARIAN
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kategori event...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // FILTER
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Semua',
                    'Dipublikasikan',
                    'Menunggu Verifikasi',
                    'Ditolak',
                  ].map((status) {
                    final selected = _filter == status;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() => _filter = status);
                        },
                        selectedColor: const Color(0xFFDBEAFE),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              if (events.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 50,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Event tidak ditemukan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Coba kata kunci atau filter lain.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ...events.map((event) => _eventCard(event)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 25),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172554),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final warna = Color(event['warna'] as int);
    final status = event['status'] as String;

    final Color warnaStatus;
    final Color latarStatus;

    if (status == 'Dipublikasikan') {
      warnaStatus = const Color(0xFF047857);
      latarStatus = const Color(0xFFD1FAE5);
    } else if (status == 'Ditolak') {
      warnaStatus = const Color(0xFFB91C1C);
      latarStatus = const Color(0xFFFEE2E2);
    } else {
      warnaStatus = const Color(0xFFB45309);
      latarStatus = const Color(0xFFFEF3C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: warna,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['judul'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event['kategori'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aksi event',
                onSelected: (aksi) {
                  if (aksi == 'detail') {
                    _showDetail(event);
                  } else if (aksi == 'terima' ||
                      aksi == 'tolak') {
                    setState(() {
                      event['status'] = aksi == 'terima'
                          ? 'Dipublikasikan'
                          : 'Ditolak';
                    });
                  } else if (aksi == 'pending') {
                    setState(() {
                      event['status'] = 'Menunggu Verifikasi';
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Text('Lihat detail'),
                  ),
                  if (status == 'Menunggu Verifikasi') ...[
                    const PopupMenuItem(
                      value: 'terima',
                      child: Text('Setujui event'),
                    ),
                    const PopupMenuItem(
                      value: 'tolak',
                      child: Text('Tolak event'),
                    ),
                  ],
                  if (status != 'Menunggu Verifikasi')
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('Kembalikan ke verifikasi'),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.calendar_month_outlined,
            event['tanggal'] as String,
          ),
          const SizedBox(height: 9),
          _infoRow(
            Icons.location_on_outlined,
            event['lokasi'] as String,
          ),
          const SizedBox(height: 9),
          _infoRow(
            Icons.confirmation_number_outlined,
            '${_rupiah(event['harga'] as int)}  •  '
                'Kuota ${event['kuota']} peserta',
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: latarStatus,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: warnaStatus,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (status == 'Menunggu Verifikasi') ...[
                OutlinedButton.icon(
                  onPressed: () => _ubahStatus(
                    event,
                    'Dipublikasikan',
                  ),
                  icon: const Icon(Icons.check, size: 17),
                  label: const Text('Setujui'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _ubahStatus(event, 'Ditolak'),
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Tolak'),
                ),
              ],
              TextButton(
                onPressed: () => _showDetail(event),
                child: const Text('Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _ubahStatus(
    Map<String, dynamic> event,
    String statusBaru,
  ) {
    setState(() {
      event['status'] = statusBaru;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${event['judul']} → $statusBaru',
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
            _detailRow('Status', event['status'].toString()),
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
