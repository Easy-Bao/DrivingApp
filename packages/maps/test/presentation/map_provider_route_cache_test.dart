import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

import '../mocks/mock_location_remote_data_source.dart';

void main() {
  late _DelayedLocationRemoteDataSource apiClient;

  setUpAll(() async {
    apiClient = _DelayedLocationRemoteDataSource();
    await MapProvider.initialize(
      nativeService: MapNativeService(
        placeServiceBaseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 8089),
        apiClient: apiClient,
      ),
    );
  });

  setUp(() {
    MapProvider.clearLookupCaches();
    apiClient.reset();
  });

  test('uses the fixed light map style', () {
    expect(MapProvider.styleUriFor(), 'mapbox://styles/mapbox/streets-v12');
  });

  test('coalesces and reuses nearby place lookups', () async {
    const latitude = 10.123456;
    const longitude = 20.654321;

    final first = MapProvider.getNearbyPOIs(
      latitude: latitude,
      longitude: longitude,
    );
    final second = MapProvider.getNearbyPOIs(
      latitude: latitude,
      longitude: longitude,
    );

    expect(await Future.wait([first, second]), everyElement(isNotEmpty));
    expect(apiClient.nearbyCallCount, 1);

    await MapProvider.getNearbyPOIs(latitude: latitude, longitude: longitude);
    expect(apiClient.nearbyCallCount, 1);
  });

  test('clears lookup caches for a foreground refresh', () async {
    const latitude = 10.123456;
    const longitude = 20.654321;

    await MapProvider.getNearbyPOIs(latitude: latitude, longitude: longitude);
    expect(apiClient.nearbyCallCount, 1);

    MapProvider.clearLookupCaches();
    await MapProvider.getNearbyPOIs(latitude: latitude, longitude: longitude);

    expect(apiClient.nearbyCallCount, 2);
  });

  test('returns a failure from getNearbyPOIsResult without caching transient errors', () async {
    const latitude = 10.223456;
    const longitude = 20.754321;
    apiClient.failNextNearby = true;

    final first = await MapProvider.getNearbyPOIsResult(
      latitude: latitude,
      longitude: longitude,
    );
    expect(first.isErr, isTrue);
    first.fold(
      (failure) => expect(failure, isA<PlaceNetworkError>()),
      (_) => fail('Expected nearby lookup failure.'),
    );

    final second = await MapProvider.getNearbyPOIsResult(
      latitude: latitude,
      longitude: longitude,
    );
    expect(second.isOk, isTrue);
    second.fold(
      (failure) => fail('Expected retry to succeed: $failure'),
      (places) => expect(places, isNotEmpty),
    );
    expect(apiClient.nearbyCallCount, 2);
  });

  test(
    'falls back to the wider nearby radius on page 1 for sparse areas only',
    () async {
      const latitude = 10.323456;
      const longitude = 20.854321;
      apiClient.nearbyOverride = [
        const {
          'id': 'regional-1',
          'name': 'Regional Hospital',
          'fullAddress': 'Highway 1',
          'latitude': 10.423456,
          'longitude': 20.854321,
          'distance_km': 11.1,
        },
      ];

      final page1 = await MapProvider.getNearbyPOIsResult(
        latitude: latitude,
        longitude: longitude,
        page: 1,
      );
      expect(page1.isOk, isTrue);
      page1.fold(
        (failure) => fail('Expected page 1 fallback places: $failure'),
        (places) {
          expect(places, hasLength(1));
          expect(places.single.id, 'regional-1');
        },
      );

      final page2 = await MapProvider.getNearbyPOIsResult(
        latitude: latitude,
        longitude: longitude,
        page: 2,
      );
      expect(page2.isOk, isTrue);
      page2.fold(
        (failure) => fail('Expected page 2 to succeed cleanly: $failure'),
        (places) => expect(places, isEmpty),
      );
    },
  );

  test('returns a failure from searchPlacesResult without caching transient errors', () async {
    apiClient.failNextSearch = true;

    final first = await MapProvider.searchPlacesResult(
      'Plaza',
      latitude: 10.1,
      longitude: 20.2,
    );
    expect(first.isErr, isTrue);
    first.fold(
      (failure) => expect(failure, isA<PlaceNetworkError>()),
      (_) => fail('Expected search failure.'),
    );

    final second = await MapProvider.searchPlacesResult(
      'Plaza',
      latitude: 10.1,
      longitude: 20.2,
    );
    expect(second.isOk, isTrue);
    second.fold(
      (failure) => fail('Expected search retry to succeed: $failure'),
      (places) => expect(places, isNotEmpty),
    );
    expect(apiClient.searchCallCount, 2);
  });

  test('coalesces and reuses travel matrix lookups', () async {
    const originLatitude = 11.123456;
    const originLongitude = 21.654321;
    const destinations = [
      (latitude: 11.130000, longitude: 21.660000),
      (latitude: 11.140000, longitude: 21.670000),
    ];

    final first = MapProvider.getDrivingDistances(
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinations: destinations,
    );
    final second = MapProvider.getDrivingDistances(
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinations: destinations,
    );

    expect(await Future.wait([first, second]), everyElement(isNotNull));
    expect(apiClient.matrixCallCount, 1);

    await MapProvider.getDrivingDistances(
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinations: destinations,
    );
    expect(apiClient.matrixCallCount, 1);
  });

  test(
    'coalesces the same route request and keeps route preferences separate',
    () async {
      apiClient.holdNextRoute();
      final first = MapProvider.getRoute(
        7.82420001,
        123.43500001,
        7.83000001,
        123.44000001,
      );
      final second = MapProvider.getRoute(
        7.82420002,
        123.43500002,
        7.83000002,
        123.44000002,
      );

      expect(apiClient.routeCallCount, 1);
      apiClient.completePendingRoute();
      expect(await Future.wait([first, second]), everyElement(isNotNull));

      await MapProvider.getRoute(7.8242, 123.4350, 7.8300, 123.4400);
      expect(apiClient.routeCallCount, 1);

      await MapProvider.getRoute(
        7.8242,
        123.4350,
        7.8300,
        123.4400,
        preference: RoutePreference.shortest,
      );
      expect(apiClient.routeCallCount, 2);
    },
  );

  test('retries a transient route network failure once', () async {
    apiClient.failNextRoute = true;

    final route = await MapProvider.getRoute(
      8.8242,
      124.4350,
      8.8300,
      124.4400,
    );

    expect(route, isNotNull);
    expect(apiClient.routeCallCount, 2);
  });

  test('evicts old route results after the bounded cache fills', () async {
    for (var index = 0; index < 25; index++) {
      final route = await MapProvider.getRoute(1 + index * 0.001, 2, 3, 4);
      expect(route, isNotNull);
    }
    expect(apiClient.routeCallCount, 25);

    await MapProvider.getRoute(1, 2, 3, 4);
    expect(apiClient.routeCallCount, 26);
  });
}

