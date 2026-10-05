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
  List<maps.Place> searchPlacesResult = [];
  Completer<Map<String, dynamic>>? nearbyPlacesCompleter;

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLat,
    double? userLng,
  }) async => {
    'places': [for (final place in searchPlacesResult) place.toJson()],
  };

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
    locationRepository.searchPlacesResult = [];
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

  test('does not show a nearby skeleton while the destination page opens', () {
    expect(
      shouldShowDestinationResultsLoading(isSearching: false, hasQuery: false),
      isFalse,
    );
    expect(
      shouldShowDestinationResultsLoading(isSearching: true, hasQuery: true),
      isTrue,
    );
    expect(
      shouldHideInitialDestinationResults(
        isLoadingNearby: true,
        hasQuery: false,
        hasResults: false,
      ),
      isTrue,
    );
    expect(
      shouldHideInitialDestinationResults(
        isLoadingNearby: true,
        hasQuery: false,
        hasResults: true,
      ),
      isFalse,
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

  testWidgets('keeps the map-pin search cycle to one back-stack return', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchDestinationPage(
            autofocusSearch: state.uri.queryParameters['focus'] == '1',
            returnToMapPin: state.uri.queryParameters['returnToMapPin'] == '1',
          ),
        ),
        GoRoute(
          name: BookingRoutes.mapPin,
          path: '/map-pin',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('map-pin-search'),
                onPressed: () =>
                    context.push('/search?focus=1&returnToMapPin=1'),
                child: const Text('Search from map pin'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: EasyRideTheme.main, routerConfig: router),
    );
    await tester.pumpAndSettle();

    Future<void> openSearchFromMapPin() async {
      await tester.tap(find.byKey(const ValueKey('map-pin-search')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final topSearch = find.byType(SearchDestinationPage).last;
      await tester.tap(
        find.descendant(
          of: topSearch,
          matching: find.byKey(const ValueKey('search-destination-map-pin')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-pin-search')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('search-destination-map-pin')));
    await tester.pumpAndSettle();
    await openSearchFromMapPin();
    await openSearchFromMapPin();

    router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(SearchDestinationPage), findsOneWidget);
  });

  testWidgets('does not stack ride-selection routes from repeated results', (
    tester,
  ) async {
    const destination = maps.Place(
      id: 'central-park',
      name: 'Central Park',
      fullAddress: 'Central Park, Mountain View',
      latitude: 37.4,
      longitude: -122.1,
    );
    locationRepository.searchPlacesResult = [destination];
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (_, _) => const SearchDestinationPage(),
        ),
        GoRoute(
          name: BookingRoutes.rideSelection,
          path: '/ride-selection',
          builder: (_, _) => const Text('Ride selection page'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: EasyRideTheme.main, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Central');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final result = find.text('Central Park');
    expect(result, findsOneWidget);
    final resultTile = tester.widget<ListTile>(
      find.ancestor(of: result, matching: find.byType(ListTile)),
    );
    resultTile.onTap!();
    resultTile.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Ride selection page'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SearchDestinationPage), findsOneWidget);

    router.dispose();
  });

  testWidgets('keeps the initial nearby state blank while the page opens', (
    tester,
  ) async {
    locationRepository.nearbyPlacesCompleter =
        Completer<Map<String, dynamic>>();

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: const SearchDestinationPage(autofocusSearch: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Nearby Places'), findsNothing);
    expect(find.byType(ListTile), findsNothing);

    locationRepository.nearbyPlacesCompleter!.complete(const {'places': []});
    await tester.pumpAndSettle();
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
