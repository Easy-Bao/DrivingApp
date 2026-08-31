import 'package:flutter/material.dart';
import 'package:design_system/src/theme/easy_ride_semantic_colors.dart';

extension DesignSystemContext on BuildContext {
  Color get canvasColor => Theme.of(this).scaffoldBackgroundColor;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  EasyRideSemanticColors get semanticColors {
    return Theme.of(this).extension<EasyRideSemanticColors>() ??
        EasyRideSemanticColors.defaults;
  }

  TextTheme get textStyles => Theme.of(this).textTheme;
}
