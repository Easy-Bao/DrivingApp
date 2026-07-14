import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';

/// Service managing background execution isolates for telemetry tracking.
///
/// Spawns a background worker executing in an independent thread boundary to keep
/// location telemetry updates ticking even if the application UI tree is completely detached.
class BackgroundTelemetryService {
  BackgroundTelemetryService._();

  /// Configures and registers the background telemetry worker channels.
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

  /// Execution entry point for the background service isolate.
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    DartPluginRegistrant.ensureInitialized();

    final dynamic backgroundInstance = service;
    final isAndroidInstance = service.runtimeType.toString().contains('Android');

    if (isAndroidInstance) {
      backgroundInstance.on('setAsForeground').listen((event) {
        backgroundInstance.setAsForegroundService();
      });

      backgroundInstance.on('setAsBackground').listen((event) {
        backgroundInstance.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Placeholder timer callback to update active driver geohashes to the server
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isAndroidInstance) {
        if (await backgroundInstance.isForegroundService() == true) {
          // Future background geohash push tracking triggers go here
        }
      }
    });
  }

  /// Execution callback for iOS background execution loops.
  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }
}
