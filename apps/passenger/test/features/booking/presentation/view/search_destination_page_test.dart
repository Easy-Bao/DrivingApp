import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/testing.dart';
import 'package:maps/maps.dart' as maps;
import 'package:passenger/src/features/booking/booking_routes.dart';
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
  List<maps.Place> nearbyPlaces = [];
  Completer<Map<String, dynamic>>? nearbyPlacesCompleter;

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
  }) {
    final completer = nearbyPlacesCompleter;
    if (completer != null) return completer.future;
    return Future.value({
      'places': [for (final place in nearbyPlaces) place.toJson()],
    });
  }

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
  final locationRepository = _FakeLocationRepository();
  final originalGeolocatorPlatform = GeolocatorPlatform.instance;

  setUp(() async {
    scope = ModularTestScope.fresh().withInstance(AppLifecycleCoordinator());
    scope.setUp();
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    await maps.MapProvider.initialize(
      nativeService: maps.MapNativeService(
        placeServiceBaseUri: Uri.parse('http://test.local'),
        apiClient: locationRepository,
      ),
    );
    maps.MapProvider.clearLookupCaches();
    locationRepository.nearbyPlaces = [];
    locationRepository.nearbyPlacesCompleter = null;
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

  test('does not show a nearby skeleton without an active nearby request', () {
    expect(
      shouldShowDestinationResultsLoading(
        isSearching: false,
        isLoadingNearby: false,
        hasQuery: false,
        hasResults: false,
      ),
      isFalse,
    );
    expect(
      shouldShowDestinationResultsLoading(
        isSearching: false,
        isLoadingNearby: true,
        hasQuery: false,
        hasResults: false,
      ),
      isTrue,
    );
  });

  test('keeps the expanded search surface above the software keyboard', () {
    expect(
      destinationSearchAvailableHeight(screenHeight: 640, keyboardInset: 280),
      360,
    );
    expect(
      destinationSearchAvailableHeight(screenHeight: 640, keyboardInset: 0),
      640,
    );
  });

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

  testWidgets('map-pin-originated search returns to its existing map pin', (
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

    final mapPinButton = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('search-destination-map-pin')),
    );
    mapPinButton.onTap!();
    mapPinButton.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Map pin page'), findsOneWidget);
    expect(find.byType(SearchDestinationPage), findsNothing);

    router.dispose();
  });

  testWidgets('ignores a second map-pin back pop while the first is pending', (
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

    final backButton = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('search-destination-back')),
    );
    backButton.onTap!();
    backButton.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Map pin page'), findsOneWidget);
    expect(find.byType(SearchDestinationPage), findsNothing);

    router.dispose();
  });

  testWidgets('does not stack map-pin routes from repeated taps', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (_, _) => const SearchDestinationPage(),
        ),
        GoRoute(
          name: BookingRoutes.mapPin,
          path: '/map-pin',
          builder: (_, _) => const Text('Map pin page'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: EasyRideTheme.main, routerConfig: router),
    );
    await tester.pumpAndSettle();

    final mapPinButton = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('search-destination-map-pin')),
    );
    mapPinButton.onTap!();
    mapPinButton.onTap!();
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Map pin page'), findsNothing);
    expect(find.byType(SearchDestinationPage), findsOneWidget);

    router.dispose();
  });

  testWidgets(
    'keeps nearby places visible while refreshing without an active search',
    (tester) async {
      final nearbyPlace = const maps.Place(
        id: 'charleston-park',
        name: 'Charleston Park',
        fullAddress: 'Charleston Park, Mountain View',
        latitude: 37.3862,
        longitude: -122.0838,
        distanceMeters: 195,
      );
      locationRepository.nearbyPlaces = [nearbyPlace];

      final lifecycleCoordinator = scope.get<AppLifecycleCoordinator>();
      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: const SearchDestinationPage(autofocusSearch: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Nearby Places'), findsOneWidget);
      expect(find.text('Charleston Park'), findsOneWidget);

      locationRepository.nearbyPlacesCompleter =
          Completer<Map<String, dynamic>>();
      maps.MapProvider.clearLookupCaches();
      lifecycleCoordinator.update(isForeground: false);
      lifecycleCoordinator.update(isForeground: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Charleston Park'), findsOneWidget);

      locationRepository.nearbyPlacesCompleter!.complete(const {'places': []});
      await tester.pumpAndSettle();
    },
  );
}
