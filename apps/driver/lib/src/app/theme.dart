import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

abstract final class DriverTheme {
  static final ThemeData main = AppTheme.main.copyWith(
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
