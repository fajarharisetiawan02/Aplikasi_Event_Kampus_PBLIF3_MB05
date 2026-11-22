import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

// Komponen kecil yang dipakai bersama oleh halaman admin.

const Color adminGaris = Color(0xFFE5EAF5);
const Color adminAbu = Color(0xFF64748B);

// Dekorasi kartu: putih, sudut 8, bingkai tipis.
BoxDecoration adminKartuDekor() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: adminGaris),
  );
}

// Lebar konten di bawah ini dianggap sempit: tabel berubah menjadi kartu.
const double adminBatasSempit = 640;

class AdminHeader extends StatelessWidget {
  final String judul;
  final String sub;

  const AdminHeader({super.key, required this.judul, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          judul,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 13, color: adminAbu)),
      ],
    );
  }
}

class AdminAvatar extends StatelessWidget {
  final String nama;
  final double radius;

  const AdminAvatar({super.key, required this.nama, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final inisial = nama.trim().isEmpty
        ? '?'
        : nama.trim().split(' ').take(2).map((x) => x[0].toUpperCase()).join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE3EEFD),
      child: Text(
        inisial,
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
      ),
    );
  }
}

class AdminBadge extends StatelessWidget {
  final String teks;
  final Color latar;
  final Color warna;

  const AdminBadge({super.key, required this.teks, required this.latar, required this.warna});

  const AdminBadge.kuning(this.teks, {super.key})
      : latar = const Color(0xFFFFF4E0),
        warna = const Color(0xFF8A4B00);

  const AdminBadge.hijau(this.teks, {super.key})
      : latar = const Color(0xFFE8F7EE),
        warna = const Color(0xFF145C33);

  const AdminBadge.merah(this.teks, {super.key})
      : latar = const Color(0xFFFDECEC),
        warna = const Color(0xFF991B1B);

  const AdminBadge.biru(this.teks, {super.key})
      : latar = const Color(0xFFE3EEFD),
        warna = const Color(0xFF0C447C);

