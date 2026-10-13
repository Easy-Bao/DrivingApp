import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:maps/maps.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:foundation/foundation.dart';

class RideFlowCubit({
  required this._rideRepository,
  required this._sessionService,
}) extends Cubit<RideFlowState> {
  final DriverRideRepository _rideRepository;
  final DriverSessionStore _sessionService;

  String? _activeRideId;
  String? _activePassengerId;
  String? _activePassengerName;
  Timer? _waitTimer;
  Future<void> _activeRideIdWriteQueue = Future<void>.value();
  int _elapsedWaitTime = 0;
  DateTime? _waitingUntil;
  DateTime? _waitStartedAt;
  bool _isActionInFlight = false;
  int _actionGeneration = 0;
  Future<void>? _passengerLocationRefresh;
  Future<void>? _rideStatusSync;
  Timer? _rideStatusSyncTimer;
  bool _isRideCompletionPending = false;

  static const _rideStatusSyncInterval = Duration(seconds: 15);
  static const _noShowClockSkewBuffer = Duration(seconds: 5);

  this : super(const RideFlowInitial());

  String? get activeRideId => _activeRideId;
  String? get activePassengerId => _activePassengerId;
  String get activePassengerName => _activePassengerName ?? 'Passenger';
  DateTime? get _passengerNoShowEligibleAt =>
      _waitingUntil?.add(_noShowClockSkewBuffer);

  Future<void> syncAuthoritativeRideState() async {
    final rideId = _activeRideId;
    if (rideId == null ||
        rideId.isEmpty ||
        _isActionInFlight ||
        _isRideCompletionPending ||
        state is RideFlowComplete) {
      return;
    }

    final inFlight = _rideStatusSync;
    if (inFlight != null) return inFlight;

    late final Future<void> request;
    request = _syncAuthoritativeRideState(rideId).whenComplete(() {
      if (identical(_rideStatusSync, request)) _rideStatusSync = null;
    });
    _rideStatusSync = request;
    return request;
  }

  Future<void> handleExternalTerminalRide({
    required String rideId,
    required String status,
  }) async {
    if (_isRideCompletionPending || state is RideFlowComplete) return;
    final normalizedStatus = status.trim().toLowerCase();
    if (!const {
      'completed',
      'canceled',
      'cancelled',
    }.contains(normalizedStatus)) {
      return;
    }
    await _finishTerminalRide(rideId: rideId, status: normalizedStatus);
  }

  Future<void> _syncAuthoritativeRideState(String rideId) async {
    final actionGeneration = _actionGeneration;
    try {
      Failure? failure;
      RideSnapshot? ride;
      (await _rideRepository.fetchRideResult(rideId))
          .fold((value) => failure = value, (value) => ride = value);
      if (!_isCurrentAction(actionGeneration) || _activeRideId != rideId) {
        return;
      }
      if (failure is RideNotFoundFailure) {
        await _finishTerminalRide(rideId: rideId, status: 'not_found');
        return;
      }
      if (ride case final RideSnapshot value when value.isTerminal) {
        await _finishTerminalRide(rideId: rideId, status: value.status);
      }
    } catch (error, stackTrace) {
      dev.log(
        'Unable to reconcile the active ride status.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _startRideStatusSyncTimer() {
    _rideStatusSyncTimer?.cancel();
    _rideStatusSyncTimer = Timer.periodic(
      _rideStatusSyncInterval,
      (_) => unawaited(syncAuthoritativeRideState()),
    );
  }

  void _stopRideStatusSyncTimer() {
    _rideStatusSyncTimer?.cancel();
    _rideStatusSyncTimer = null;
    _rideStatusSync = null;
  }

  Future<void> _finishTerminalRide({
    required String rideId,
    required String status,
  }) async {
    if (isClosed ||
        (_activeRideId != null && _activeRideId != rideId) ||
        rideId.trim().isEmpty) {
      return;
    }
    final actionGeneration = ++_actionGeneration;
    _waitTimer?.cancel();
    _stopRideStatusSyncTimer();
    _activeRideId = null;
    _activePassengerId = null;
    _activePassengerName = null;
    _waitingUntil = null;
    _waitStartedAt = null;
    _elapsedWaitTime = 0;
    _isActionInFlight = true;
    _isRideCompletionPending = false;
    await _clearActiveRideSession();
    if (!_isCurrentAction(actionGeneration)) return;
    _isActionInFlight = false;
    emit(
      RideFlowTerminal(
        rideId: rideId,
        status: status,
        message: switch (status) {
          'completed' => 'This trip has already been completed.',
          'not_found' => 'This trip is no longer available.',
          _ => 'This trip was canceled.',
        },
      ),
    );
  }

  Future<void> refreshPassengerLocation() async {
    final rideId = _activeRideId;
    if (rideId == null || state is! RideFlowInTransit) return;

    final inFlight = _passengerLocationRefresh;
    if (inFlight != null) return inFlight;

    late final Future<void> request;
    request = _refreshPassengerLocation(rideId).whenComplete(() {
      if (identical(_passengerLocationRefresh, request)) {
        _passengerLocationRefresh = null;
      }
    });
    _passengerLocationRefresh = request;
    return request;
  }

  Future<void> _refreshPassengerLocation(String rideId) async {
    try {
      final result = await _rideRepository.fetchPassengerLocationResult(rideId);
      if (isClosed || _activeRideId != rideId) return;

      result.fold((_) {}, (location) {
        if (location == null) return;
        final currentState = state;
        if (currentState is! RideFlowInTransit) return;
        emit(
          RideFlowInTransit(
            passengerName: currentState.passengerName,
            destLat: currentState.destLat,
            destLng: currentState.destLng,
            distanceKm: currentState.distanceKm,
            passengerLat: location.$1,
            passengerLng: location.$2,
          ),
        );
      });
    } catch (_) {
      // A later tracking refresh can recover from a transient location error.
    }
  }

  Future<bool> resumeRide({
    required String rideId,
    required String status,
    required String passengerName,
    String? passengerId,
    double? distanceKm,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
    DateTime? arrivedAt,
    DateTime? waitingUntil,
  }) async {
    final normalizedStatus = status.trim().toLowerCase();
    if (const {
      'completed',
      'canceled',
      'cancelled',
    }.contains(normalizedStatus)) {
      final actionGeneration = ++_actionGeneration;
      _waitTimer?.cancel();
      _stopRideStatusSyncTimer();
      _activeRideId = null;
      _activePassengerId = null;
      _activePassengerName = null;
      _waitingUntil = null;
      _waitStartedAt = null;
      _elapsedWaitTime = 0;
      _isActionInFlight = true;
      await _clearActiveRideSession();
      if (!_isCurrentAction(actionGeneration)) return false;
      _isActionInFlight = false;
      emit(const RideFlowError('This trip is no longer active.'));
      return false;
    }

    final typedRideId = RideId.tryParse(rideId);
    if (typedRideId == null) {
      emit(const RideFlowError('This trip is no longer active.'));
      return false;
    }
    final actionGeneration = ++_actionGeneration;
    _waitTimer?.cancel();
    _isActionInFlight = true;
    _activeRideId = typedRideId.normalized;
    _activePassengerId = passengerId;
    _activePassengerName = passengerName;
    await _saveActiveRideSession(typedRideId.normalized);
    if (!_isCurrentAction(actionGeneration)) return false;
    _isActionInFlight = false;
    _waitingUntil = waitingUntil?.toUtc();
    if (status == 'arrived') {
      _waitStartedAt = arrivedAt?.toUtc() ?? DateTime.now().toUtc();
      _startWaitTimer(
        actionGeneration: _actionGeneration,
        passengerName: passengerName,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destLat: destLat,
        destLng: destLng,
      );
    } else if (status == 'in_transit') {
      _waitingUntil = null;
      _waitStartedAt = null;
      emit(
        RideFlowInTransit(
          passengerName: passengerName,
          destLat: destLat,
          destLng: destLng,
          distanceKm: distanceKm,
          passengerLat: pickupLat,
          passengerLng: pickupLng,
        ),
      );
    } else {
      _waitingUntil = null;
      _waitStartedAt = null;
      emit(
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    }
    _isRideCompletionPending = false;
    _startRideStatusSyncTimer();
    return true;
  }

  bool get canMarkPassengerNoShow {
    final eligibleAt = _passengerNoShowEligibleAt;
    return eligibleAt != null && !DateTime.now().toUtc().isBefore(eligibleAt);
  }

  Duration? get passengerNoShowTimeRemaining {
    final eligibleAt = _passengerNoShowEligibleAt;
    if (eligibleAt == null) return null;
    final remaining = eligibleAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    if (_isActionInFlight) return;
    final typedRideId = RideId.tryParse(rideId);
    if (typedRideId == null) {
      emit(const RideFlowError('This trip is no longer active.'));
      return;
    }
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _activeRideId = typedRideId.normalized;
    _activePassengerName = passengerName;
    _isRideCompletionPending = false;

    final driverId = await _sessionService.readDriverId();
    if (!_isCurrentAction(actionGeneration)) return;
    if (driverId == null || driverId.isEmpty) {
      _activeRideId = null;
      await _clearActiveRideSession();
      if (!_isCurrentAction(actionGeneration)) return;
      _isActionInFlight = false;
      emit(RideFlowError(ErrorHandler.getErrorMessage(const AuthFailure())));
      return;
    }

    try {
      final result = await _rideRepository.acceptRideResult(
        rideId: rideId,
        driverId: driverId,
      );
      if (!_isCurrentAction(actionGeneration)) return;
      final failure = result.fold<Failure?>((value) => value, (_) => null);
      if (failure != null) {
        _activeRideId = null;
        await _clearActiveRideSession();
        if (!_isCurrentAction(actionGeneration)) return;
        _isActionInFlight = false;
        emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
        return;
      }

      await _saveActiveRideSession(typedRideId.normalized);
      if (!_isCurrentAction(actionGeneration)) return;

      emit(
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
      _startRideStatusSyncTimer();
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return;
      dev.log('Error accepting ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<void> arriveAtPickup(
    String passengerName, {
    required double driverLat,
    required double driverLng,
    required DateTime observedAt,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    if (_isActionInFlight) return;
    final activeRideId = _activeRideId;
    if (activeRideId == null || activeRideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return;
    }
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;
    _waitingUntil = null;

    try {
      RideSnapshot? arrivedRide;
      Failure? arrivalFailure;
      (await _rideRepository.markArrivedResult(
        rideId: activeRideId,
        latitude: driverLat,
        longitude: driverLng,
        observedAt: observedAt,
      )).fold(
        (failure) => arrivalFailure = failure,
        (value) => arrivedRide = value,
      );
      if (arrivalFailure != null || arrivedRide == null) {
        emit(
          RideFlowError(
            arrivalFailure?.message ??
                ErrorHandler.getErrorMessage(const ServerFailure()),
          ),
        );
        return;
      }
      _waitingUntil = arrivedRide!.waitingUntil;

      _waitStartedAt = arrivedRide!.arrivedAt;
      _startWaitTimer(
        actionGeneration: actionGeneration,
        passengerName: passengerName,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destLat: destLat,
        destLng: destLng,
      );
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return;
      dev.log('Error confirming arrival: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<bool> markPassengerNoShow() async {
    if (_isActionInFlight || _activeRideId == null) return false;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    try {
      Failure? noShowFailure;
      (await _rideRepository.markPassengerNoShowResult(_activeRideId!))
          .fold((failure) => noShowFailure = failure, (_) {});
      if (!_isCurrentAction(actionGeneration)) return false;
      if (noShowFailure != null) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(noShowFailure!)));
        return false;
      }
      _waitTimer?.cancel();
      _stopRideStatusSyncTimer();
      _activeRideId = null;
      _activePassengerId = null;
      _activePassengerName = null;
      _waitingUntil = null;
      _waitStartedAt = null;
      _elapsedWaitTime = 0;
      await _clearActiveRideSession();
      emit(const RideFlowInitial());
      return true;
    } catch (error) {
      if (_isCurrentAction(actionGeneration)) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      }
      return false;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<bool> cancelRide({required String reason, String details = ''}) async {
    if (_isActionInFlight || _activeRideId == null) return false;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    try {
      Failure? cancellationFailure;
      (await _rideRepository.cancelRideResult(
        rideId: _activeRideId!,
        reason: reason,
        details: details,
      )).fold((failure) => cancellationFailure = failure, (_) {});
      if (!_isCurrentAction(actionGeneration)) return false;
      if (cancellationFailure != null) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(cancellationFailure!)));
        return false;
      }
      _waitTimer?.cancel();
      _stopRideStatusSyncTimer();
      _activeRideId = null;
      _activePassengerId = null;
      _activePassengerName = null;
      _waitingUntil = null;
      _waitStartedAt = null;
      _elapsedWaitTime = 0;
      await _clearActiveRideSession();
      if (!_isCurrentAction(actionGeneration)) return false;
      emit(const RideFlowInitial());
      return true;
    } catch (error) {
      if (_isCurrentAction(actionGeneration)) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      }
      return false;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<bool> emergencyStop({
    required String reason,
    String details = '',
  }) async {
    if (_isActionInFlight || _activeRideId == null) return false;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    try {
      Failure? emergencyStopFailure;
      (await _rideRepository.emergencyStopResult(
        rideId: _activeRideId!,
        reason: reason,
        details: details,
      )).fold((failure) => emergencyStopFailure = failure, (_) {});
      if (!_isCurrentAction(actionGeneration)) return false;
      if (emergencyStopFailure != null) {
        emit(
          RideFlowError(ErrorHandler.getErrorMessage(emergencyStopFailure!)),
        );
        return false;
      }
      _waitTimer?.cancel();
      _stopRideStatusSyncTimer();
      _activeRideId = null;
      _activePassengerId = null;
      _activePassengerName = null;
      _waitingUntil = null;
      _waitStartedAt = null;
      _elapsedWaitTime = 0;
      await _clearActiveRideSession();
      if (!_isCurrentAction(actionGeneration)) return false;
      emit(const RideFlowInitial());
      return true;
    } catch (error) {
      if (_isCurrentAction(actionGeneration)) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      }
      return false;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  void _startWaitTimer({
    required int actionGeneration,
    required String passengerName,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) {
    _waitTimer?.cancel();
    _waitStartedAt ??= DateTime.now().toUtc();
    void emitWaiting() {
      if (!_isCurrentAction(actionGeneration)) return;
      _elapsedWaitTime = _calculateElapsedWaitSeconds();
      emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: _elapsedWaitTime,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    }

    emitWaiting();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isCurrentAction(actionGeneration)) {
        _waitTimer?.cancel();
        return;
      }
      emitWaiting();
    });
  }

  int _calculateElapsedWaitSeconds() {
    final start = _waitStartedAt ?? DateTime.now().toUtc();
    final elapsed = DateTime.now().toUtc().difference(start).inSeconds;
    return elapsed.clamp(0, 24 * 60 * 60).toInt();
  }

  Future<bool> startRide({
    required String passengerName,
    required double? destLat,
    required double? destLng,
    required double distanceKm,
    required double driverLat,
    required double driverLng,
    required DateTime observedAt,
    double? passengerLat,
    double? passengerLng,
  }) async {
    if (_isActionInFlight) return false;
    final activeRideId = _activeRideId;
    if (activeRideId == null || activeRideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return false;
    }
    if (!_isValidCoordinatePair(driverLat, driverLng)) {
      emit(
        RideFlowError(ErrorHandler.getErrorMessage(const LocationFailure())),
      );
      return false;
    }
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTimer?.cancel();
    _waitingUntil = null;
    _waitStartedAt = null;

    try {
      var resolvedDestLat = destLat;
      var resolvedDestLng = destLng;
      if (resolvedDestLat == null || resolvedDestLng == null) {
        final recoveredDestination = await _loadActiveRideDestination();
        if (!_isCurrentAction(actionGeneration)) return false;
        resolvedDestLat = recoveredDestination?.$1;
        resolvedDestLng = recoveredDestination?.$2;
      }

      if (!_isValidCoordinatePair(resolvedDestLat, resolvedDestLng)) {
        if (!_isCurrentAction(actionGeneration)) return false;
        emit(
          RideFlowError(
            ErrorHandler.getErrorMessage(const RouteCalculationFailure()),
          ),
        );
        return false;
      }

      RideSnapshot? startedRide;
      Failure? startFailure;
      (await _rideRepository.startRideResult(
        rideId: activeRideId,
        latitude: driverLat,
        longitude: driverLng,
        observedAt: observedAt,
      )).fold(
        (failure) => startFailure = failure,
        (value) => startedRide = value,
      );
      if (!_isCurrentAction(actionGeneration)) return false;
      if (startFailure != null || startedRide == null) {
        emit(
          RideFlowError(
            startFailure?.message ??
                ErrorHandler.getErrorMessage(const ServerFailure()),
          ),
        );
        return false;
      }

      if (!_isCurrentAction(actionGeneration)) return false;
      emit(
        RideFlowInTransit(
          passengerName: passengerName,
          destLat: resolvedDestLat,
          destLng: resolvedDestLng,
          distanceKm: distanceKm,
          passengerLat: passengerLat,
          passengerLng: passengerLng,
        ),
      );
      return true;
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return false;
      dev.log('Error updating status to in_transit: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(const ServerFailure())));
      return false;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<(double, double)?> _loadActiveRideDestination() async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) return null;

    try {
      RideSnapshot? ride;
      (await _rideRepository.fetchRideResult(rideId))
          .fold((_) {}, (value) => ride = value);
      final latitude = ride?.dropoffLatitude;
      final longitude = ride?.dropoffLongitude;
      if (_isValidCoordinatePair(latitude, longitude)) {
        return (latitude!, longitude!);
      }
    } catch (error, stackTrace) {
      dev.log(
        'Unable to recover the active ride destination',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  bool _isValidCoordinatePair(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Future<RideSnapshot?> _loadCompletedRide(
    int actionGeneration, {
    required double driverLat,
    required double driverLng,
  }) async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      if (_isCurrentAction(actionGeneration)) {
        emit(const RideFlowError('This trip is no longer active.'));
      }
      return null;
    }

    try {
      RideSnapshot? ride;
      Failure? loadFailure;
      (await _rideRepository.fetchRideResult(rideId))
          .fold((failure) => loadFailure = failure, (value) => ride = value);
      if (!_isCurrentAction(actionGeneration)) return null;
      if (ride == null) {
        final failure = loadFailure;
        emit(
          RideFlowError(
            failure == null
                ? 'Unable to load the active ride.'
                : ErrorHandler.getErrorMessage(failure),
          ),
        );
        return null;
      }
      _activePassengerId ??= ride!.passengerId;
      _activePassengerName ??= ride!.passengerName;
      final status = ride!.status;
      if (status != 'completed') {
        RideSnapshot? completedRide;
        Failure? completionFailure;
        (await _rideRepository.completeRideResult(
          rideId: rideId,
          latitude: driverLat,
          longitude: driverLng,
        )).fold(
          (failure) => completionFailure = failure,
          (value) => completedRide = value,
        );
        if (!_isCurrentAction(actionGeneration)) return null;
        if (completionFailure != null || completedRide == null) {
          // The repository maps completion failures to safe user-facing messages.
          emit(
            RideFlowError(
              completionFailure?.message ??
                  ErrorHandler.getErrorMessage(const ServerFailure()),
            ),
          );
          return null;
        }
        ride = completedRide;
      }
      return ride;
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return null;
      dev.log('Error completing ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> completeRide({
    required double driverLat,
    required double driverLng,
  }) async {
    if (_isActionInFlight) return null;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTimer?.cancel();
    try {
      final ride = await _loadCompletedRide(
        actionGeneration,
        driverLat: driverLat,
        driverLng: driverLng,
      );
      if (!_isCurrentAction(actionGeneration) || ride == null) return null;

      final fareAmount = ride.fareAmount;
      if (fareAmount == null || fareAmount <= 0) {
        emit(
          RideFlowError(ErrorHandler.getErrorMessage(const ServerFailure())),
        );
        return null;
      }
      _isRideCompletionPending = true;
      _rideStatusSyncTimer?.cancel();
      _rideStatusSyncTimer = null;
      return fareAmount / 100;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<double?> confirmCashPayment({
    int? cashReceivedAmount,
    int cashChangeAmount = 0,
    String cashOutcome = 'paid',
  }) async {
    if (_isActionInFlight) return null;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;

    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
      emit(const RideFlowError('This trip is no longer active.'));
      return null;
    }

    try {
      int? fareAmount;
      var receivedAmount = cashReceivedAmount;
      if (receivedAmount == null) {
        RideSnapshot? ride;
        (await _rideRepository.fetchRideResult(rideId))
            .fold((_) {}, (value) => ride = value);
        receivedAmount = ride?.fareAmount;
      }
      if (receivedAmount == null || receivedAmount <= 0) {
        emit(const RideFlowError('The cash fare is unavailable.'));
        return null;
      }
      Failure? settleFailure;
      (await _rideRepository.settleCashResult(
        rideId: rideId,
        cashReceivedAmount: receivedAmount,
        cashChangeAmount: cashChangeAmount,
        cashOutcome: cashOutcome,
      )).fold(
        (failure) => settleFailure = failure,
        (value) => fareAmount = value,
      );
      if (!_isCurrentAction(actionGeneration)) return null;
      if (fareAmount == null) {
        final failure = settleFailure;
        emit(
          RideFlowError(
            failure == null
                ? ErrorHandler.getErrorMessage(const ServerFailure())
                : ErrorHandler.getErrorMessage(failure),
          ),
        );
        return null;
      }
      final finalFare = fareAmount! / 100;
      emit(RideFlowComplete(fare: finalFare));
      return finalFare;
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return null;
      dev.log('Error settling cash trip: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<RideSnapshot?> restorePendingCashSettlement() async {
    final cachedRideId = (await _sessionService.readActiveRideId())?.trim();
    if (cachedRideId == null || cachedRideId.isEmpty) return null;

    final typedRideId = RideId.tryParse(cachedRideId);
    if (typedRideId == null) {
      await _clearActiveRideSession();
      return null;
    }

    RideSnapshot? ride;
    Failure? loadFailure;
    try {
      (await _rideRepository.fetchRideResult(typedRideId.normalized))
          .fold((failure) => loadFailure = failure, (value) => ride = value);
    } catch (error, stackTrace) {
      dev.log(
        'Unable to restore the pending cash settlement.',
        error: error,
        stackTrace: stackTrace,
      );
      loadFailure = const ServerFailure();
    }

    if (ride == null) {
      if (loadFailure is RideNotFoundFailure) {
        await _clearActiveRideSession();
        return null;
      }
      emit(
        RideFlowError(
          loadFailure == null
              ? 'Unable to restore the pending cash settlement.'
              : ErrorHandler.getErrorMessage(loadFailure!),
        ),
      );
      return null;
    }

    if (ride!.status != 'completed') {
      if (ride!.isTerminal) await _clearActiveRideSession();
      return null;
    }
    if (ride!.hasCashSettlement) {
      await _clearActiveRideSession();
      return null;
    }

    final fare = ride!.farePesos;
    if (fare == null || fare <= 0) {
      emit(const RideFlowError('The completed cash fare is unavailable.'));
      return null;
    }

    _activeRideId = typedRideId.normalized;
    _activePassengerId = ride!.passengerId;
    _activePassengerName = ride!.passengerName;
    emit(RideFlowComplete(fare: fare));
    return ride;
  }

  Future<double?> endRide({
    required double driverLat,
    required double driverLng,
  }) async {
    final completedFare = await completeRide(
      driverLat: driverLat,
      driverLng: driverLng,
    );
    if (completedFare == null) return null;
    return confirmCashPayment();
  }

  Future<void> reset() async {
    final actionGeneration = ++_actionGeneration;
    _waitTimer?.cancel();
    _stopRideStatusSyncTimer();
    _activeRideId = null;
    _activePassengerId = null;
    _activePassengerName = null;
    _waitingUntil = null;
    _waitStartedAt = null;
    _elapsedWaitTime = 0;
    _isRideCompletionPending = false;
    _isActionInFlight = true;
    await _clearActiveRideSession();
    if (!_isCurrentAction(actionGeneration)) return;
    _isActionInFlight = false;
    emit(const RideFlowInitial());
  }

  Future<void> _clearActiveRideSession() =>
      _serializeActiveRideIdWrite(() async {
        try {
          await _sessionService.clearActiveRideId();
        } catch (error, stackTrace) {
          dev.log(
            'Unable to clear the locally cached active ride',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });

  Future<void> _saveActiveRideSession(String rideId) =>
      _serializeActiveRideIdWrite(() async {
        try {
          await _sessionService.saveActiveRideId(rideId);
        } catch (error, stackTrace) {
          dev.log(
            'Unable to cache the active ride for recovery',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });

  Future<void> _serializeActiveRideIdWrite(Future<void> Function() write) {
    final operation = _activeRideIdWriteQueue.then((_) => write());
    _activeRideIdWriteQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  @override
  Future<void> close() {
    ++_actionGeneration;
    _waitTimer?.cancel();
    _stopRideStatusSyncTimer();
    return super.close();
  }

  bool _isCurrentAction(int generation) {
    return !isClosed && generation == _actionGeneration;
  }
}
