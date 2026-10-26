import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'admin_shell.dart';
import 'admin_widgets.dart';

// Login admin (data contoh, belum terhubung ke backend).
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  static const _emailContoh = 'admin@eventin.test';
  static const _sandiContoh = 'admin123';

  bool _lihat = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _masuk() {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim().toLowerCase();

    // Sementara (data contoh): hanya satu akun admin dengan kata sandi tetap.
    // Nanti diganti login ke API; pemeriksaan peran admin wajib di backend,
    // dan kata sandi tidak boleh disimpan di kode aplikasi.
    if (email == _emailContoh && _sandi.text == _sandiContoh) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } else if (email == 'budi.s@gmail.com') {
      setState(() => _galat = 'Akun ini bukan admin. Gunakan aplikasi EventIn di ponsel.');
    } else {
      setState(() => _galat = 'Email atau kata sandi salah. Coba lagi.');
    }
  }

  InputDecoration _dekor(String hint, IconData ikon, {Widget? akhir}) {
    OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(ikon, size: 20, color: adminAbu),
      suffixIcon: akhir,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: garis(const Color(0xFFD1D9E6)),
      enabledBorder: garis(const Color(0xFFD1D9E6)),
      focusedBorder: garis(AppColors.primaryBlue, 1.5),
    );
  }

  Widget _label(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PolaIkonPainter())),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Image.asset('assets/images/logo.png', width: 110, height: 110)),
                        const SizedBox(height: 4),
                        const Center(child: AdminBadge.biru('Khusus admin')),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Selamat datang',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Center(
                          child: Text(
                            'Masuk untuk mengelola platform',
                            style: TextStyle(fontSize: 13, color: adminAbu),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _label('Email'),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dekor('Email admin', Icons.mail_outline_rounded),
                          onChanged: (_) {
                            if (_galat != null) setState(() => _galat = null);
                          },
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Email wajib diisi';
                            if (!t.contains('@') || !t.contains('.')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _label('Kata sandi'),
                        TextFormField(
                          controller: _sandi,
                          obscureText: !_lihat,
                          decoration: _dekor(
                            'Kata sandi Anda',
                            Icons.lock_outline_rounded,
                            akhir: IconButton(
                              icon: Icon(
                                _lihat ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: adminAbu,
                              ),
                              onPressed: () => setState(() => _lihat = !_lihat),
                            ),
                          ),
                          onFieldSubmitted: (_) => _masuk(),
                          validator: (v) => (v ?? '').isEmpty ? 'Kata sandi wajib diisi' : null,
                        ),
                        if (_galat != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFF991B1B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _galat!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _masuk,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            'Lupa kata sandi? Hubungi tim pengembang EventIn.',
                            style: TextStyle(fontSize: 12, color: adminAbu),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Latar: pola ikon event (kalender, tiket, bintang, dan lainnya) yang samar.
class _PolaIkonPainter extends CustomPainter {
  const _PolaIkonPainter();

  static const _ikon = <IconData>[
    Icons.calendar_month_outlined,
    Icons.confirmation_num_outlined,
    Icons.star_outline_rounded,
    Icons.location_on_outlined,
    Icons.groups_outlined,
    Icons.qr_code_2_rounded,
    Icons.music_note_outlined,
    Icons.mic_none_rounded,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const jarak = 120.0;
    var n = 0;

    for (double y = 20; y < size.height + jarak; y += jarak) {
      final geser = ((y ~/ jarak) % 2 == 0) ? 0.0 : jarak / 2;
      for (double x = -20 + geser; x < size.width + jarak; x += jarak) {
        final ikon = _ikon[n % _ikon.length];
        n++;

        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(ikon.codePoint),
            style: TextStyle(
              fontSize: 38,
              fontFamily: ikon.fontFamily,
              package: ikon.fontPackage,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(n.isEven ? -0.3 : 0.25);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}