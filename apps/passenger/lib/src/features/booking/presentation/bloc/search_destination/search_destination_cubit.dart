import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/formatters/search_destination_formatters.dart';

class SearchDestinationState extends Equatable {
  const SearchDestinationState({
    this.results = const [],
    this.allNearbyPlaces = const [],
    this.displayedCount = 10,
    this.currentNearbyPage = 1,
    this.isLoadingMoreNearby = false,
    this.hasMoreNearbyPages = true,
    this.isSearching = false,
    this.isLoadingNearby = false,
    this.drivingDistances = const {},
    this.drivingDistanceRequests = const {},
    this.userLatitude,
    this.userLongitude,
    this.searchError,
  });

  final List<Place> results;
  final List<Place> allNearbyPlaces;
  final int displayedCount;
  final int currentNearbyPage;
  final bool isLoadingMoreNearby;
  final bool hasMoreNearbyPages;
  final bool isSearching;
  final bool isLoadingNearby;
  final Map<String, double> drivingDistances;
  final Set<String> drivingDistanceRequests;
  final double? userLatitude;
  final double? userLongitude;
  final String? searchError;

  List<Place> visiblePlaces({required bool hasQuery}) {
    if (hasQuery) return results;
    if (displayedCount >= allNearbyPlaces.length) return allNearbyPlaces;
    return allNearbyPlaces.sublist(
      0,
      displayedCount.clamp(0, allNearbyPlaces.length),
    );
  }

  SearchDestinationState copyWith({
    List<Place>? results,
    List<Place>? allNearbyPlaces,
    int? displayedCount,
    int? currentNearbyPage,
    bool? isLoadingMoreNearby,
    bool? hasMoreNearbyPages,
    bool? isSearching,
    bool? isLoadingNearby,
    Map<String, double>? drivingDistances,
    Set<String>? drivingDistanceRequests,
    double? userLatitude,
    double? userLongitude,
    String? searchError,
    bool clearSearchError = false,
  }) {
    return SearchDestinationState(
      results: results ?? this.results,
      allNearbyPlaces: allNearbyPlaces ?? this.allNearbyPlaces,
      displayedCount: displayedCount ?? this.displayedCount,
      currentNearbyPage: currentNearbyPage ?? this.currentNearbyPage,
      isLoadingMoreNearby: isLoadingMoreNearby ?? this.isLoadingMoreNearby,
      hasMoreNearbyPages: hasMoreNearbyPages ?? this.hasMoreNearbyPages,
      isSearching: isSearching ?? this.isSearching,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
      drivingDistances: drivingDistances ?? this.drivingDistances,
      drivingDistanceRequests:
          drivingDistanceRequests ?? this.drivingDistanceRequests,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
    );
  }

  @override
  List<Object?> get props => [
    results,
    allNearbyPlaces,
    displayedCount,
    currentNearbyPage,
    isLoadingMoreNearby,
    hasMoreNearbyPages,
    isSearching,
    isLoadingNearby,
    drivingDistances,
    drivingDistanceRequests,
    userLatitude,
    userLongitude,
    searchError,
  ];
}

class SearchDestinationCubit extends Cubit<SearchDestinationState> {
  SearchDestinationCubit({double? initialLatitude, double? initialLongitude})
    : super(
        SearchDestinationState(
          userLatitude: initialLatitude,
          userLongitude: initialLongitude,
          isLoadingNearby: initialLatitude != null && initialLongitude != null,
        ),
      );

  int _searchRequestId = 0;

