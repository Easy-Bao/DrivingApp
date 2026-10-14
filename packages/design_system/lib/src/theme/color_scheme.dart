import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/status_colors.dart';
import 'package:flutter/material.dart';

abstract final class EasyRideColorScheme {
  static const main = ColorScheme(
    brightness: Brightness.light,
    primary: EasyRidePalette.obsidian,
    onPrimary: EasyRidePalette.white,
    primaryContainer: EasyRidePalette.gray100,
    onPrimaryContainer: EasyRidePalette.obsidian,
    secondary: EasyRidePalette.gray800,
    onSecondary: EasyRidePalette.white,
    secondaryContainer: EasyRidePalette.gray100,
    onSecondaryContainer: EasyRidePalette.obsidian,
    tertiary: EasyRidePalette.amber,
    onTertiary: EasyRidePalette.gray900,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF92400E),
    error: EasyRideStatusColors.error,
    onError: EasyRidePalette.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7A2020),
    surface: EasyRidePalette.offWhite,
    surfaceDim: EasyRidePalette.subtleWhite,
    surfaceBright: EasyRidePalette.white,
    surfaceContainerLowest: EasyRidePalette.white,
    surfaceContainerLow: EasyRidePalette.offWhite,
    surfaceContainer: EasyRidePalette.softWhite,
    surfaceContainerHigh: EasyRidePalette.softWhite,
    surfaceContainerHighest: EasyRidePalette.subtleWhite,
    onSurface: EasyRidePalette.obsidian,
    onSurfaceVariant: EasyRidePalette.gray600,
    outline: EasyRidePalette.gray500,
    outlineVariant: EasyRidePalette.gray200,
    shadow: EasyRidePalette.ambientShadow,
    scrim: Color(0x66000000),
    inverseSurface: EasyRidePalette.gray900,
    onInverseSurface: EasyRidePalette.softWhite,
    inversePrimary: EasyRidePalette.gray400,
    surfaceTint: Colors.transparent,
  );
}
