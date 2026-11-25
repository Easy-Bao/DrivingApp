part of 'booking_bloc.dart';

extension _BookingBlocDriverDiscovery on BookingBloc {
  void _onStartNearbyDriverSearch(
    StartNearbyDriverSearchEvent event,
    Emitter<BookingState> emit,
  ) {
    if (hasActiveBooking || _isCreatingBidSession) return;
    _stopNearbyDriverSearch();
    ++_bookingFlowGeneration;
    final generation = ++_nearbySearchGeneration;
    _nearestSearchCancelled = false;
    _isAutoAcceptingOffer = false;
    _lastFailedDriverSearch = null;
    _nearbySearchRemainingTimeout = _nearbyDriverSearchTimeout;
    _nearbySearchTimedOutWaitingForLookup = false;
    _setTripContext(
      event.trip,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      distanceKm: event.distanceKm,
      durationMinutes: event.durationMinutes,
    );
    emit(
      BookingFindingNearbyDrivers(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        distanceKm: event.distanceKm,
        durationMinutes: event.durationMinutes,
        isLoading: _lifecycleCoordinator.isForeground,
      ),
    );
    _nearbyDriverLifecycleSubscription = _lifecycleCoordinator.changes.listen(
      (status) => _onNearbyDriverLifecycleChanged(status, generation),
    );
    if (!_lifecycleCoordinator.isForeground) return;
    _startNearbySearchTimeoutTimer(generation);
    unawaited(_pollNearbyDrivers(generation: generation));
  }

  void _onNearbyDriverLifecycleChanged(
    AppLifecycleStatus status,
    int generation,
  ) {
    if (isClosed ||
        generation != _nearbySearchGeneration ||
        state is! BookingFindingNearbyDrivers) {
      return;
    }
    if (status == AppLifecycleStatus.background) {
      _nearbyDriverPollTimer?.cancel();
      _nearbyDriverPollTimer = null;
      _pauseNearbySearchTimeoutTimer();
      return;
    }

    final current = state as BookingFindingNearbyDrivers;
    if (current.drivers.isEmpty && current.errorMessage == null) {
      if (_nearbySearchRemainingTimeout > Duration.zero) {
        _startNearbySearchTimeoutTimer(generation);
      } else {
        _nearbySearchTimedOutWaitingForLookup = true;
      }
    }
    unawaited(_pollNearbyDrivers(generation: generation));
  }

  void _startNearbySearchTimeoutTimer(int generation) {
    _nearbyDriverTimeoutTimer?.cancel();
    _nearbyDriverTimeoutTimer = null;
    _nearbySearchTimerStartedAt = null;
    if (isClosed ||
        generation != _nearbySearchGeneration ||
        !_lifecycleCoordinator.isForeground) {
      return;
    }
    if (_nearbySearchRemainingTimeout <= Duration.zero) {
      add(_NearbyDriverSearchTimedOutEvent(generation: generation));
      return;
    }
    _nearbySearchTimerStartedAt = _now();
    _nearbyDriverTimeoutTimer = Timer(_nearbySearchRemainingTimeout, () {
      if (isClosed || generation != _nearbySearchGeneration) return;
      add(_NearbyDriverSearchTimedOutEvent(generation: generation));
    });
  }

  void _pauseNearbySearchTimeoutTimer() {
    if (_nearbyDriverTimeoutTimer == null) return;
    final startedAt = _nearbySearchTimerStartedAt;
    if (startedAt != null) {
      final elapsed = _now().difference(startedAt);
      if (elapsed > Duration.zero) {
        final remaining = _nearbySearchRemainingTimeout - elapsed;
        _nearbySearchRemainingTimeout = remaining > Duration.zero
            ? remaining
            : Duration.zero;
      }
    }
    _nearbyDriverTimeoutTimer?.cancel();
    _nearbyDriverTimeoutTimer = null;
    _nearbySearchTimerStartedAt = null;
  }

  void _cancelNearbySearchTimeoutTimer({bool resetRemaining = false}) {
    _nearbyDriverTimeoutTimer?.cancel();
    _nearbyDriverTimeoutTimer = null;
    _nearbySearchTimerStartedAt = null;
    if (resetRemaining) {
      _nearbySearchRemainingTimeout = _nearbyDriverSearchTimeout;
    }
  }

  void _scheduleNextNearbyDriverPoll({
    required int generation,
    required Duration delay,
  }) {
    _nearbyDriverPollTimer?.cancel();
    _nearbyDriverPollTimer = null;
    if (isClosed ||
        generation != _nearbySearchGeneration ||
        state is! BookingFindingNearbyDrivers ||
        !_lifecycleCoordinator.isForeground) {
      return;
    }
    _nearbyDriverPollTimer = Timer(delay, () {
      unawaited(_pollNearbyDrivers(generation: generation));
    });
  }

