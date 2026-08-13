import 'package:flutter/material.dart';

class TeleTheme {
  // Brand Colors from Stitch Design System
  static const Color primary = Color(0xFF0088CC);
  static const Color primaryDark = Color(0xFF006193);
  static const Color primaryContainer = Color(0xFF007BB9);
  
  static const Color sentBubbleLight = Color(0xFFE4ECF7);
  static const Color sentBubbleDark = Color(0xFF004B73);
  
  static const Color receivedBubbleLight = Color(0xFFFFFFFF);
  static const Color receivedBubbleDark = Color(0xFF262F38);
  
  static const Color bgLight = Color(0xFFF7F9FF);
  static const Color bgDark = Color(0xFF181C20);
  
  static const Color onlineSuccess = Color(0xFF34C759);
  static const Color textPrimaryLight = Color(0xFF181C20);
  static const Color textSecondaryLight = Color(0xFF575F68);
  static const Color textPrimaryDark = Color(0xFFF1F4FA);
  static const Color textSecondaryDark = Color(0xFF9EACBF);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: const Color(0xFF575F68),
        surface: const Color(0xFFF7F9FF),
        onSurface: textPrimaryLight,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textSecondaryLight,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEBEFF7),
        selectedColor: primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: Colors.white,
        secondary: textSecondaryDark,
        surface: const Color(0xFF21272E),
        onSurface: textPrimaryDark,
      ),
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF21272E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textSecondaryDark,
        backgroundColor: Color(0xFF1E242B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
