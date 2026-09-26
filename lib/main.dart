import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KostLy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', // Sesuaikan font jika ada
      ),
      home: const SplashScreen(), // 👈 Atur ke SplashScreen di sini
    );
  }
}