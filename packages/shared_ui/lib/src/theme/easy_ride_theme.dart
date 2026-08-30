import 'package:flutter/material.dart';
import 'package:shared_ui/src/theme/app_design_tokens.dart';
import 'package:shared_ui/src/theme/easy_ride_semantic_colors.dart';

/// The semantic Material themes shared by passenger and driver clients.
class EasyRideTheme {
  EasyRideTheme._();

  static const _lightCanvas = Color(0xFFF8F9FA);
  static const _darkCanvas = Color(0xFF090D12);

  static const _lightScheme = ColorScheme.light(
    primary: Color(0xFF100E11),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5F5EF),
    onPrimaryContainer: Color(0xFF100E11),
    secondary: Color(0xFF8A4F35),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE3E2C3),
    onSecondaryContainer: Color(0xFF28251C),
    tertiary: Color(0xFF198754),
    onTertiary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceContainerHighest: AppDesignTokens.neutral,
    onSurface: Color(0xFF100E11),
    onSurfaceVariant: Color(0xFF5F6670),
    outline: Color(0xFFCED3D8),
    outlineVariant: Color(0xFFE5E8EB),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF2F3033),
    onInverseSurface: Color(0xFFF4F0F3),
    inversePrimary: Color(0xFFD8C2CE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const _darkScheme = ColorScheme.dark(
    primary: Color(0xFFF4EEE9),
    onPrimary: Color(0xFF17120F),
    primaryContainer: Color(0xFF332C29),
    onPrimaryContainer: Color(0xFFF4EEE9),
    secondary: Color(0xFFCDB7AA),
    onSecondary: Color(0xFF251A15),
    secondaryContainer: Color(0xFF3A302C),
    onSecondaryContainer: Color(0xFFF7EAE3),
    tertiary: Color(0xFF75D59B),
    onTertiary: Color(0xFF062113),
    surface: Color(0xFF121820),
    onSurface: Color(0xFFF4EEE9),
    onSurfaceVariant: Color(0xFFA9AFB6),
    outline: Color(0xFF7A8189),
    outlineVariant: Color(0x1FFFFFFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    inverseSurface: Color(0xFFF4EEE9),
    onInverseSurface: Color(0xFF282124),
    inversePrimary: Color(0xFF574B46),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceContainerLowest: Color(0xFF090D12),
    surfaceContainerLow: Color(0xFF0E141A),
    surfaceContainer: Color(0xFF121820),
    surfaceContainerHigh: Color(0xFF161E26),
    surfaceContainerHighest: Color(0xFF1A222B),
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colorScheme: _lightScheme,
    canvas: _lightCanvas,
    semanticColors: EasyRideSemanticColors.light,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    canvas: _darkCanvas,
    semanticColors: EasyRideSemanticColors.dark,
  );

  /// Temporary light-theme alias for consumers migrating to [light].
  static ThemeData get data => light;

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color canvas,
    required EasyRideSemanticColors semanticColors,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      fontFamily: 'packages/shared_ui/ProductSans',
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.pageHorizontalPadding,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: _fieldBorder(colorScheme.outline),
        enabledBorder: _fieldBorder(colorScheme.outline),
        focusedBorder: _fieldBorder(colorScheme.primary, width: 1.5),
        errorBorder: _fieldBorder(colorScheme.error),
        focusedErrorBorder: _fieldBorder(colorScheme.error, width: 1.5),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 20),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDesignTokens.cardRadius),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(
          alpha: isDark ? 0.16 : 0.08,
        ),
        height: 70,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(
            fontSize: AppDesignTokens.navigationLabelSize,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outlineVariant,
        circularTrackColor: colorScheme.outlineVariant,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: colorScheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: colorScheme.outline),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        minVerticalPadding: 12,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppDesignTokens.fieldRadius),
      ),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