  const AdminBadge.abu(this.teks, {super.key})
      : latar = const Color(0xFFF1F5F9),
        warna = const Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(4)),
      child: Text(teks, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: warna)),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final String label;
  final String nilai;
  final String? ket; // keterangan kecil di bawah label

  const AdminStatCard({
    super.key,
    required this.ikon,
    required this.warna,
    required this.label,
    required this.nilai,
    this.ket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: adminKartuDekor(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ikon, size: 21, color: warna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nilai,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(label, style: const TextStyle(fontSize: 12, color: adminAbu)),
                if (ket != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(ket!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  const AdminSearch({super.key, required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: c),
        );

    return Container(
      decoration: adminKartuDekor(),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: garis(Colors.transparent),
          enabledBorder: garis(Colors.transparent),
          focusedBorder: garis(AppColors.primaryBlue),
        ),
      ),
    );
  }
}

class AdminChips extends StatelessWidget {
  final List<String> label;
  final int terpilih;
  final ValueChanged<int> onPilih;

  const AdminChips({super.key, required this.label, required this.terpilih, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < label.length; i++)
          GestureDetector(
            onTap: () => onPilih(i),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: i == terpilih ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: i == terpilih ? AppColors.primaryBlue : const Color(0xFFDCE7FB)),
                ),
                child: Text(
                  label[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: i == terpilih ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AdminKolom {
  final String label;
  final int flex;
  final bool kanan;

  const AdminKolom(this.label, this.flex, {this.kanan = false});
}

// Layar lebar: judul kolom tipis, tiap baris berupa kartu sendiri.
// Layar sempit: daftar kartu.
class AdminTable extends StatelessWidget {
  final List<AdminKolom> kolom;
  final List<List<Widget>> baris;
  final List<Widget> kartu;
  final String kosong;

  const AdminTable({
    super.key,
    required this.kolom,
    required this.baris,
    required this.kartu,
    this.kosong = 'Tidak ada data.',
  });

  @override
  Widget build(BuildContext context) {
    if (baris.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44),
        decoration: adminKartuDekor(),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(kosong, style: const TextStyle(fontSize: 13, color: adminAbu)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < adminBatasSempit) {
          return Column(children: kartu);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Row(
                children: [
                  for (final k in kolom)
                    Expanded(
                      flex: k.flex,
                      child: Text(
                        k.label,
                        textAlign: k.kanan ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: adminAbu),
                      ),
                    ),
                ],
              ),
            ),
            for (final r in baris)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: adminKartuDekor(),
                child: Row(
                  children: [
                    for (var i = 0; i < kolom.length; i++)
                      Expanded(
                        flex: kolom[i].flex,
                        child: Align(
                          alignment: kolom[i].kanan ? Alignment.centerRight : Alignment.centerLeft,
                          child: r[i],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// Kartu untuk tampilan sempit.
class AdminKartu extends StatelessWidget {
  final List<Widget> children;

  const AdminKartu({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: adminKartuDekor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class AdminTombol extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool utama;
  final bool bahaya;

  const AdminTombol({
    super.key,
    required this.label,
    required this.onTap,
    this.utama = false,
    this.bahaya = false,
  });

  @override
  Widget build(BuildContext context) {
    final bentuk = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
    const gaya = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    return SizedBox(
      height: 34,
      child: utama
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: bentuk,
              ),
              child: Text(label, style: gaya),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: bahaya ? const Color(0xFFDC2626) : AppColors.textDark,
                backgroundColor: bahaya ? const Color(0xFFFEF2F2) : null,
                side: BorderSide(color: bahaya ? const Color(0xFFFCA5A5) : const Color(0xFFD1D9E6)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: bentuk,
              ),
              child: Text(label, style: gaya),
            ),
    );
  }
}

// Halaman yang belum dikerjakan: menunjukkan file mana yang perlu dibuat.
class AdminSegeraHadir extends StatelessWidget {
  final String judul;
  final String sub;
  final IconData ikon;
  final String berkas;

  const AdminSegeraHadir({
    super.key,
    required this.judul,
    required this.sub,
    required this.ikon,
    required this.berkas,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      children: [
        AdminHeader(judul: judul, sub: sub),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          decoration: adminKartuDekor(),
          child: Column(
            children: [
              Icon(ikon, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 14),
              const AdminBadge.kuning('Belum dikerjakan'),
              const SizedBox(height: 12),
              Text(
                'Halaman $judul segera hadir',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Dikerjakan di $berkas',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: adminAbu),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Komponen tampilan web baru (kerangka, daftar status, tabel).
// ---------------------------------------------------------------------------

const Color adminNavy = Color(0xFF0F3865);
const Color adminLatar = Color(0xFFF1F4F9);
const Color adminHijau = Color(0xFF15803D);
const Color adminMerah = Color(0xFFC62828);

// Kartu putih berbingkai tipis.
class AdminPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AdminPanel({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminGaris),
      ),
      child: child,
    );
  }
}

class AdminStatusItem {
  final String label;
  final int jumlah;
  final bool sorot; // true untuk status yang perlu ditinjau (oranye)

  const AdminStatusItem(this.label, this.jumlah, {this.sorot = false});
}

// Daftar status di kiri tabel. Di layar sempit tampil sebagai deretan chip.
class AdminDaftarStatus extends StatelessWidget {
  final List<AdminStatusItem> item;
  final int terpilih;
  final ValueChanged<int> onPilih;
  final bool horizontal;

  const AdminDaftarStatus({
    super.key,
    required this.item,
    required this.terpilih,
    required this.onPilih,
    this.horizontal = false,
  });

  Widget _angka(AdminStatusItem it) {
    if (it.sorot && it.jumlah > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(color: AppColors.accentOrange, borderRadius: BorderRadius.circular(4)),
        child: Text(
          '${it.jumlah}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    return Text(
      '${it.jumlah}',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < item.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onPilih(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: i == terpilih ? adminNavy : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: i == terpilih ? adminNavy : adminGaris),
                ),
                child: Text(
                  '${item[i].label} (${item[i].jumlah})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: i == terpilih ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return AdminPanel(
      padding: const EdgeInsets.all(10),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < item.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () => onPilih(i),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: i == terpilih ? const Color(0xFFEAF1FD) : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Stack(
                      children: [
                        if (i == terpilih)
                          const Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 3,
                            child: ColoredBox(color: AppColors.primaryBlue),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item[i].sorot
                                ? AppColors.accentOrange
                                : (i == terpilih ? AppColors.primaryBlue : const Color(0xFFCBD2DD)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item[i].label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: i == terpilih ? FontWeight.bold : FontWeight.w500,
                              color: i == terpilih ? AppColors.primaryBlue : AppColors.textDark,
                            ),
                          ),
                        ),
                        _angka(item[i]),
                      ],
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Daftar status di kiri dan isi di kanan; di layar sempit daftar status ada di atas.
class AdminDuaKolom extends StatelessWidget {
  final Widget Function(bool horizontal) rail;
  final Widget isi;

  const AdminDuaKolom({super.key, required this.rail, required this.isi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 236, child: rail(false)),
              const SizedBox(width: 16),
              Expanded(child: isi),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [rail(true), const SizedBox(height: 12), isi],
        );
      },
    );
  }
}

// Baris pencarian di atas tabel. Hasil langsung disaring saat mengetik.
// `filter` = pilihan tambahan di sebelah pencarian, `kanan` = isi di ujung kanan.
class AdminBarisCari extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged; // dipanggil setiap huruf diketik (hanya menyegarkan tampilan)
  final VoidCallback onCari; // tombol Filter atau Enter: terapkan kata pencarian
  final VoidCallback onReset; // tombol Reset: hapus semua penyaringan
  final List<Widget> filter;
  final Widget? kanan;

  const AdminBarisCari({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onCari,
    required this.onReset,
    this.filter = const [],
    this.kanan,
  });

  Widget _tombolFilter() {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onCari,
        icon: const Icon(Icons.filter_alt_rounded, size: 15),
        label: const Text('Filter', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _tombolReset() {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onReset,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: Color(0xFFD1D9E6)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text('Reset', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: c),
        );

    final cari = SizedBox(
      width: 300,
      height: 36,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        onSubmitted: (_) => onCari(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 36),
          suffixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    controller.clear();
                    onCari();
                  },
                ),
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: garis(adminGaris),
          enabledBorder: garis(adminGaris),
          focusedBorder: garis(AppColors.primaryBlue),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: adminGaris))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [cari, ...filter, _tombolFilter(), _tombolReset()],
            ),
          ),
          if (kanan != null) ...[const SizedBox(width: 12), kanan!],
        ],
      ),
    );
  }
}

class AdminKol {
  final String label;
  final int flex;
  final bool kanan;
  final bool tengah;
  final bool urut; // true: judul kolom bisa diklik untuk mengurutkan

  const AdminKol(this.label, this.flex, {this.kanan = false, this.tengah = false, this.urut = false});
}

class AdminBaris {
  final List<Widget> sel;
  final bool sorot; // baris yang menunggu ditinjau: garis dan latar oranye
  final VoidCallback? onTap;

  const AdminBaris({required this.sel, this.sorot = false, this.onTap});
}

// Teks "Menampilkan 1 - 4 dari 6 data event" (angka tebal, total biru).
class AdminInfoJumlah extends StatelessWidget {
  final int mulai;
  final int sampai;
  final int total;
  final String label;

  const AdminInfoJumlah({
    super.key,
    required this.mulai,
    required this.sampai,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    const dasar = TextStyle(fontSize: 12.5, color: adminAbu);
    const tebal = TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark);

    if (total == 0) return Text('Tidak ada data $label', style: dasar);

    return Text.rich(
      TextSpan(
        style: dasar,
        children: [
          const TextSpan(text: 'Menampilkan '),
          TextSpan(text: '$mulai', style: tebal),
          const TextSpan(text: ' - '),
          TextSpan(text: '$sampai', style: tebal),
          const TextSpan(text: ' dari '),
          TextSpan(
            text: '$total',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
          ),
          TextSpan(text: ' data $label'),
        ],
      ),
    );
  }
}

// Jumlah halaman untuk total data dan banyak data per halaman (minimal 1).
int adminJumlahHalaman(int total, int perHalaman) =>
    total <= 0 ? 1 : (total + perHalaman - 1) ~/ perHalaman;

// Tombol halaman: Sebelumnya, nomor halaman, Berikutnya. Halaman dihitung dari 0.
class AdminPaging extends StatelessWidget {
  final int halaman;
  final int jumlah;
  final ValueChanged<int> onPilih;

  const AdminPaging({super.key, required this.halaman, required this.jumlah, required this.onPilih});

  Widget _kotak(String teks, {bool aktif = false, VoidCallback? onTap}) {
    final mati = onTap == null && !aktif;
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 30),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? adminNavy : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: aktif ? adminNavy : adminGaris),
        ),
        child: Text(
          teks,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: aktif ? Colors.white : (mati ? const Color(0xFFB0B8C4) : AppColors.textDark),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // tampilkan paling banyak 5 nomor di sekitar halaman aktif
    var awal = halaman - 2;
    if (awal < 0) awal = 0;
    var akhir = awal + 4;
    if (akhir > jumlah - 1) {
      akhir = jumlah - 1;
      awal = akhir - 4 < 0 ? 0 : akhir - 4;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _kotak('Sebelumnya', onTap: halaman > 0 ? () => onPilih(halaman - 1) : null),
        for (var i = awal; i <= akhir; i++) ...[
          const SizedBox(width: 4),
          _kotak('${i + 1}', aktif: i == halaman, onTap: i == halaman ? null : () => onPilih(i)),
        ],
        const SizedBox(width: 4),
        _kotak('Berikutnya', onTap: halaman < jumlah - 1 ? () => onPilih(halaman + 1) : null),
      ],
    );
  }
}

const _bulanPendek = ['jan', 'feb', 'mar', 'apr', 'mei', 'jun', 'jul', 'agu', 'sep', 'okt', 'nov', 'des'];
const _bulanNama = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

// "20 Okt 2026" atau "20 Oktober 2026" menjadi DateTime (untuk mengurutkan).
DateTime adminParseTanggal(String s) {
  final p = s.trim().split(RegExp(r'\s+'));
  if (p.length < 3) return DateTime(1970);
  final hari = int.tryParse(p[0]) ?? 1;
  final bln = p[1].length < 3 ? -1 : _bulanPendek.indexOf(p[1].toLowerCase().substring(0, 3));
  final tahun = int.tryParse(p[2]) ?? 1970;
  return DateTime(tahun, bln < 0 ? 1 : bln + 1, hari);
}

// Format tanggal pendek yang sama di semua halaman: "20 Okt 2026".
String adminTanggalPendek(DateTime d) => '${d.day} ${_bulanNama[d.month - 1]} ${d.year}';

// Pesan singkat di bawah layar setelah sebuah aksi (berhasil atau gagal).
void adminPesan(BuildContext context, String teks, {bool galat = false}) {
  final lebar = MediaQuery.sizeOf(context).width;
  final pesan = ScaffoldMessenger.of(context);
  pesan.hideCurrentSnackBar();
  pesan.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: lebar >= 480 ? 420 : null,
      backgroundColor: galat ? adminMerah : adminNavy,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      content: Row(
        children: [
          Icon(
            galat ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 19,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 13, color: Colors.white))),
        ],
      ),
    ),
  );
}

