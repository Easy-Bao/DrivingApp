import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/core/telemetry/battery_optimization.dart';
import 'package:driver/src/core/telemetry/location_point_mapper.dart';
import 'package:driver/src/core/telemetry/location_spool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _backgroundTelemetryInterval = Duration(seconds: 10);
const _backgroundPresenceInterval = Duration(seconds: 20);
const _backgroundRideRequestInterval = Duration(seconds: 4);
const _backgroundInactivityTimeout = Duration(minutes: 3);
const _notificationChannelId = 'easyride_driver_location';
const _notificationId = 4801;

class BackgroundTelemetry({
  required this._apiBaseUri,
  required this._lifecycleCoordinator,
  FlutterBackgroundService? service,
  bool? enabled,
}) {
  final Uri _apiBaseUri;
  final FlutterBackgroundService _service;
  final bool _isEnabled;
  final AppLifecycleCoordinator _lifecycleCoordinator;
  bool _configured = false;

  this
    : _service = service ?? FlutterBackgroundService(),
      _isEnabled = enabled ?? false;

  bool get isEnabled => _isEnabled;

  static Future<void> stopExistingServiceForStartup() async {
    await _stopRunningService(FlutterBackgroundService());
  }

  Future<void> initialize() async {
    if (!_isEnabled || _configured) return;

    // The Android plugin persists its callback handle. Stop an instance from
    // an older build before configuring this isolate, otherwise the old
    // callback can continue running after a hot reinstall.
    await _stopRunningServiceBeforeConfigure();

    final configured = await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundTelemetryOnStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        initialNotificationTitle: 'EasyRide Driver',
        initialNotificationContent: 'Sharing location while you are online.',
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
    if (!_isEnabled) return;
    await initialize();
    await _waitForResumedActivity();
    await _ensureLocationAccess();
    final batteryOptimizationWarning =
        await BatteryOptimization.isOptimizationEnabled();
    var serviceWasStarted = false;
    if (!await _service.isRunning()) {
      final started = await _service.startService();
      if (!started) {
        throw StateError('Background telemetry service could not be started.');
      }
      serviceWasStarted = true;
    }
    await _configureService(
      serviceWasStarted: serviceWasStarted,
      batteryOptimizationWarning: batteryOptimizationWarning,
    );
  }

  Future<void> _configureService({
    required bool serviceWasStarted,
    required bool batteryOptimizationWarning,
  }) async {
    final configuration = <String, dynamic>{
      'baseUrl': _apiBaseUri.toString(),
      'appVisible': _lifecycleCoordinator.isForeground,
      'batteryOptimizationWarning': batteryOptimizationWarning,
    };
    _service.invoke('configure', configuration);
    if (!serviceWasStarted) return;

    // The plugin starts a separate isolate. The first event can arrive before
    // that isolate has registered its listener, so replay configuration after
    // short bounded delays. Reconfiguration is idempotent in the entrypoint.
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
    if (!_isEnabled) return;
    if (await _service.isRunning()) {
      _service.invoke('stopService');
    }
  }

  Future<void> setAppVisible(bool isVisible) async {
    if (!_isEnabled) return;
    try {
      if (await _service.isRunning()) {
        _service.invoke('setAppVisible', {'visible': isVisible});
      }
    } catch (error) {
      dev.log('Unable to update telemetry visibility: $error');
    }
  }
}

@pragma('vm:entry-point')
void backgroundTelemetryOnStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  final storage = const FlutterSecureStorage();
  final sessionStore = SessionStore(storage: storage);
  DriverBackgroundTelemetrySession(
    service: service,
    sessionStore: sessionStore,
    clearSessionFallback: () async {
      SharedPreferences? preferences;
      try {
        preferences = await SharedPreferences.getInstance();
      } catch (_) {}
      await SessionStore(
        storage: storage,
        preferences: preferences,
      ).clearSession();
    },
  ).start();
}

@visibleForTesting
class DriverBackgroundTelemetrySession {
  DriverBackgroundTelemetrySession({
    required this.service,
    SessionStore? sessionStore,
    LocationSpool? locationSpool,
    Dio Function(Uri baseUri, BaseOptions options)? createHttpClient,
    Future<Position> Function()? readCurrentPosition,
    this._clearSessionFallback,
    this._onUpdateNotification,
    DateTime Function()? now,
  }) : _sessionStore =
           sessionStore ?? SessionStore(storage: const FlutterSecureStorage()),
       _locationSpool = locationSpool ?? LocationSpool(),
       _createHttpClient = createHttpClient ?? _defaultHttpClient,
       _readCurrentPosition = readCurrentPosition ?? _defaultCurrentPosition,
       _now = now ?? DateTime.now;

