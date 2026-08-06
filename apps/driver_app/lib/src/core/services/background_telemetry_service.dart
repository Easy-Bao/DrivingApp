import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/core/constants/storage_keys.dart';

const _backgroundTelemetryInterval = Duration(seconds: 10);

class BackgroundTelemetryService {
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
        onStart: backgroundTelemetryOnStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        initialNotificationTitle: 'EasyRide Driver',
        initialNotificationContent: 'Sharing location while you are online.',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: backgroundTelemetryOnStart,
        onBackground: backgroundTelemetryOnIosBackground,
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
}

@pragma('vm:entry-point')
void backgroundTelemetryOnStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  final storage = const FlutterSecureStorage();
  Dio? telemetryClient;
  var sending = false;

  service.on('configure').listen((event) {
    final baseUrl = event?['baseUrl'] as String?;
    final parsed = Uri.tryParse(baseUrl ?? '');
    if (parsed == null || !_isValidTelemetryBaseUri(parsed)) {
      telemetryClient?.close(force: true);
      telemetryClient = null;
      return;
    }
    telemetryClient?.close(force: true);
    telemetryClient = Dio(
      BaseOptions(
        baseUrl: parsed.toString(),
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  });

  Future<void> sendLocation() async {
    final client = telemetryClient;
    if (sending || client == null) return;

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
      await client.post<void>(
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
      dev.log(
        'Driver telemetry request failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
      );
    } catch (_) {
      dev.log('Driver telemetry collection failed.');
    } finally {
      sending = false;
    }
  }

  Timer? timer;
  service.on('stopService').listen((_) {
    timer?.cancel();
    telemetryClient?.close(force: true);
    telemetryClient = null;
    unawaited(service.stopSelf());
  });
  timer = Timer.periodic(
    _backgroundTelemetryInterval,
    (_) => unawaited(sendLocation()),
  );
  unawaited(sendLocation());
}

bool _isValidTelemetryBaseUri(Uri uri) {
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

@pragma('vm:entry-point')
bool backgroundTelemetryOnIosBackground(ServiceInstance service) {
  return true;
}