// Kotak pilihan putih berbingkai dengan lebar tetap; daftarnya terbuka tepat di bawah
// kotak dan selebar kotak itu.
Widget _kotakPilihan({
  required String teks,
  required double tinggi,
  required double lebar,
  required TextStyle? gaya,
}) {
  return Container(
    height: tinggi,
    width: lebar,
    padding: const EdgeInsets.only(left: 12, right: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFD1D9E6)),
    ),
    child: Row(
      children: [
        Expanded(child: Text(teks, style: gaya, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 19, color: adminAbu),
      ],
    ),
  );
}

PopupMenuButton<T> _menuPilihan<T>({
  required T nilai,
  required List<T> opsi,
  required String Function(T) teks,
  required ValueChanged<T> onUbah,
  required TextStyle? gaya,
  required double lebar,
  required Widget kotak,
}) {
  return PopupMenuButton<T>(
    tooltip: '',
    position: PopupMenuPosition.under,
    offset: const Offset(0, 4),
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    padding: EdgeInsets.zero,
    menuPadding: const EdgeInsets.symmetric(vertical: 4),
    constraints: BoxConstraints(minWidth: lebar, maxWidth: lebar),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: adminGaris),
    ),
    onSelected: onUbah,
    itemBuilder: (_) => [
      for (final o in opsi)
        PopupMenuItem<T>(
          value: o,
          height: 32,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: 32,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: o == nilai ? const Color(0xFFEAF1FD) : null,
            child: Text(
              teks(o),
              style: o == nilai
                  ? gaya?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)
                  : gaya,
            ),
          ),
        ),
    ],
    child: kotak,
  );
}