  final ServiceInstance service;
  final SessionStore _sessionStore;
  final LocationSpool _locationSpool;
  final Dio Function(Uri baseUri, BaseOptions options) _createHttpClient;
  final Future<Position> Function() _readCurrentPosition;
  final Future<void> Function()? _clearSessionFallback;
  final Future<void> Function(String content)? _onUpdateNotification;
  final DateTime Function() _now;

  Dio? _telemetryClient;
  Dio? _refreshClient;
  RefreshableTokenProvider? _tokenProvider;
  Future<bool>? _onlineWorkCheck;
  bool _sending = false;
  bool _sendingPresence = false;
  bool _pollingRideRequests = false;
  bool _appIsVisible = false;
  bool _batteryOptimizationWarning = false;
  bool _isConfigured = false;
  Set<String> _activeRequestIds = <String>{};
  DateTime? _previousLocationSampleAt;
  Timer? _locationTimer;
  Timer? _presenceTimer;
  Timer? _requestTimer;
  StreamSubscription<Map<String, dynamic>?>? _configureSubscription;
  StreamSubscription<Map<String, dynamic>?>? _visibilitySubscription;
  StreamSubscription<Map<String, dynamic>?>? _stopSubscription;
  bool _isStopping = false;

  static Dio _defaultHttpClient(Uri _, BaseOptions options) => Dio(options);

