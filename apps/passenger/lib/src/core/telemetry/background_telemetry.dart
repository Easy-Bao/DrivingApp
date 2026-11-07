import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:passenger/src/core/network/auth_interceptor.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/session/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _backgroundTelemetryInterval = Duration(seconds: 10);
const _notificationChannelId = 'easyride_passenger_location';
const _notificationId = 4802;

class BackgroundTelemetry {
  BackgroundTelemetry({
    required this.apiBaseUri,
    required this.lifecycleCoordinator,
    FlutterBackgroundService? service,
  }) : _service = service ?? FlutterBackgroundService();

  final Uri apiBaseUri;
  final FlutterBackgroundService _service;
  final AppLifecycleCoordinator lifecycleCoordinator;
  bool _configured = false;

  Uri get _apiBaseUri => apiBaseUri;
  AppLifecycleCoordinator get _lifecycleCoordinator => lifecycleCoordinator;

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
    var serviceWasStarted = false;
    if (!await _service.isRunning()) {
      final started = await _service.startService();
      if (!started) {
        throw StateError('Background telemetry service could not be started.');
      }
      serviceWasStarted = true;
    }
    await _configureService(serviceWasStarted: serviceWasStarted);
  }

  Future<void> _configureService({required bool serviceWasStarted}) async {
    final configuration = <String, dynamic>{'baseUrl': _apiBaseUri.toString()};
    _service.invoke('configure', configuration);
    if (!serviceWasStarted) return;

    for (final delay in const [
      Duration(milliseconds: 200),
      Duration(milliseconds: 500),
    ]) {
      await Future<void>.delayed(delay);
      if (!await _service.isRunning()) return;
      _service.invoke('configure', configuration);
    }
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

  Future<void> stopRideTelemetry() => stop();
}

@pragma('vm:entry-point')
void backgroundTelemetryOnStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  final storage = const FlutterSecureStorage();
  final sessionStore = SessionStore(storage: storage);
  Dio? telemetryClient;
  Dio? refreshClient;
  RefreshableTokenProvider? tokenProvider;
  var sending = false;
  var isConfigured = false;
  Timer? timer;
  StreamSubscription<Map<String, dynamic>?>? configureSubscription;
  StreamSubscription<Map<String, dynamic>?>? stopSubscription;
  var isStopping = false;

  Future<void> shutdown() async {
    if (isStopping) return;
    isStopping = true;
    isConfigured = false;
    timer?.cancel();
    timer = null;

    final client = telemetryClient;
    final refresh = refreshClient;
    telemetryClient = null;
    refreshClient = null;
    tokenProvider = null;
    client?.close(force: true);
    refresh?.close(force: true);

    try {
      await Future.wait([
        configureSubscription?.cancel() ?? Future<void>.value(),
        stopSubscription?.cancel() ?? Future<void>.value(),
      ]);
    } catch (error) {
      dev.log('Unable to close telemetry event subscriptions: $error');
    }

    try {
      await service.stopSelf();
    } catch (error) {
      dev.log('Unable to stop passenger telemetry service: $error');
    }
  }

  configureSubscription = service.on('configure').listen((event) {
    if (isStopping) return;
    final baseUrl = event?['baseUrl'] as String?;
    final parsed = Uri.tryParse(baseUrl ?? '');
    if (parsed == null || !_isValidTelemetryBaseUri(parsed)) {
      isConfigured = false;
      telemetryClient?.close(force: true);
      refreshClient?.close(force: true);
      telemetryClient = null;
      refreshClient = null;
      tokenProvider = null;
      return;
    }
    telemetryClient?.close(force: true);
    refreshClient?.close(force: true);
    final client = Dio(
      BaseOptions(
        baseUrl: parsed.toString(),
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final refresh = Dio(
      BaseOptions(
        baseUrl: parsed.toString(),
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final provider = RefreshableTokenProvider(
      readAccessToken: sessionStore.readToken,
      readRefreshToken: sessionStore.readRefreshToken,
      saveAccessToken: sessionStore.saveToken,
      saveRefreshToken: sessionStore.saveRefreshToken,
      clearSession: () async {
        await sessionStore.clearSession();
        try {
          final preferences = await SharedPreferences.getInstance();
          for (final key in StorageKeys.profileCacheKeys) {
            await preferences.remove(key);
          }
        } catch (_) {}
      },
      hasActiveMission: () async {
        final activeRideId = await sessionStore.readActiveRideId();
        return activeRideId != null && activeRideId.trim().isNotEmpty;
      },
      refreshClient: refresh,
      onSessionExpired: shutdown,
    );
    client.interceptors.add(
      AuthInterceptor(
        sessionStore,
        dio: client,
        allowedBaseUri: parsed,
        tokenProvider: provider,
      ),
    );
    telemetryClient = client;
    refreshClient = refresh;
    tokenProvider = provider;
    isConfigured = true;
  });

  Future<void> sendLocation() async {
    final client = telemetryClient;
    final provider = tokenProvider;
    if (!isConfigured || sending || client == null || provider == null) return;

    final token = await provider.getToken();
    final rideId = (await sessionStore.readActiveRideId())?.trim();
    if (token == null || token.isEmpty || rideId == null || rideId.isEmpty) {
      return;
    }

    sending = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await client.post<void>(
        '/api/v1/telemetry/passenger/${Uri.encodeComponent(rideId)}',
        data: {'latitude': position.latitude, 'longitude': position.longitude},
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

  stopSubscription = service.on('stopService').listen((_) {
    unawaited(shutdown());
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