// Pilihan dropdown berbingkai, selaras dengan kotak pencarian (mis. filter kategori).
class AdminPilihan extends StatelessWidget {
  final String nilai;
  final List<String> opsi;
  final ValueChanged<String> onUbah;

  const AdminPilihan({super.key, required this.nilai, required this.opsi, required this.onUbah});

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.textDark);
    final terpilih = opsi.contains(nilai) ? nilai : opsi.first;

    return _menuPilihan<String>(
      nilai: terpilih,
      opsi: opsi,
      teks: (o) => o,
      onUbah: onUbah,
      gaya: gaya,
      lebar: 170,
      kotak: _kotakPilihan(teks: terpilih, tinggi: 36, lebar: 170, gaya: gaya),
    );
  }
}

// "Tampilkan [10] data": memilih banyak baris per halaman.
class AdminPilihPerHal extends StatelessWidget {
  final int nilai;
  final ValueChanged<int> onUbah;

  const AdminPilihPerHal({super.key, required this.nilai, required this.onUbah});

  static const opsi = [5, 10, 25, 50];

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.textDark);
    const teks = TextStyle(fontSize: 12.5, color: adminAbu);
    final terpilih = opsi.contains(nilai) ? nilai : 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Tampilkan', style: teks),
        const SizedBox(width: 8),
        _menuPilihan<int>(
          nilai: terpilih,
          opsi: opsi,
          teks: (o) => '$o',
          onUbah: onUbah,
          gaya: gaya,
          lebar: 68,
          kotak: _kotakPilihan(teks: '$terpilih', tinggi: 32, lebar: 68, gaya: gaya),
        ),
        const SizedBox(width: 8),
        const Text('data', style: teks),
      ],
    );
  }
}

