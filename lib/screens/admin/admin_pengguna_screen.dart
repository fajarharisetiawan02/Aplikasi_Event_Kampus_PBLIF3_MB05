import 'package:flutter/material.dart';

class AdminPenggunaScreen extends StatefulWidget {
  const AdminPenggunaScreen({super.key});

  @override
  State<AdminPenggunaScreen> createState() => _AdminPenggunaScreenState();
}

class _AdminPenggunaScreenState extends State<AdminPenggunaScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedRole = 'Semua';

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
      'email': 'admin@eventin.com',
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
    final keyword = _searchController.text.toLowerCase();

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

  int get _jumlahAktif => _users.where((user) => user['aktif'] == true).length;

  int get _jumlahMahasiswa =>
      _users.where((user) => user['role'] == 'Mahasiswa').length;

  int get _jumlahAdmin =>
      _users.where((user) => user['role'] == 'Admin').length;

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;
    final lebar = MediaQuery.of(context).size.width;
    final desktop = lebar >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        elevation: 0,
        title: const Text(
          'Manajemen Pengguna',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
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
                            'Kelola Pengguna',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pantau akun mahasiswa, admin, dan '
                            'penyelenggara event dalam satu tempat.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.5,
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
                              '${_users.length} akun terdaftar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.manage_accounts_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Ringkasan Pengguna',
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
                  final jumlahKolom = constraints.maxWidth >= 650 ? 4 : 2;

                 
return GridView.count(
  crossAxisCount: jumlahKolom,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: jumlahKolom == 4 ? 1.25 : 1.25,

                    children: [
                      _statCard(
                        'Total Akun',
                        _users.length.toString(),
                        Icons.people_alt_outlined,
                        const Color(0xFF2563EB),
                      ),
                      _statCard(
                        'Akun Aktif',
                        _jumlahAktif.toString(),
                        Icons.verified_user_outlined,
                        const Color(0xFF059669),
                      ),
                      _statCard(
                        'Mahasiswa',
                        _jumlahMahasiswa.toString(),
                        Icons.school_outlined,
                        const Color(0xFF7C3AED),
                      ),
                      _statCard(
                        'Admin',
                        _jumlahAdmin.toString(),
                        Icons.admin_panel_settings_outlined,
                        const Color(0xFFEA580C),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // JUDUL DAFTAR
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar Pengguna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                  ),
                  Text(
                    '${users.length} pengguna',
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
                  hintText: 'Cari nama, email, atau NIM...',
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // FILTER ROLE
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Semua', 'Mahasiswa', 'Penyelenggara', 'Admin']
                      .map((role) {
                        final selected = _selectedRole == role;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(role),
                            selected: selected,
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() {
                                _selectedRole = role;
                              });
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
                      })
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // DAFTAR AKUN
              if (users.isEmpty)
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
                        Icons.person_search_outlined,
                        size: 52,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Pengguna tidak ditemukan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Coba kata kunci atau filter yang berbeda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ...users.map((user) => _userCard(user)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
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
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172554),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final warna = Color(user['warna'] as int);
    final aktif = user['aktif'] as bool;
    final role = user['role'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: warna.withValues(alpha: 0.12),
                child: Text(
                  (user['nama'] as String)
                      .trim()
                      .split(RegExp(r'\s+'))
                      .take(2)
                      .map((e) => e[0])
                      .join()
                      .toUpperCase(),
                  style: TextStyle(
                    color: warna,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['nama'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF172554),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aksi pengguna',
                onSelected: (aksi) {
                  if (aksi == 'detail') {
                    _showUserDetail(user);
                  } else if (aksi == 'status') {
                    setState(() {
                      user['aktif'] = !aktif;
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Lihat detail'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                          aktif
                              ? Icons.person_off_outlined
                              : Icons.how_to_reg_outlined,
                          size: 20,
                        ),

                        const SizedBox(width: 10),
                        Text(aktif ? 'Nonaktifkan' : 'Aktifkan'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE8EDF5)),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'NIM: ${user['nim']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              _badge(
                role,
                role == 'Admin'
                    ? const Color(0xFFFFEDD5)
                    : role == 'Penyelenggara'
                    ? const Color(0xFFF3E8FF)
                    : const Color(0xFFDBEAFE),
                role == 'Admin'
                    ? const Color(0xFF9A3412)
                    : role == 'Penyelenggara'
                    ? const Color(0xFF7E22CE)
                    : const Color(0xFF1D4ED8),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                aktif ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 17,
                color: aktif
                    ? const Color(0xFF059669)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 7),
              Text(
                aktif ? 'Akun aktif' : 'Akun nonaktif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: aktif
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showUserDetail(user),
                child: const Text('Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
