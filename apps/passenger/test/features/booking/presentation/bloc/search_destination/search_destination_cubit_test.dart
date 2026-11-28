import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/bloc/search_destination/search_destination_cubit.dart';

class _FakeLocationRepository implements LocationRepository {
  final Map<int, Completer<Map<String, dynamic>>> nearbyCompleters = {};
  List<Place> nearbyPlaces = const [];
  List<Place> searchPlacesResult = const [];
  Object? nearbyError;
  Object? searchError;
  int nearbyCalls = 0;

  void reset() {
    nearbyCompleters.clear();
    nearbyPlaces = const [];
    searchPlacesResult = const [];
    nearbyError = null;
    searchError = null;
    nearbyCalls = 0;
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) async {
    nearbyCalls++;
    final completer = nearbyCompleters.remove(nearbyCalls);
    if (completer != null) return completer.future;
    final error = nearbyError;
    if (error != null) throw error;
    return {
      'places': [for (final place in nearbyPlaces) place.toJson()],
    };
  }

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final error = searchError;
    if (error != null) throw error;
    return {
      'places': [for (final place in searchPlacesResult) place.toJson()],
    };
  }

  @override
  Future<Place> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Route> getRoute({required Map<String, dynamic> body}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  }) async => {'distances_km': <double>[]};
}

DioException _httpError(String path, int statusCode) {
  final request = RequestOptions(path: path);
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: request,
      statusCode: statusCode,
    ),
  );
}

void main() {
  final repository = _FakeLocationRepository();

  setUpAll(() async {
    await MapProvider.initialize(
      nativeService: MapNativeService(
        placeServiceBaseUri: Uri.parse('http://test.local'),
        apiClient: repository,
      ),
    );
  });

  setUp(() {
    MapProvider.clearLookupCaches();
    repository.reset();
  });

  test(
    'loadNearbyPlaces surfaces nearbyError on 503 and recovers on retry',
    () async {
      repository.nearbyError = _httpError('/api/v1/location/nearby', 503);
      final cubit = SearchDestinationCubit(
        initialLatitude: 37.422,
        initialLongitude: -122.084,
      );
      addTearDown(cubit.close);

      await cubit.loadNearbyPlaces();

      expect(cubit.state.isLoadingNearby, isFalse);
      expect(cubit.state.allNearbyPlaces, isEmpty);
      expect(
        cubit.state.nearbyError,
        'The service is unavailable. Try again later.',
      );

      repository.nearbyError = null;
      repository.nearbyPlaces = const [
        Place(
          id: 'park-1',
          name: 'Charleston Park',
          fullAddress: 'Charleston Park, Mountain View',
          latitude: 37.4221,
          longitude: -122.0841,
          distanceKm: 0.2,
        ),
      ];

      cubit.markNearbyRefreshing();
      expect(cubit.state.isLoadingNearby, isTrue);
      expect(cubit.state.nearbyError, isNull);

      await cubit.loadNearbyPlaces();

      expect(cubit.state.isLoadingNearby, isFalse);
      expect(cubit.state.nearbyError, isNull);
      expect(cubit.state.allNearbyPlaces.map((p) => p.name), [
        'Charleston Park',
      ]);
    },
  );

  test(
    'loadNearbyPlaces keeps existing places visible when refresh fails',
    () async {
      repository.nearbyPlaces = const [
        Place(
          id: 'park-1',
          name: 'Charleston Park',
          fullAddress: 'Charleston Park, Mountain View',
          latitude: 37.4221,
          longitude: -122.0841,
          distanceKm: 0.2,
        ),
      ];
      final cubit = SearchDestinationCubit(
        initialLatitude: 37.422,
        initialLongitude: -122.084,
      );
      addTearDown(cubit.close);

      await cubit.loadNearbyPlaces();
      expect(cubit.state.allNearbyPlaces, hasLength(1));

      MapProvider.clearLookupCaches();
      repository.nearbyError = _httpError('/api/v1/location/nearby', 502);
      cubit.markNearbyRefreshing();
      await cubit.loadNearbyPlaces();

      expect(cubit.state.isLoadingNearby, isFalse);
      expect(cubit.state.allNearbyPlaces.map((p) => p.name), [
        'Charleston Park',
      ]);
      expect(cubit.state.nearbyError, isNull);
    },
  );

  test('ignores stale concurrent loadNearbyPlaces responses', () async {
    final firstCompleter = Completer<Map<String, dynamic>>();
    final secondCompleter = Completer<Map<String, dynamic>>();
    repository.nearbyCompleters[1] = firstCompleter;
    repository.nearbyCompleters[2] = secondCompleter;

    final cubit = SearchDestinationCubit(
      initialLatitude: 37.422,
      initialLongitude: -122.084,
    );
    addTearDown(cubit.close);

    final firstLoad = cubit.loadNearbyPlaces();
    cubit.updateUserLocation(latitude: 37.43, longitude: -122.09);
    final secondLoad = cubit.loadNearbyPlaces();

    secondCompleter.complete({
      'places': [
        const Place(
          id: 'fresh-1',
          name: 'Fresh Cafe',
          fullAddress: 'Mountain View',
          latitude: 37.4301,
          longitude: -122.0901,
          distanceKm: 0.1,
        ).toJson(),
      ],
    });
    await secondLoad;

    firstCompleter.complete(const {'places': <Map<String, dynamic>>[]});
    await firstLoad;

    expect(cubit.state.allNearbyPlaces.map((p) => p.name), ['Fresh Cafe']);
    expect(cubit.state.isLoadingNearby, isFalse);
  });

  test('performSearch surfaces searchError on failure while keeping nearbyError intact across clearSearch', () async {
    repository.nearbyError = _httpError('/api/v1/location/nearby', 503);
    repository.searchError = _httpError('/api/v1/location/search', 503);

    final cubit = SearchDestinationCubit(
      initialLatitude: 37.422,
      initialLongitude: -122.084,
    );
    addTearDown(cubit.close);

    await cubit.loadNearbyPlaces();
    expect(cubit.state.nearbyError, isNotNull);

    final requestId = cubit.startSearchPending();
    await cubit.performSearch(
      'Hospital',
      isAuthenticated: false,
      requestId: requestId,
    );

    expect(cubit.state.isSearching, isFalse);
    expect(
      cubit.state.searchError,
      'The service is unavailable. Try again later.',
    );

    cubit.clearSearch();
    expect(cubit.state.searchError, isNull);
    expect(
      cubit.state.nearbyError,
      'The service is unavailable. Try again later.',
    );
  });
}