// Sel dalam satu baris tabel mengikuti perataan kolomnya.
Widget _selTabel(AdminKol k, Widget w) {
  return Expanded(
    flex: k.flex,
    child: Align(
      alignment: k.kanan ? Alignment.centerRight : (k.tengah ? Alignment.center : Alignment.centerLeft),
      child: w,
    ),
  );
}

// Satu baris data. Warnanya berubah saat kursor lewat.
class _BarisTabel extends StatefulWidget {
  final AdminBaris baris;
  final List<AdminKol> kolom;

  const _BarisTabel({required this.baris, required this.kolom});

  @override
  State<_BarisTabel> createState() => _BarisTabelState();
}

class _BarisTabelState extends State<_BarisTabel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.baris;
    final warna = b.sorot
        ? (_hover ? const Color(0xFFFFF3DB) : const Color(0xFFFFFBF2))
        : (_hover ? const Color(0xFFF4F8FE) : Colors.white);

    final isi = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: warna,
        border: Border(
          left: BorderSide(color: b.sorot ? AppColors.accentOrange : Colors.transparent, width: 3),
          bottom: const BorderSide(color: Color(0xFFEEF1F6)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < widget.kolom.length; i++) _selTabel(widget.kolom[i], b.sel[i]),
        ],
      ),
    );

    return MouseRegion(
      cursor: b.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: b.onTap == null
          ? isi
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: b.onTap, child: isi),
    );
  }
}

