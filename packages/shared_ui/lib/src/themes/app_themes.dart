import 'package:flutter/material.dart';

class AppLightTheme {
  AppLightTheme._();

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
}

class AppDarkTheme {
  AppDarkTheme._();

  static const Color primaryColor = Color(0xFFF8F8F8);
  static const Color secondaryColor = Color(0xFF382C24);
  static const Color tertiaryColor = Color(0xFF8CA5B5);
  static const Color neutralColor = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF141414);
  static const Color borderSide = Color(0xFF2C2C2C);

  static const Color selectedItemColor = Color(0xFFF8F8F8);
  static const Color indicatorColor = Color(0xFFF8F8F8);
  static Color unselectedItemColor = const Color(0xFFF8F8F8).withValues(alpha: 0.3);
  static Color outlineBorderColor = const Color(0xFFF8F8F8).withValues(alpha: 0.1);

  static const Color complete = Color(0xFF387A63);
  static const Color cancel = Color(0xFFFF5252);
  static const Color inProgress = Color(0xFF8CA5B5);
}

class AppTheme {
  AppTheme._();

  static const Color primaryColor = AppLightTheme.primaryColor;
  static const Color secondaryColor = AppLightTheme.secondaryColor;
  static const Color tertiaryColor = AppLightTheme.tertiaryColor;
  static const Color neutralColor = AppLightTheme.neutralColor;
  static const Color surface = AppLightTheme.surface;
  static const Color borderSide = AppLightTheme.borderSide;

  static const Color selectedItemColor = AppLightTheme.selectedItemColor;
  static const Color indicatorColor = AppLightTheme.indicatorColor;
  static Color unselectedItemColor = AppLightTheme.unselectedItemColor;
  static Color outlineBorderColor = AppLightTheme.outlineBorderColor;

  static const Color complete = AppLightTheme.complete;
  static const Color cancel = AppLightTheme.cancel;
  static const Color inProgress = AppLightTheme.inProgress;

  static ThemeData get lightThemeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppLightTheme.surface,
      colorScheme: const ColorScheme.light(
        primary: AppLightTheme.primaryColor,
        secondary: AppLightTheme.secondaryColor,
        tertiary: AppLightTheme.tertiaryColor,
        surface: AppLightTheme.surface,
        onSurface: AppLightTheme.primaryColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppLightTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppLightTheme.primaryColor, fontSize: 14),
        titleLarge: TextStyle(color: AppLightTheme.primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppLightTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppLightTheme.primaryColor.withValues(alpha: 0.38),
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: const TextStyle(
          color: AppLightTheme.primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppLightTheme.primaryColor.withValues(alpha: 0.6),
        suffixIconColor: AppLightTheme.primaryColor.withValues(alpha: 0.6),
      ),
      iconTheme: const IconThemeData(
        color: AppLightTheme.primaryColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppLightTheme.primaryColor,
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }

  static ThemeData get darkThemeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDarkTheme.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppDarkTheme.primaryColor,
        secondary: AppDarkTheme.secondaryColor,
        tertiary: AppDarkTheme.tertiaryColor,
        surface: AppDarkTheme.surface,
        onSurface: AppDarkTheme.primaryColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppDarkTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppDarkTheme.primaryColor, fontSize: 14),
        titleLarge: TextStyle(color: AppDarkTheme.primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppDarkTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppDarkTheme.primaryColor.withValues(alpha: 0.38),
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: const TextStyle(
          color: AppDarkTheme.primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppDarkTheme.primaryColor.withValues(alpha: 0.6),
        suffixIconColor: AppDarkTheme.primaryColor.withValues(alpha: 0.6),
      ),
      iconTheme: const IconThemeData(
        color: AppDarkTheme.primaryColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppDarkTheme.primaryColor,
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }
}
