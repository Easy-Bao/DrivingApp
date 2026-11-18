import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
    final configuration = <String, dynamic>{'baseUrl': apiBaseUri.toString()};
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
    if (lifecycleCoordinator.isForeground) return;

    final resumed = Completer<void>();
    late final StreamSubscription<AppLifecycleStatus> subscription;
    subscription = lifecycleCoordinator.changes.listen((status) {
      if (status != AppLifecycleStatus.foreground) return;
      if (!resumed.isCompleted) resumed.complete();
    });
    if (lifecycleCoordinator.isForeground && !resumed.isCompleted) {
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

/// Manages background telemetry configuration, periodic location dispatch,
/// and service shutdown inside the background service isolate.
@visibleForTesting
class BackgroundTelemetrySession {
  BackgroundTelemetrySession({
    required this.service,
    SessionStore? sessionStore,
    Dio Function(Uri baseUri)? createHttpClient,
    Future<Position> Function()? readCurrentPosition,
    Future<void> Function()? clearProfileCache,
  }) : _sessionStore =
           sessionStore ?? SessionStore(storage: const FlutterSecureStorage()),
       _createHttpClient = createHttpClient ?? _defaultTelemetryHttpClient,
       _readCurrentPosition =
           readCurrentPosition ?? _defaultReadCurrentPosition,
       _clearProfileCache = clearProfileCache ?? _defaultClearProfileCache;

  final ServiceInstance service;
  final SessionStore _sessionStore;
  final Dio Function(Uri baseUri) _createHttpClient;
  final Future<Position> Function() _readCurrentPosition;
  final Future<void> Function() _clearProfileCache;

  Dio? _telemetryClient;
  Dio? _refreshClient;
  RefreshableTokenProvider? _tokenProvider;
  bool _sending = false;
  bool _isConfigured = false;
  bool _isStopping = false;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>?>? _configureSubscription;
  StreamSubscription<Map<String, dynamic>?>? _stopSubscription;

  void start() {
    _configureSubscription = service.on('configure').listen(configure);
    _stopSubscription = service.on('stopService').listen((_) {
      unawaited(shutdown());
    });
    _timer = Timer.periodic(
      _backgroundTelemetryInterval,
      (_) => unawaited(sendLocation()),
    );
    unawaited(sendLocation());
  }

  void configure(Map<String, dynamic>? event) {
    if (_isStopping) return;
    final baseUrl = event?['baseUrl'] as String?;
    final parsed = Uri.tryParse(baseUrl ?? '');
    if (parsed == null || !_isValidTelemetryBaseUri(parsed)) {
      _isConfigured = false;
      _closeClients();
      _tokenProvider = null;
      return;
    }

    _closeClients();
    final client = _createHttpClient(parsed);
    final refresh = _createHttpClient(parsed);
    final provider = RefreshableTokenProvider(
      readAccessToken: _sessionStore.readToken,
      readRefreshToken: _sessionStore.readRefreshToken,
      saveAccessToken: _sessionStore.saveToken,
      saveRefreshToken: _sessionStore.saveRefreshToken,
      clearSession: () async {
        await _sessionStore.clearSession();
        await _clearProfileCache();
      },
      hasActiveMission: () async {
        final activeRideId = await _sessionStore.readActiveRideId();
        return activeRideId != null && activeRideId.trim().isNotEmpty;
      },
      refreshClient: refresh,
      onSessionExpired: shutdown,
    );
    client.interceptors.add(
      AuthInterceptor(
        _sessionStore,
        dio: client,
        allowedBaseUri: parsed,
        tokenProvider: provider,
      ),
    );
    _telemetryClient = client;
    _refreshClient = refresh;
    _tokenProvider = provider;
    _isConfigured = true;
  }

  Future<void> sendLocation() async {
    final client = _telemetryClient;
    final provider = _tokenProvider;
    if (_isStopping ||
        !_isConfigured ||
        _sending ||
        client == null ||
        provider == null) {
      return;
    }

    _sending = true;
    try {
      final token = await provider.getToken();
      final rideId = (await _sessionStore.readActiveRideId())?.trim();
      if (_isStopping ||
          !_isConfigured ||
          !identical(_telemetryClient, client) ||
          token == null ||
          token.isEmpty ||
          rideId == null ||
          rideId.isEmpty) {
        return;
      }

      final position = await _readCurrentPosition();
      if (_isStopping ||
          !_isConfigured ||
          !identical(_telemetryClient, client)) {
        return;
      }
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
      _sending = false;
    }
  }

  Future<void> shutdown() async {
    if (_isStopping) return;
    _isStopping = true;
    _isConfigured = false;
    _timer?.cancel();
    _timer = null;

    _tokenProvider = null;
    _closeClients();

    try {
      await Future.wait([
        _configureSubscription?.cancel() ?? Future<void>.value(),
        _stopSubscription?.cancel() ?? Future<void>.value(),
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

  void _closeClients() {
    final client = _telemetryClient;
    final refresh = _refreshClient;
    _telemetryClient = null;
    _refreshClient = null;
    client?.close(force: true);
    refresh?.close(force: true);
  }
}

Dio _defaultTelemetryHttpClient(Uri baseUri) => Dio(
  BaseOptions(
    baseUrl: baseUri.toString(),
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

Future<Position> _defaultReadCurrentPosition() => Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
    timeLimit: Duration(seconds: 5),
  ),
);

Future<void> _defaultClearProfileCache() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    for (final key in StorageKeys.profileCacheKeys) {
      await preferences.remove(key);
    }
  } catch (_) {}
}

@pragma('vm:entry-point')
void backgroundTelemetryOnStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  BackgroundTelemetrySession(service: service).start();
}

bool _isValidTelemetryBaseUri(Uri uri) {
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

@pragma('vm:entry-point')
bool backgroundTelemetryOnIosBackground(ServiceInstance service) {
  return true;
}
