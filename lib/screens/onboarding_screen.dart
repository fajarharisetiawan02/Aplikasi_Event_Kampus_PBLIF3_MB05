import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../utils/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color iconBgColor;
  final Color iconColor;

  _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconBgColor,
    required this.iconColor,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.search,
      title: 'Informasi Event Kampus',
      description: 'Dapatkan informasi lengkap berbagai event kampus mulai dari seminar, workshop, hingga kompetisi dalam satu aplikasi.',
      iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
      iconColor: AppColors.primaryBlue,
    ),
    _OnboardingItem(
      icon: Icons.confirmation_number_outlined,
      title: 'Pendaftaran Event dengan Mudah',
      description: 'Daftar event langsung dari HP, lengkapi pembayaran jika diperlukan, lalu dapatkan e-tiket berupa QR code untuk check-in di lokasi.',
      iconBgColor: AppColors.accentYellow.withValues(alpha: 0.15),
      iconColor: AppColors.accentOrange,
    ),
    _OnboardingItem(
      icon: Icons.campaign_outlined,
      title: 'Jadi Penyelenggara Event',
      description: 'Punya event sendiri? Ajukan diri sebagai penyelenggara dan kelola pendaftaran, peserta, hingga laporan penjualan.',
      iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
      iconColor: AppColors.primaryBlue,
    ),
  ];

  void _goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _onNextPressed() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _goToLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', width: 40, height: 40),
                  TextButton(onPressed: _goToLogin, child: const Text('Lewati')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(color: item.iconBgColor, shape: BoxShape.circle),
                          child: Icon(item.icon, size: 72, color: item.iconColor),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primaryBlue : AppColors.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastPage ? AppColors.accentOrange : AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isLastPage ? 'Mulai' : 'Lanjut', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}