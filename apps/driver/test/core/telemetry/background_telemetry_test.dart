import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/core/telemetry/background_telemetry.dart';
import 'package:driver/src/core/telemetry/location_spool.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockServiceInstance extends Mock implements ServiceInstance {}

class _MockSessionStore extends Mock implements SessionStore {}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.data,
  });

  final String method;
  final Uri uri;
  final Map<String, Object?> headers;
  final Object? data;
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final List<_CapturedRequest> requests = [];
  Future<ResponseBody> Function(RequestOptions options)? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _CapturedRequest(
        method: options.method,
        uri: options.uri,
        headers: Map<String, Object?>.from(options.headers),
        data: options.data,
      ),
    );
    final customHandler = onFetch;
    if (customHandler != null) {
      return customHandler(options);
    }
    if (options.uri.path == '/api/v1/bids/active') {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{"status":"ok"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Position _testPosition({
  double latitude = 14.5995,
  double longitude = 120.9842,
  DateTime? timestamp,
}) => Position(
  longitude: longitude,
  latitude: latitude,
  timestamp: timestamp ?? DateTime.utc(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 90,
  headingAccuracy: 1,
  speed: 8,
  speedAccuracy: 1,
);

void main() {
  late _MockServiceInstance service;
  late _MockSessionStore sessionStore;
  late _FakeHttpClientAdapter adapter;
  late LocationSpool spool;
  late List<String> notifications;
  var gpsReadCount = 0;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = _MockServiceInstance();
    sessionStore = _MockSessionStore();
    adapter = _FakeHttpClientAdapter();
    spool = LocationSpool();
    notifications = <String>[];
    gpsReadCount = 0;

    when(() => service.on(any()))
        .thenAnswer((_) => const Stream<Map<String, dynamic>?>.empty());
    when(() => service.stopSelf()).thenAnswer((_) async {});

    when(() => sessionStore.readDriverOnlineStatus())
        .thenAnswer((_) async => true);
    when(() => sessionStore.saveDriverOnlineStatus(any()))
        .thenAnswer((_) async {});
    when(() => sessionStore.clearDriverLastActive()).thenAnswer((_) async {});
    when(() => sessionStore.readDriverLastActive())
        .thenAnswer((_) async => DateTime.now().toUtc());
    when(() => sessionStore.readActiveRideId())
        .thenAnswer((_) async => 'ride-42');
    when(() => sessionStore.readToken()).thenAnswer((_) async => 'token-123');
    when(() => sessionStore.readRefreshToken()).thenAnswer((_) async => null);
    when(() => sessionStore.readDriverId()).thenAnswer((_) async => 'driver-7');
    when(() => sessionStore.saveToken(any())).thenAnswer((_) async {});
    when(() => sessionStore.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => sessionStore.clearSession()).thenAnswer((_) async {});
  });

  DriverBackgroundTelemetrySession createSession({
    Future<Position> Function()? readCurrentPosition,
    DateTime Function()? now,
  }) => DriverBackgroundTelemetrySession(
    service: service,
    sessionStore: sessionStore,
    locationSpool: spool,
    createHttpClient: (_, options) => Dio(options)..httpClientAdapter = adapter,
    readCurrentPosition:
        readCurrentPosition ??
        () async {
          gpsReadCount += 1;
          return _testPosition();
        },
    clearSessionFallback: () async {},
    onUpdateNotification: (content) async => notifications.add(content),
    now: now ?? DateTime.now,
  );

  group('DriverBackgroundTelemetrySession', () {
    test(
      'posts spooled coordinates with bearer header when configured',
      () async {
        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        await session.sendLocation();

        expect(gpsReadCount, 1);
        final locationRequests = adapter.requests
            .where((r) => r.uri.path == '/api/v1/telemetry/location')
            .toList();
        expect(locationRequests, hasLength(1));
        final request = locationRequests.single;
        expect(request.headers['Authorization'], 'Bearer token-123');
        expect(request.data, <String, Object?>{
          'latitude': 14.5995,
          'longitude': 120.9842,
          'observed_at': DateTime.utc(2026).toIso8601String(),
          'heading': 90.0,
          'speed': 8.0,
        });
      },
    );

    test(
      'drops overlapping sendLocation call while online check is suspended',
      () async {
        final onlineStatusCompleter = Completer<bool?>();
        when(() => sessionStore.readDriverOnlineStatus())
            .thenAnswer((_) => onlineStatusCompleter.future);

        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        final firstSend = session.sendLocation();
        await Future<void>.delayed(Duration.zero);
        await session.sendLocation();

        verify(() => sessionStore.readDriverOnlineStatus()).called(1);
        expect(gpsReadCount, 0);

        onlineStatusCompleter.complete(true);
        await firstSend;

        expect(gpsReadCount, 1);
        expect(
          adapter.requests.where(
            (r) => r.uri.path == '/api/v1/telemetry/location',
          ),
          hasLength(1),
        );
      },
    );

    test(
      'coalesces concurrent startup online checks when inactivity expires',
      () async {
        final onlineStatusCompleter = Completer<bool?>();
        final staleLastActive = DateTime.utc(2026, 1, 1, 10, 0);
        when(() => sessionStore.readDriverOnlineStatus())
            .thenAnswer((_) => onlineStatusCompleter.future);
        when(() => sessionStore.readActiveRideId()).thenAnswer((_) async => '');
        when(() => sessionStore.readDriverLastActive())
            .thenAnswer((_) async => staleLastActive);

        final session = createSession(
          now: () => staleLastActive.add(const Duration(minutes: 5)),
        );
        session.configure({'baseUrl': 'https://api.example.com'});

        final sends = Future.wait([
          session.sendLocation(),
          session.sendOnlinePresence(),
          session.pollRideRequests(),
        ]);
        await Future<void>.delayed(Duration.zero);
        onlineStatusCompleter.complete(true);
        await sends;
        await untilCalled(() => service.stopSelf());

        verify(() => sessionStore.readDriverOnlineStatus()).called(1);
        verify(() => sessionStore.saveDriverOnlineStatus(false)).called(1);
        verify(() => service.stopSelf()).called(1);
        final offlinePosts = adapter.requests
            .where((r) => r.uri.path == '/api/v1/drivers/driver-7/online')
            .toList();
        expect(offlinePosts, hasLength(1));
        expect(offlinePosts.single.data, <String, Object?>{'is_online': false});
      },
    );

    test(
      'skips spooling and POST when shutdown occurs during GPS read',
      () async {
        final gpsCompleter = Completer<Position>();
        final session = createSession(
          readCurrentPosition: () {
            gpsReadCount += 1;
            return gpsCompleter.future;
          },
        );
        session.configure({'baseUrl': 'https://api.example.com'});

        final firstSend = session.sendLocation();
        await Future<void>.delayed(Duration.zero);

        await session.shutdown();
        gpsCompleter.complete(_testPosition());
        await firstSend;

        verify(() => service.stopSelf()).called(1);
        expect(gpsReadCount, 1);
        expect(adapter.requests, isEmpty);
        final spooled = <LocationPoint>[];
        await spool.flush((point) async {
          spooled.add(point);
          return true;
        });
        expect(spooled, isEmpty);
      },
    );

    test('skips bid notification updates when shutdown happens during request poll', () async {
      final pollCompleter = Completer<ResponseBody>();
      adapter.onFetch = (options) {
        if (options.uri.path == '/api/v1/bids/active') {
          return pollCompleter.future;
        }
        return Future.value(ResponseBody.fromString('{}', 200));
      };

      final session = createSession();
      session.configure({'baseUrl': 'https://api.example.com'});
      notifications.clear();

      final pollFuture = session.pollRideRequests();
      await Future<void>.delayed(Duration.zero);

      await session.shutdown();
      pollCompleter.complete(ResponseBody.fromString('[{"id":"bid-1"}]', 200));
      await pollFuture;

      expect(notifications, isEmpty);
      verify(() => service.stopSelf()).called(1);
    });

    test(
      'skips GPS read when app becomes visible while token read is suspended',
      () async {
        final tokenCompleter = Completer<String?>();
        when(() => sessionStore.readToken())
            .thenAnswer((_) => tokenCompleter.future);

        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        final firstSend = session.sendLocation();
        await Future<void>.delayed(Duration.zero);

        session.setAppVisible({'visible': true});
        tokenCompleter.complete('token-123');
        await firstSend;

        expect(gpsReadCount, 0);
        expect(adapter.requests, isEmpty);
      },
    );

    test('updates notification for new active bid requests and resets when cleared', () async {
      var payload = '[{"id":"bid-1"}]';
      adapter.onFetch = (options) {
        if (options.uri.path == '/api/v1/bids/active') {
          return Future.value(
            ResponseBody.fromString(
              payload,
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
          );
        }
        return Future.value(ResponseBody.fromString('{}', 200));
      };

      final session = createSession();
      session.configure({'baseUrl': 'https://api.example.com'});
      notifications.clear();

      await session.pollRideRequests();
      expect(notifications, <String>['New ride request available.']);

      payload = '[]';
      await session.pollRideRequests();
      expect(notifications, <String>[
        'New ride request available.',
        'Sharing location while you are online.',
      ]);
    });

    test('disables telemetry after invalid baseUrl reconfiguration', () async {
      final session = createSession();
      session.configure({'baseUrl': 'https://api.example.com'});
      session.configure({'baseUrl': 'ftp://bad'});

      await session.sendLocation();
      await session.pollRideRequests();
      await session.sendOnlinePresence();

      expect(gpsReadCount, 0);
      expect(adapter.requests, isEmpty);
    });

    test(
      'preserves existing HTTP clients when identical baseUrl is replayed',
      () async {
        var createdClients = 0;
        final session = DriverBackgroundTelemetrySession(
          service: service,
          sessionStore: sessionStore,
          locationSpool: spool,
          createHttpClient: (_, options) {
            createdClients++;
            return Dio(options)..httpClientAdapter = adapter;
          },
          readCurrentPosition: () async => _testPosition(),
          clearSessionFallback: () async {},
          onUpdateNotification: (content) async => notifications.add(content),
        );

        session.configure({
          'baseUrl': 'https://api.example.com',
          'appVisible': false,
        });
        session.configure({
          'baseUrl': 'https://api.example.com',
          'appVisible': false,
          'batteryOptimizationWarning': true,
        });

        expect(createdClients, 2);
      },
    );

    test(
      'drops permanently rejected 400 spooled point so subsequent points flush',
      () async {
        await spool.enqueue(
          LocationPoint(
            latitude: 7.1,
            longitude: 123.4,
            observedAt: DateTime.utc(2026, 9, 18),
          ),
        );
        var attempts = 0;
        adapter.onFetch = (options) {
          attempts++;
          if (attempts == 1) {
            return Future.value(ResponseBody.fromString('bad request', 400));
          }
          return Future.value(ResponseBody.fromString('{}', 202));
        };

        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        await session.sendLocation();

        expect(attempts, 2);
        final remaining = <LocationPoint>[];
        await spool.flush((point) async {
          remaining.add(point);
          return true;
        });
        expect(remaining, isEmpty);
      },
    );
  });
}
