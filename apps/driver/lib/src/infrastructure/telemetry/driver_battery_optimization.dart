import 'package:flutter/services.dart';

final class DriverBatteryOptimization {
  DriverBatteryOptimization._();

  static const _channel = MethodChannel('easyride/driver_battery');

  static Future<bool> isOptimizationEnabled() async {
    try {
      final isIgnoring = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return !(isIgnoring ?? true);
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
