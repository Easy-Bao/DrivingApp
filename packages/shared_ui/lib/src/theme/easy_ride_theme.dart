import 'package:flutter/material.dart';
import 'package:shared_ui/src/theme/app_design_tokens.dart';

/// The common Material theme for passenger and driver clients.
class EasyRideTheme {
  EasyRideTheme._();

  static ThemeData get data {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppDesignTokens.background,
      colorScheme: const ColorScheme.light(
        primary: AppDesignTokens.primary,
        onPrimary: AppDesignTokens.surface,
        primaryContainer: AppDesignTokens.secondarySurface,
        onPrimaryContainer: AppDesignTokens.primary,
        secondary: AppDesignTokens.primary,
        onSecondary: AppDesignTokens.surface,
        secondaryContainer: AppDesignTokens.secondarySurface,
        onSecondaryContainer: AppDesignTokens.primary,
        tertiary: AppDesignTokens.tertiary,
        onTertiary: AppDesignTokens.surface,
        surface: AppDesignTokens.surface,
        surfaceContainerHighest: AppDesignTokens.neutral,
        onSurface: AppDesignTokens.primary,
        onSurfaceVariant: AppDesignTokens.tertiary,
        outline: AppDesignTokens.border,
        error: AppDesignTokens.error,
        onError: AppDesignTokens.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppDesignTokens.primary),
        titleTextStyle: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: AppDesignTokens.tertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppDesignTokens.tertiary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: AppDesignTokens.tertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppDesignTokens.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDesignTokens.pageHorizontalPadding,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: AppDesignTokens.hint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: AppDesignTokens.primary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppDesignTokens.fieldLabel,
        suffixIconColor: AppDesignTokens.fieldLabel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignTokens.fieldRadius),
          ),
          borderSide: BorderSide(color: AppDesignTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignTokens.fieldRadius),
          ),
          borderSide: BorderSide(color: AppDesignTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignTokens.fieldRadius),
          ),
          borderSide: BorderSide(color: AppDesignTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignTokens.fieldRadius),
          ),
          borderSide: BorderSide(color: AppDesignTokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignTokens.fieldRadius),
          ),
          borderSide: BorderSide(color: AppDesignTokens.error, width: 1.5),
        ),
        errorStyle: TextStyle(
          color: AppDesignTokens.error,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(color: AppDesignTokens.primary, size: 20),
      cardTheme: const CardThemeData(
        color: AppDesignTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignTokens.cardRadius),
          ),
          side: BorderSide(color: AppDesignTokens.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppDesignTokens.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppDesignTokens.surface,
        indicatorColor: AppDesignTokens.primary,
        height: 70,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: AppDesignTokens.navigationLabelSize),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppDesignTokens.primary
                : AppDesignTokens.tertiary,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDesignTokens.surface,
        modalBackgroundColor: AppDesignTokens.surface,
        showDragHandle: true,
        dragHandleColor: AppDesignTokens.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppDesignTokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppDesignTokens.primary,
        contentTextStyle: const TextStyle(
          color: AppDesignTokens.surface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppDesignTokens.primary,
        linearTrackColor: AppDesignTokens.border,
        circularTrackColor: AppDesignTokens.border,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppDesignTokens.primary,
        selectionColor: Color(0x40100E11),
        selectionHandleColor: AppDesignTokens.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignTokens.primary,
          foregroundColor: AppDesignTokens.surface,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignTokens.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppDesignTokens.border),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDesignTokens.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      fontFamily: 'packages/shared_ui/ProductSans',
    );
  }
}
