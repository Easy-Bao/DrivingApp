import 'package:flutter/material.dart';

/// Product-specific status colors that are not represented by [ColorScheme].
@immutable
class EasyRideSemanticColors extends ThemeExtension<EasyRideSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color rating;
  final Color warmAccent;

  const EasyRideSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.rating,
    required this.warmAccent,
  });

  static const light = EasyRideSemanticColors(
    success: Color(0xFF198754),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFB26A00),
    onWarning: Color(0xFFFFFFFF),
    rating: Color(0xFFD99A32),
    warmAccent: Color(0xFF8A4F35),
  );

  static const dark = EasyRideSemanticColors(
    success: Color(0xFF75D59B),
    onSuccess: Color(0xFF062113),
    warning: Color(0xFFF6C453),
    onWarning: Color(0xFF261A00),
    rating: Color(0xFFF6C453),
    warmAccent: Color(0xFFCDB7AA),
  );

  @override
  EasyRideSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? rating,
    Color? warmAccent,
  }) {
    return EasyRideSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      rating: rating ?? this.rating,
      warmAccent: warmAccent ?? this.warmAccent,
    );
  }

  @override
  EasyRideSemanticColors lerp(
    covariant EasyRideSemanticColors? other,
    double t,
  ) {
    if (other == null) return this;
    return EasyRideSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      warmAccent: Color.lerp(warmAccent, other.warmAccent, t)!,
    );
  }
}
