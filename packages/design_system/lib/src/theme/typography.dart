import 'package:flutter/material.dart';

abstract final class EasyRideTypography {
  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );
}
