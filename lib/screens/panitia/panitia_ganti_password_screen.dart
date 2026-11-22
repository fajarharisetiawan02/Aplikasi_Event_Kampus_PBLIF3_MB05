import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';
import 'panitia_scan_screen.dart';

// Ganti password akun panitia. Saat login pertama (wajib = true) layar ini tidak bisa dilewati,
// karena password awal dikirim lewat email.
class PanitiaGantiPasswordScreen extends StatefulWidget {
  final bool wajib;
  const PanitiaGantiPasswordScreen({super.key, this.wajib = false});

  @override
  State<PanitiaGantiPasswordScreen> createState() => _PanitiaGantiPasswordScreenState();
}

class _PanitiaGantiPasswordScreenState extends State<PanitiaGantiPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();

  bool _lihat = false;
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      await AuthService.changePassword(currentPassword: _lama.text, newPassword: _baru.text);
      try {
        await AuthService.fetchProfile(); // muat ulang supaya penanda "wajib ganti" hilang
      } catch (_) {}

      if (!mounted) return;

      if (widget.wajib) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PanitiaScanScreen()),
        );
      } else {
        Navigator.pop(context, 'Password berhasil diganti');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kirim = false;
          _galat = '$e';
        });
      }
    }
  }

  InputDecoration _dekor(String label) {
    OutlineInputBorder garis(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
      suffixIcon: IconButton(
        icon: Icon(_lihat ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF94A3B8)),
        onPressed: () => setState(() => _lihat = !_lihat),
      ),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.wajib,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.wajib,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Ganti password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.wajib) ...[
                    const Text(
                      'Buat password barumu',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF4E0), borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Password awalmu dikirim lewat email. Demi keamanan, ganti dengan password milikmu sendiri sebelum mulai memindai tiket.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8A4B00)),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  TextFormField(
                    controller: _lama,
                    obscureText: !_lihat,
                    style: const TextStyle(fontSize: 14),
                    decoration: _dekor(widget.wajib ? 'Password awal (dari email)' : 'Password saat ini'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _baru,
                    obscureText: !_lihat,
                    style: const TextStyle(fontSize: 14),
                    decoration: _dekor('Password baru'),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'Password baru minimal 6 karakter';
                      if (v == _lama.text) return 'Password baru harus berbeda dari yang lama';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ulang,
                    obscureText: !_lihat,
                    style: const TextStyle(fontSize: 14),
                    decoration: _dekor('Ulangi password baru'),
                    validator: (v) => v == _baru.text ? null : 'Konfirmasi password tidak sama',
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
                      onPressed: _kirim ? null : _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _kirim
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.wajib ? 'Simpan dan mulai scan' : 'Simpan password', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (widget.wajib)
                    Center(
                      child: TextButton(
                        onPressed: _kirim
                            ? null
                            : () async {
                          await AuthService.logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        },
                        child: const Text('Keluar', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
