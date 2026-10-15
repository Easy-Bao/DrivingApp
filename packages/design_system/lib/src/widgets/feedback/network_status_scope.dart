import 'package:flutter/widgets.dart';

/// Shares the app-shell connectivity state with route-level status surfaces.
///
/// A page can keep its own actionable error state, but it should yield to the
/// operating system while the transport is degraded or unavailable.
class AppNetworkStatusScope extends InheritedWidget {
  const AppNetworkStatusScope({
    super.key,
    required this.isUnavailable,
    required super.child,
  });

  final bool isUnavailable;

  static bool isUnavailableOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppNetworkStatusScope>()
            ?.isUnavailable ??
        false;
  }

  @override
  bool updateShouldNotify(AppNetworkStatusScope oldWidget) {
    return isUnavailable != oldWidget.isUnavailable;
  }
}
