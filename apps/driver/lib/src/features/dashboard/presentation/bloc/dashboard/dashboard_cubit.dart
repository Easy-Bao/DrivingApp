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
  Future<void>? _initialization;
  Future<void>? _statsRequestInFlight;
  DateTime? _silentDispatchRetryAfter;
  DateTime? _onlineSince;

  this : _now = now ?? DateTime.now, super(const DashboardState());

  DateTime? get onlineSince => _onlineSince;

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
          if (!isOnline) _onlineSince = null;
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
    final onlineSinceResult = await _repository.getPersistedOnlineSinceResult();
    if (isClosed) return;
    onlineSinceResult.fold(
      (failure) => dev.log(
        'Unable to restore the driver shift timer: ${failure.message}',
      ),
      (value) {
        _onlineSince = state.isOnline ? value ?? _now() : null;
      },
    );
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

    try {
      final shouldIncludeOffers = includeOffers && !state.hasActiveRide;
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
          if (!silent) {
            if (isClosed) return false;
            emit(
              state.copyWith(
                isLoadingDispatch: false,
                errorMessage: ErrorHandler.getErrorMessage(failure),
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
          _silentDispatchRetryAfter = null;
          emit(
            state.copyWith(
              isLoadingDispatch: false,
              activeRide: snapshot.activeRide,
              activeBids: snapshot.activeRide != null
                  ? const <Map<String, dynamic>>[]
                  : shouldIncludeOffers
                  ? _immutableMaps(snapshot.rideOffers)
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

  /// Reconciles active offers and trips through one authoritative snapshot
  /// after realtime transport recovery.
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
    if (ride.id.isEmpty || ride.isTerminal) return;
    _activeRideRevision++;
    emit(
      state.copyWith(
        activeRide: ride,
        activeBids: const <Map<String, dynamic>>[],
      ),
    );
  }

  void removeActiveRide(String? rideId) {
    if (rideId == null || rideId.isEmpty || state.activeRide?.id != rideId) {
      return;
    }
    _activeRideRevision++;
    emit(
      state.copyWith(
        activeRide: null,
        activeBids: const <Map<String, dynamic>>[],
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

  void removeExpiredRideOffers() {
    final now = DateTime.now();
    final remaining = state.activeBids
        .where((bid) {
          final expiresAt = DateTime.tryParse(
            _stringValue(bid['expires_at']) ?? '',
          );
          return expiresAt == null || expiresAt.isAfter(now);
        })
        .toList(growable: false);
    if (remaining.length == state.activeBids.length) return;
    emit(state.copyWith(activeBids: remaining));
  }

  void clearActiveBids() {
    if (state.activeBids.isEmpty) return;
    emit(state.copyWith(activeBids: const <Map<String, dynamic>>[]));
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
          removeActiveBid(sessionId);
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
    final previousOnlineSince = _onlineSince;
    _onlineSince = goingOnline ? (_onlineSince ?? _now()) : null;
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
    if (state.isOnline == previousOnline && state.errorMessage != null) {
      _onlineSince = previousOnlineSince;
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
    _onlineSince = null;
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
        final offlineResult = await _repository.updateOnlineStatusResult(
          isOnline: false,
          lat: lat,
          lng: lng,
        );
        if (isClosed) return false;
        final reconciled = offlineResult.fold((_) => false, (_) => true);
        if (reconciled) {
          _onlineSince = null;
          emit(
            state.copyWith(
              isOnline: false,
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
          return false;
        }
      }
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)));
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

  static String? _stringValue(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
