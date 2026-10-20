import 'package:flutter/material.dart';
import 'package:design_system/src/theme/semantic_colors.dart';

extension DesignSystemContext on BuildContext {
  Color get canvasColor => Theme.of(this).scaffoldBackgroundColor;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppSemanticColors get semanticColors {
    return Theme.of(this).extension<AppSemanticColors>() ??
        AppSemanticColors.defaults;
  }

  TextTheme get textStyles => Theme.of(this).textTheme;
}
