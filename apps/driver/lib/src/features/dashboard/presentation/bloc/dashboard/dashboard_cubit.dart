import 'dart:developer' as dev;

import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_offer_store.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class DashboardCubit({
  required this._repository,
  DateTime Function()? now,
  this._silentDispatchFailureCooldown = const Duration(seconds: 15),
}) extends Cubit<DashboardState> {
  final DashboardRepository _repository;
  final DateTime Function() _now;
  final Duration _silentDispatchFailureCooldown;
  late final DashboardOfferStore _offerStore = DashboardOfferStore(now: _now);
  bool _isDispatchRequestInFlight = false;
  bool _isTogglingOnline = false;
  int _activeRideRevision = 0;
  int _submittedOfferRevision = 0;
  Future<void>? _initialization;
  Future<void>? _statsRequestInFlight;
  DateTime? _silentDispatchRetryAfter;

  this : _now = now ?? DateTime.now, super(const DashboardState());

  Future<void> initialize() async {
    final existingInitialization = _initialization;
    if (existingInitialization != null) {
      await existingInitialization;
      return;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    }
  }

  void dismissError() {
    if (isClosed) return;
    emit(state.copyWith(errorMessage: null, statsErrorMessage: null));
  }

  Future<void> _initialize() async {
    try {
      final onlineStatusResult = await _repository
          .getPersistedOnlineStatusResult();
      switch (onlineStatusResult) {
        case Err(:final failure):
          dev.log('Unable to restore driver online status: ${failure.message}');
        case Ok(value: final isOnline):
          if (!isClosed) emit(state.copyWith(isOnline: isOnline));
      }
    } catch (error, stackTrace) {
      dev.log(
        'Unable to restore driver online status.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (isClosed) return;
    await loadStats();
  }

  Future<void> loadStats() {
    final existingRequest = _statsRequestInFlight;
    if (existingRequest != null) return existingRequest;

    late final Future<void> request;
    request = _loadStats().whenComplete(() {
      if (identical(_statsRequestInFlight, request)) {
        _statsRequestInFlight = null;
      }
    });
    _statsRequestInFlight = request;
    return request;
  }

  Future<void> _loadStats() async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingStats: true, statsErrorMessage: null));
    try {
      final result = await _repository.getDashboardStatsResult();
      if (isClosed) return;
      switch (result) {
        case Err(:final failure):
          emit(
            state.copyWith(
              isLoadingStats: false,
              statsErrorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        case Ok(value: final stats):
          emit(
            state.copyWith(
              isLoadingStats: false,
              hasLoadedStats: true,
              earnings: stats.earnings,
              completedTrips: stats.completedTrips,
              statsErrorMessage: null,
            ),
          );
      }
    } catch (error) {
      if (isClosed) return;
      dev.log('Error loading driver dashboard stats: $error');
      emit(
        state.copyWith(
          isLoadingStats: false,
          statsErrorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<bool> loadDispatchSnapshot({
    bool includeOffers = true,
    bool silent = false,
    bool force = false,
  }) async {
    if (silent && !force && _isSilentDispatchCoolingDown) return false;
    if (_isDispatchRequestInFlight) return false;
    _isDispatchRequestInFlight = true;
    if (!silent) {
      emit(state.copyWith(isLoadingDispatch: true, errorMessage: null));
    }
    final activeRideRevision = _activeRideRevision;
    final submittedOfferRevision = _submittedOfferRevision;

    try {
      final shouldIncludeOffers = includeOffers && !state.isAtBookingCapacity;
      final result = await _repository.getDispatchSnapshotResult(
        includeOffers: shouldIncludeOffers,
      );
      if (isClosed) return false;
      switch (result) {
        case Err(:final failure):
          if (_pausesSilentDispatch(failure)) {
            _silentDispatchRetryAfter = _now().add(
              _silentDispatchFailureCooldown,
            );
          }
          if (!silent && !isClosed) {
            emit(
              state.copyWith(
                isLoadingDispatch: false,
                errorMessage: ErrorHandler.getErrorMessage(failure),
              ),
            );
          }
          return false;
        case Ok(value: final snapshot):
          if (activeRideRevision != _activeRideRevision) {
            emit(state.copyWith(isLoadingDispatch: false, errorMessage: null));
            return true;
          }
          final snapshotIds = snapshot.activeRides
              .map((ride) => ride.id)
              .toSet();
          for (final current in state.activeRides) {
            if (!snapshotIds.contains(current.id)) {
              _offerStore.recordTerminalRideId(current.id);
            }
          }
          for (final ride in snapshot.activeRides.where(
            (ride) => ride.isTerminal,
          )) {
            _offerStore.recordTerminalRideId(ride.id);
          }
          final activeRides = List<RideSnapshot>.unmodifiable(
            snapshot.activeRides.where(
              (ride) =>
                  ride.id.isNotEmpty &&
                  !ride.isTerminal &&
                  !_offerStore.isTerminalRide(ride.id),
            ),
          );
          final isFull = activeRides.length >= DashboardState.maxActiveBookings;
          _silentDispatchRetryAfter = null;
          final partitioned = shouldIncludeOffers
              ? _offerStore.partitionSnapshotOffers(
                  snapshotOffers: snapshot.rideOffers,
                  currentSubmittedOffers: state.submittedOffers,
                  preserveLocalSubmissions:
                      submittedOfferRevision != _submittedOfferRevision,
                )
              : null;
          emit(
            state.copyWith(
              isLoadingDispatch: false,
              activeRides: activeRides,
              activeBids: isFull
                  ? const <Map<String, dynamic>>[]
                  : partitioned?.activeBids,
              submittedOffers: isFull
                  ? const <Map<String, dynamic>>[]
                  : partitioned?.submittedOffers,
              errorMessage: null,
            ),
          );
          return true;
      }
    } catch (error, stackTrace) {
      if (isClosed) return false;
      dev.log(
        'Unable to load driver dispatch snapshot.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!silent) {
        emit(
          state.copyWith(
            isLoadingDispatch: false,
            errorMessage: ErrorHandler.getErrorMessage(error),
          ),
        );
      }
      _silentDispatchRetryAfter = _now().add(_silentDispatchFailureCooldown);
      return false;
    } finally {
      _isDispatchRequestInFlight = false;
    }
  }

  Future<void> resyncActiveTrip() async {
    await loadDispatchSnapshot(includeOffers: true, silent: true, force: true);
  }

  bool get _isSilentDispatchCoolingDown {
    final retryAfter = _silentDispatchRetryAfter;
    if (retryAfter == null) return false;
    if (!_now().isBefore(retryAfter)) {
      _silentDispatchRetryAfter = null;
      return false;
    }
    return true;
  }

  bool _pausesSilentDispatch(Failure failure) {
    if (failure is NetworkFailure) return true;
    if (failure case ServerFailure(:final statusCode)) {
      return statusCode == null || statusCode >= 500;
    }
    return false;
  }

  void mergeActiveRide(RideSnapshot ride, {String? sessionId}) {
    if (ride.id.isEmpty) return;
    if (ride.isTerminal) {
      removeActiveRide(ride.id);
      return;
    }
    if (_offerStore.isTerminalRide(ride.id)) return;
    _activeRideRevision++;
    final rides = List<RideSnapshot>.unmodifiable([
      for (final current in state.activeRides)
        if (current.id == ride.id) ride else current,
      if (!state.activeRides.any((current) => current.id == ride.id)) ride,
    ]);
    final isFull = rides.length >= DashboardState.maxActiveBookings;
    final resolvedSessionId = DashboardOfferStore.normalizedString(sessionId);
    if (resolvedSessionId != null) {
      _offerStore.recordResolvedOfferSession(
        resolvedSessionId,
        candidates: [...state.submittedOffers, ...state.activeBids],
      );
      _submittedOfferRevision++;
    }
    emit(
      state.copyWith(
        activeRides: rides,
        activeBids: isFull
            ? const []
            : resolvedSessionId != null
            ? DashboardOfferStore.immutableMaps(
                state.activeBids.where(
                  (bid) =>
                      DashboardOfferStore.normalizedString(bid['id']) !=
                      resolvedSessionId,
                ),
              )
            : null,
        submittedOffers: isFull
            ? const []
            : resolvedSessionId != null
            ? DashboardOfferStore.immutableMaps(
                state.submittedOffers.where(
                  (offer) =>
                      DashboardOfferStore.normalizedString(offer['id']) !=
                      resolvedSessionId,
                ),
              )
            : null,
      ),
    );
  }

  void removeActiveRide(String? rideId) {
    if (rideId == null || rideId.isEmpty) return;
    final removesCurrentRide = state.activeRides.any(
      (ride) => ride.id == rideId,
    );
    final addedTombstone = _offerStore.recordTerminalRideId(rideId);
    if (!addedTombstone && !removesCurrentRide) return;
    _activeRideRevision++;
    if (!removesCurrentRide) return;
    emit(
      state.copyWith(
        activeRides: List.unmodifiable(
          state.activeRides.where((ride) => ride.id != rideId),
        ),
      ),
    );
  }

  void removeActiveBid(String? bidId) {
    if (bidId == null) return;
    final remaining = state.activeBids
        .where(
          (bid) => DashboardOfferStore.normalizedString(bid['id']) != bidId,
        )
        .toList(growable: false);
    if (remaining.length == state.activeBids.length) return;
    emit(state.copyWith(activeBids: remaining));
  }

  bool removeExpiredRideOffers() {
    final pruned = _offerStore.pruneExpiredOffers(
      activeBids: state.activeBids,
      submittedOffers: state.submittedOffers,
    );
    if (!pruned.changed) return false;
    emit(
      state.copyWith(
        activeBids: pruned.activeBids,
        submittedOffers: pruned.submittedOffers,
      ),
    );
    return pruned.submittedOfferExpired;
  }

  void clearActiveBids() {
    _offerStore.clearResolvedOffers();
    if (state.activeBids.isEmpty && state.submittedOffers.isEmpty) return;
    emit(
      state.copyWith(
        activeBids: const <Map<String, dynamic>>[],
        submittedOffers: const <Map<String, dynamic>>[],
      ),
    );
  }

  void markOfferSubmitted(String? sessionId) {
    if (sessionId == null || state.isAtBookingCapacity) return;
    if (_offerStore.isResolvedOfferSession(sessionId)) {
      removeActiveBid(sessionId);
      return;
    }
    final matchingBid = state.activeBids.where(
      (bid) => DashboardOfferStore.normalizedString(bid['id']) == sessionId,
    );
    if (matchingBid.isEmpty) return;

    final submitted = Map<String, dynamic>.from(matchingBid.first)
      ..['local_offer_submitted'] = true;
    final activeBids = state.activeBids
        .where(
          (bid) => DashboardOfferStore.normalizedString(bid['id']) != sessionId,
        )
        .toList(growable: false);
    final submittedOffers = [
      ...state.submittedOffers.where(
        (offer) =>
            DashboardOfferStore.normalizedString(offer['id']) != sessionId,
      ),
      submitted,
    ];
    emit(
      state.copyWith(
        activeBids: DashboardOfferStore.immutableMaps(activeBids),
        submittedOffers: DashboardOfferStore.immutableMaps(submittedOffers),
      ),
    );
    _submittedOfferRevision++;
  }

  bool resolveSubmittedOffer(String? sessionId) {
    final resolvedSessionId = DashboardOfferStore.normalizedString(sessionId);
    if (resolvedSessionId == null) return false;
    final hasMatchingBid =
        state.submittedOffers.any(
          (offer) =>
              DashboardOfferStore.normalizedString(offer['id']) ==
              resolvedSessionId,
        ) ||
        state.activeBids.any(
          (bid) =>
              DashboardOfferStore.normalizedString(bid['id']) ==
              resolvedSessionId,
        );
    _offerStore.recordResolvedOfferSession(
      resolvedSessionId,
      candidates: [...state.submittedOffers, ...state.activeBids],
    );
    if (!hasMatchingBid) return false;

    emit(
      state.copyWith(
        activeBids: DashboardOfferStore.immutableMaps(
          state.activeBids.where(
            (bid) =>
                DashboardOfferStore.normalizedString(bid['id']) !=
                resolvedSessionId,
          ),
        ),
        submittedOffers: DashboardOfferStore.immutableMaps(
          state.submittedOffers.where(
            (offer) =>
                DashboardOfferStore.normalizedString(offer['id']) !=
                resolvedSessionId,
          ),
        ),
      ),
    );
    _submittedOfferRevision++;
    return true;
  }

  Future<bool> declineRideRequest(String sessionId) async {
    final result = await _repository.declineRideRequestResult(sessionId);
    if (isClosed) return false;
    return switch (result) {
      Err(:final failure) => () {
        emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        );
        return false;
      }(),
      Ok() => () {
        removeActiveBid(sessionId);
        return true;
      }(),
    };
  }

  Future<bool> submitRideOffer({
    required String sessionId,
    required double farePesos,
  }) async {
    try {
      final result = await _repository.submitRideOfferResult(
        sessionId: sessionId,
        farePesos: farePesos,
      );
      if (isClosed) return false;
      return switch (result) {
        Err(:final failure) => () {
          emit(
            state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
          );
          return false;
        }(),
        Ok() => () {
          markOfferSubmitted(sessionId);
          return true;
        }(),
      };
    } catch (error, stackTrace) {
      if (isClosed) return false;
      dev.log(
        'Unable to submit driver ride offer.',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(error)));
      return false;
    }
  }

  Future<RideSnapshot?> fetchAuthoritativeRide(String rideId) async {
    try {
      final result = await _repository.fetchRideResult(rideId);
      return switch (result) {
        Err(:final failure) => () {
          dev.log('Unable to refresh driver trip $rideId: ${failure.message}');
          return null;
        }(),
        Ok(value: final ride) => ride,
      };
    } catch (error, stackTrace) {
      dev.log(
        'Unable to refresh driver trip $rideId.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> toggleOnline({
    required double lat,
    required double lng,
    bool? requestedOnline,
  }) async {
    if (_isTogglingOnline) return;
    _isTogglingOnline = true;
    final goingOnline = requestedOnline ?? !state.isOnline;
    final previousOnline = state.isOnline;
    emit(state.copyWith(isOnline: goingOnline, errorMessage: null));

    try {
      final updateResult = await _repository.updateOnlineStatusResult(
        isOnline: goingOnline,
        lat: lat,
        lng: lng,
      );
      if (isClosed) return;

      switch (updateResult) {
        case Err(:final failure):
          emit(
            state.copyWith(
              isOnline: previousOnline,
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        case Ok():
          emit(state.copyWith(isOnline: goingOnline, errorMessage: null));
      }
    } catch (error, stackTrace) {
      if (isClosed) return;
      dev.log(
        'Unable to update driver online status.',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isOnline: previousOnline,
          errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
        ),
      );
    } finally {
      _isTogglingOnline = false;
    }
  }

  Future<void> forceOffline({required double lat, required double lng}) async {
    final updateResult = await _repository.updateOnlineStatusResult(
      isOnline: false,
      lat: lat,
      lng: lng,
    );
    if (isClosed) return;

    switch (updateResult) {
      case Err(:final failure):
        emit(
          state.copyWith(
            isOnline: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
      case Ok():
        emit(state.copyWith(isOnline: false, errorMessage: null));
    }
  }

  Future<bool> publishDriverLocation({
    required double lat,
    required double lng,
  }) async {
    if (!state.isOnline || (lat == 0 && lng == 0)) return false;
    final result = await _repository.publishDriverLocationResult(
      lat: lat,
      lng: lng,
    );
    if (isClosed) return false;
    return switch (result) {
      Err(:final failure) => () {
        dev.log('Unable to publish driver location: ${failure.runtimeType}');
        return false;
      }(),
      Ok() => true,
    };
  }

  Future<bool> refreshOnlinePresence({
    required double lat,
    required double lng,
  }) async {
    if (!state.isOnline) return false;

    final updateResult = await _repository.updateOnlineStatusResult(
      isOnline: true,
      lat: lat,
      lng: lng,
    );
    if (isClosed) return false;
    switch (updateResult) {
      case Ok():
        return true;
      case Err(:final failure):
        if (_isAuthoritativeAvailabilityRejection(failure)) {
          await _repository.updateOnlineStatusResult(
            isOnline: false,
            lat: lat,
            lng: lng,
          );
          if (isClosed) return false;
          emit(
            state.copyWith(
              isOnline: false,
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
          return false;
        }
        // Presence is background work; transient failures must not interrupt the UI.
        dev.log('Unable to refresh driver presence: ${failure.runtimeType}');
        return false;
    }
  }

  Future<bool> checkOnlineInactivity() async {
    if (!state.isOnline) return false;
    try {
      final onlineStatusResult = await _repository
          .getPersistedOnlineStatusResult();
      if (isClosed) return false;
      return switch (onlineStatusResult) {
        Err() => false,
        Ok(value: final isOnline) => () {
          if (!isOnline && state.isOnline) {
            emit(state.copyWith(isOnline: false));
            return true;
          }
          return false;
        }(),
      };
    } catch (error, stackTrace) {
      dev.log(
        'Unable to verify online inactivity: $error',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> recordActivity() async {
    if (!state.isOnline) return;
    try {
      await _repository.recordActivityResult();
    } catch (error, stackTrace) {
      dev.log(
        'Unable to record driver activity: $error',
        stackTrace: stackTrace,
      );
    }
  }

  bool _isAuthoritativeAvailabilityRejection(Failure failure) {
    return failure is ServerFailure &&
        (failure.statusCode == 403 || failure.statusCode == 404);
  }
}
