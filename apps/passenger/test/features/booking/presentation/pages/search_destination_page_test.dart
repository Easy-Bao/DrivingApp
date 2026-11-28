import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart' as maps;
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/pages/search_destination_page.dart';

class _SessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  double latitude = 37.3861;
  double longitude = -122.0839;

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
      longitude: longitude,
      latitude: latitude,
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
  bool throwOnSearch = false;
  Object? nearbyError;
  int nearbyCallCount = 0;
  Completer<Map<String, dynamic>>? nearbyPlacesCompleter;

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (throwOnSearch) {
      throw Exception('search backend unavailable');
    }
    return {
      'places': [for (final place in searchPlacesResult) place.toJson()],
    };
  }

  @override
  Future<maps.Place> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) {
    nearbyCallCount++;
    final completer = nearbyPlacesCompleter;
    if (completer != null) return completer.future;
    final error = nearbyError;
    if (error != null) return Future.error(error);
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
  late _TestMapPlatform mapPlatform;
  late _FakeGeolocatorPlatform geolocatorPlatform;
  final locationRepository = _FakeLocationRepository();
  final originalGeolocatorPlatform = GeolocatorPlatform.instance;

  setUp(() async {
    mapPlatform = _TestMapPlatform();
    geolocatorPlatform = _FakeGeolocatorPlatform();
    MapboxMapsFlutterPlatform.instance = mapPlatform;
    GeolocatorPlatform.instance = geolocatorPlatform;
    await maps.MapProvider.initialize(
      nativeService: maps.MapNativeService(
        placeServiceBaseUri: Uri.parse('http://test.local'),
        apiClient: locationRepository,
      ),
    );
    maps.MapProvider.clearLookupCaches();
    locationRepository.nearbyPlaces = [];
    locationRepository.searchPlacesResult = [];
    locationRepository.throwOnSearch = false;
    locationRepository.nearbyError = null;
    locationRepository.nearbyCallCount = 0;
    locationRepository.nearbyPlacesCompleter = null;
    await maps.LocationService.getCurrentPosition();
  });

  tearDown(() async {
    GeolocatorPlatform.instance = originalGeolocatorPlatform;
  });

  testWidgets(
    'shows a circular loader while map tiles load and keeps map pin button visible',
    (tester) async {
      mapPlatform.autoLoad = false;
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.main, home: const SearchDestinationPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const ValueKey('search-destination-map-pin')),
        findsOneWidget,
      );
      mapPlatform.onMapEvent!(_loadedMapEvent());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byKey(const ValueKey('search-destination-map-pin')),
        findsOneWidget,
      );
    },
  );

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
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
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
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
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
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
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
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
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
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
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
    final session = _SessionBloc();
    when(() => session.state).thenReturn(const GuestSession());
    addTearDown(session.close);
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
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      ),
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
        theme: AppTheme.main,
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

      final lifecycleCoordinator = AppLifecycleCoordinator();
      addTearDown(lifecycleCoordinator.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: SearchDestinationPage(
            autofocusSearch: true,
            lifecycleCoordinator: lifecycleCoordinator,
          ),
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

  testWidgets(
    'clears loading state when destination search throws and keeps map-pin key unique when expanded',
    (tester) async {
      locationRepository.throwOnSearch = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const SearchDestinationPage(autofocusSearch: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('search-destination-map-pin')),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Robinsons');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Search unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);

      locationRepository.throwOnSearch = false;
      locationRepository.searchPlacesResult = const [
        maps.Place(
          id: 'robinsons-1',
          name: 'Robinsons Place',
          fullAddress: 'Robinsons Place, Mountain View',
          latitude: 37.3865,
          longitude: -122.0835,
          distanceKm: 0.4,
        ),
      ];

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Robinsons Place'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows nearby places error with retry and recovers when backend returns',
    (tester) async {
      final request = RequestOptions(path: '/api/v1/location/nearby');
      locationRepository.nearbyError = DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(requestOptions: request, statusCode: 503),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const SearchDestinationPage(autofocusSearch: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Nearby places unavailable'), findsOneWidget);
      expect(
        find.text('The service is unavailable. Try again later.'),
        findsOneWidget,
      );
      expect(find.text('No nearby places found'), findsNothing);

      locationRepository.nearbyError = null;
      locationRepository.nearbyPlaces = const [
        maps.Place(
          id: 'charleston-park',
          name: 'Charleston Park',
          fullAddress: 'Charleston Park, Mountain View',
          latitude: 37.3862,
          longitude: -122.0838,
          distanceKm: 0.2,
        ),
      ];

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Charleston Park'), findsOneWidget);
      expect(find.text('Nearby places unavailable'), findsNothing);

      // Verify the expanded nearby panel fills the viewport rather than
      // clipping to the top search bar height.
      final nearbyTileRect = tester.getRect(find.text('Charleston Park'));
      final overlayStackSize = tester.getSize(
        find
            .ancestor(
              of: find.text('Charleston Park'),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(overlayStackSize.height, greaterThan(nearbyTileRect.bottom));
    },
  );

  testWidgets(
    'avoids duplicate nearby fetches for unchanged coordinates and reloads when position moves',
    (tester) async {
      locationRepository.nearbyPlaces = const [
        maps.Place(
          id: 'charleston-park',
          name: 'Charleston Park',
          fullAddress: 'Charleston Park, Mountain View',
          latitude: 37.3862,
          longitude: -122.0838,
          distanceKm: 0.2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const SearchDestinationPage(autofocusSearch: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(locationRepository.nearbyCallCount, 1);
      expect(find.text('Charleston Park'), findsOneWidget);

      maps.MapProvider.clearLookupCaches();
      geolocatorPlatform
        ..latitude = 37.4100
        ..longitude = -122.1000;
      locationRepository
        ..nearbyCallCount = 0
        ..nearbyPlaces = const [
          maps.Place(
            id: 'moved-place',
            name: 'Shoreline Lake',
            fullAddress: 'Mountain View',
            latitude: 37.4102,
            longitude: -122.1002,
            distanceKm: 0.3,
          ),
        ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const SearchDestinationPage(
            key: ValueKey('moved-search'),
            autofocusSearch: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(locationRepository.nearbyCallCount, 2);
      expect(find.text('Shoreline Lake'), findsOneWidget);
    },
  );
}

final class _TestMapPlatform extends MapboxMapsFlutterPlatform {
  bool autoLoad = true;
  void Function(MapEvent)? onMapEvent;

  @override
  Widget buildView({
    required String styleUri,
    PlatformMapCreatedCallback? onMapCreated,
    ViewportState? viewport,
    ViewportTransition? viewportTransition,
    void Function(bool)? viewportTransitionCompletion,
    void Function(MapEvent)? onMapEvent,
    MapOptions? mapOptions,
    bool? textureView,
    // ignore: experimental_member_use
    required AndroidPlatformViewHostingMode androidHostingMode,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    bool? isOpaque = true,
  }) {
    this.onMapEvent = onMapEvent;
    if (autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onMapEvent?.call(_loadedMapEvent()),
      );
    }
    return const SizedBox.expand();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MapLoadedEventData _loadedMapEvent() => MapLoadedEventData(
  timeInterval: EventTimeInterval(
    begin: DateTime.utc(2026),
    end: DateTime.utc(2026),
  ),
);
