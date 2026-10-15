import 'package:design_system/src/widgets/feedback/network_status_scope.dart';
import 'package:design_system/src/widgets/feedback/snack_bar.dart';
import 'package:flutter/material.dart';

abstract final class CustomToast {
  static ScaffoldMessengerState? _lastMessenger;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) return;
    _lastMessenger = ScaffoldMessenger.maybeOf(context);
    AppSnackBar.show(context, message, isError: isError, duration: duration);
  }

  static void dismiss() {
    _lastMessenger?.hideCurrentSnackBar();
    _lastMessenger = null;
  }
}
