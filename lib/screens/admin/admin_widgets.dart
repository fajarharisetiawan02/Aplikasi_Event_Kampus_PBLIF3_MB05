import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

// Komponen kecil yang dipakai bersama oleh halaman admin.

const Color adminGaris = Color(0xFFE5EAF5);
const Color adminAbu = Color(0xFF64748B);

// Dekorasi kartu: putih, sudut 18, bayangan tipis (sama seperti di aplikasi mobile).
BoxDecoration adminKartuDekor() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
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
      decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(20)),
      child: Text(teks, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: warna)),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final String label;
  final String nilai;

  const AdminStatCard({
    super.key,
    required this.ikon,
    required this.warna,
    required this.label,
    required this.nilai,
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
              borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );

    return Container(
      decoration: adminKartuDekor().copyWith(borderRadius: BorderRadius.circular(14)),
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
                  borderRadius: BorderRadius.circular(20),
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
    final bentuk = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
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
