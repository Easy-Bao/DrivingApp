import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:passenger/src/infrastructure/session/passenger_storage_keys.dart';

const _backgroundTelemetryInterval = Duration(seconds: 10);
const _notificationChannelId = 'easyride_passenger_location';
const _notificationId = 4802;

class PassengerBackgroundTelemetry({
  required this._apiBaseUri,
  required this._lifecycleCoordinator,
  FlutterBackgroundService? service,
}) {
  final Uri _apiBaseUri;
  final FlutterBackgroundService _service;
  final AppLifecycleCoordinator _lifecycleCoordinator;
  bool _configured = false;

  this : _service = service ?? FlutterBackgroundService();

  static Future<void> stopExistingServiceForStartup() async {
    await _stopRunningService(FlutterBackgroundService());
  }

  Future<void> initialize() async {
    if (_configured) return;

    await _stopRunningServiceBeforeConfigure();

    final configured = await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundTelemetryOnStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        initialNotificationTitle: 'EasyRide Passenger',
        initialNotificationContent: 'Sharing location during your active ride.',
        notificationChannelId: _notificationChannelId,
        foregroundServiceNotificationId: _notificationId,
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
    await _waitForResumedActivity();
    await _ensureLocationAccess();
    if (!await _service.isRunning()) {
      final started = await _service.startService();
      if (!started) {
        throw StateError('Background telemetry service could not be started.');
      }
    }
    _service.invoke('configure', {'baseUrl': _apiBaseUri.toString()});
  }

  Future<void> _stopRunningServiceBeforeConfigure() async {
    await _stopRunningService(_service);
  }

  static Future<void> _stopRunningService(
    FlutterBackgroundService service,
  ) async {
    try {
      if (!await service.isRunning()) return;

      service.invoke('stopService');
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (await service.isRunning() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } catch (error) {
      dev.log('Unable to stop an existing telemetry service: $error');
    }
  }

  Future<void> _waitForResumedActivity() async {
    if (_lifecycleCoordinator.isForeground) return;

    final resumed = Completer<void>();
    late final StreamSubscription<AppLifecycleStatus> subscription;
    subscription = _lifecycleCoordinator.changes.listen((status) {
      if (status != AppLifecycleStatus.foreground) return;
      if (!resumed.isCompleted) resumed.complete();
    });
    if (_lifecycleCoordinator.isForeground && !resumed.isCompleted) {
      resumed.complete();
    }
    try {
      await resumed.future.timeout(const Duration(seconds: 15));
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _ensureLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError('Location permission is not granted.');
    }
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
  RefreshableTokenProvider? tokenProvider;
  var sending = false;

  service.on('configure').listen((event) {
    final baseUrl = event?['baseUrl'] as String?;
    final parsed = Uri.tryParse(baseUrl ?? '');
    if (parsed == null || !_isValidTelemetryBaseUri(parsed)) {
      telemetryClient?.close(force: true);
      telemetryClient = null;
      tokenProvider = null;
      return;
    }
    telemetryClient?.close(force: true);
    final client = Dio(
      BaseOptions(
        baseUrl: parsed.toString(),
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    telemetryClient = client;
    tokenProvider = RefreshableTokenProvider(
      readAccessToken: () => storage.read(key: PassengerStorageKeys.jwtToken),
      readRefreshToken: () =>
          storage.read(key: PassengerStorageKeys.refreshToken),
      saveAccessToken: (token) =>
          storage.write(key: PassengerStorageKeys.jwtToken, value: token),
      saveRefreshToken: (token) =>
          storage.write(key: PassengerStorageKeys.refreshToken, value: token),
      clearSession: storage.deleteAll,
      refreshClient: client,
    );
  });

  Future<void> sendLocation() async {
    final client = telemetryClient;
    final provider = tokenProvider;
    if (sending || client == null || provider == null) return;

    final token = await provider.getToken();
    final rideId = await storage.read(key: PassengerStorageKeys.activeRideId);
    if (token == null || token.isEmpty || rideId == null || rideId.isEmpty) {
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
        '/api/v1/telemetry/passenger/${Uri.encodeComponent(rideId)}',
        data: {'latitude': position.latitude, 'longitude': position.longitude},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (error) {
      dev.log(
        'Passenger telemetry request failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
      );
    } catch (_) {
      dev.log('Passenger telemetry collection failed.');
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
