import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

import 'mock_location_api_client.dart';

void main() {
  late _DelayedLocationApiClient apiClient;

  setUpAll(() async {
    apiClient = _DelayedLocationApiClient();
    await MapProvider.initialize(
      nativeService: MapNativeService(
        placeServiceBaseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 8089),
        apiClient: apiClient,
      ),
    );
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
}

class _DelayedLocationApiClient extends MockLocationApiClient {
  final Completer<RouteModel> _pendingRoute = Completer<RouteModel>();
  int routeCallCount = 0;

  @override
  Future<RouteModel> getRoute({required Map<String, dynamic> body}) {
    routeCallCount++;
    if (routeCallCount == 1) return _pendingRoute.future;
    return Future.value(_route);
  }

  void completePendingRoute() => _pendingRoute.complete(_route);

  static const _route = RouteModel(
    polylinePoints: [
      [123.4350, 7.8242],
      [123.4400, 7.8300],
    ],
    distanceKm: 4.5,
    durationSeconds: 720,
  );
}
