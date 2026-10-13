import 'package:flutter/foundation.dart';

// Dipakai untuk pindah tab di HomeScreen dari layar lain (misal: dari detail event ke tab Tiket).
class AppNav {
  static final ValueNotifier<int> tabRequest = ValueNotifier<int>(-1);
}
