import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/theme/app_colors.dart';

mixin AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
    );
  }
}