  static Future<Position> _defaultCurrentPosition() =>
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 5),
        ),
      );

  static BaseOptions _createDioOptions(Uri baseUri) => BaseOptions(
    baseUrl: baseUri.toString(),
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  void start() {
    _configureSubscription = service.on('configure').listen(configure);
    _visibilitySubscription = service.on('setAppVisible').listen(setAppVisible);
    _stopSubscription = service.on('stopService').listen((_) {
      unawaited(shutdown());
    });
    _locationTimer = Timer.periodic(
      _backgroundTelemetryInterval,
      (_) => unawaited(sendLocation()),
    );
    _presenceTimer = Timer.periodic(
      _backgroundPresenceInterval,
      (_) => unawaited(sendOnlinePresence()),
    );
    _requestTimer = Timer.periodic(
      _backgroundRideRequestInterval,
      (_) => unawaited(pollRideRequests()),
    );
    unawaited(sendLocation());
    unawaited(sendOnlinePresence());
    unawaited(pollRideRequests());
  }

  void configure(Map<String, dynamic>? event) {
    if (_isStopping) return;
    _appIsVisible = event?['appVisible'] == true;
    _batteryOptimizationWarning = event?['batteryOptimizationWarning'] == true;
    final baseUrl = event?['baseUrl'] as String?;
    final parsed = Uri.tryParse(baseUrl ?? '');
    if (parsed == null || !_isValidTelemetryBaseUri(parsed)) {
      _clearClients();
      return;
    }

    unawaited(_updateNotification(_idleNotificationContent()));
    _closeClients();

    final options = _createDioOptions(parsed);
    final client = _createHttpClient(parsed, options);
    final refresh = _createHttpClient(parsed, options);
    final provider = RefreshableTokenProvider(
      readAccessToken: _sessionStore.readToken,
      readRefreshToken: _sessionStore.readRefreshToken,
      saveAccessToken: _sessionStore.saveToken,
      saveRefreshToken: _sessionStore.saveRefreshToken,
      clearSession: () async {
        final clearFallback = _clearSessionFallback;
        if (clearFallback != null) {
          await clearFallback();
          return;
        }
        await _sessionStore.clearSession();
      },
      hasActiveMission: () async {
        final activeRideId = await _sessionStore.readActiveRideId();
        return activeRideId != null && activeRideId.trim().isNotEmpty;
      },
      refreshClient: refresh,
      onSessionExpired: shutdown,
    );
    client.interceptors.add(
      ApiClientFactory.createAuthInterceptor(
        sessionStore: _sessionStore,
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

  void setAppVisible(Map<String, dynamic>? event) {
    if (_isStopping) return;
    _appIsVisible = event?['visible'] == true;
  }

  Future<void> shutdown() async {
    if (_isStopping) return;
    _isStopping = true;
    _locationTimer?.cancel();
    _presenceTimer?.cancel();
    _requestTimer?.cancel();
    _locationTimer = null;
    _presenceTimer = null;
    _requestTimer = null;
    _activeRequestIds = <String>{};
    _clearClients();

    try {
      await Future.wait([
        _configureSubscription?.cancel() ?? Future<void>.value(),
        _visibilitySubscription?.cancel() ?? Future<void>.value(),
        _stopSubscription?.cancel() ?? Future<void>.value(),
      ]);
    } catch (error) {
      dev.log('Unable to close telemetry event subscriptions: $error');
    }

    try {
      await service.stopSelf();
    } catch (error) {
      dev.log('Unable to stop driver telemetry service: $error');
    }
  }

  void _clearClients() {
    _isConfigured = false;
    _closeClients();
  }

  void _closeClients() {
    final client = _telemetryClient;
    final refresh = _refreshClient;
    _telemetryClient = null;
    _refreshClient = null;
    _tokenProvider = null;
    client?.close(force: true);
    refresh?.close(force: true);
  }

  ({Dio client, RefreshableTokenProvider provider})? _activeCredentials() {
    final client = _telemetryClient;
    final provider = _tokenProvider;
    if (_isStopping ||
        !_isConfigured ||
        _appIsVisible ||
        client == null ||
        provider == null) {
      return null;
    }
    return (client: client, provider: provider);
  }

  bool _canContinueWith(Dio client, RefreshableTokenProvider provider) {
    return !_isStopping &&
        _isConfigured &&
        !_appIsVisible &&
        identical(_telemetryClient, client) &&
        identical(_tokenProvider, provider);
  }

  static bool _hasCredential(String? value) =>
      value != null && value.isNotEmpty;

  String _idleNotificationContent() => _batteryOptimizationWarning
      ? 'Battery saver may delay location updates. Allow unrestricted battery use.'
      : 'Sharing location while you are online.';

  String _newRequestNotificationContent() => _batteryOptimizationWarning
      ? 'New ride request available. Battery saver may delay location updates.'
      : 'New ride request available.';

  Future<bool> _shouldContinueOnlineWork() {
    final inFlight = _onlineWorkCheck;
    if (inFlight != null) return inFlight;

    late final Future<bool> check;
    check = _performOnlineWorkCheck().whenComplete(() {
      if (identical(_onlineWorkCheck, check)) {
        _onlineWorkCheck = null;
      }
    });
    _onlineWorkCheck = check;
    return check;
  }

  Future<bool> _performOnlineWorkCheck() async {
    try {
      if (_isStopping) return false;
      final isOnline = await _sessionStore.readDriverOnlineStatus() == true;
      if (_isStopping || !isOnline) return false;

      if (!_appIsVisible) {
        final activeRideId = await _sessionStore.readActiveRideId();
        if (_isStopping) return false;
        if (activeRideId == null || activeRideId.trim().isEmpty) {
          final lastActive = await _sessionStore.readDriverLastActive();
          if (_isStopping) return false;
          if (lastActive == null ||
              _now().toUtc().difference(lastActive) >
                  _backgroundInactivityTimeout) {
            dev.log(
              'Background telemetry expiring online presence due to inactivity.',
            );
            await _sessionStore.saveDriverOnlineStatus(false);
            await _sessionStore.clearDriverLastActive();
            final client = _telemetryClient;
            if (!_isStopping && client != null) {
              final driverId = await _sessionStore.readDriverId();
              if (!_isStopping &&
                  identical(_telemetryClient, client) &&
                  _hasCredential(driverId)) {
                try {
                  await client.post<void>(
                    '/api/v1/drivers/${Uri.encodeComponent(driverId!)}/online',
                    data: {'is_online': false},
                  );
                } catch (_) {}
              }
            }
            unawaited(shutdown());
            return false;
          }
        }
      }
      return !_isStopping;
    } catch (error) {
      // If the local online intent cannot be read, fail closed. Continuing to
      // publish a heartbeat could resurrect an explicitly stopped driver.
      dev.log('Unable to read driver online intent: $error');
      return false;
    }
  }

  Future<void> _updateNotification(String content) async {
    final override = _onUpdateNotification;
    if (override != null) {
      await override(content);
      return;
    }
    final serviceInstance = service;
    if (serviceInstance is! AndroidServiceInstance) return;
    try {
      if (!await serviceInstance.isForegroundService()) return;
      await serviceInstance.setForegroundNotificationInfo(
        title: 'EasyRide Driver',
        content: content,
      );
    } catch (error) {
      dev.log('Unable to update telemetry notification: $error');
    }
  }

  Future<String?> _prepareDriverRequest(
    Dio client,
    RefreshableTokenProvider provider,
  ) async {
    if (!await _shouldContinueOnlineWork() ||
        !_canContinueWith(client, provider)) {
      return null;
    }
    final token = await provider.getToken();
    final driverId = await _sessionStore.readDriverId();
    if (!_canContinueWith(client, provider) ||
        !_hasCredential(token) ||
        !_hasCredential(driverId)) {
      return null;
    }
    return driverId;
  }

  Future<void> sendLocation() async {
    final active = _activeCredentials();
    if (active == null || _sending) return;
    final (:client, :provider) = active;

    _sending = true;
    try {
      if (!await _shouldContinueOnlineWork() ||
          !_canContinueWith(client, provider)) {
        return;
      }

      final token = await provider.getToken();
      if (!_canContinueWith(client, provider) || !_hasCredential(token)) {
        return;
      }

      final position = await _readCurrentPosition();
      if (!_canContinueWith(client, provider)) return;

      final point = locationPointFromPosition(position);
      final receivedAt = _now().toUtc();
      final sampleInterval = _previousLocationSampleAt == null
          ? null
          : point.observedAt.difference(_previousLocationSampleAt!);
      _previousLocationSampleAt = point.observedAt;

      await _locationSpool.enqueue(point);
      if (!_canContinueWith(client, provider)) return;

      var acknowledgedPointCount = 0;
      final flushSucceeded = await _locationSpool.flush((spooledPoint) async {
        if (!_canContinueWith(client, provider)) return false;
        try {
          final response = await client.post<void>(
            '/api/v1/telemetry/location',
            data: {
              'latitude': spooledPoint.latitude,
              'longitude': spooledPoint.longitude,
              'observed_at': spooledPoint.observedAt.toUtc().toIso8601String(),
              'heading': spooledPoint.heading,
              'speed': spooledPoint.speed,
            },
          );
          final acknowledged =
              response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 202;
          if (acknowledged) acknowledgedPointCount++;
          return acknowledged;
        } on DioException catch (error) {
          dev.log(
            'Driver telemetry request failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
          );
          return false;
        }
      });
      if (!kReleaseMode) {
        dev.log(
          'sample_interval_ms=${sampleInterval?.inMilliseconds ?? -1} '
          'sample_age_ms=${receivedAt.difference(point.observedAt).inMilliseconds} '
          'accuracy_m=${position.accuracy.toStringAsFixed(1)} '
          'acknowledged_points=$acknowledgedPointCount '
          'flush_succeeded=$flushSucceeded',
          name: 'easyride.performance.driver.location',
          time: receivedAt,
        );
      }
    } on DioException catch (error) {
      dev.log(
        'Driver telemetry request failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
      );
    } catch (_) {
      dev.log('Driver telemetry collection failed.');
    } finally {
      _sending = false;
    }
  }

  Future<void> pollRideRequests() async {
    final active = _activeCredentials();
    if (active == null || _pollingRideRequests) return;
    final (:client, :provider) = active;

    _pollingRideRequests = true;
    try {
      final driverId = await _prepareDriverRequest(client, provider);
      if (driverId == null) return;

      final response = await client.get<List<dynamic>>('/api/v1/bids/active');
      if (!_canContinueWith(client, provider)) return;

      final requestIds = <String>{};
      for (final item in response.data ?? const <dynamic>[]) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id']?.toString().trim();
        if (id != null && id.isNotEmpty) requestIds.add(id);
      }

      final hasNewRequest = requestIds.difference(_activeRequestIds).isNotEmpty;
      _activeRequestIds = requestIds;
      if (hasNewRequest) {
        await _updateNotification(_newRequestNotificationContent());
      } else if (requestIds.isEmpty) {
        await _updateNotification(_idleNotificationContent());
      }
    } on DioException catch (error) {
      dev.log(
        'Driver request polling failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
      );
    } catch (_) {
      dev.log('Driver request polling failed.');
    } finally {
      _pollingRideRequests = false;
    }
  }

  Future<void> sendOnlinePresence() async {
    final active = _activeCredentials();
    if (active == null || _sendingPresence) return;
    final (:client, :provider) = active;

    _sendingPresence = true;
    try {
      final driverId = await _prepareDriverRequest(client, provider);
      if (driverId == null) return;

      final response = await client.post<void>(
        '/api/v1/drivers/${Uri.encodeComponent(driverId)}/online',
        data: {'is_online': true},
      );
      if (response.statusCode != 200) {
        dev.log(
          'Driver presence heartbeat was rejected: ${response.statusCode}',
        );
      }
    } on DioException catch (error) {
      dev.log(
        'Driver presence heartbeat failed: ${error.type.name}/${error.response?.statusCode ?? 'network'}',
      );
    } catch (_) {
      dev.log('Driver presence heartbeat failed.');
    } finally {
      _sendingPresence = false;
    }
  }
}

bool _isValidTelemetryBaseUri(Uri uri) {
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

@pragma('vm:entry-point')
bool backgroundTelemetryOnIosBackground(ServiceInstance service) {
  return true;
}
