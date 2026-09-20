// This is a basic Flutter widget test.
//
// Karena aplikasi ini pakai autentikasi & multi-halaman (Splash, Onboarding,
// Login, dst), test bawaan Flutter (counter test) tidak relevan lagi.
// File ini diganti dengan test sederhana yang hanya memastikan
// aplikasi bisa dibangun (build) tanpa error.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasi_event_kampus_pblfi3_mb05/main.dart';

void main() {
  testWidgets('App dapat dibangun tanpa error', (WidgetTester tester) async {
    // Build aplikasi dan trigger satu frame.
    await tester.pumpWidget(const EventApp());

    // Beri waktu untuk animasi/loading awal (Splash Screen).
    await tester.pump(const Duration(seconds: 1));

    // Cukup pastikan tidak ada exception saat build.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}