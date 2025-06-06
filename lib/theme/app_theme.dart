import 'package:flutter/material.dart';

class AppTheme {
  // Define main colors based on the UI style
  static const Color primaryPink = Color(0xFFF48FB1); // A soft but vibrant pink
  static const Color lightPinkBackground = Color(0xFFFFF8F9);
  static const Color accentPink = Color(0xFFF06292);
  static const Color darkText = Color(0xFF424242);
  static const Color lightText = Color(0xFF757575);

  // Main application theme
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightPinkBackground,
      primaryColor: primaryPink,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white, // Color for title text and icons
        elevation: 2,
        centerTitle: true,
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryPink, width: 2.0),
        ),
        labelStyle: const TextStyle(color: lightText),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Bottom Navigation / TabBar Theme
      tabBarTheme: const TabBarTheme(
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Text Theme
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: lightText),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPink,
        background: lightPinkBackground
      ),
    );
  }
}
