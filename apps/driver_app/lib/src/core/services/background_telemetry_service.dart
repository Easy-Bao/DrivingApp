import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/core/constants/storage_keys.dart';

const _backgroundTelemetryInterval = Duration(seconds: 10);
const _backgroundRideRequestInterval = Duration(seconds: 4);

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
  var pollingRideRequests = false;
  var activeRequestIds = <String>{};

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

  Future<void> updateNotification(String content) async {
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: 'EasyRide Driver',
        content: content,
      );
    }
  }

  Future<void> pollRideRequests() async {
    final client = telemetryClient;
    if (pollingRideRequests || client == null) return;

    final token = await storage.read(key: StorageKeys.jwtToken);
    final driverId = await storage.read(key: StorageKeys.driverId);
    if (token == null ||
        token.isEmpty ||
        driverId == null ||
        driverId.isEmpty) {
      return;
    }

    pollingRideRequests = true;
    try {
      final response = await client.get<List<dynamic>>(
        '/api/v1/bids/active',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final requestIds = <String>{};
      for (final item in response.data ?? const <dynamic>[]) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id']?.toString().trim();
        if (id != null && id.isNotEmpty) requestIds.add(id);
      }

      final hasNewRequest = requestIds.difference(activeRequestIds).isNotEmpty;
      activeRequestIds = requestIds;
      if (hasNewRequest) {
        await updateNotification('New ride request available.');
      } else if (requestIds.isEmpty) {
        await updateNotification('Sharing location while you are online.');
      }
    } on DioException catch (error) {
      dev.log(
        'Driver request polling failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
      );
    } catch (_) {
      dev.log('Driver request polling failed.');
    } finally {
      pollingRideRequests = false;
    }
  }

  Timer? locationTimer;
  Timer? requestTimer;
  service.on('stopService').listen((_) {
    locationTimer?.cancel();
    requestTimer?.cancel();
    activeRequestIds = <String>{};
    telemetryClient?.close(force: true);
    telemetryClient = null;
    unawaited(service.stopSelf());
  });
  locationTimer = Timer.periodic(
    _backgroundTelemetryInterval,
    (_) => unawaited(sendLocation()),
  );
  requestTimer = Timer.periodic(
    _backgroundRideRequestInterval,
    (_) => unawaited(pollRideRequests()),
  );
  unawaited(sendLocation());
  unawaited(pollRideRequests());
}

bool _isValidTelemetryBaseUri(Uri uri) {
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

@pragma('vm:entry-point')
bool backgroundTelemetryOnIosBackground(ServiceInstance service) {
  return true;
}
