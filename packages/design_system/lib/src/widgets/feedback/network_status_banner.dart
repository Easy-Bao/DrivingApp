import 'package:flutter/material.dart';
import 'package:design_system/src/widgets/feedback/status_banner.dart';
import 'package:design_system/src/widgets/feedback/network_status_scope.dart';

/// This is intentionally a status surface without a retry action. Page loads
/// own their retry controls, while background work can report one shared state
/// without adding a second failure toast or page banner.
class const AppNetworkStatusBanner({
  super.key,
  this.isVisible = true,
  this.isActiveTracking = true,
  this.usePositioned = false,
  this.isServiceUnavailable = false,
}) extends StatelessWidget {
  final bool isVisible;
  final bool isActiveTracking;
  final bool usePositioned;
  final bool isServiceUnavailable;

  @override
  Widget build(BuildContext context) {
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final shouldShow = isNetworkUnavailable || (isVisible && isActiveTracking);

    return AppStatusBanner(
      isVisible: shouldShow,
      ignoreNetworkScope: true,
      message: isServiceUnavailable && !isNetworkUnavailable
          ? 'Some features are temporarily unavailable. Please try again shortly.'
          : 'Connection unavailable. Retrying automatically.',
      tone: AppStatusBannerTone.warning,
      usePositioned: usePositioned,
    );
  }
}
