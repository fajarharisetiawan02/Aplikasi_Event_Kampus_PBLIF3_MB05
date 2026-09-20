import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // TODO: nanti kalau sudah ada penyimpanan token (login) &
    // penanda "sudah pernah buka app", cek di sini:
    // - belum pernah buka app sama sekali -> OnboardingScreen
    // - sudah pernah tapi belum login -> LoginScreen
    // - sudah login -> HomeScreen

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Image.asset(
              'assets/images/logo.png',
              width: 160,
              height: 160,
            ),
            const SizedBox(height: 12),
            const Text(
              'Temukan & Kelola Event Kampusmu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
