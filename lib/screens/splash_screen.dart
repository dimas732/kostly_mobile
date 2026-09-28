import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'auth/auth_gate.dart'; // Atau langsung 'login_screen.dart' jika tidak pakai AuthGate

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State createState() => _SplashScreenState();
}

class _SplashScreenState extends State {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    // Memberikan jeda waktu 3 detik sebelum berpindah halaman
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Menggunakan pushReplacement agar pengguna tidak bisa kembali ke Splash Screen saat menekan tombol back
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF), // Latar belakang yang sama dengan LoginScreen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo Aplikasi dari Folder Assets
            Image.asset(
              'assets/img/logo_kostly(fix).png', // Ganti dengan path logo kamu (misal: 'assets/images/logo.png')
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),

            // 2. Nama Brand / Aplikasi
            const Text(
              'KostLy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Find Your Best Living Space',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 48),

            // 3. Loading Indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}