class _DelayedLocationRemoteDataSource extends MockLocationRemoteDataSource {
  Completer<Route>? _pendingRoute;
  int routeCallCount = 0;
  int nearbyCallCount = 0;
  int searchCallCount = 0;
  int matrixCallCount = 0;
  bool failNextRoute = false;
  bool failNextNearby = false;
  bool failNextSearch = false;
  List<Map<String, dynamic>>? nearbyOverride;

  void reset() {
    _pendingRoute = null;
    routeCallCount = 0;
    nearbyCallCount = 0;
    searchCallCount = 0;
    matrixCallCount = 0;
    failNextRoute = false;
    failNextNearby = false;
    failNextSearch = false;
    nearbyOverride = null;
  }

  void holdNextRoute() {
    _pendingRoute = Completer<Route>();
  }

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) {
    searchCallCount++;
    if (failNextSearch) {
      failNextSearch = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/location/search'),
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/api/v1/location/search'),
          statusCode: 503,
        ),
      );
    }
    return super.searchPlaces(
      query: query,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) {
    nearbyCallCount++;
    if (failNextNearby) {
      failNextNearby = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/location/nearby'),
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/api/v1/location/nearby'),
          statusCode: 503,
        ),
      );
    }
    final override = nearbyOverride;
    if (override != null) {
      return Future.value({'places': override});
    }
    return super.getNearbyPois(
      latitude: latitude,
      longitude: longitude,
      page: page,
    );
  }

  @override
  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  }) {
    matrixCallCount++;
    return super.getTravelMatrix(body: body);
  }

  @override
  Future<Route> getRoute({required Map<String, dynamic> body}) {
    routeCallCount++;
    if (failNextRoute) {
      failNextRoute = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/location/route'),
        type: DioExceptionType.connectionError,
      );
    }
    final pending = _pendingRoute;
    if (pending != null && !pending.isCompleted) {
      return pending.future;
    }
    return Future.value(_route);
  }

  void completePendingRoute() {
    final pending = _pendingRoute;
    _pendingRoute = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(_route);
    }
  }

  static const _route = Route(
    polylinePoints: [
      [123.4350, 7.8242],
      [123.4400, 7.8300],
    ],
    distanceKm: 4.5,
    durationSeconds: 720,
  );
}
