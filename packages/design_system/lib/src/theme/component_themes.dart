import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter/material.dart';

abstract final class EasyRideComponentThemes {
  static ElevatedButtonThemeData elevatedButton(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: colors.surfaceContainerHighest,
        disabledForegroundColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(
          EasyRideSize.minimumTouchTarget,
          EasyRideSize.controlHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        ),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  static FilledButtonThemeData filledButton(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: colors.surfaceContainerHighest,
        disabledForegroundColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
        elevation: 0,
        minimumSize: const Size(
          EasyRideSize.minimumTouchTarget,
          EasyRideSize.controlHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        ),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButton(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface,
        disabledForegroundColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
        side: BorderSide(color: colors.outlineVariant, width: 1.5),
        minimumSize: const Size(
          EasyRideSize.minimumTouchTarget,
          EasyRideSize.controlHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        ),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  static TextButtonThemeData textButton(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        disabledForegroundColor: colors.onSurfaceVariant.withValues(alpha: 0.38),
        minimumSize: const Size(
          EasyRideSize.minimumTouchTarget,
          EasyRideSize.minimumTouchTarget,
        ),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme input(ColorScheme colors, TextTheme textTheme) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EasyRideSpacing.xl,
        vertical: EasyRideSpacing.lg,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
      labelStyle: textTheme.bodyLarge?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: colors.onSurfaceVariant,
      suffixIconColor: colors.onSurfaceVariant,
      border: border(colors.outline),
      enabledBorder: border(colors.outline),
      focusedBorder: border(colors.primary, width: 1.5),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, width: 1.5),
      errorStyle: textTheme.bodySmall?.copyWith(color: colors.error),
    );
  }

  static CardThemeData card(ColorScheme colors) {
    return CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        side: BorderSide(color: colors.outlineVariant),
      ),
    );
  }

  static NavigationBarThemeData navigationBar(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.surfaceContainerHighest,
      height: EasyRideSize.navigationBarHeight,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
          size: EasyRideSize.navigationIcon,
        );
      }),
    );
  }

  static BottomSheetThemeData bottomSheet(ColorScheme colors) {
    return BottomSheetThemeData(
      backgroundColor: colors.surfaceContainerLow,
      modalBackgroundColor: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colors.outlineVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EasyRideRadius.sheet),
        ),
      ),
    );
  }

  static DividerThemeData divider(ColorScheme colors) {
    return DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 1,
    );
  }
}
