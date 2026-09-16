import 'package:design_system/src/theme/color_scheme.dart';
import 'package:design_system/src/theme/component_themes.dart';
import 'package:design_system/src/theme/easy_ride_semantic_colors.dart';
import 'package:design_system/src/theme/typography.dart';
import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:flutter/material.dart';

/// The single Material theme shared by every EasyRide application.
abstract final class EasyRideTheme {
  static final ThemeData main = _build();

  static ThemeData _build() {
    final colors = EasyRideColorScheme.main;
    final textTheme = EasyRideTypography.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colors,
      scaffoldBackgroundColor: EasyRidePalette.gray50,
      canvasColor: EasyRidePalette.gray50,
      fontFamily: 'packages/design_system/ProductSans',
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        EasyRideSemanticColors.defaults,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.onSurface),
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: EasyRideComponentThemes.input(colors, textTheme),
      iconTheme: IconThemeData(color: colors.onSurface, size: 20),
      cardTheme: EasyRideComponentThemes.card(colors),
      dividerTheme: EasyRideComponentThemes.divider(colors),
      navigationBarTheme: EasyRideComponentThemes.navigationBar(
        colors,
        textTheme,
      ),
      bottomSheetTheme: EasyRideComponentThemes.bottomSheet(colors),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
          borderRadius: BorderRadius.circular(EasyRideRadius.md),
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
      filledButtonTheme: EasyRideComponentThemes.filledButton(colors, textTheme),
      outlinedButtonTheme: EasyRideComponentThemes.outlinedButton(
        colors,
        textTheme,
      ),
      textButtonTheme: EasyRideComponentThemes.textButton(colors, textTheme),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primaryContainer,
        disabledColor: colors.surfaceContainerHighest,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.pill),
        ),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      elevatedButtonTheme: EasyRideComponentThemes.elevatedButton(
        colors,
        textTheme,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colors.onPrimaryContainer,
          size: EasyRideSize.navigationIcon,
        ),
        unselectedIconTheme: IconThemeData(
          color: colors.onSurfaceVariant,
          size: EasyRideSize.navigationIcon,
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
          borderRadius: BorderRadius.circular(EasyRideRadius.md),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colors.onInverseSurface,
        ),
      ),
    );
  }
}
