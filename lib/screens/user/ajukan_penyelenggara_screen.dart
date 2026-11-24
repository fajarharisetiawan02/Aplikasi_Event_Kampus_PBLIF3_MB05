import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/pengajuan_service.dart';
import '../../utils/app_colors.dart';

// Form pengajuan menjadi penyelenggara. Data diri diambil dari akun, jadi hanya perlu
// organisasi, jabatan, dan (opsional) bukti seperti foto surat tugas atau SK pengurus.
class AjukanPenyelenggaraScreen extends StatefulWidget {
  const AjukanPenyelenggaraScreen({super.key});

  @override
  State<AjukanPenyelenggaraScreen> createState() => _AjukanPenyelenggaraScreenState();
}

class _AjukanPenyelenggaraScreenState extends State<AjukanPenyelenggaraScreen> {
  final _form = GlobalKey<FormState>();
  final _organisasi = TextEditingController();
  final _jabatan = TextEditingController();

  String? _bukti;
  String? _namaBukti;
  bool _mengunggah = false;
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _organisasi.dispose();
    _jabatan.dispose();
    super.dispose();
  }

  Future<void> _pilihBukti() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() {
        _mengunggah = true;
        _galat = null;
      });
      final url = await PengajuanService.uploadBukti(await file.readAsBytes(), file.name);
      if (mounted) {
        setState(() {
          _bukti = url;
          _namaBukti = file.name;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  Future<void> _kirimPengajuan() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      final pesan = await PengajuanService.ajukan(
        organisasi: _organisasi.text.trim(),
        jabatan: _jabatan.text.trim(),
        buktiUrl: _bukti,
      );
      if (mounted) Navigator.pop(context, pesan);
    } catch (e) {
      if (mounted) {
        setState(() {
          _kirim = false;
          _galat = '$e';
        });
      }
    }
  }

  InputDecoration _dekor(String label, IconData ikon) {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(ikon, size: 20, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: garis(const Color(0xFFE5EAF5)),
      enabledBorder: garis(const Color(0xFFE5EAF5)),
      focusedBorder: garis(AppColors.primaryBlue),
      errorBorder: garis(const Color(0xFFDC2626)),
      focusedErrorBorder: garis(const Color(0xFFDC2626)),
    );
  }

  Widget _catatan(IconData ikon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Jadi penyelenggara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajukan akunmu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admin akan memeriksa pengajuanmu sebelum kamu bisa membuat event.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE3EEFD),
                        child: Text(
                          (user?.nama.isNotEmpty ?? false) ? user!.nama[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.nama ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text(
                              [user?.email, user?.nim].whereType<String>().where((e) => e.isNotEmpty).join('  •  '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organisasi,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: _dekor('Nama organisasi', Icons.groups_outlined),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Nama organisasi minimal 3 karakter' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jabatan,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: _dekor('Jabatan di organisasi', Icons.badge_outlined),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Jabatan wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _mengunggah ? null : _pilihBukti,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5EAF5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _bukti == null ? Icons.upload_file_outlined : Icons.check_circle_rounded,
                          color: _bukti == null ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _bukti == null ? 'Unggah bukti (opsional)' : 'Bukti terunggah',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _namaBukti ?? 'Foto surat tugas atau SK pengurus, JPG/PNG maks. 2 MB',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (_mengunggah)
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF1F6FE), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _catatan(Icons.confirmation_number_outlined, 'Pengajuan tidak bisa dikirim kalau kamu masih punya tiket event yang belum selesai.'),
                      _catatan(Icons.storefront_outlined, 'Setelah disetujui, akunmu hanya dipakai untuk mengurus event. Kamu tidak bisa mendaftar event sebagai peserta.'),
                      _catatan(Icons.verified_user_outlined, 'Setiap event yang kamu buat tetap diperiksa admin sebelum tampil.'),
                    ],
                  ),
                ),
                if (_galat != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                    child: Text(_galat!, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_kirim || _mengunggah) ? null : _kirimPengajuan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _kirim
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kirim pengajuan', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
