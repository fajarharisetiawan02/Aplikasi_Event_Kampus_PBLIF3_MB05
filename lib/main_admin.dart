import 'package:flutter/material.dart';
import 'screens/admin/admin_login_screen.dart';
import 'utils/app_colors.dart';

// Pintu masuk admin (web). Jalankan dengan:
//   flutter run -t lib/main_admin.dart -d chrome
void main() {
  runApp(const AdminApp());
}

// Teks dibuat rapat seperti web pada umumnya (tanpa jarak antarhuruf bawaan Material).
TextTheme _rapat(TextTheme t) {
  TextStyle? r(TextStyle? s) => s?.copyWith(letterSpacing: 0);
  return t.copyWith(
    displayLarge: r(t.displayLarge),
    displayMedium: r(t.displayMedium),
    displaySmall: r(t.displaySmall),
    headlineLarge: r(t.headlineLarge),
    headlineMedium: r(t.headlineMedium),
    headlineSmall: r(t.headlineSmall),
    titleLarge: r(t.titleLarge),
    titleMedium: r(t.titleMedium),
    titleSmall: r(t.titleSmall),
    bodyLarge: r(t.bodyLarge),
    bodyMedium: r(t.bodyMedium),
    bodySmall: r(t.bodySmall),
    labelLarge: r(t.labelLarge),
    labelMedium: r(t.labelMedium),
    labelSmall: r(t.labelSmall),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dasar = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Selawik',
    );

    return MaterialApp(
      title: 'EventIn Admin',
      debugShowCheckedModeBanner: false,
      theme: dasar.copyWith(textTheme: _rapat(dasar.textTheme)),
      home: const AdminLoginScreen(),
    );
  }
}
