import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF524646);
  static const Color primaryDark = Color(0xFF3B3030);
  static const Color secondaryColor = Color(0xFFD2AE8B);
  static const Color tertiaryColor = Color(0xFF756A68);
  static const Color neutralColor = Color(0xFFF4EFEC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFBF8F6);
  static const Color borderSide = Color(0xFFE4DCD8);
  static const Color secondarySurface = Color(0xFFF3E5D9);
  static const Color accent = Color(0xFFA56A4C);

  static const Color mutedSand = secondaryColor;
  static const Color slate = tertiaryColor;
  static const Color darkSlate = tertiaryColor;

  static const Color complete = Color(0xFF2F7D5A);
  static const Color cancel = Color(0xFFB84C4C);
  static const Color inProgress = primaryColor;

  static const Color selectedItemColor = primaryColor;
  static const Color unselectedItemColor = Color(0xFF8A7E7B);
  static const Color outlineBorderColor = Color(0xFFE9E1DD);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: secondarySurface,
        onPrimaryContainer: primaryDark,
        secondary: accent,
        onSecondary: Colors.white,
        secondaryContainer: secondarySurface,
        onSecondaryContainer: primaryDark,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        surface: surface,
        surfaceContainerHighest: neutralColor,
        onSurface: primaryColor,
        onSurfaceVariant: tertiaryColor,
        outline: borderSide,
        error: cancel,
        onError: Colors.white,
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
        displayLarge: TextStyle(
          color: primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        titleLarge: TextStyle(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: tertiaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: tertiaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: tertiaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(color: cancel, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(color: cancel, width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: cancel,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(color: primaryColor, size: 20),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: borderSide),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSide,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0x1F524646),
        height: 70,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : unselectedItemColor,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderSide,
        circularTrackColor: borderSide,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: Color(0x40524646),
        selectionHandleColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: borderSide),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }
}
