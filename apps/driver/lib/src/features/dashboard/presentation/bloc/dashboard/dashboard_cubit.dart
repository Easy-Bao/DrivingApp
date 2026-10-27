import 'package:driver/src/features/active_ride/active_ride.dart';

import 'dart:developer' as dev;

import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/features/dashboard/domain/repositories/dashboard_repository.dart';
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
  bool _isDispatchRequestInFlight = false;
  int _activeRideRevision = 0;
  int _submittedOfferRevision = 0;
  Future<void>? _initialization;
  Future<void>? _statsRequestInFlight;
  DateTime? _silentDispatchRetryAfter;
  final Map<String, DateTime> _resolvedOfferSessions = <String, DateTime>{};
  final Set<String> _terminalRideIds = <String>{};

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
      onlineStatusResult.fold(
        (failure) => dev.log(
          'Unable to restore driver online status: ${failure.message}',
        ),
        (isOnline) {
          if (isClosed) return;
          emit(state.copyWith(isOnline: isOnline));
        },
      );
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
      result.fold(
        (failure) {
          if (isClosed) return;
          emit(
            state.copyWith(
              isLoadingStats: false,
              statsErrorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        },
        (stats) {
          if (isClosed) return;
          emit(
            state.copyWith(
              isLoadingStats: false,
              hasLoadedStats: true,
              earnings: stats.earnings,
              completedTrips: stats.completedTrips,
              statsErrorMessage: null,
            ),
          );
        },
      );
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
      return await result.fold(
        (failure) {
          if (_pausesSilentDispatch(failure)) {
            _silentDispatchRetryAfter = _now().add(
              _silentDispatchFailureCooldown,
            );
          }
          // A settlement block is persistent and explains why no requests
          // arrive, so it is surfaced even for silent background polls.
          final isSettlementBlock =
              failure is ServerFailure && failure.statusCode == 409;
          if (!silent || isSettlementBlock) {
            if (isClosed) return false;
            emit(
              state.copyWith(
                isLoadingDispatch: false,
                // The generic user message would replace the specific reason
                // the server gave for the settlement block.
                errorMessage: isSettlementBlock
                    ? failure.message
                    : ErrorHandler.getErrorMessage(failure),
              ),
            );
          }
          return false;
        },
        (snapshot) {
          if (isClosed) return false;
          if (activeRideRevision != _activeRideRevision) {
            emit(state.copyWith(isLoadingDispatch: false, errorMessage: null));
            return true;
          }
          final snapshotIds = snapshot.activeRides
              .map((ride) => ride.id)
              .toSet();
          for (final current in state.activeRides) {
            if (!snapshotIds.contains(current.id))
              _terminalRideIds.add(current.id);
          }
          for (final ride in snapshot.activeRides.where(
            (ride) => ride.isTerminal,
          )) {
            _terminalRideIds.add(ride.id);
          }
          final activeRides = List<RideSnapshot>.unmodifiable(
            snapshot.activeRides.where(
              (ride) =>
                  ride.id.isNotEmpty &&
                  !ride.isTerminal &&
                  !_terminalRideIds.contains(ride.id),
            ),
          );
          final isFull = activeRides.length >= DashboardState.maxActiveBookings;
          _silentDispatchRetryAfter = null;
          final offeredSessions = <Map<String, dynamic>>[];
          final submittedOffers = <Map<String, dynamic>>[];
          if (shouldIncludeOffers) {
            for (final bid in snapshot.rideOffers) {
              final sessionId = _stringValue(bid['id']);
              if (sessionId != null && _isResolvedOfferSession(sessionId)) {
                continue;
              }
              if (_hasSubmittedOffer(bid)) {
                submittedOffers.add(bid);
              } else {
                offeredSessions.add(bid);
              }
            }
          }
          if (submittedOfferRevision != _submittedOfferRevision) {
            final submittedSessionIds = submittedOffers
                .map((offer) => _stringValue(offer['id']))
                .whereType<String>()
                .toSet();
            for (final offer in state.submittedOffers) {
              final sessionId = _stringValue(offer['id']);
              if (offer['local_offer_submitted'] == true &&
                  sessionId != null &&
                  !submittedSessionIds.contains(sessionId) &&
                  !_isResolvedOfferSession(sessionId)) {
                submittedOffers.add(offer);
              }
            }
            final preservedSessionIds = submittedOffers
                .where((offer) => offer['local_offer_submitted'] == true)
                .map((offer) => _stringValue(offer['id']))
                .whereType<String>()
                .toSet();
            offeredSessions.removeWhere(
              (bid) => preservedSessionIds.contains(_stringValue(bid['id'])),
            );
          }
          emit(
            state.copyWith(
              isLoadingDispatch: false,
              activeRides: activeRides,
              activeBids: isFull
                  ? const <Map<String, dynamic>>[]
                  : shouldIncludeOffers
                  ? _immutableMaps(offeredSessions)
                  : null,
              submittedOffers: isFull
                  ? const <Map<String, dynamic>>[]
                  : shouldIncludeOffers
                  ? _immutableMaps(submittedOffers)
                  : null,
              errorMessage: null,
            ),
          );
          return true;
        },
      );
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

  bool _pausesSilentDispatch(Failure failure) =>
      failure is NetworkFailure ||
      (failure is ServerFailure &&
          (failure.statusCode == null || failure.statusCode! >= 500));

  void mergeActiveRide(RideSnapshot ride) {
    if (ride.id.isEmpty) return;
    if (ride.isTerminal) {
      removeActiveRide(ride.id);
      return;
    }
    if (_terminalRideIds.contains(ride.id)) return;
    _activeRideRevision++;
    final rides = List<RideSnapshot>.unmodifiable([
      for (final current in state.activeRides)
        if (current.id == ride.id) ride else current,
      if (!state.activeRides.any((current) => current.id == ride.id)) ride,
    ]);
    final isFull = rides.length >= DashboardState.maxActiveBookings;
    emit(
      state.copyWith(
        activeRides: rides,
        activeBids: isFull ? const [] : null,
        submittedOffers: isFull ? const [] : null,
      ),
    );
  }

  void removeActiveRide(String? rideId) {
    if (rideId == null || rideId.isEmpty) return;
    final removesCurrentRide = state.activeRides.any(
      (ride) => ride.id == rideId,
    );
    final addedTombstone = _terminalRideIds.add(rideId);
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
        .where((bid) => _stringValue(bid['id']) != bidId)
        .toList(growable: false);
    if (remaining.length == state.activeBids.length) return;
    emit(state.copyWith(activeBids: remaining));
  }

  bool removeExpiredRideOffers() {
    final now = _now();
    final remaining = state.activeBids
        .where((bid) {
          final expiresAt = DateTime.tryParse(
            _stringValue(bid['expires_at']) ?? '',
          );
          return expiresAt == null || expiresAt.isAfter(now);
        })
        .toList(growable: false);
    final remainingSubmitted = state.submittedOffers
        .where((offer) {
          final expiresAt = DateTime.tryParse(
            _stringValue(offer['expires_at']) ?? '',
          );
          return expiresAt == null || expiresAt.isAfter(now);
        })
        .toList(growable: false);
    _resolvedOfferSessions.removeWhere(
      (_, expiresAt) => !expiresAt.isAfter(now),
    );
    if (remaining.length == state.activeBids.length &&
        remainingSubmitted.length == state.submittedOffers.length) {
      return false;
    }
    final submittedOfferExpired =
        remainingSubmitted.length < state.submittedOffers.length;
    emit(
      state.copyWith(
        activeBids: remaining,
        submittedOffers: remainingSubmitted,
      ),
    );
    return submittedOfferExpired;
  }

  void clearActiveBids() {
    _resolvedOfferSessions.clear();
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
    if (_isResolvedOfferSession(sessionId)) {
      removeActiveBid(sessionId);
      return;
    }
    final matchingBid = state.activeBids.where(
      (bid) => _stringValue(bid['id']) == sessionId,
    );
    if (matchingBid.isEmpty) return;

    final submitted = Map<String, dynamic>.from(matchingBid.first)
      ..['local_offer_submitted'] = true;
    final activeBids = state.activeBids
        .where((bid) => _stringValue(bid['id']) != sessionId)
        .toList(growable: false);
    final submittedOffers = [
      ...state.submittedOffers.where(
        (offer) => _stringValue(offer['id']) != sessionId,
      ),
      submitted,
    ];
    emit(
      state.copyWith(
        activeBids: _immutableMaps(activeBids),
        submittedOffers: _immutableMaps(submittedOffers),
      ),
    );
    _submittedOfferRevision++;
  }

  bool resolveSubmittedOffer(String? sessionId) {
    if (sessionId == null) return false;
    final candidates = [...state.submittedOffers, ...state.activeBids];
    Map<String, dynamic>? matchingBid;
    for (final bid in candidates) {
      if (_stringValue(bid['id']) == sessionId) {
        matchingBid = bid;
        break;
      }
    }
    if (matchingBid == null) return false;

    final expiresAt = DateTime.tryParse(
      _stringValue(matchingBid['expires_at']) ?? '',
    );
    if (expiresAt != null && expiresAt.isAfter(_now())) {
      _resolvedOfferSessions[sessionId] = expiresAt;
    }
    emit(
      state.copyWith(
        activeBids: _immutableMaps(
          state.activeBids.where((bid) => _stringValue(bid['id']) != sessionId),
        ),
        submittedOffers: _immutableMaps(
          state.submittedOffers.where(
            (offer) => _stringValue(offer['id']) != sessionId,
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
    return result.fold(
      (failure) {
        emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        );
        return false;
      },
      (_) {
        removeActiveBid(sessionId);
        return true;
      },
    );
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
      return await result.fold(
        (failure) {
          if (isClosed) return false;
          emit(
            state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
          );
          return false;
        },
        (_) {
          markOfferSubmitted(sessionId);
          return true;
        },
      );
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
      return await result.fold((failure) {
        dev.log('Unable to refresh driver trip $rideId: ${failure.message}');
        return null;
      }, (ride) => ride);
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

      updateResult.fold(
        (failure) {
          if (isClosed) return;
          emit(
            state.copyWith(
              isOnline: previousOnline,
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        },
        (_) {
          if (isClosed) return;
          emit(state.copyWith(isOnline: goingOnline, errorMessage: null));
        },
      );
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
    }
  }

  Future<void> forceOffline({required double lat, required double lng}) async {
    final updateResult = await _repository.updateOnlineStatusResult(
      isOnline: false,
      lat: lat,
      lng: lng,
    );
    if (isClosed) return;

    updateResult.fold(
      (failure) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isOnline: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
      },
      (_) {
        if (isClosed) return;
        emit(state.copyWith(isOnline: false, errorMessage: null));
      },
    );
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
    return updateResult.fold((failure) async {
      if (isClosed) return false;
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
    }, (_) => true);
  }

  bool _isAuthoritativeAvailabilityRejection(Failure failure) {
    return failure is ServerFailure &&
        (failure.statusCode == 403 || failure.statusCode == 404);
  }

  static List<Map<String, dynamic>> _immutableMaps(
    Iterable<Map<String, dynamic>> values,
  ) {
    return List<Map<String, dynamic>>.unmodifiable(
      values.map(Map<String, dynamic>.from),
    );
  }

  bool _hasSubmittedOffer(Map<String, dynamic> bid) {
    if (bid['local_offer_submitted'] == true) return true;
    final offers = bid['offers'];
    if (offers is! List) return false;
    return offers.any(
      (offer) =>
          offer is Map &&
          _stringValue(offer['status'])?.toLowerCase() == 'pending',
    );
  }

  bool _isResolvedOfferSession(String sessionId) {
    final expiresAt = _resolvedOfferSessions[sessionId];
    if (expiresAt == null) return false;
    if (expiresAt.isAfter(_now())) return true;
    _resolvedOfferSessions.remove(sessionId);
    return false;
  }

  static String? _stringValue(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
