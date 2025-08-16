import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Updated Pediatric Theme using Clinic Colors
/// This provides a consistent, professional healthcare appearance
ThemeData getPediatricTheme(BuildContext context) => clinicTheme(context).copyWith(
  // Override with specific pediatric customizations
  textTheme: clinicTheme(context).textTheme.copyWith(
    headlineSmall: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
      color: ClinicColors.onSurface,
      fontFamily: 'Nunito',
    ),
    titleMedium: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ClinicColors.onSurface,
      fontFamily: 'Nunito',
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      height: 1.3,
      color: ClinicColors.onSurface,
      fontFamily: 'Nunito',
    ),
    bodyMedium: const TextStyle(
      fontSize: 15,
      height: 1.3,
      color: ClinicColors.onSurfaceMuted,
      fontFamily: 'Nunito',
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ClinicColors.onSurface,
      fontFamily: 'Nunito',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ClinicColors.primary,
      foregroundColor: ClinicColors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: ClinicColors.primary, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ClinicColors.onSurfaceMuted.withOpacity(0.3), width: 1),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    filled: true,
    fillColor: ClinicColors.white,
  ),
  cardTheme: CardThemeData(
    color: ClinicColors.white,
    elevation: 4,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: ClinicColors.primary,
    foregroundColor: ClinicColors.white,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: ClinicColors.white,
    ),
  ),
  iconTheme: const IconThemeData(
    color: ClinicColors.primary,
    size: 24,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: ClinicColors.primary,
    foregroundColor: ClinicColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
); 