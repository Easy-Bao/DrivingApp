import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Driver-facing aliases for the shared EasyRide design system.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = AppDesignTokens.primary;
  static const Color primaryDark = AppDesignTokens.primary;
  static const Color secondaryColor = AppDesignTokens.secondary;
  static const Color tertiaryColor = AppDesignTokens.tertiary;
  static const Color neutralColor = AppDesignTokens.neutral;
  static const Color surface = AppDesignTokens.surface;
  static const Color interactiveSurface = surface;
  static const Color activeControlBackground = primaryColor;
  static const Color activeControlForeground = surface;
  static const Color background = AppDesignTokens.background;
  static const Color borderSide = AppDesignTokens.border;
  static const Color secondarySurface = AppDesignTokens.secondarySurface;
  static const Color accent = primaryColor;
  static const Color mutedSand = secondaryColor;
  static const Color slate = tertiaryColor;
  static const Color darkSlate = tertiaryColor;

  static const Color complete = AppDesignTokens.success;
  static const Color cancel = AppDesignTokens.error;
  static const Color inProgress = primaryColor;

  static const Color selectedItemColor = primaryColor;
  static const Color unselectedItemColor = tertiaryColor;
  static const Color outlineBorderColor = AppDesignTokens.outline;
  static const Color fieldLabel = AppDesignTokens.fieldLabel;
  static const Color warmAccent = AppDesignTokens.warmAccent;
  static const Color rating = AppDesignTokens.rating;
  static const Color warning = AppDesignTokens.warning;

  static ThemeData get themeData => EasyRideTheme.data;
}
