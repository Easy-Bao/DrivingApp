import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundTelemetryService {
  BackgroundTelemetryService._();

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'telemetry_channel',
        initialNotificationTitle: 'EasyRide Telemetry Sync',
        initialNotificationContent: 'Tracking driver dispatch location...',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        unawaited(service.setAsForegroundService());
      });

      service.on('setAsBackground').listen((event) {
        unawaited(service.setAsBackgroundService());
      });
    }

    service.on('stopService').listen((event) {
      unawaited(service.stopSelf());
    });

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        //TODO: Make configurable and no empty block
        if (await service.isForegroundService() == true) {
          // background geohash update loop goes here
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }
}
