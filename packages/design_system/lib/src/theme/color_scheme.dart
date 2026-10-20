import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/status_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppColorScheme {
  static const main = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.obsidian,
    onPrimary: AppPalette.white,
    primaryContainer: AppPalette.gray100,
    onPrimaryContainer: AppPalette.obsidian,
    secondary: AppPalette.gray800,
    onSecondary: AppPalette.white,
    secondaryContainer: AppPalette.gray100,
    onSecondaryContainer: AppPalette.obsidian,
    tertiary: AppPalette.amber,
    onTertiary: AppPalette.gray900,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF92400E),
    error: AppStatusColors.error,
    onError: AppPalette.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7A2020),
    surface: AppPalette.offWhite,
    surfaceDim: AppPalette.subtleWhite,
    surfaceBright: AppPalette.white,
    surfaceContainerLowest: AppPalette.white,
    surfaceContainerLow: AppPalette.offWhite,
    surfaceContainer: AppPalette.softWhite,
    surfaceContainerHigh: AppPalette.softWhite,
    surfaceContainerHighest: AppPalette.subtleWhite,
    onSurface: AppPalette.obsidian,
    onSurfaceVariant: AppPalette.gray600,
    outline: AppPalette.gray500,
    outlineVariant: AppPalette.gray200,
    shadow: AppPalette.ambientShadow,
    scrim: Color(0x66000000),
    inverseSurface: AppPalette.gray900,
    onInverseSurface: AppPalette.softWhite,
    inversePrimary: AppPalette.gray400,
    surfaceTint: Colors.transparent,
  );
}
