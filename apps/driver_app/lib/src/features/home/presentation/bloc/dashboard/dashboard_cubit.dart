import 'package:driver_app/src/features/active_ride/active_ride.dart';
import 'dart:developer' as dev;

import 'package:driver_app/src/features/home/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final IDashboardRepository _repository;
  final DateTime Function() _now;
  final Duration _silentDispatchFailureCooldown;
  bool _isDispatchRequestInFlight = false;
  Future<void>? _initialization;
  Future<void>? _statsRequestInFlight;
  DateTime? _silentDispatchRetryAfter;

  DashboardCubit({
    required IDashboardRepository repository,
    DateTime Function()? now,
    Duration silentDispatchFailureCooldown = const Duration(seconds: 15),
  }) : _repository = repository,
       _now = now ?? DateTime.now,
       _silentDispatchFailureCooldown = silentDispatchFailureCooldown,
       super(const DashboardState());

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
      final onlineStatusResult = await _repository.getPersistedOnlineStatus();
      onlineStatusResult.fold(
        (failure) => dev.log(
          'Unable to restore driver online status: ${failure.message}',
        ),
        (isOnline) => emit(state.copyWith(isOnline: isOnline)),
      );
    } catch (error, stackTrace) {
      dev.log(
        'Unable to restore driver online status.',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    emit(state.copyWith(isLoadingStats: true, statsErrorMessage: null));
    try {
      final result = await _repository.getDashboardStats();
      result.fold(
        (failure) => emit(
          state.copyWith(
            isLoadingStats: false,
            statsErrorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (stats) => emit(
          state.copyWith(
            isLoadingStats: false,
            earnings: stats.earnings,
            completedTrips: stats.completedTrips,
            statsErrorMessage: null,
          ),
        ),
      );
    } catch (error) {
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
  }) async {
    if (silent && _isSilentDispatchCoolingDown) return false;
    if (_isDispatchRequestInFlight) return false;
    _isDispatchRequestInFlight = true;
    if (!silent) {
      emit(state.copyWith(isLoadingDispatch: true, errorMessage: null));
    }

    try {
      final result = await _repository.getDispatchSnapshot(
        includeOffers: includeOffers,
      );
      return result.fold(
        (failure) {
          if (_pausesSilentDispatch(failure)) {
            _silentDispatchRetryAfter = _now().add(
              _silentDispatchFailureCooldown,
            );
          }
          if (!silent) {
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
          _silentDispatchRetryAfter = null;
          emit(
            state.copyWith(
              isLoadingDispatch: false,
              activeTrips: _sortedActiveTrips(snapshot.activeTrips),
              activeBids: includeOffers
                  ? _immutableMaps(snapshot.rideOffers)
                  : null,
              errorMessage: null,
            ),
          );
          return true;
        },
      );
    } catch (error, stackTrace) {
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

  void mergeActiveTrip(Map<String, dynamic> ride) {
    final rideId = _stringValue(ride['id']);
    if (rideId == null) return;

    final updatedTrips = <Map<String, dynamic>>[
      for (final trip in state.activeTrips) Map<String, dynamic>.from(trip),
    ];
    final existingIndex = updatedTrips.indexWhere(
      (trip) => _stringValue(trip['id']) == rideId,
    );
    final normalizedRide = Map<String, dynamic>.from(ride)..['id'] = rideId;
    if (existingIndex >= 0) {
      updatedTrips[existingIndex] = {
        ...updatedTrips[existingIndex],
        ...normalizedRide,
      };
    } else {
      updatedTrips.insert(0, normalizedRide);
    }
    emit(state.copyWith(activeTrips: _sortedActiveTrips(updatedTrips)));
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
      final result = await _repository.submitRideOffer(
        sessionId: sessionId,
        farePesos: farePesos,
      );
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
    } catch (error, stackTrace) {
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
      final result = await _repository.fetchRide(rideId);
      return result.fold((failure) {
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

    final updateResult = await _repository.updateOnlineStatus(
      isOnline: goingOnline,
      lat: lat,
      lng: lng,
    );

    if (updateResult.isLeft()) {
      updateResult.fold(
        (failure) => emit(
          state.copyWith(
            isOnline: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (_) {},
      );
      return;
    }

    if (goingOnline) {
      emit(state.copyWith(isOnline: true, errorMessage: null));
    } else {
      emit(state.copyWith(isOnline: false, errorMessage: null));
    }
  }

  Future<void> forceOffline({required double lat, required double lng}) async {
    final updateResult = await _repository.updateOnlineStatus(
      isOnline: false,
      lat: lat,
      lng: lng,
    );

    updateResult.fold(
      (failure) => emit(
        state.copyWith(
          isOnline: false,
          errorMessage: ErrorHandler.getErrorMessage(failure),
        ),
      ),
      (_) => emit(state.copyWith(isOnline: false, errorMessage: null)),
    );
  }

  Future<bool> refreshOnlinePresence({
    required double lat,
    required double lng,
  }) async {
    if (!state.isOnline) return false;

    final updateResult = await _repository.updateOnlineStatus(
      isOnline: true,
      lat: lat,
      lng: lng,
    );
    return updateResult.fold((failure) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)));
      return false;
    }, (_) => true);
  }

  static List<Map<String, dynamic>> _sortedActiveTrips(
    Iterable<Map<String, dynamic>> trips,
  ) {
    final sorted = trips.map(Map<String, dynamic>.from).toList();
    sorted.sort((a, b) {
      const statusPriority = <String, int>{
        'in_transit': 0,
        'arrived': 1,
        'accepted': 2,
        'assigned': 2,
      };
      final aPriority = statusPriority[_stringValue(a['status'])] ?? 3;
      final bPriority = statusPriority[_stringValue(b['status'])] ?? 3;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return (_stringValue(a['created_at']) ?? '').compareTo(
        _stringValue(b['created_at']) ?? '',
      );
    });
    return _immutableMaps(sorted);
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
