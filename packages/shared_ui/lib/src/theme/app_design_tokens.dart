import 'package:flutter/material.dart';

/// Shared visual values used by both EasyRide clients.
///
/// Keeping these values in one package prevents passenger and driver screens
/// from slowly developing different spacing, control sizing, and semantic
/// colors for the same product surface.
class AppDesignTokens {
  AppDesignTokens._();

  static const Color primary = Color(0xFF100E11);
  static const Color secondary = Color(0xFFE3E2C3);
  static const Color tertiary = Color(0xFF6C757D);
  static const Color neutral = Color(0xFFF1F3F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FA);
  static const Color border = Color(0xFFDEE2E6);
  static const Color outline = Color(0xFFE9ECEF);
  static const Color secondarySurface = Color(0xFFF5F5EF);
  static const Color hint = Color(0xFFA0AEC0);
  static const Color fieldLabel = Color(0xFF495057);
  static const Color success = Color(0xFF198754);
  static const Color error = Color(0xFFDC3545);
  static const Color warmAccent = Color(0xFF8A4F35);
  static const Color rating = Color(0xFFD99A32);
  static const Color warning = Color(0xFFFFC107);

  static const double navigationBarHeight = 68;
  static const double navigationIconSize = 21;
  static const double navigationLabelSize = 11;
  static const double minimumTouchTarget = 48;
  static const double pageHorizontalPadding = 20;
  static const double compactGap = 8;
  static const double sectionGap = 16;
  static const double cardRadius = 20;
  static const double pillRadius = 30;
  static const double fieldRadius = 36;
}
