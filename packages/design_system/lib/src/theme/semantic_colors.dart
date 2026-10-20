import 'package:design_system/src/tokens/status_colors.dart';
import 'package:flutter/material.dart';

@immutable
class const AppSemanticColors({
  required this.success,
  required this.onSuccess,
  required this.warning,
  required this.onWarning,
  required this.info,
  required this.rating,
  required this.online,
  required this.offline,
}) extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color rating;
  final Color online;
  final Color offline;

  static const defaults = AppSemanticColors(
    success: AppStatusColors.success,
    onSuccess: Color(0xFFFFFFFF),
    warning: AppStatusColors.warning,
    onWarning: Color(0xFFFFFFFF),
    info: AppStatusColors.info,
    rating: AppStatusColors.rating,
    online: AppStatusColors.success,
    offline: Color(0xFF64748B),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? rating,
    Color? online,
    Color? offline,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      rating: rating ?? this.rating,
      online: online ?? this.online,
      offline: offline ?? this.offline,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
    );
  }
}
