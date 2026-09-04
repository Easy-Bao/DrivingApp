import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:foundation/foundation.dart';

const _backgroundTelemetryInterval = Duration(seconds: 10);
const _backgroundRideRequestInterval = Duration(seconds: 4);
const _notificationChannelId = 'easyride_driver_location';
const _notificationId = 4801;

class DriverBackgroundTelemetry({
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
    final configuration = <String, dynamic>{
      'baseUrl': _apiBaseUri.toString(),
      'appVisible': _lifecycleCoordinator.isForeground,
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

  final storage = const FlutterSecureStorage(
    // Keep the Android storage mode explicit for existing encrypted entries.
    // ignore: deprecated_member_use
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final sessionStore = DriverSessionStore(storage: storage);
  Dio? telemetryClient;
  RefreshableTokenProvider? tokenProvider;
  var sending = false;
  var pollingRideRequests = false;
  var appIsVisible = false;
  var isConfigured = false;
  var activeRequestIds = <String>{};
  Timer? locationTimer;
  Timer? requestTimer;
  StreamSubscription<Map<String, dynamic>?>? configureSubscription;
  StreamSubscription<Map<String, dynamic>?>? visibilitySubscription;
  StreamSubscription<Map<String, dynamic>?>? stopSubscription;
  var isStopping = false;

  Future<void> shutdown() async {
    if (isStopping) return;
    isStopping = true;
    locationTimer?.cancel();
    requestTimer?.cancel();
    locationTimer = null;
    requestTimer = null;
    activeRequestIds = <String>{};
    isConfigured = false;

    final client = telemetryClient;
    telemetryClient = null;
    tokenProvider = null;
    client?.close(force: true);

    try {
      await Future.wait([
        configureSubscription?.cancel() ?? Future<void>.value(),
        visibilitySubscription?.cancel() ?? Future<void>.value(),
        stopSubscription?.cancel() ?? Future<void>.value(),
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

  configureSubscription = service.on('configure').listen((event) {
    if (isStopping) return;
    appIsVisible = event?['appVisible'] == true;
    final baseUrl = event?['baseUrl'] as String?;
    final parsed = Uri.tryParse(baseUrl ?? '');
    if (parsed == null || !_isValidTelemetryBaseUri(parsed)) {
      isConfigured = false;
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
      readAccessToken: sessionStore.readToken,
      readRefreshToken: sessionStore.readRefreshToken,
      saveAccessToken: sessionStore.saveToken,
      saveRefreshToken: sessionStore.saveRefreshToken,
      clearSession: sessionStore.clearSession,
      refreshClient: client,
    );
    isConfigured = true;
  });
  visibilitySubscription = service.on('setAppVisible').listen((event) {
    if (isStopping) return;
    appIsVisible = event?['visible'] == true;
  });

  Future<void> sendLocation() async {
    final client = telemetryClient;
    final provider = tokenProvider;
    if (!isConfigured ||
        appIsVisible ||
        sending ||
        client == null ||
        provider == null) {
      return;
    }

    final token = await provider.getToken();
    if (token == null || token.isEmpty) {
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
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading.isFinite && position.heading >= 0
              ? position.heading.clamp(0, 360)
              : 0,
          'speed': position.speed.isFinite && position.speed >= 0
              ? position.speed.clamp(0, 200)
              : 0,
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
    if (service is! AndroidServiceInstance) return;
    try {
      if (!await service.isForegroundService()) return;
      await service.setForegroundNotificationInfo(
        title: 'EasyRide Driver',
        content: content,
      );
    } catch (error) {
      dev.log('Unable to update telemetry notification: $error');
    }
  }

  Future<void> pollRideRequests() async {
    final client = telemetryClient;
    final provider = tokenProvider;
    if (!isConfigured ||
        appIsVisible ||
        pollingRideRequests ||
        client == null ||
        provider == null) {
      return;
    }

    final token = await provider.getToken();
    final driverId = await sessionStore.readDriverId();
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

  stopSubscription = service.on('stopService').listen((_) {
    unawaited(shutdown());
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
