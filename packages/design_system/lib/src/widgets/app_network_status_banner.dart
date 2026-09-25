import 'package:flutter/material.dart';
import 'package:design_system/src/widgets/app_status_banner.dart';
import 'package:design_system/src/widgets/app_network_status_scope.dart';

/// Shows the quiet transport status while an active trip loses connectivity.
///
/// This is intentionally a status surface without a retry action. Page loads
/// own their retry controls, while background work can report one shared state
/// without adding a second failure toast or page banner.
class const AppNetworkStatusBanner({
  super.key,
  required this.isVisible,
  this.isActiveTracking = true,
}) extends StatelessWidget {
  final bool isVisible;
  final bool isActiveTracking;

  @override
  Widget build(BuildContext context) {
    return AppStatusBanner(
      isVisible:
          isVisible &&
          isActiveTracking &&
          !AppNetworkStatusScope.isUnavailableOf(context),
      message: 'Connection unavailable. Retrying automatically.',
      tone: AppStatusBannerTone.warning,
    );
  }
}
