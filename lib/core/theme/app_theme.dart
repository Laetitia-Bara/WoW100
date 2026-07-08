import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF150713);
  static const Color card = Color(0xFF181020);
  static const Color gold = Color(0xFFD7A84B);
  static const Color blue = Color(0xFF3B82F6);
  static const Color text = Color(0xFFF8FAFC);
  static const Color mutedText = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xE6150713),
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
