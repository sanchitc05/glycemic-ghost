// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F5F7),
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.black,
    ),
  );
}
