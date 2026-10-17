import 'package:flutter/material.dart';
import 'package:design_system/src/widgets/feedback/status_banner.dart';
import 'package:design_system/src/widgets/feedback/network_status_scope.dart';

/// Shows the quiet transport status while an active trip loses connectivity.
///
/// This is intentionally a status surface without a retry action. Page loads
/// own their retry controls, while background work can report one shared state
/// without adding a second failure toast or page banner.
class const AppNetworkStatusBanner({
  super.key,
  this.isVisible = true,
  this.isActiveTracking = true,
  this.usePositioned = false,
}) extends StatelessWidget {
  final bool isVisible;
  final bool isActiveTracking;
  final bool usePositioned;

  @override
  Widget build(BuildContext context) {
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final shouldShow = isNetworkUnavailable || (isVisible && isActiveTracking);

    return AppStatusBanner(
      isVisible: shouldShow,
      ignoreNetworkScope: true,
      message: 'Connection unavailable. Retrying automatically.',
      tone: AppStatusBannerTone.warning,
      usePositioned: usePositioned,
    );
  }
}