  Future<void> _pollNearbyDrivers({required int generation}) async {
    if (isClosed ||
        generation != _nearbySearchGeneration ||
        state is! BookingFindingNearbyDrivers ||
        !_lifecycleCoordinator.isForeground ||
        _isFetchingNearbyDrivers) {
      return;
    }
    final current = state as BookingFindingNearbyDrivers;
    _nearbyDriverPollTimer?.cancel();
    _nearbyDriverPollTimer = null;
    _isFetchingNearbyDrivers = true;
    Result<List<DriverModel>, DomainFailure> result;
    try {
      result = await _driverRepository.getNearbyDriversResult(
        lat: current.pickupLat,
        lng: current.pickupLng,
      );
    } catch (error) {
      result = Err(ServerFailure(ErrorHandler.getErrorMessage(error)));
    } finally {
      _isFetchingNearbyDrivers = false;
    }
    if (isClosed ||
        generation != _nearbySearchGeneration ||
        state is! BookingFindingNearbyDrivers) {
      return;
    }
    add(
      _NearbyDriversPollCompletedEvent(generation: generation, result: result),
    );
  }

  void _onNearbyDriversPollCompleted(
    _NearbyDriversPollCompletedEvent event,
    Emitter<BookingState> emit,
  ) {
    if (event.generation != _nearbySearchGeneration) return;
    final current = state;
    if (current is! BookingFindingNearbyDrivers) return;

    event.result.fold(
      (failure) {
        _cancelNearbySearchTimeoutTimer(resetRemaining: true);
        _nearbySearchTimedOutWaitingForLookup = false;
        emit(
          current.copyWith(
            isLoading: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
        _scheduleNextNearbyDriverPoll(
          generation: event.generation,
          delay: _nearbyDriverActivePollInterval,
        );
      },
      (drivers) {
        final byId = {for (final driver in drivers) driver.id: driver};
        final sorted = byId.values.toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        if (sorted.isNotEmpty) {
          _cancelNearbySearchTimeoutTimer(resetRemaining: true);
          _nearbySearchTimedOutWaitingForLookup = false;
          emit(
            current.copyWith(
              drivers: List.unmodifiable(sorted),
              hasLoaded: true,
              isLoading: false,
              clearErrorMessage: true,
            ),
          );
          _scheduleNextNearbyDriverPoll(
            generation: event.generation,
            delay: _nearbyDriverActivePollInterval,
          );
          return;
        }

        if (_nearbySearchTimedOutWaitingForLookup) {
          _emitNoNearbyDriversFound(emit);
          return;
        }

        emit(
          current.copyWith(
            drivers: const [],
            hasLoaded: true,
            isLoading: false,
            clearErrorMessage: true,
          ),
        );
        if (_nearbyDriverTimeoutTimer == null &&
            _lifecycleCoordinator.isForeground) {
          _nearbySearchRemainingTimeout = _nearbyDriverSearchTimeout;
          _startNearbySearchTimeoutTimer(event.generation);
        }
        _scheduleNextNearbyDriverPoll(
          generation: event.generation,
          delay: _nearbyDriverEmptyPollInterval,
        );
      },
    );
  }

  void _onNearbyDriverSearchTimedOut(
    _NearbyDriverSearchTimedOutEvent event,
    Emitter<BookingState> emit,
  ) {
    if (event.generation != _nearbySearchGeneration) return;
    final current = state;
    if (current is! BookingFindingNearbyDrivers) return;

    _nearbyDriverTimeoutTimer?.cancel();
    _nearbyDriverTimeoutTimer = null;
    _nearbySearchTimerStartedAt = null;
    _nearbySearchRemainingTimeout = Duration.zero;

    if (current.drivers.isNotEmpty || current.errorMessage != null) {
      return;
    }
    if (!current.hasLoaded) {
      _nearbySearchTimedOutWaitingForLookup = true;
      return;
    }
    _emitNoNearbyDriversFound(emit);
  }

  void _emitNoNearbyDriversFound(Emitter<BookingState> emit) {
    _stopNearbyDriverSearch();
    _captureFailedDriverSearch();
    _activeTrip = null;
    emit(
      BookingFailure(
        ErrorHandler.getErrorMessage(const NoDriversAvailableFailure()),
        isNoDriverFound: true,
      ),
    );
  }

  void _stopNearbyDriverSearch() {
    ++_nearbySearchGeneration;
    _nearbyDriverPollTimer?.cancel();
    _nearbyDriverPollTimer = null;
    _nearbyDriverTimeoutTimer?.cancel();
    _nearbyDriverTimeoutTimer = null;
    _nearbySearchTimerStartedAt = null;
    _nearbySearchRemainingTimeout = Duration.zero;
    _nearbySearchTimedOutWaitingForLookup = false;
    _isFetchingNearbyDrivers = false;
    unawaited(_nearbyDriverLifecycleSubscription?.cancel());
    _nearbyDriverLifecycleSubscription = null;
  }

  Future<void> _onLocateNearestDriver(
    LocateNearestDriverEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveDriverSearch) return;
    _stopNearbyDriverSearch();
    ++_bookingFlowGeneration;
    _nearestSearchCancelled = false;
    _isAutoAcceptingOffer = false;
    _lastFailedDriverSearch = null;
    _totalTrips = null;
    ++_reviewsRequestGeneration;
    _activeTrip = event.trip;
    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = _pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _distanceKm = null;
    _durationMinutes = null;
    emit(
      FindingNearestDriver(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );

    List<DriverModel> nearbyDrivers = [];
    Failure? lastFailure;
    var lastLookupSucceeded = false;

    for (int attempt = 0; attempt < _nearestDriverMaxAttempts; attempt++) {
      final result = await _driverRepository.getNearbyDriversResult(
        lat: event.pickupLat,
        lng: event.pickupLng,
      );
      if (isClosed || _nearestSearchCancelled) return;

      result.fold(
        (failure) {
          lastFailure = failure;
          lastLookupSucceeded = false;
        },
        (drivers) {
          lastLookupSucceeded = true;
          lastFailure = null;
          nearbyDrivers = drivers;
        },
      );

      if (nearbyDrivers.isNotEmpty) break;
      if (!lastLookupSucceeded) break;
      if (attempt + 1 < _nearestDriverMaxAttempts) {
        await Future.delayed(_nearestDriverRetryDelay);
      }
      if (isClosed || _nearestSearchCancelled) return;
    }

    if (nearbyDrivers.isEmpty) {
      if (!lastLookupSucceeded && lastFailure != null) {
        _activeTrip = null;
        emit(BookingFailure(ErrorHandler.getErrorMessage(lastFailure!)));
        return;
      }
      if (isClosed || _nearestSearchCancelled) return;
      _captureFailedDriverSearch();
      _activeTrip = null;
      emit(
        BookingFailure(
          lastFailure == null
              ? ErrorHandler.getErrorMessage(const NoDriversAvailableFailure())
              : ErrorHandler.getErrorMessage(lastFailure!),
          isNoDriverFound: true,
        ),
      );
      return;
    }

    DriverModel closestDriver = nearbyDrivers.first;
    for (final d in nearbyDrivers) {
      if (d.distanceKm < closestDriver.distanceKm) {
        closestDriver = d;
      }
    }
    final reviewsRequestGeneration = ++_reviewsRequestGeneration;
    emit(
      NearestDriverFound(
        driver: closestDriver,
        nearbyDrivers: nearbyDrivers,
        totalTrips: null,
        reviewsDriverId: closestDriver.id,
        reviews: const [],
        isLoadingReviews: true,
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );

    int? loadedTotalTrips;
    List<DriverReview> loadedReviews = const [];
    await Future.wait<void>([
      _loadDriverTripCount(closestDriver.id).then((value) {
        loadedTotalTrips = value;
      }),
      _loadDriverReviews(closestDriver.id).then((value) {
        loadedReviews = value;
      }),
    ]);
    if (isClosed || _nearestSearchCancelled) return;
    _totalTrips = loadedTotalTrips;
    final currentState = state;
    if (currentState is NearestDriverFound) {
      final reviewsAreCurrent =
          reviewsRequestGeneration == _reviewsRequestGeneration;
      emit(
        currentState.copyWith(
          totalTrips: _totalTrips,
          reviews: reviewsAreCurrent ? loadedReviews : null,
          isLoadingReviews: reviewsAreCurrent ? false : null,
        ),
      );
    }
  }

  Future<int?> _loadDriverTripCount(String driverId) async {
    int? totalTrips;
    (await _driverProfileRepository.fetchStatsResult(driverId)).fold(
      (failure) => dev.log('Unable to load driver stats: ${failure.message}'),
      (stats) => totalTrips = stats.completedTrips,
    );
    return totalTrips;
  }

  Future<List<DriverReview>> _loadDriverReviews(String driverId) async {
    List<DriverReview> reviews = const [];
    (await _driverProfileRepository.fetchReviewsResult(
      driverId,
      page: 1,
      limit: 6,
    )).fold(
      (failure) => dev.log('Failed to process reviews: ${failure.message}'),
      (values) => reviews = List<DriverReview>.unmodifiable(values.items),
    );
    return reviews;
  }

  Future<void> _onLoadDriverReviews(
    LoadDriverReviewsEvent event,
    Emitter<BookingState> emit,
  ) async {
    final driverId = event.driverId.trim();
    final currentState = state;
    if (driverId.isEmpty || currentState is! NearestDriverFound) return;
    if (currentState.reviewsDriverId == driverId) return;

    final requestGeneration = ++_reviewsRequestGeneration;
    emit(
      currentState.copyWith(
        reviewsDriverId: driverId,
        reviews: const [],
        isLoadingReviews: true,
      ),
    );

    final reviews = await _loadDriverReviews(driverId);
    if (isClosed || requestGeneration != _reviewsRequestGeneration) return;
    final latestState = state;
    if (latestState is! NearestDriverFound ||
        latestState.reviewsDriverId != driverId) {
      return;
    }

    emit(latestState.copyWith(reviews: reviews, isLoadingReviews: false));
  }
}
