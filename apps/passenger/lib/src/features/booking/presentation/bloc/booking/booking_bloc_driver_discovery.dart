part of 'booking_bloc.dart';

extension _BookingBlocDriverDiscovery on BookingBloc {
  Future<void> _onLocateNearestDriver(
    LocateNearestDriverEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveDriverSearch) return;
    _nearestSearchCancelled = false;
    _noDriverNotificationSent = false;
    _isAutoAcceptingOffer = false;
    _totalTrips = null;
    ++_reviewsRequestGeneration;
    _activeTrip = event.trip;
    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = this._pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
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
      if (!_nearestSearchCancelled) {
        _notifyNoDriverFound();
      }
      if (isClosed || _nearestSearchCancelled) return;
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
      (values) => reviews = List<DriverReview>.unmodifiable(values),
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

  void _notifyNoDriverFound() {
    final inboxCubit = _inboxCubit;
    if (_noDriverNotificationSent ||
        inboxCubit == null ||
        inboxCubit.isClosed) {
      return;
    }
    _noDriverNotificationSent = true;
    inboxCubit.addLocalNotification(
      InboxNotification(
        id: 'no-driver-${DateTime.now().millisecondsSinceEpoch}',
        title: 'No drivers nearby',
        message: 'Try searching again when you’re ready.',
        timestamp: DateTime.now(),
        type: 'driver',
        isRead: false,
      ),
    );
  }
}
