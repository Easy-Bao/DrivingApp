import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

import 'mock_location_remote_data_source.dart';

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

  test('uses the fixed light map style', () {
    expect(MapProvider.styleUriFor(), 'mapbox://styles/mapbox/streets-v12');
  });

  test(
    'coalesces the same route request and keeps route preferences separate',
    () async {
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
    final callsBeforeRetry = apiClient.routeCallCount;
    apiClient.failNextRoute = true;

    final route = await MapProvider.getRoute(
      8.8242,
      124.4350,
      8.8300,
      124.4400,
    );

    expect(route, isNotNull);
    expect(apiClient.routeCallCount, callsBeforeRetry + 2);
  });
}

class _DelayedLocationRemoteDataSource extends MockLocationRemoteDataSource {
  final Completer<Route> _pendingRoute = Completer<Route>();
  int routeCallCount = 0;
  bool failNextRoute = false;

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
    if (routeCallCount == 1) return _pendingRoute.future;
    return Future.value(_route);
  }

  void completePendingRoute() => _pendingRoute.complete(_route);

  static const _route = Route(
    polylinePoints: [
      [123.4350, 7.8242],
      [123.4400, 7.8300],
    ],
    distanceKm: 4.5,
    durationSeconds: 720,
  );
}
