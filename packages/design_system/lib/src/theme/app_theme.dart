import 'package:design_system/src/theme/color_scheme.dart';
import 'package:design_system/src/theme/component_themes.dart';
import 'package:design_system/src/theme/semantic_colors.dart';
import 'package:design_system/src/theme/typography.dart';
import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData main = _build();

  static ThemeData _build() {
    final colors = AppColorScheme.main;
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colors,
      scaffoldBackgroundColor: AppPalette.softWhite,
      canvasColor: AppPalette.softWhite,
      fontFamily: 'packages/design_system/ProductSans',
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.defaults],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.onSurface),
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: AppComponentThemes.input(colors, textTheme),
      iconTheme: IconThemeData(color: colors.onSurface, size: 20),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSize.minimumTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: colors.onSurface,
          disabledForegroundColor: colors.onSurfaceVariant.withValues(
            alpha: 0.38,
          ),
        ),
      ),
      cardTheme: AppComponentThemes.card(colors),
      dividerTheme: AppComponentThemes.divider(colors),
      navigationBarTheme: AppComponentThemes.navigationBar(colors, textTheme),
      bottomSheetTheme: AppComponentThemes.bottomSheet(colors),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: colors.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.outlineVariant,
        circularTrackColor: colors.outlineVariant,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.25),
        selectionHandleColor: colors.primary,
      ),
      filledButtonTheme: AppComponentThemes.filledButton(colors, textTheme),
      outlinedButtonTheme: AppComponentThemes.outlinedButton(colors, textTheme),
      textButtonTheme: AppComponentThemes.textButton(colors, textTheme),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primaryContainer,
        disabledColor: colors.surfaceContainerHighest,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      elevatedButtonTheme: AppComponentThemes.elevatedButton(colors, textTheme),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colors.onPrimaryContainer,
          size: AppSize.navigationIcon,
        ),
        unselectedIconTheme: IconThemeData(
          color: colors.onSurfaceVariant,
          size: AppSize.navigationIcon,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        minVerticalPadding: 12,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colors.onInverseSurface,
        ),
      ),
    );
  }
}
