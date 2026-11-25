import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/admin_store.dart';
import '../../utils/app_colors.dart';
import 'admin_widgets.dart';

class AdminPengajuanScreen extends StatefulWidget {
  const AdminPengajuanScreen({super.key});

  @override
  State<AdminPengajuanScreen> createState() => _AdminPengajuanScreenState();
}

class _AdminPengajuanScreenState extends State<AdminPengajuanScreen> {
  final _cari = TextEditingController();
  String _cariAktif = ''; // kata pencarian yang sudah diterapkan (tombol Filter atau Enter)
  int _tab = 1; // 0 semua, 1 menunggu, 2 disetujui, 3 ditolak, 4 dicabut (awalnya Menunggu)
  int _hal = 0;
  int _perHal = 10;
  int? _urut; // nomor kolom yang dipakai untuk mengurutkan
  bool _naik = true;

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  int _hitung(List<Pengajuan> d, StatusPengajuan s) => d.where((p) => p.status == s).length;

  List<Pengajuan> _saring(List<Pengajuan> d) {
    final q = _cariAktif;
    return d.where((p) {
      final cocokTab = switch (_tab) {
        1 => p.status == StatusPengajuan.menunggu,
        2 => p.status == StatusPengajuan.disetujui,
        3 => p.status == StatusPengajuan.ditolak,
        4 => p.status == StatusPengajuan.dicabut,
        _ => true,
      };
      final cocokCari = q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.organisasi.toLowerCase().contains(q);
      return cocokTab && cocokCari;
    }).toList();
  }

  // Menjalankan aksi ke backend lalu menampilkan hasilnya.
  Future<void> _jalankan(Future<void> Function() aksi, String pesan) async {
    try {
      await aksi();
      if (mounted) adminPesan(context, pesan);
    } on AuthException catch (e) {
      if (mounted) adminPesan(context, e.message, galat: true);
    }
  }

