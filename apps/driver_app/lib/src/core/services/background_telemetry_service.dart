import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/core/constants/storage_keys.dart';

class BackgroundTelemetryService {
  static const _interval = Duration(seconds: 10);

  final Uri _apiBaseUri;
  final FlutterBackgroundService _service;
  bool _configured = false;

  BackgroundTelemetryService({
    required Uri apiBaseUri,
    FlutterBackgroundService? service,
  }) : _apiBaseUri = apiBaseUri,
       _service = service ?? FlutterBackgroundService();

  Future<void> initialize() async {
    if (_configured) return;

    final configured = await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        initialNotificationTitle: 'EasyRide Driver',
        initialNotificationContent: 'Sharing location while you are online.',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    if (!configured) {
      throw StateError('Background telemetry service could not be configured.');
    }
    _configured = true;
  }

  Future<void> start() async {
    await initialize();
    if (!await _service.isRunning()) {
      final started = await _service.startService();
      if (!started) {
        throw StateError('Background telemetry service could not be started.');
      }
    }
    _service.invoke('configure', {'baseUrl': _apiBaseUri.toString()});
  }

  Future<void> stop() async {
    if (await _service.isRunning()) {
      _service.invoke('stopService');
    }
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) {
    DartPluginRegistrant.ensureInitialized();

    final storage = const FlutterSecureStorage();
    String? baseUrl;
    var sending = false;

    service.on('configure').listen((event) {
      baseUrl = event?['baseUrl'] as String?;
    });

    Future<void> sendLocation() async {
      if (sending || baseUrl == null) return;

      final token = await storage.read(key: StorageKeys.jwtToken);
      final driverId = await storage.read(key: StorageKeys.driverId);
      if (token == null ||
          token.isEmpty ||
          driverId == null ||
          driverId.isEmpty) {
        return;
      }

      sending = true;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );
        await Dio(BaseOptions(baseUrl: baseUrl!)).post<void>(
          '/api/v1/telemetry/location',
          data: {
            'driverId': driverId,
            'lat': position.latitude,
            'lng': position.longitude,
            'heading': position.heading,
            'speed': position.speed,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException catch (error) {
        dev.log('Driver telemetry request failed: ${error.message}');
      } catch (error) {
        dev.log('Driver telemetry collection failed: $error');
      } finally {
        sending = false;
      }
    }

    Timer? timer;
    service.on('stopService').listen((_) {
      timer?.cancel();
      unawaited(service.stopSelf());
    });
    timer = Timer.periodic(_interval, (_) => unawaited(sendLocation()));
    unawaited(sendLocation());
  }

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    return true;
  }
}
