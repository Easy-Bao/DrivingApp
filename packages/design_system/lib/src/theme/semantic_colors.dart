import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/status_colors.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class const AppSemanticColors({
  required this.success,
  required this.onSuccess,
  required this.successContainer,
  required this.onSuccessContainer,
  required this.warning,
  required this.onWarning,
  required this.warningContainer,
  required this.onWarningContainer,
  required this.info,
  required this.onInfo,
  required this.infoContainer,
  required this.onInfoContainer,
  required this.rating,
  required this.online,
  required this.offline,
}) extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color rating;
  final Color online;
  final Color offline;

  static const defaults = AppSemanticColors(
    success: AppStatusColors.success,
    onSuccess: AppPalette.white,
    successContainer: AppPalette.green100,
    onSuccessContainer: AppPalette.green800,
    warning: AppStatusColors.warning,
    onWarning: AppPalette.white,
    warningContainer: AppPalette.amber100,
    onWarningContainer: AppPalette.amber800,
    info: AppStatusColors.info,
    onInfo: AppPalette.white,
    infoContainer: AppPalette.blue100,
    onInfoContainer: AppPalette.blue800,
    rating: AppStatusColors.rating,
    online: AppStatusColors.success,
    offline: AppPalette.gray600,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? rating,
    Color? online,
    Color? offline,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      rating: rating ?? this.rating,
      online: online ?? this.online,
      offline: offline ?? this.offline,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? other.success,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? other.onSuccess,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          other.successContainer,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ??
          other.onSuccessContainer,
      warning: Color.lerp(warning, other.warning, t) ?? other.warning,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? other.onWarning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          other.warningContainer,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t) ??
          other.onWarningContainer,
      info: Color.lerp(info, other.info, t) ?? other.info,
      onInfo: Color.lerp(onInfo, other.onInfo, t) ?? other.onInfo,
      infoContainer:
          Color.lerp(infoContainer, other.infoContainer, t) ??
          other.infoContainer,
      onInfoContainer:
          Color.lerp(onInfoContainer, other.onInfoContainer, t) ??
          other.onInfoContainer,
      rating: Color.lerp(rating, other.rating, t) ?? other.rating,
      online: Color.lerp(online, other.online, t) ?? other.online,
      offline: Color.lerp(offline, other.offline, t) ?? other.offline,
    );
  }
}
