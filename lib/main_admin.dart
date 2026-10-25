import 'package:flutter/material.dart';
import 'screens/admin/admin_login_screen.dart';
import 'utils/app_colors.dart';

// Pintu masuk admin (web). Jalankan dengan:
//   flutter run -t lib/main_admin.dart -d chrome
void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventIn Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const AdminLoginScreen(),
    );
  }
}
