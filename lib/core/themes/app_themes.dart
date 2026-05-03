import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Color theme
  static const Color primaryColor = Color(0xFF222222);
  static const Color secondaryColor = Color(0xFFF2E0D0);
  static const Color tertiaryColor = Color(0xFF607B8B);
  static const Color neutralColor = Color(0xFFF8F5F2);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color borderSide = Color(0xFFE0E0E0);

  // TabBar Active/Inactive Theme
  static Color selectedItemColor = Color(0xFF222222);
  static Color indicatorColor = Color(0xFF222222);
  static Color unselectedItemColor = Color(0xFF222222).withValues(alpha: 0.3);
  static Color outlineBorderColor = Color(0xFF222222).withValues(alpha: 0.1);

  // Activtiy Status
  static Color complete = Color(0xFF285A48);
  static Color cancel = Color(0xFFFF3737);
  static Color inProgress = Color(0xFF607B8B);
}
