import 'package:flutter/material.dart';
import 'package:shared_ui/src/theme/easy_ride_semantic_colors.dart';

extension EasyRideThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;

  Color get canvasColor => Theme.of(this).scaffoldBackgroundColor;

  EasyRideSemanticColors get semanticColors {
    return Theme.of(this).extension<EasyRideSemanticColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? EasyRideSemanticColors.dark
            : EasyRideSemanticColors.light);
  }
}
