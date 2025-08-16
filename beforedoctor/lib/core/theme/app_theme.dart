import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// Pediatric Clinic Color Palette - Soft, Trustworthy, Kid-Friendly
class ClinicColors {
  // Primary Colors (Trust & Care)
  static const primary = Color(0xFF2BB3B1);      // Teal 500
  static const secondary = Color(0xFFB79FE1);    // Lavender 400
  static const mint = Color(0xFF7ED9C2);         // Mint 400
  
  // Status Colors
  static const sea = Color(0xFF3BAA78);          // Sea Green 500 (Listening)
  static const amber = Color(0xFFFFC04D);        // Amber 400 (Processing)
  static const speak = Color(0xFF5A8DEE);        // Cornflower 500 (Speaking)
  static const coral = Color(0xFFFF8A65);        // Coral 400 (Concern/Alert)
  
  // Surface Colors
  static const surface = Color(0xFFF7FAFC);      // Light Surface
  static const surfaceDark = Color(0xFF0F172A);  // Dark Surface
  static const onSurface = Color(0xFF1E293B);    // Primary Text
  static const onSurfaceMuted = Color(0xFF64748B); // Secondary Text
  
  // Utility Colors
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
}



/// Status Color Mapping
Color statusColor(AppStatus status) {
  switch (status) {
    case AppStatus.listening:
      return ClinicColors.sea;
    case AppStatus.processing:
      return ClinicColors.amber;
    case AppStatus.speaking:
      return ClinicColors.speak;
    case AppStatus.complete:
      return ClinicColors.secondary;
    case AppStatus.concerned:
      return ClinicColors.coral;
    case AppStatus.ready:
    default:
      return ClinicColors.primary;
  }
}

/// Status Gradient Mapping (Low Contrast, Pediatric-Friendly)
LinearGradient statusGradient(AppStatus status) {
  switch (status) {
    case AppStatus.listening:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF11998E),      // Dark Sea Green
          Color(0xFF2BB3B1),      // Teal
          Color(0xFF7ED9C2),      // Mint
        ],
        stops: [0.0, 0.55, 1.0],
      );
    case AppStatus.processing:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7B5E00),      // Dark Amber
          Color(0xFFFFC04D),      // Amber
          Color(0xFFFFE4A3),      // Light Amber
        ],
        stops: [0.0, 0.5, 1.0],
      );
    case AppStatus.speaking:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E60D3),      // Dark Blue
          Color(0xFF5A8DEE),      // Cornflower
          Color(0xFFB3CCFF),      // Light Blue
        ],
        stops: [0.0, 0.5, 1.0],
      );
    case AppStatus.complete:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6D56C1),      // Dark Lavender
          Color(0xFFB79FE1),      // Lavender
          Color(0xFFE6DBFF),      // Light Lavender
        ],
        stops: [0.0, 0.5, 1.0],
      );
    case AppStatus.concerned:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF9F4C3B),      // Dark Coral
      Color(0xFFFF9A7A),      // Softer Coral (was FFF8A65)
      Color(0xFFFFE0D7),      // Very Light Coral (was FFFD0C2)
        ],
        stops: [0.0, 0.5, 1.0],
      );
    case AppStatus.ready:
    default:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E8BA3),      // Dark Teal
          Color(0xFF2BB3B1),      // Teal
          Color(0xFF7ED9C2),      // Mint
        ],
        stops: [0.0, 0.5, 1.0],
      );
  }
}

/// Soft Badge Decoration for Status Indicators
BoxDecoration softBadge(Color color) {
  return BoxDecoration(
    color: color.withOpacity(0.14),
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    border: Border.all(
      color: color.withOpacity(0.4),
      width: 1,
    ),
  );
}

/// Main Clinic Theme
ThemeData clinicTheme(BuildContext context) {
  final base = ThemeData.light(useMaterial3: true);
  
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: ClinicColors.primary,
      secondary: ClinicColors.secondary,
      surface: ClinicColors.surface,
      onSurface: ClinicColors.onSurface,
      error: ClinicColors.coral,
    ),
    scaffoldBackgroundColor: ClinicColors.surface,
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: ClinicColors.onSurface,
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ClinicColors.onSurface,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.3,
        color: ClinicColors.onSurface,
      ),
      bodyMedium: const TextStyle(
        fontSize: 15,
        height: 1.3,
        color: ClinicColors.onSurfaceMuted,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ClinicColors.onSurface,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(
        color: ClinicColors.onSurfaceMuted.withOpacity(0.25),
      ),
      backgroundColor: ClinicColors.white.withOpacity(0.6),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
      cardTheme: CardThemeData(
    color: ClinicColors.white,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ClinicColors.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ClinicColors.onSurface,
      ),
    ),
  );
}
