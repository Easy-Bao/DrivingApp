import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/status_colors.dart';
import 'package:flutter/material.dart';

abstract final class EasyRideColorScheme {
  static const main = ColorScheme(
    brightness: Brightness.light,
    primary: EasyRidePalette.blue,
    onPrimary: EasyRidePalette.white,
    primaryContainer: Color(0xFFDDEAF5),
    onPrimaryContainer: EasyRidePalette.navy,
    secondary: EasyRidePalette.navy,
    onSecondary: EasyRidePalette.white,
    secondaryContainer: Color(0xFFE3EAF2),
    onSecondaryContainer: EasyRidePalette.navy,
    tertiary: EasyRidePalette.amber,
    onTertiary: EasyRidePalette.gray900,
    tertiaryContainer: Color(0xFFFFE9C7),
    onTertiaryContainer: EasyRidePalette.gray900,
    error: EasyRideStatusColors.error,
    onError: EasyRidePalette.white,
    errorContainer: Color(0xFFFDE2E2),
    onErrorContainer: Color(0xFF7A2020),
    surface: EasyRidePalette.white,
    surfaceDim: EasyRidePalette.gray200,
    surfaceBright: EasyRidePalette.white,
    surfaceContainerLowest: EasyRidePalette.white,
    surfaceContainerLow: EasyRidePalette.gray50,
    surfaceContainer: EasyRidePalette.gray50,
    surfaceContainerHigh: EasyRidePalette.gray100,
    surfaceContainerHighest: EasyRidePalette.gray100,
    onSurface: EasyRidePalette.gray900,
    onSurfaceVariant: EasyRidePalette.gray600,
    outline: EasyRidePalette.gray400,
    outlineVariant: EasyRidePalette.gray200,
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    inverseSurface: EasyRidePalette.gray900,
    onInverseSurface: EasyRidePalette.gray50,
    inversePrimary: Color(0xFF8EB5DA),
    surfaceTint: EasyRidePalette.blue,
  );
}
