import 'package:flutter/material.dart';

class PassengerTheme {
  PassengerTheme._();

  static const Color primaryColor = Color(0xFF1A1D20);       // Dark Obsidian Charcoal
  static const Color secondaryColor = Color(0xFFE3E2C3);     // Healing Springs Sand Accent
  static const Color tertiaryColor = Color(0xFF6C757D);      // Slate Grey Subtitle
  static const Color neutralColor = Color(0xFFF1F3F5);       // Soft Tint Neutral
  static const Color surface = Color(0xFFFFFFFF);            // Pure White Card/Input Surface
  static const Color background = Color(0xFFF8F9FA);         // Soft Off-White Scaffold Background
  static const Color borderSide = Color(0xFFDEE2E6);         // Clean Subtle Border

  static const Color accent = primaryColor;
  static const Color mutedSand = secondaryColor;
  static const Color slate = tertiaryColor;
  static const Color darkSlate = tertiaryColor;

  static const Color complete = Color(0xFF198754);
  static const Color cancel = Color(0xFFDC3545);
  static const Color inProgress = Color(0xFF1A1D20);

  static const Color selectedItemColor = Color(0xFF1A1D20);
  static const Color unselectedItemColor = Color(0xFF6C757D);
  static const Color outlineBorderColor = Color(0xFFE9ECEF);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surface,
        onSurface: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        titleLarge: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleMedium: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: tertiaryColor, fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: Color(0xFFA0AEC0),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: const Color(0xFF495057),
        suffixIconColor: const Color(0xFF495057),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(color: borderSide, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(color: borderSide, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 20,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }
}

class DriverTheme {
  DriverTheme._();

  static const Color primaryColor = Color(0xFF1A1D20);
  static const Color secondaryColor = Color(0xFFE3E2C3);
  static const Color tertiaryColor = Color(0xFF6C757D);
  static const Color neutralColor = Color(0xFFF1F3F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color borderSide = Color(0xFFDEE2E6);

  static const Color selectedItemColor = Color(0xFF1A1D20);
  static const Color indicatorColor = Color(0xFF1A1D20);
  static Color unselectedItemColor = const Color(0xFF6C757D);
  static Color outlineBorderColor = const Color(0xFFDEE2E6);

  static const Color complete = Color(0xFF198754);
  static const Color cancel = Color(0xFFDC3545);
  static const Color inProgress = Color(0xFF1A1D20);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
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

  static const Color primaryColor = PassengerTheme.primaryColor;
  static const Color secondaryColor = PassengerTheme.secondaryColor;
  static const Color tertiaryColor = PassengerTheme.tertiaryColor;
  static const Color neutralColor = PassengerTheme.neutralColor;
  static const Color surface = PassengerTheme.surface;
  static const Color background = PassengerTheme.background;
  static const Color borderSide = PassengerTheme.borderSide;

  static const Color selectedItemColor = PassengerTheme.selectedItemColor;
  static const Color indicatorColor = PassengerTheme.primaryColor;
  static Color unselectedItemColor = PassengerTheme.unselectedItemColor;
  static Color outlineBorderColor = PassengerTheme.outlineBorderColor;

  static const Color complete = PassengerTheme.complete;
  static const Color cancel = PassengerTheme.cancel;
  static const Color inProgress = PassengerTheme.inProgress;

  static ThemeData get lightThemeData => PassengerTheme.themeData;
  static ThemeData get passengerThemeData => PassengerTheme.themeData;
  static ThemeData get driverThemeData => DriverTheme.themeData;
}
