import 'package:flutter/material.dart';
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
  int _tab = 1; // 0 semua, 1 menunggu, 2 disetujui, 3 ditolak (awalnya Menunggu)
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
        _ => true,
      };
      final cocokCari = q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.organisasi.toLowerCase().contains(q);
      return cocokTab && cocokCari;
    }).toList();
  }

  void _ubah(Pengajuan p, StatusPengajuan s, String pesan) {
    ubahPengajuan(p.id, s);
    adminPesan(context, pesan);
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

  Future<void> _konfirmasiTolak(Pengajuan p) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak pengajuan?'),
        content: Text('Pengajuan ${p.nama} (${p.organisasi}) akan ditolak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak', style: TextStyle(color: Color(0xFF991B1B))),
          ),
        ],
      ),
    );
    if (ya == true) _ubah(p, StatusPengajuan.ditolak, 'Pengajuan ${p.nama} ditolak');
  }

  Widget _status(StatusPengajuan s) {
    return switch (s) {
      StatusPengajuan.menunggu => const AdminBadge.kuning('Menunggu'),
      StatusPengajuan.disetujui => const AdminBadge.hijau('Disetujui'),
      StatusPengajuan.ditolak => const AdminBadge.merah('Ditolak'),
    };
  }

  List<Widget> _aksi(Pengajuan p) {
    if (p.status == StatusPengajuan.menunggu) {
      return [
        AdminTombolAksi(
          label: 'Setujui',
          jenis: AdminAksi.setujui,
          onTap: () => _ubah(p, StatusPengajuan.disetujui, '${p.nama} kini menjadi penyelenggara'),
        ),
        AdminTombolAksi(label: 'Tolak', jenis: AdminAksi.tolak, onTap: () => _konfirmasiTolak(p)),
      ];
    }
    return [
      AdminTombolAksi(
        label: 'Batalkan',
        jenis: AdminAksi.netral,
        ikon: Icons.undo_rounded,
        onTap: () => _ubah(p, StatusPengajuan.menunggu, 'Pengajuan ${p.nama} dikembalikan ke menunggu'),
      ),
    ];
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
                  AdminKol('Aksi', 4, tengah: true),
                ],
                baris: [
                  for (var i = 0; i < tampil.length; i++)
                    AdminBaris(
                      sorot: tampil[i].status == StatusPengajuan.menunggu,
                      sel: [
                        Text('${hal * _perHal + i + 1}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF667085))),
                        _orang(tampil[i]),
                        _teks(tampil[i].organisasi),
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
