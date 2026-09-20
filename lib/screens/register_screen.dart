import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  final String? eventTitle;

  const RegisterScreen({
    super.key,
    this.eventTitle,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi syarat dan ketentuan
    if (!_agreeToTerms) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kamu harus menyetujui Syarat & Ketentuan terlebih dahulu',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService.register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        noHp: _noHpController.text.trim(),
        nim: _nimController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun berhasil dibuat. Selamat datang, ${user.nama}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Menangani error lain yang tidak terduga
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventTitle != null
              ? 'Pendaftaran - ${widget.eventTitle}'
              : 'Buat Akun',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 16),

                Text(
                  widget.eventTitle != null
                      ? 'Daftar untuk ${widget.eventTitle}'
                      : 'Daftar Akun Baru',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Setelah daftar, kamu bisa mengajukan diri sebagai\n'
                  'penyelenggara event kapan saja.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 28),

                // Nama
                _buildTextField(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }

                    if (value.trim().length < 3) {
                      return 'Nama minimal 3 karakter';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // NIM
                _buildTextField(
                  controller: _nimController,
                  label: 'NIM (Nomor Induk Mahasiswa)',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NIM wajib diisi';
                    }

                    final nim = value.trim();

                    final nimRegex = RegExp(r'^[0-9]{6,15}$');

                    if (!nimRegex.hasMatch(nim)) {
                      return 'NIM hanya boleh angka (6-15 digit)';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }

                    final email = value.trim();

                    final emailRegex = RegExp(
                      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                    );

                    if (!emailRegex.hasMatch(email)) {
                      return 'Format email tidak valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Nomor HP
                _buildTextField(
                  controller: _noHpController,
                  label: 'Nomor HP',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hintText: '08xxxxxxxxxx',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor HP wajib diisi';
                    }

                    final phone = value.trim();

                    final phoneRegex = RegExp(r'^[0-9]{9,13}$');

                    if (!phoneRegex.hasMatch(phone)) {
                      return 'Nomor HP tidak valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  obscure: _obscurePassword,
                  toggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }

                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Konfirmasi Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password',
                  obscure: _obscureConfirmPassword,
                  toggle: () {
                    setState(() {
                      _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }

                    if (value != _passwordController.text) {
                      return 'Password tidak sama';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Syarat & Ketentuan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),

                    const Expanded(
                      child: Text(
                        'Saya menyetujui Syarat & Ketentuan serta '
                        'Kebijakan Privasi',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tombol Daftar
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sudah punya akun
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun?'),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('Masuk'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }
}