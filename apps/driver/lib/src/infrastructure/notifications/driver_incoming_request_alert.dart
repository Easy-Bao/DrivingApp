import 'package:flutter/services.dart';

final class DriverIncomingRequestAlert {
  DriverIncomingRequestAlert._();

  static const MethodChannel channel = MethodChannel('easyride/driver_alerts');

  static Future<void> play() async {
    try {
      await channel.invokeMethod<void>('playIncomingRideAlert');
    } on MissingPluginException {
      await _playSystemAlert();
    } on PlatformException {
      await _playSystemAlert();
    }
  }

  static Future<void> _playSystemAlert() =>
      SystemSound.play(SystemSoundType.alert);
}