// Tabel dalam satu panel: pencarian, judul kolom, baris, lalu info jumlah.
// Judul kolom yang bertanda `urut` bisa diklik untuk mengurutkan.
// Di bawah lebar 760 tabel bisa digeser ke samping.
class AdminTabelBaru extends StatelessWidget {
  final Widget? atas;
  final List<AdminKol> kolom;
  final List<AdminBaris> baris;
  final String kosong;
  final Widget info;
  final Widget? paging;
  final int? urutKolom;
  final bool urutNaik;
  final ValueChanged<int>? onUrut;

  const AdminTabelBaru({
    super.key,
    this.atas,
    this.paging,
    required this.kolom,
    required this.baris,
    required this.info,
    this.kosong = 'Tidak ada data.',
    this.urutKolom,
    this.urutNaik = true,
    this.onUrut,
  });

  Widget _judulSel(AdminKol k, int i) {
    final teks = Text(
      k.label,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
    );
    if (!k.urut || onUrut == null) return teks;

    final aktif = urutKolom == i;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => onUrut!(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            teks,
            const SizedBox(width: 3),
            Icon(
              aktif
                  ? (urutNaik ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 14,
              color: aktif ? AppColors.primaryBlue : const Color(0xFFB0B8C4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _judul() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
        border: Border(bottom: BorderSide(color: adminGaris)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < kolom.length; i++) _selTabel(kolom[i], _judulSel(kolom[i], i)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?atas,
            LayoutBuilder(
              builder: (context, c) {
                final isi = Column(
                  children: [
                    _judul(),
                    if (baris.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(kosong, style: const TextStyle(fontSize: 13, color: adminAbu)),
                          ],
                        ),
                      )
                    else
                      for (final b in baris) _BarisTabel(baris: b, kolom: kolom),
                  ],
                );
                if (c.maxWidth >= 760) return isi;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 760, child: isi),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                border: Border(top: BorderSide(color: adminGaris)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 16,
                children: [info, ?paging],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AdminAksi { setujui, tolak, detail, netral }

// Tombol di kolom aksi tabel: berwarna penuh, ikon di kiri teks, tinggi 28, sudut 6, teks 12.
// Detail = biru langit, Setujui = hijau, Tolak = merah, netral = kuning.
class AdminTombolAksi extends StatelessWidget {
  final String label;
  final AdminAksi jenis;
  final VoidCallback onTap;
  final double? lebar;
  final IconData? ikon; // kalau kosong, ikon mengikuti jenis tombol

  const AdminTombolAksi({
    super.key,
    required this.label,
    required this.jenis,
    required this.onTap,
    this.lebar,
    this.ikon,
  });

  // Lebar tetap per jenis supaya tombol di semua baris sejajar.
  double get _lebarBawaan => switch (jenis) {
        AdminAksi.setujui => 84,
        AdminAksi.tolak => 68,
        AdminAksi.detail => 76,
        AdminAksi.netral => 84,
      };

  Color get _warna => switch (jenis) {
        AdminAksi.setujui => const Color(0xFF16A34A),
        AdminAksi.tolak => const Color(0xFFEF4444),
        AdminAksi.detail => const Color(0xFF0EA5E9),
        AdminAksi.netral => const Color(0xFFF59E0B),
      };

  IconData get _ikon =>
      ikon ??
      switch (jenis) {
        AdminAksi.setujui => Icons.check_rounded,
        AdminAksi.tolak => Icons.close_rounded,
        AdminAksi.detail => Icons.visibility_rounded,
        AdminAksi.netral => Icons.edit_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: lebar ?? _lebarBawaan,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(_ikon, size: 13),
        iconAlignment: IconAlignment.start,
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _warna,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