  // Dialog alasan (wajib, minimal 3 karakter). Mengembalikan null kalau dibatalkan.
  Future<String?> _tanyaAlasan(String judul, String isi, String tombol) {
    final c = TextEditingController();
    String? galat;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(judul),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isi, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: c,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Tulis alasannya (dilihat oleh pemohon)',
                    errorText: galat,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                if (c.text.trim().length < 3) {
                  setD(() => galat = 'Alasan minimal 3 karakter');
                  return;
                }
                Navigator.pop(ctx, c.text.trim());
              },
              child: Text(tombol, style: const TextStyle(color: Color(0xFF991B1B))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tolak(Pengajuan p) async {
    final alasan = await _tanyaAlasan(
      'Tolak pengajuan?',
      'Pengajuan ${p.nama} (${p.organisasi}) akan ditolak.',
      'Tolak',
    );
    if (alasan == null) return;
    await _jalankan(() => tolakPengajuan(p.id, alasan), 'Pengajuan ${p.nama} ditolak');
  }

  Future<void> _cabut(Pengajuan p) async {
    final alasan = await _tanyaAlasan(
      'Cabut peran penyelenggara?',
      '${p.nama} kembali menjadi mahasiswa biasa, dan akun panitia dari event miliknya dinonaktifkan.',
      'Cabut',
    );
    if (alasan == null) return;
    await _jalankan(() => cabutPengajuan(p.id, alasan), 'Peran ${p.nama} dicabut');
  }

  void _detail(Pengajuan p) {
    Widget baris(String label, String nilai) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: adminAbu)),
              const SizedBox(height: 2),
              Text(nilai.isEmpty ? '-' : nilai, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
          ),
        );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail pengajuan'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                baris('Pemohon', '${p.nama} (${p.email})'),
                baris('Organisasi', p.organisasi),
                baris('Jabatan', p.jabatan),
                baris('Diajukan', p.tanggal),
                baris('Status', switch (p.status) {
                  StatusPengajuan.menunggu => 'Menunggu',
                  StatusPengajuan.disetujui => 'Disetujui',
                  StatusPengajuan.ditolak => 'Ditolak',
                  StatusPengajuan.dicabut => 'Dicabut',
                }),
                if ((p.alasan ?? '').isNotEmpty) baris('Alasan', p.alasan!),
                const Text('Bukti', style: TextStyle(fontSize: 11, color: adminAbu)),
                const SizedBox(height: 6),
                if (p.buktiUrl == null)
                  const Text('Tidak ada bukti yang diunggah.', style: TextStyle(fontSize: 13))
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      p.buktiUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text('Gambar bukti tidak bisa dimuat.', style: TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
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

  List<Pengajuan> _urutkan(List<Pengajuan> d) {
    if (_urut == null) return d;
    int banding(Pengajuan a, Pengajuan b) {
      switch (_urut) {
        case 1:
          return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
        case 2:
          return a.organisasi.toLowerCase().compareTo(b.organisasi.toLowerCase());
        case 3:
          return adminParseTanggal(a.tanggal).compareTo(adminParseTanggal(b.tanggal));
        case 4:
          return a.status.index.compareTo(b.status.index);
        default:
          return 0;
      }
    }

    final hasil = [...d]..sort(banding);
    return _naik ? hasil : hasil.reversed.toList();
  }

  Widget _status(StatusPengajuan s) {
    return switch (s) {
      StatusPengajuan.menunggu => const AdminBadge.kuning('Menunggu'),
      StatusPengajuan.disetujui => const AdminBadge.hijau('Disetujui'),
      StatusPengajuan.ditolak => const AdminBadge.merah('Ditolak'),
      StatusPengajuan.dicabut => const AdminBadge.abu('Dicabut'),
    };
  }

  List<Widget> _aksi(Pengajuan p) {
    final detail = AdminTombolAksi(label: 'Detail', jenis: AdminAksi.detail, onTap: () => _detail(p));
    switch (p.status) {
      case StatusPengajuan.menunggu:
        return [
          detail,
          AdminTombolAksi(
            label: 'Setujui',
            jenis: AdminAksi.setujui,
            onTap: () => _jalankan(() => setujuiPengajuan(p.id), '${p.nama} kini menjadi penyelenggara'),
          ),
          AdminTombolAksi(label: 'Tolak', jenis: AdminAksi.tolak, onTap: () => _tolak(p)),
        ];
      case StatusPengajuan.disetujui:
        return [
          detail,
          AdminTombolAksi(label: 'Cabut', jenis: AdminAksi.tolak, ikon: Icons.block_rounded, onTap: () => _cabut(p)),
        ];
      case StatusPengajuan.ditolak:
      case StatusPengajuan.dicabut:
        return [detail];
    }
  }

  Widget _orang(Pengajuan p) {
    return Row(
      children: [
        AdminAvatar(nama: p.nama),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.nama, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Text(p.email, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: adminAbu)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _organisasi(Pengajuan p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _teks(p.organisasi),
        if (p.jabatan.isNotEmpty) Text(p.jabatan, style: const TextStyle(fontSize: 11, color: adminAbu)),
      ],
    );
  }

  Widget _teks(String t) => Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textDark));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Pengajuan>>(
      valueListenable: daftarPengajuan,
      builder: (context, data, _) {
        final semua = _urutkan(_saring(data));
        final jumlahHal = adminJumlahHalaman(semua.length, _perHal);
        final hal = _hal >= jumlahHal ? jumlahHal - 1 : _hal;
        final tampil = semua.skip(hal * _perHal).take(_perHal).toList();
        final menunggu = _hitung(data, StatusPengajuan.menunggu);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            AdminDuaKolom(
              rail: (horizontal) => AdminDaftarStatus(
                horizontal: horizontal,
                item: [
                  AdminStatusItem('Semua', data.length),
                  AdminStatusItem('Menunggu', menunggu, sorot: true),
                  AdminStatusItem('Disetujui', _hitung(data, StatusPengajuan.disetujui)),
                  AdminStatusItem('Ditolak', _hitung(data, StatusPengajuan.ditolak)),
                  AdminStatusItem('Dicabut', _hitung(data, StatusPengajuan.dicabut)),
                ],
                terpilih: _tab,
                onPilih: (i) => setState(() {
                  _tab = i;
                  _hal = 0;
                }),
              ),
              isi: AdminTabelBaru(
                atas: AdminBarisCari(
                  controller: _cari,
                  hint: 'Cari nama, email, atau organisasi',
                  onChanged: () => setState(() {}),
                  onCari: () => setState(() {
                    _cariAktif = _cari.text.trim().toLowerCase();
                    _hal = 0;
                  }),
                  onReset: () => setState(() {
                    _cari.clear();
                    _cariAktif = '';
                    _tab = 0;
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
                  AdminKol('Pemohon', 5, urut: true),
                  AdminKol('Organisasi', 3, urut: true),
                  AdminKol('Tanggal', 2, urut: true),
                  AdminKol('Status', 2, tengah: true, urut: true),
                  AdminKol('Aksi', 5, tengah: true),
                ],
                baris: [
                  for (var i = 0; i < tampil.length; i++)
                    AdminBaris(
                      sorot: tampil[i].status == StatusPengajuan.menunggu,
                      sel: [
                        Text('${hal * _perHal + i + 1}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF667085))),
                        _orang(tampil[i]),
                        _organisasi(tampil[i]),
                        _teks(tampil[i].tanggal),
                        _status(tampil[i].status),
                        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: _aksi(tampil[i])),
                      ],
                    ),
                ],
                kosong: 'Tidak ada pengajuan.',
                info: AdminInfoJumlah(
                  mulai: semua.isEmpty ? 0 : hal * _perHal + 1,
                  sampai: hal * _perHal + tampil.length,
                  total: semua.length,
                  label: 'pengajuan',
                ),
                paging: AdminPaging(halaman: hal, jumlah: jumlahHal, onPilih: (i) => setState(() => _hal = i)),
              ),
            ),
          ],
        );
      },
    );
  }
}
