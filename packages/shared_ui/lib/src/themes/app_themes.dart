import 'package:flutter/material.dart';

class PassengerTheme {
  PassengerTheme._();

  static const Color accent = Color(0xFFE3E2C3);
  static const Color mutedSand = Color(0xFFC1C1A9);
  static const Color slate = Color(0xFF8B8A87);
  static const Color darkSlate = Color(0xFF6A6A67);
  static const Color surface = Color(0xFF272727);
  static const Color background = Color(0xFF141413);
  static const Color borderSide = Color(0xFF383838);

  static const Color primaryColor = accent;
  static const Color secondaryColor = mutedSand;
  static const Color tertiaryColor = slate;
  static const Color neutralColor = surface;

  static const Color complete = Color(0xFF4CAF50);
  static const Color cancel = Color(0xFFFF5252);
  static const Color inProgress = Color(0xFFE3E2C3);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: mutedSand,
        tertiary: slate,
        surface: surface,
        onSurface: accent,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: mutedSand, fontSize: 14),
        titleLarge: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(
          color: slate,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: const TextStyle(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: accent,
        suffixIconColor: accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSide),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSide),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: accent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accent,
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }
}

class DriverTheme {
  DriverTheme._();

  static const Color primaryColor = Color(0xFF222222);
  static const Color secondaryColor = Color(0xFFF2E0D0);
  static const Color tertiaryColor = Color(0xFF607B8B);
  static const Color neutralColor = Color(0xFFF8F5F2);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color borderSide = Color(0xFFE0E0E0);

  static const Color selectedItemColor = Color(0xFF222222);
  static const Color indicatorColor = Color(0xFF222222);
  static Color unselectedItemColor = const Color(0xFF222222).withValues(alpha: 0.3);
  static Color outlineBorderColor = const Color(0xFF222222).withValues(alpha: 0.1);

  static const Color complete = Color(0xFF285A48);
  static const Color cancel = Color(0xFFFF3737);
  static const Color inProgress = Color(0xFF607B8B);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surface,
        onSurface: primaryColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: primaryColor, fontSize: 14),
        titleLarge: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }
}

class AppTheme {
  AppTheme._();

  static const Color primaryColor = DriverTheme.primaryColor;
  static const Color secondaryColor = DriverTheme.secondaryColor;
  static const Color tertiaryColor = DriverTheme.tertiaryColor;
  static const Color neutralColor = DriverTheme.neutralColor;
  static const Color surface = DriverTheme.surface;
  static const Color borderSide = DriverTheme.borderSide;

  static const Color selectedItemColor = DriverTheme.selectedItemColor;
  static const Color indicatorColor = DriverTheme.indicatorColor;
  static Color unselectedItemColor = DriverTheme.unselectedItemColor;
  static Color outlineBorderColor = DriverTheme.outlineBorderColor;

  static const Color complete = DriverTheme.complete;
  static const Color cancel = DriverTheme.cancel;
  static const Color inProgress = DriverTheme.inProgress;

  static ThemeData get lightThemeData => DriverTheme.themeData;
  static ThemeData get passengerThemeData => PassengerTheme.themeData;
  static ThemeData get driverThemeData => DriverTheme.themeData;
}
