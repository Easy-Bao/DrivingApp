import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';

class _MockServiceInstance extends Mock implements ServiceInstance {}

class _MockSessionStore extends Mock implements SessionStore {}

class _CapturedTelemetryRequest {
  const _CapturedTelemetryRequest({
    required this.uri,
    required this.headers,
    required this.data,
  });

  final Uri uri;
  final Map<String, Object?> headers;
  final Object? data;
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final List<_CapturedTelemetryRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _CapturedTelemetryRequest(
        uri: options.uri,
        headers: Map<String, Object?>.from(options.headers),
        data: options.data,
      ),
    );
    return ResponseBody.fromString('{"status":"ok"}', 200);
  }

  @override
  void close({bool force = false}) {}
}

Position _testPosition({
  double latitude = 14.5995,
  double longitude = 120.9842,
}) => Position(
  longitude: longitude,
  latitude: latitude,
  timestamp: DateTime.utc(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

void main() {
  late _MockServiceInstance service;
  late _MockSessionStore sessionStore;
  late _FakeHttpClientAdapter adapter;
  var gpsReadCount = 0;

  setUp(() {
    service = _MockServiceInstance();
    sessionStore = _MockSessionStore();
    adapter = _FakeHttpClientAdapter();
    gpsReadCount = 0;

    when(() => service.on(any()))
        .thenAnswer((_) => const Stream<Map<String, dynamic>?>.empty());
    when(() => service.stopSelf()).thenAnswer((_) async {});

    when(() => sessionStore.readToken()).thenAnswer((_) async => 'token-123');
    when(() => sessionStore.readRefreshToken()).thenAnswer((_) async => null);
    when(() => sessionStore.readActiveRideId())
        .thenAnswer((_) async => 'ride-42');
    when(() => sessionStore.saveToken(any())).thenAnswer((_) async {});
    when(() => sessionStore.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => sessionStore.clearSession()).thenAnswer((_) async {});
  });

  BackgroundTelemetrySession createSession({
    Future<Position> Function()? readCurrentPosition,
  }) => BackgroundTelemetrySession(
    service: service,
    sessionStore: sessionStore,
    createHttpClient: (baseUri) =>
        Dio(BaseOptions(baseUrl: baseUri.toString()))
          ..httpClientAdapter = adapter,
    readCurrentPosition:
        readCurrentPosition ??
        () async {
          gpsReadCount += 1;
          return _testPosition();
        },
    clearProfileCache: () async {},
  );

  group('BackgroundTelemetrySession', () {
    test(
      'posts passenger coordinates to active ride endpoint with bearer header',
      () async {
        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        await session.sendLocation();

        expect(adapter.requests, hasLength(1));
        final request = adapter.requests.single;
        expect(request.uri.path, '/api/v1/telemetry/passenger/ride-42');
        expect(request.headers['Authorization'], 'Bearer token-123');
        expect(
          request.data,
          equals({'latitude': 14.5995, 'longitude': 120.9842}),
        );
      },
    );

    test(
      'drops concurrent sendLocation call while token lookup is in flight',
      () async {
        final tokenCompleter = Completer<String?>();
        when(() => sessionStore.readToken())
            .thenAnswer((_) => tokenCompleter.future);

        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        final firstSend = session.sendLocation();
        await Future<void>.delayed(Duration.zero);
        await session.sendLocation();

        verify(() => sessionStore.readToken()).called(1);
        expect(gpsReadCount, 0);
        expect(adapter.requests, isEmpty);

        tokenCompleter.complete('token-123');
        await firstSend;

        expect(gpsReadCount, 1);
        expect(adapter.requests, hasLength(1));
      },
    );

    test(
      'skips POST when shutdown completes while token lookup is in flight',
      () async {
        final tokenCompleter = Completer<String?>();
        when(() => sessionStore.readToken())
            .thenAnswer((_) => tokenCompleter.future);

        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});

        final firstSend = session.sendLocation();
        await Future<void>.delayed(Duration.zero);

        await session.shutdown();
        tokenCompleter.complete('token-123');
        await firstSend;

        verify(() => service.stopSelf()).called(1);
        expect(gpsReadCount, 0);
        expect(adapter.requests, isEmpty);
      },
    );

    test(
      'skips POST when shutdown occurs while position lookup is in flight',
      () async {
        final positionCompleter = Completer<Position>();
        final session = createSession(
          readCurrentPosition: () {
            gpsReadCount += 1;
            return positionCompleter.future;
          },
        );
        session.configure({'baseUrl': 'https://api.example.com'});

        final firstSend = session.sendLocation();
        await Future<void>.delayed(Duration.zero);

        await session.shutdown();
        positionCompleter.complete(_testPosition());
        await firstSend;

        verify(() => service.stopSelf()).called(1);
        expect(gpsReadCount, 1);
        expect(adapter.requests, isEmpty);
      },
    );

    test(
      'disables sending when configure receives a non-HTTP baseUrl',
      () async {
        final session = createSession();
        session.configure({'baseUrl': 'https://api.example.com'});
        session.configure({'baseUrl': 'ftp://bad'});

        await session.sendLocation();

        verifyNever(() => sessionStore.readToken());
        expect(gpsReadCount, 0);
        expect(adapter.requests, isEmpty);
      },
    );
  });
}
