import 'package:flutter/widgets.dart';

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
