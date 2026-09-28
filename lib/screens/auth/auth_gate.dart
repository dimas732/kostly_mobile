import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import halaman-halaman kamu
import '/../screens/auth/login_screen.dart';
import '/../screens/admin_screen.dart';
import '/../screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Sedang memuat status autentikasi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika belum login, arahkan ke LoginScreen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        // 3. Jika sudah login, ambil data role dari Firestore
        return FutureBuilder(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map?;
              final role = (data?['roles'] ?? '').toString().toLowerCase().trim();

              // 🔍 CEK DI RUN / DEBUG CONSOLE ANDROID STUDIO:
              debugPrint("=== DEBUG USER ROLE ===");
              debugPrint("UID Auth: ${user.uid}");
              debugPrint("Data Firestore: $data");
              debugPrint("Role Terbaca: '$role'");

              if (role == 'owner') {
                return const AdminScreen();
              }
            } else {
              debugPrint("⚠️ DOKUMEN FIRESTORE DENGAN UID ${user.uid} TIDAK DITEMUKAN!");
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}