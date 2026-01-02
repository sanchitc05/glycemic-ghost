// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/glucose_screen.dart';
import 'theme/app_theme.dart';
import './screens/login_screen.dart';

void main() {
  runApp(const GlycemicGhostApp());
}

class GlycemicGhostApp extends StatelessWidget {
  const GlycemicGhostApp({super.key});

  @override
  Widget build(BuildContext context) {
    // const dummy_token = 'DUMMY_JWT_TOKEN';
    return MaterialApp(
      title: 'Glycemic Ghost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => LoginScreen(
          onLogin: (userId, token) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GlucoseScreen(userId: userId, authToken: token),
            ),
          ),
        ),
      ),
    );
  }
}
