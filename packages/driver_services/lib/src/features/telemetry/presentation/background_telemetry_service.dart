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

    const telemetrySyncIntervalSeconds = 10;
    Timer.periodic(const Duration(seconds: telemetrySyncIntervalSeconds),
        (timer) async {
      if (service is AndroidServiceInstance) {
        final isForeground = await service.isForegroundService();
        if (isForeground) {
          unawaited(
            service.setForegroundNotificationInfo(
              title: 'Telemetry Active',
              content: 'Driver background location telemetry active',
            ),
          );
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }
}
