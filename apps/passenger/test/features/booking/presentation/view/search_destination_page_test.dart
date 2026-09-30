import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/testing.dart';
import 'package:maps/maps.dart' as maps;
import 'package:passenger/src/features/booking/presentation/view/search_destination_page.dart';

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return Position(
      longitude: -122.0839,
      latitude: 37.3861,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );
  }
}

class _FakeLocationRepository implements maps.LocationRepository {
  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLat,
    double? userLng,
  }) async => {};

  @override
  Future<maps.Place> reverseGeocode({
    required double lat,
    required double lng,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  }) async => {};

  @override
  Future<maps.Route> getRoute({required Map<String, dynamic> body}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  }) async => {'distances_km': <double>[]};
}

void main() {
  late ModularTestScope scope;
  final originalGeolocatorPlatform = GeolocatorPlatform.instance;

  setUp(() async {
    scope = ModularTestScope.fresh().withInstance(AppLifecycleCoordinator());
    scope.setUp();
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    await maps.MapProvider.initialize(
      nativeService: maps.MapNativeService(
        placeServiceBaseUri: Uri.parse('http://test.local'),
        apiClient: _FakeLocationRepository(),
      ),
    );
    await maps.LocationService.getCurrentPosition();
  });

  tearDown(() async {
    GeolocatorPlatform.instance = originalGeolocatorPlatform;
    await scope.get<AppLifecycleCoordinator>().dispose();
    scope.tearDown();
  });

  test(
    'destination search keeps the rate-limit debounce at 300 milliseconds',
    () {
      expect(
        SearchDestinationPage.searchDebounceDuration,
        const Duration(milliseconds: 300),
      );
    },
  );

  testWidgets('map-pin search back returns to the map-pin route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/map-pin',
      routes: [
        GoRoute(
          path: '/map-pin',
          builder: (_, _) => const Text('Map pin page'),
        ),
        GoRoute(
          path: '/search',
          builder: (_, _) => Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => const SearchDestinationPage(
                autofocusSearch: true,
                returnToMapPin: true,
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: EasyRideTheme.main, routerConfig: router),
    );
    await tester.pumpAndSettle();

    unawaited(router.push('/search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('search-destination-back')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('search-destination-back')));
    await tester.pumpAndSettle();

    expect(find.text('Map pin page'), findsOneWidget);
    expect(find.byType(SearchDestinationPage), findsNothing);

    router.dispose();
  });
}
