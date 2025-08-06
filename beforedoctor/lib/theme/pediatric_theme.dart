import 'package:flutter/material.dart';

final ThemeData pediatricTheme = ThemeData(
  primaryColor: Color(0xFF4FC3F7), // Sky Blue
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: Color(0xFFFFCDD2), // Soft Peach
    surface: Color(0xFFF0F9FF), // Light Blue Background
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Color(0xFFF0F9FF),
  cardColor: Colors.white,
  fontFamily: 'Raleway',
  textTheme: TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
    titleSmall: TextStyle(fontSize: 14, color: Colors.black54),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF4FC3F7),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF4FC3F7), width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF4FC3F7),
    foregroundColor: Colors.white,
    elevation: 2,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  iconTheme: IconThemeData(
    color: Color(0xFF4FC3F7),
    size: 24,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF4FC3F7),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
); 