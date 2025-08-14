import 'package:flutter/material.dart';

/// Pediatric healthcare theme with calming colors and accessible design
class PediatricTheme {
  // Private constructor to prevent instantiation
  PediatricTheme._();

  // Color palette - calming blues and greens
  static const Color primary = Color(0xFF4A90E2);      // Calming blue
  static const Color secondary = Color(0xFF7ED321);    // Soft green
  static const Color accent = Color(0xFFFFB74D);       // Warm orange
  static const Color background = Color(0xFFF8FBFF);   // Very light blue-white
  static const Color surface = Color(0xFFFFFFFF);      // Pure white
  static const Color onPrimary = Color(0xFFFFFFFF);    // White text on primary
  static const Color onSecondary = Color(0xFFFFFFFF);  // White text on secondary
  static const Color onSurface = Color(0xFF2C3E50);    // Dark text on surface
  static const Color onBackground = Color(0xFF34495E); // Dark text on background
  static const Color error = Color(0xFFE74C3C);        // Error red
  static const Color warning = Color(0xFFF39C12);      // Warning orange
  static const Color success = Color(0xFF27AE60);      // Success green
  static const Color info = Color(0xFF3498DB);         // Info blue

  // Typography
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: onSurface,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: onSurface,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: onSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: onSurface,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: onSurface,
    ),
  );

  // Button themes
  static final ButtonThemeData buttonTheme = ButtonThemeData(
    buttonColor: primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  // Elevated button style
  static final ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 2,
      shadowColor: primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Outlined button style
  static final OutlinedButtonThemeData outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: const BorderSide(color: primary, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Text button style
  static final TextButtonThemeData textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Input decoration theme
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primary.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primary.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: textTheme.bodyMedium?.copyWith(
      color: onSurface.withOpacity(0.6),
    ),
  );

  // Card theme
  static final CardThemeData cardTheme = CardThemeData(
    color: surface,
    elevation: 2,
    shadowColor: primary.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.all(8),
  );

  // App bar theme
  static final AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: primary,
    foregroundColor: onPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: textTheme.titleLarge?.copyWith(
      color: onPrimary,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: onPrimary),
  );

  // Bottom navigation bar theme
  static final BottomNavigationBarThemeData bottomNavigationBarTheme = BottomNavigationBarThemeData(
    backgroundColor: surface,
    selectedItemColor: primary,
    unselectedItemColor: onSurface.withOpacity(0.6),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // Floating action button theme
  static final FloatingActionButtonThemeData floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: primary,
    foregroundColor: onPrimary,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  // Icon theme
  static const IconThemeData iconTheme = IconThemeData(
    color: primary,
    size: 24,
  );

  // Divider theme
  static const DividerThemeData dividerTheme = DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
    space: 1,
  );

  // Complete theme data
  static final ThemeData themeData = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      onBackground: onBackground,
      error: error,
    ),
    textTheme: textTheme,
    buttonTheme: buttonTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    outlinedButtonTheme: outlinedButtonTheme,
    textButtonTheme: textButtonTheme,
    inputDecorationTheme: inputDecorationTheme,
    cardTheme: cardTheme,
    appBarTheme: appBarTheme,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
    floatingActionButtonTheme: floatingActionButtonTheme,
    iconTheme: iconTheme,
    dividerTheme: dividerTheme,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    primarySwatch: MaterialColor(0xFF4A90E2, {
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF4A90E2), // primary
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    }),
  );
}
