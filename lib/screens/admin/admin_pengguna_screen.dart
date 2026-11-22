import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'admin_widgets.dart';

class AdminPenggunaScreen extends StatefulWidget {
  const AdminPenggunaScreen({super.key});

  @override
  State<AdminPenggunaScreen> createState() => _AdminPenggunaScreenState();
}

class _AdminPenggunaScreenState extends State<AdminPenggunaScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedRole = 'Semua';
  String _cariAktif = ''; // kata pencarian yang sudah diterapkan (tombol Filter atau Enter)
  int _hal = 0;
  int _perHal = 10;
  int? _urut; // nomor kolom yang dipakai untuk mengurutkan
  bool _naik = true;

  final List<Map<String, dynamic>> _users = [
    {
      'nama': 'Muhammad Rafie',
      'email': 'rafie@student.polibatam.ac.id',
      'nim': '3312511136',
      'role': 'Mahasiswa',
      'aktif': true,
      'warna': 0xFF2563EB,
    },
    {
      'nama': 'Andi Pratama',
      'email': 'andi@student.polibatam.ac.id',
      'nim': '3312511101',
      'role': 'Mahasiswa',
      'aktif': true,
      'warna': 0xFF0D9488,
    },
    {
      'nama': 'Siti Aulia',
      'email': 'siti@student.polibatam.ac.id',
      'nim': '3312511102',
      'role': 'Mahasiswa',
      'aktif': true,
      'warna': 0xFF9333EA,
    },
    {
      'nama': 'Admin EventIn',
      'email': 'admin@eventin.test',
      'nim': '-',
      'role': 'Admin',
      'aktif': true,
      'warna': 0xFFEA580C,
    },
    {
      'nama': 'Rizky Ramadhan',
      'email': 'rizky@student.polibatam.ac.id',
      'nim': '3312511103',
      'role': 'Mahasiswa',
      'aktif': false,
      'warna': 0xFF64748B,
    },
    {
      'nama': 'Nadia Putri',
      'email': 'nadia@student.polibatam.ac.id',
      'nim': '3312511104',
      'role': 'Penyelenggara',
      'aktif': true,
      'warna': 0xFFDB2777,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final keyword = _cariAktif;

    return _users.where((user) {
      final cocokRole =
          _selectedRole == 'Semua' || user['role'] == _selectedRole;

      final cocokCari =
          user['nama'].toString().toLowerCase().contains(keyword) ||
          user['email'].toString().toLowerCase().contains(keyword) ||
          user['nim'].toString().toLowerCase().contains(keyword);

      return cocokRole && cocokCari;
    }).toList();
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
          return a['nama'].toString().toLowerCase().compareTo(b['nama'].toString().toLowerCase());
        case 2:
          return a['nim'].toString().compareTo(b['nim'].toString());
        case 3:
          return a['role'].toString().compareTo(b['role'].toString());
        case 4:
          return (b['aktif'] == true ? 1 : 0).compareTo(a['aktif'] == true ? 1 : 0);
        default:
          return 0;
      }
    }

    final hasil = [...d]..sort(banding);
    return _naik ? hasil : hasil.reversed.toList();
  }


  static const _daftarRole = ['Semua', 'Mahasiswa', 'Penyelenggara', 'Admin'];

  int _hitungRole(String role) =>
      role == 'Semua' ? _users.length : _users.where((u) => u['role'] == role).length;

  Widget _badgeRole(String role) {
    switch (role) {
      case 'Admin':
        return const AdminBadge(teks: 'Admin', latar: Color(0xFFE6EBF3), warna: adminNavy);
      case 'Penyelenggara':
        return const AdminBadge.biru('Penyelenggara');
      default:
        return const AdminBadge.abu('Mahasiswa');
    }
  }

  AdminBaris _baris(Map<String, dynamic> user, int no) {
    final aktif = user['aktif'] == true;
    final nama = user['nama'] as String;
    final warna = Color(user['warna'] as int);
    final inisial = nama.trim().split(' ').take(2).map((x) => x[0].toUpperCase()).join();

    return AdminBaris(
      onTap: () => _showUserDetail(user),
      sel: [
        Text('$no', style: const TextStyle(fontSize: 12.5, color: Color(0xFF667085))),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: warna.withValues(alpha: 0.14),
              child: Text(inisial, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: warna)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    user['email'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: adminAbu),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(user['nim'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        _badgeRole(user['role'] as String),
        aktif ? const AdminBadge.hijau('Aktif') : const AdminBadge.abu('Nonaktif'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            AdminTombolAksi(label: 'Detail', jenis: AdminAksi.detail, onTap: () => _showUserDetail(user)),
            if (user['role'] != 'Admin')
              AdminTombolAksi(
                label: aktif ? 'Nonaktifkan' : 'Aktifkan',
                jenis: aktif ? AdminAksi.tolak : AdminAksi.setujui,
                ikon: Icons.power_settings_new_rounded,
                lebar: 100,
                onTap: () {
                  setState(() => user['aktif'] = !aktif);
                  adminPesan(context, aktif ? 'Akun $nama dinonaktifkan' : 'Akun $nama diaktifkan');
                },
              )
            else
              const SizedBox(width: 100),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final semua = _urutkan(_filteredUsers);
    final jumlahHal = adminJumlahHalaman(semua.length, _perHal);
    final hal = _hal >= jumlahHal ? jumlahHal - 1 : _hal;
    final users = semua.skip(hal * _perHal).take(_perHal).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        AdminDuaKolom(
          rail: (horizontal) => AdminDaftarStatus(
            horizontal: horizontal,
            item: [for (final r in _daftarRole) AdminStatusItem(r, _hitungRole(r))],
            terpilih: _daftarRole.indexOf(_selectedRole),
            onPilih: (i) => setState(() {
              _selectedRole = _daftarRole[i];
              _hal = 0;
            }),
          ),
          isi: AdminTabelBaru(
            atas: AdminBarisCari(
              controller: _searchController,
              hint: 'Cari nama, email, atau NIM',
              onChanged: () => setState(() {}),
              onCari: () => setState(() {
                _cariAktif = _searchController.text.trim().toLowerCase();
                _hal = 0;
              }),
              onReset: () => setState(() {
                _searchController.clear();
                _cariAktif = '';
                _selectedRole = 'Semua';
                _urut = null;
                _naik = true;
                _hal = 0;
              }),
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
              AdminKol('Pengguna', 6, urut: true),
              AdminKol('NIM', 3, urut: true),
              AdminKol('Role', 3, tengah: true, urut: true),
              AdminKol('Status', 2, tengah: true, urut: true),
              AdminKol('Aksi', 5, tengah: true),
            ],
            baris: [for (var i = 0; i < users.length; i++) _baris(users[i], hal * _perHal + i + 1)],
            kosong: 'Pengguna tidak ditemukan',
            info: AdminInfoJumlah(
              mulai: semua.isEmpty ? 0 : hal * _perHal + 1,
              sampai: hal * _perHal + users.length,
              total: semua.length,
              label: 'pengguna',
            ),
            paging: AdminPaging(halaman: hal, jumlah: jumlahHal, onPilih: (i) => setState(() => _hal = i)),
          ),
        ),
      ],
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Detail Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['nama'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _detailRow('Email', user['email'] as String),
            _detailRow('NIM', user['nim'] as String),
            _detailRow('Role', user['role'] as String),
            _detailRow('Status', user['aktif'] ? 'Aktif' : 'Nonaktif'),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          SelectableText(
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
