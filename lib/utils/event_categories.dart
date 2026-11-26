import 'package:flutter/material.dart';

// Daftar kategori event yang dipakai bersama oleh Home dan Explore.
const List<Map<String, dynamic>> eventCategoryItems = [
  {'name': 'Musik', 'icon': Icons.music_note},
  {'name': 'Olahraga', 'icon': Icons.sports_soccer},
  {'name': 'Seminar', 'icon': Icons.school},
  {'name': 'Seni', 'icon': Icons.palette},
  {'name': 'Teknologi', 'icon': Icons.computer},
];

List<String> get eventCategoryNames =>
    eventCategoryItems.map((c) => c['name'] as String).toList();
