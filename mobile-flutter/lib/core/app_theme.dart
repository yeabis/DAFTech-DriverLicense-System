import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF262626);
  static const Color primaryTeal = Color(0xFF1A4C46);
  static const Color accentTeal = Color(0xFF20B2AA);
  static const Color textColor = Colors.white;

  static Color glassBackground = const Color(0xFF1A4C46).withOpacity(0.15);
  static Color glassBorder = const Color(0xFF1A4C46).withOpacity(0.5);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryTeal,
      
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: textColor.withOpacity(0.9),
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          color: textColor.withOpacity(0.7),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor.withOpacity(0.5), 
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: Colors.grey[400],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glassBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentTeal, width: 2.0),
        ),
      ),
    );
  }
}