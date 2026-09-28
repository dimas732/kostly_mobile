import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1B82FF); //sky blue
  static const Color secondaryBlue = Color(0xFF0EA5E9); //accent blue
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color calculatorBg = Color(0xFFE0F2FE);

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primaryBlue,
    appBarTheme: const AppBarTheme(
      backgroundColor: cardBg,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: secondaryBlue,
    ),
  );
}