  void updateUserLocation({
    required double latitude,
    required double longitude,
    bool markLoadingNearby = true,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        userLatitude: latitude,
        userLongitude: longitude,
        isLoadingNearby: markLoadingNearby ? true : state.isLoadingNearby,
      ),
    );
  }

  void markNearbyLoadStopped() {
    if (isClosed || !state.isLoadingNearby) return;
    emit(state.copyWith(isLoadingNearby: false));
  }

  void markNearbyRefreshing() {
    if (isClosed) return;
    emit(state.copyWith(isLoadingNearby: true));
  }

  Future<void> loadNearbyPlaces() async {
    final latitude = state.userLatitude;
    final longitude = state.userLongitude;
    if (latitude == null || longitude == null) {
      markNearbyLoadStopped();
      return;
    }

    try {
      final results = await MapProvider.getNearbyPOIs(
        latitude: latitude,
        longitude: longitude,
        page: 1,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          allNearbyPlaces: List<Place>.unmodifiable(results),
          displayedCount: results.length,
          currentNearbyPage: 1,
          hasMoreNearbyPages: results.length == 10,
          isLoadingNearby: false,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Unable to load nearby places for destination search.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!isClosed) {
        emit(state.copyWith(isLoadingNearby: false));
      }
    }
  }

  void loadNextNearbyBatch() {
    if (state.displayedCount < state.allNearbyPlaces.length) {
      emit(
        state.copyWith(
          displayedCount: (state.displayedCount + 10).clamp(
            0,
            state.allNearbyPlaces.length,
          ),
        ),
      );
      return;
    }

    if (!state.isLoadingMoreNearby && state.hasMoreNearbyPages) {
      unawaited(fetchMoreNearbyFromApi());
    }
  }

  Future<void> fetchMoreNearbyFromApi() async {
    final latitude = state.userLatitude;
    final longitude = state.userLongitude;
    if (latitude == null || longitude == null || state.isLoadingMoreNearby) {
      return;
    }
    emit(state.copyWith(isLoadingMoreNearby: true));

    final nextPage = state.currentNearbyPage + 1;
    try {
      final moreResults = await MapProvider.getNearbyPOIs(
        latitude: latitude,
        longitude: longitude,
        page: nextPage,
      );
      if (isClosed) return;

      if (moreResults.isEmpty) {
        emit(
          state.copyWith(
            currentNearbyPage: nextPage,
            hasMoreNearbyPages: false,
            isLoadingMoreNearby: false,
          ),
        );
        return;
      }

      final previousCount = state.allNearbyPlaces.length;
      final merged =
          mergeUniqueDestinationResults(state.allNearbyPlaces, moreResults)
            ..sort((a, b) {
              final distA = a.distanceKm ?? double.maxFinite;
              final distB = b.distanceKm ?? double.maxFinite;
              return distA.compareTo(distB);
            });
      final addedCount = merged.length - previousCount;

      emit(
        state.copyWith(
          allNearbyPlaces: List<Place>.unmodifiable(merged),
          displayedCount: merged.length,
          currentNearbyPage: nextPage,
          hasMoreNearbyPages: addedCount > 0 && moreResults.length >= 10,
          isLoadingMoreNearby: false,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Unable to load additional nearby places.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!isClosed) {
        emit(state.copyWith(isLoadingMoreNearby: false));
      }
    }
  }

  int startSearchPending() {
    final requestId = ++_searchRequestId;
    if (!isClosed) {
      emit(state.copyWith(isSearching: true, clearSearchError: true));
    }
    return requestId;
  }

  void clearSearch() {
    _searchRequestId++;
    if (isClosed) return;
    emit(
      state.copyWith(
        results: const [],
        isSearching: false,
        clearSearchError: true,
      ),
    );
  }

  Future<void> performSearch(
    String rawQuery, {
    required bool isAuthenticated,
    int? requestId,
  }) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    final activeRequestId = requestId ?? ++_searchRequestId;

    final localMatches = state.allNearbyPlaces
        .where((place) => destinationMatchesSearchQuery(place, query))
        .toList();

    try {
      final apiResults = await MapProvider.searchPlaces(
        query,
        latitude: state.userLatitude,
        longitude: state.userLongitude,
      );
      if (isClosed || activeRequestId != _searchRequestId) return;

      final mergedResults = mergeUniqueDestinationResults(
        localMatches,
        apiResults.where(
          (place) =>
              (place.distanceKm == null || (place.distanceKm ?? 0) <= 10.0) &&
              destinationMatchesSearchQuery(place, query),
        ),
        compareCoordinates: true,
      );

      final sorted = sortDestinationsByDistance(
        mergedResults,
        state.drivingDistances,
      );
      emit(
        state.copyWith(
          results: List<Place>.unmodifiable(sorted),
          isSearching: false,
          clearSearchError: true,
        ),
      );

      if (isAuthenticated) {
        unawaited(_loadDrivingDistances(mergedResults, activeRequestId));
      }
    } catch (error, stackTrace) {
      developer.log(
        'Destination search failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (isClosed || activeRequestId != _searchRequestId) return;
      final fallback = sortDestinationsByDistance(
        localMatches,
        state.drivingDistances,
      );
      emit(
        state.copyWith(
          results: List<Place>.unmodifiable(fallback),
          isSearching: false,
          searchError: fallback.isEmpty
              ? 'Unable to search places right now. Try again.'
              : null,
        ),
      );
    }
  }

  Future<void> _loadDrivingDistances(List<Place> places, int requestId) async {
    final originLat = state.userLatitude;
    final originLng = state.userLongitude;
    if (isClosed || originLat == null || originLng == null) return;

    final pendingPlaces = <Place>[];
    final pendingKeys = <String>[];
    final nextInFlight = Set<String>.of(state.drivingDistanceRequests);
    for (final place in places) {
      final key = destinationPlaceKey(place);
      if (state.drivingDistances.containsKey(key) || !nextInFlight.add(key)) {
        continue;
      }
      pendingPlaces.add(place);
      pendingKeys.add(key);
    }

    if (pendingPlaces.isEmpty) return;
    emit(
      state.copyWith(
        drivingDistanceRequests: Set<String>.unmodifiable(nextInFlight),
      ),
    );

    try {
      final distances = await MapProvider.getDrivingDistances(
        originLatitude: originLat,
        originLongitude: originLng,
        destinations: [
          for (final place in pendingPlaces)
            (latitude: place.latitude, longitude: place.longitude),
        ],
      );
      if (isClosed || distances == null) return;

      final resolvedDistances = Map<String, double>.of(state.drivingDistances);
      var addedAny = false;
      for (var index = 0; index < pendingKeys.length; index++) {
        if (index >= distances.length) break;
        final distance = distances[index];
        if (distance.isFinite && distance >= 0) {
          resolvedDistances[pendingKeys[index]] = distance;
          addedAny = true;
        }
      }
      if (!addedAny) return;

      final updatedResults = requestId == _searchRequestId
          ? List<Place>.unmodifiable(
              sortDestinationsByDistance(state.results, resolvedDistances),
            )
          : state.results;
      emit(
        state.copyWith(
          drivingDistances: Map<String, double>.unmodifiable(resolvedDistances),
          results: updatedResults,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Unable to load driving distances for destination results.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!isClosed) {
        final remaining = Set<String>.of(state.drivingDistanceRequests)
          ..removeAll(pendingKeys);
        emit(
          state.copyWith(
            drivingDistanceRequests: Set<String>.unmodifiable(remaining),
          ),
        );
      }
    }
  }
}
