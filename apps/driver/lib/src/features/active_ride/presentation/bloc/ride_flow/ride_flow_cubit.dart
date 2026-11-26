import 'dart:async';
import 'dart:developer' as dev;

import 'package:core_domain/core_domain.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_session_coordinator.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';

class RideFlowCubit({
  required this._rideRepository,
  required SessionStore sessionService,
}) extends Cubit<RideFlowState> {
  final RideRepository _rideRepository;
  final RideFlowSessionCoordinator _sessionCoordinator;
  final RideFlowWaitTracker _waitTracker = RideFlowWaitTracker();

  String? _activeRideId;
  String? _activeBookingReference;
  String? _activePassengerId;
  String? _activePassengerName;
  bool _isActionInFlight = false;
  String? _lastActionFailureMessage;
  int _actionGeneration = 0;
  Future<void>? _passengerLocationRefresh;
  Future<void>? _rideStatusSync;
  Timer? _rideStatusSyncTimer;
  bool _isRideCompletionPending = false;

  static const _rideStatusSyncInterval = Duration(seconds: 15);

  this
    : _sessionCoordinator = RideFlowSessionCoordinator(
        sessionService: sessionService,
      ),
      super(const RideFlowInitial());

  /// Retains rejected action feedback while the active snapshot is restored
  /// so map coordinates and retry controls survive a recoverable failure.
  String? get lastActionFailureMessage => _lastActionFailureMessage;

  String? get activeRideId => _activeRideId;
  String? get activeBookingReference => _activeBookingReference;
  String? get activePassengerId => _activePassengerId;
  String get activePassengerName => _activePassengerName ?? 'Passenger';

  bool get canMarkPassengerNoShow => _waitTracker.canMarkPassengerNoShow;

  Duration? get passengerNoShowTimeRemaining =>
      _waitTracker.passengerNoShowTimeRemaining;

  Future<void> syncAuthoritativeRideState() async {
    final rideId = _activeRideId;
    if (rideId == null ||
        rideId.isEmpty ||
        _isActionInFlight ||
        _isRideCompletionPending) {
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
    if (_isRideCompletionPending) return;
    final terminalStatus = RideStatus.fromString(status);
    if (!terminalStatus.isTerminal) return;
    await _finishTerminalRide(rideId: rideId, status: terminalStatus.value);
  }

  Future<void> _syncAuthoritativeRideState(String rideId) async {
    final actionGeneration = _actionGeneration;
    try {
      final result = await _rideRepository.fetchRideResult(rideId);
      if (!_isCurrentAction(actionGeneration) || _activeRideId != rideId) {
        return;
      }
      switch (result) {
        case Err(failure: RideNotFoundFailure()):
          await _finishTerminalRide(rideId: rideId, status: 'not_found');
        case Err():
          break;
        case Ok(:final value) when value.isTerminal:
          await _finishTerminalRide(rideId: rideId, status: value.status);
        case Ok():
          break;
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
    _clearLocalRideState();
    _isActionInFlight = true;
    _isRideCompletionPending = false;
    await _sessionCoordinator.clearActiveRideSession();
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

      if (result case Ok(value: final location?)) {
        final currentState = state;
        if (currentState is! RideFlowInTransit) return;
        emit(
          RideFlowInTransit(
            passengerName: currentState.passengerName,
            destinationLatitude: currentState.destinationLatitude,
            destinationLongitude: currentState.destinationLongitude,
            distanceKm: currentState.distanceKm,
            passengerLatitude: location.$1,
            passengerLongitude: location.$2,
          ),
        );
      }
    } catch (_) {
      // A later tracking refresh can recover from a transient location error.
    }
  }

  Future<bool> resumeRide({
    required String rideId,
    String? bookingReference,
    required String status,
    required String passengerName,
    String? passengerId,
    double? distanceKm,
    double? pickupLatitude,
    double? pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
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
      _clearLocalRideState();
      _isActionInFlight = true;
      await _sessionCoordinator.clearActiveRideSession();
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
    _waitTracker.cancelTimer();
    _isActionInFlight = true;
    _activeRideId = typedRideId.normalized;
    _activeBookingReference = bookingReference;
    _activePassengerId = passengerId;
    _activePassengerName = passengerName;
    await _sessionCoordinator.saveActiveRideSession(typedRideId.normalized);
    if (!_isCurrentAction(actionGeneration)) return false;
    _isActionInFlight = false;
    if (normalizedStatus == 'arrived') {
      _waitTracker.configure(
        waitingUntil: waitingUntil,
        waitStartedAt: arrivedAt ?? DateTime.now().toUtc(),
      );
      _startWaitTimer(
        actionGeneration: _actionGeneration,
        passengerName: passengerName,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );
    } else if (normalizedStatus == 'in_transit') {
      _waitTracker.clear();
      emit(
        RideFlowInTransit(
          passengerName: passengerName,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
          distanceKm: distanceKm,
          passengerLatitude: pickupLatitude,
          passengerLongitude: pickupLongitude,
        ),
      );
    } else {
      _waitTracker.clear();
      emit(
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLatitude: pickupLatitude,
          pickupLongitude: pickupLongitude,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
        ),
      );
    }
    _isRideCompletionPending = false;
    _startRideStatusSyncTimer();
    return true;
  }

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLatitude,
    required double pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
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

    final driverId = await _sessionCoordinator.readDriverId();
    if (!_isCurrentAction(actionGeneration)) return;
    if (driverId == null || driverId.isEmpty) {
      _activeRideId = null;
      await _sessionCoordinator.clearActiveRideSession();
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
      if (result case Err(:final failure)) {
        _activeRideId = null;
        await _sessionCoordinator.clearActiveRideSession();
        if (!_isCurrentAction(actionGeneration)) return;
        _isActionInFlight = false;
        emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
        return;
      }

      await _sessionCoordinator.saveActiveRideSession(typedRideId.normalized);
      if (!_isCurrentAction(actionGeneration)) return;

      emit(
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLatitude: pickupLatitude,
          pickupLongitude: pickupLongitude,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
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
    required double driverLatitude,
    required double driverLongitude,
    required DateTime observedAt,
    double? pickupLatitude,
    double? pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
  }) async {
    if (_isActionInFlight) return;
    final activeRideId = _activeRideId;
    if (activeRideId == null || activeRideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return;
    }
    final tripBeforeAction = state;
    _lastActionFailureMessage = null;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTracker.clear();

    try {
      final result = await _rideRepository.markArrivedResult(
        rideId: activeRideId,
        latitude: driverLatitude,
        longitude: driverLongitude,
        observedAt: observedAt,
      );
      if (!_isCurrentAction(actionGeneration)) return;
      switch (result) {
        case Err(:final failure):
          emit(RideFlowError(failure.message));
          return;
        case Ok(value: final arrivedRide):
          _waitTracker.configure(
            waitingUntil: arrivedRide.waitingUntil,
            waitStartedAt: arrivedRide.arrivedAt,
          );
          _startWaitTimer(
            actionGeneration: actionGeneration,
            passengerName: passengerName,
            pickupLatitude: pickupLatitude,
            pickupLongitude: pickupLongitude,
            destinationLatitude: destinationLatitude,
            destinationLongitude: destinationLongitude,
          );
      }
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return;
      dev.log('Error confirming arrival: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
    } finally {
      if (_isCurrentAction(actionGeneration)) {
        _isActionInFlight = false;
        _restoreTripAfterFailedAction(tripBeforeAction, actionGeneration);
      }
    }
  }

  Future<bool> _executeTerminalAction(
    Future<Result<void, DomainFailure>> Function(String rideId) action,
  ) async {
    final rideId = _activeRideId;
    if (_isActionInFlight || rideId == null) return false;
    final tripBeforeAction = state;
    _lastActionFailureMessage = null;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    try {
      final result = await action(rideId);
      if (!_isCurrentAction(actionGeneration)) return false;
      if (result case Err(:final failure)) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
        return false;
      }
      _clearLocalRideState();
      await _sessionCoordinator.clearActiveRideSession();
      if (!_isCurrentAction(actionGeneration)) return false;
      emit(const RideFlowInitial());
      return true;
    } catch (error) {
      if (_isCurrentAction(actionGeneration)) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      }
      return false;
    } finally {
      if (_isCurrentAction(actionGeneration)) {
        _isActionInFlight = false;
        _restoreTripAfterFailedAction(tripBeforeAction, actionGeneration);
      }
    }
  }

  Future<bool> markPassengerNoShow() =>
      _executeTerminalAction(_rideRepository.markPassengerNoShowResult);

  Future<bool> cancelRide({required String reason, String details = ''}) =>
      _executeTerminalAction(
        (rideId) => _rideRepository.cancelRideResult(
          rideId: rideId,
          reason: reason,
          details: details,
        ),
      );

  Future<bool> emergencyStop({required String reason, String details = ''}) =>
      _executeTerminalAction(
        (rideId) => _rideRepository.emergencyStopResult(
          rideId: rideId,
          reason: reason,
          details: details,
        ),
      );

  void _restoreTripAfterFailedAction(RideState previous, int generation) {
    if (state is! RideFlowError ||
        (previous is! DriverEnRoute && previous is! TripInProgress)) {
      return;
    }
    _lastActionFailureMessage = state.failureMessage;
    if (previous is DriverEnRoute && previous.isWaitingAtPickup) {
      _startWaitTimer(
        actionGeneration: generation,
        passengerName: previous.passengerName,
        pickupLatitude: previous.pickupLatitude,
        pickupLongitude: previous.pickupLongitude,
        destinationLatitude: previous.destinationLatitude,
        destinationLongitude: previous.destinationLongitude,
      );
    } else {
      emit(previous);
    }
  }

  void _startWaitTimer({
    required int actionGeneration,
    required String passengerName,
    double? pickupLatitude,
    double? pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
  }) {
    _waitTracker.start(
      isActive: () => _isCurrentAction(actionGeneration),
      onTick: (elapsedSeconds) => emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: elapsedSeconds,
          pickupLatitude: pickupLatitude,
          pickupLongitude: pickupLongitude,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
        ),
      ),
    );
  }

  Future<bool> startRide({
    required String passengerName,
    required double? destinationLatitude,
    required double? destinationLongitude,
    required double distanceKm,
    required double driverLatitude,
    required double driverLongitude,
    required DateTime observedAt,
    double? passengerLatitude,
    double? passengerLongitude,
  }) async {
    if (_isActionInFlight) return false;
    _lastActionFailureMessage = null;
    final activeRideId = _activeRideId;
    if (activeRideId == null || activeRideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return false;
    }
    if (!isValidCoordinatePair(driverLatitude, driverLongitude)) {
      emit(
        RideFlowError(ErrorHandler.getErrorMessage(const LocationFailure())),
      );
      return false;
    }
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    final waitingBeforeStart = state;
    final waitingUntilBeforeStart = _waitTracker.waitingUntil;
    final waitStartedAtBeforeStart = _waitTracker.waitStartedAt;
    _waitTracker.clear();

    // A rejected start leaves the ride arrived on the server, so the waiting
    // snapshot, deadline and timer must survive to allow a retry or no-show.
    void restoreWaitingAfterFailure() {
      if (waitingBeforeStart is! RideFlowWaitingPassenger) return;
      _waitTracker.configure(
        waitingUntil: waitingUntilBeforeStart,
        waitStartedAt: waitStartedAtBeforeStart,
      );
      _startWaitTimer(
        actionGeneration: actionGeneration,
        passengerName: waitingBeforeStart.passengerName,
        pickupLatitude: waitingBeforeStart.pickupLatitude,
        pickupLongitude: waitingBeforeStart.pickupLongitude,
        destinationLatitude: waitingBeforeStart.destinationLatitude,
        destinationLongitude: waitingBeforeStart.destinationLongitude,
      );
    }

    try {
      var resolvedDestinationLatitude = destinationLatitude;
      var resolvedDestinationLongitude = destinationLongitude;
      if (resolvedDestinationLatitude == null ||
          resolvedDestinationLongitude == null) {
        final recoveredDestination = await _loadActiveRideDestination();
        if (!_isCurrentAction(actionGeneration)) return false;
        resolvedDestinationLatitude = recoveredDestination?.$1;
        resolvedDestinationLongitude = recoveredDestination?.$2;
      }

      if (!isValidCoordinatePair(
        resolvedDestinationLatitude,
        resolvedDestinationLongitude,
      )) {
        if (!_isCurrentAction(actionGeneration)) return false;
        final message = ErrorHandler.getErrorMessage(
          const RouteCalculationFailure(),
        );
        _lastActionFailureMessage = message;
        emit(RideFlowError(message));
        restoreWaitingAfterFailure();
        return false;
      }

      final startResult = await _rideRepository.startRideResult(
        rideId: activeRideId,
        latitude: driverLatitude,
        longitude: driverLongitude,
        observedAt: observedAt,
      );
      if (!_isCurrentAction(actionGeneration)) return false;
      if (startResult case Err(:final failure)) {
        final message = failure.message;
        _lastActionFailureMessage = message;
        emit(RideFlowError(message));
        restoreWaitingAfterFailure();
        return false;
      }

      if (!_isCurrentAction(actionGeneration)) return false;
      emit(
        RideFlowInTransit(
          passengerName: passengerName,
          destinationLatitude: resolvedDestinationLatitude,
          destinationLongitude: resolvedDestinationLongitude,
          distanceKm: distanceKm,
          passengerLatitude: passengerLatitude,
          passengerLongitude: passengerLongitude,
        ),
      );
      return true;
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return false;
      dev.log('Error updating status to in_transit: $error');
      final message = ErrorHandler.getErrorMessage(const ServerFailure());
      _lastActionFailureMessage = message;
      emit(RideFlowError(message));
      restoreWaitingAfterFailure();
      return false;
    } finally {
      if (_actionGeneration == actionGeneration) _isActionInFlight = false;
    }
  }

  Future<(double, double)?> _loadActiveRideDestination() async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) return null;

    try {
      final result = await _rideRepository.fetchRideResult(rideId);
      if (result case Ok(value: final ride)) {
        final latitude = ride.dropoffLatitude;
        final longitude = ride.dropoffLongitude;
        if (latitude != null &&
            longitude != null &&
            isValidCoordinatePair(latitude, longitude)) {
          return (latitude, longitude);
        }
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

  Future<RideSnapshot?> _loadCompletedRide(
    int actionGeneration, {
    required double driverLatitude,
    required double driverLongitude,
  }) async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      if (_isCurrentAction(actionGeneration)) {
        emit(const RideFlowError('This trip is no longer active.'));
      }
      return null;
    }

    try {
      final fetchResult = await _rideRepository.fetchRideResult(rideId);
      if (!_isCurrentAction(actionGeneration)) return null;
      final RideSnapshot ride;
      switch (fetchResult) {
        case Err(:final failure):
          emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
          return null;
        case Ok(:final value):
          ride = value;
      }

      _activePassengerId ??= ride.passengerId;
      _activePassengerName ??= ride.passengerName;
      if (ride.status == 'completed') {
        return ride;
      }

      final completionResult = await _rideRepository.completeRideResult(
        rideId: rideId,
        latitude: driverLatitude,
        longitude: driverLongitude,
      );
      if (!_isCurrentAction(actionGeneration)) return null;
      switch (completionResult) {
        case Ok(:final value):
          return value;
        case Err(:final failure):
          final recheck = await _rideRepository.fetchRideResult(rideId);
          if (!_isCurrentAction(actionGeneration)) return null;
          if (recheck case Ok(value: final authoritative)
              when authoritative.status == 'completed') {
            return authoritative;
          }
          emit(RideFlowError(failure.message));
          return null;
      }
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return null;
      dev.log('Error completing ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> completeRide({
    required double driverLatitude,
    required double driverLongitude,
  }) async {
    if (_isActionInFlight) return null;
    final tripBeforeAction = state;
    _lastActionFailureMessage = null;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTracker.cancelTimer();
    try {
      final ride = await _loadCompletedRide(
        actionGeneration,
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
      );
      if (!_isCurrentAction(actionGeneration) || ride == null) return null;

      final fareAmount = ride.fareAmount;
      _isRideCompletionPending = true;
      _rideStatusSyncTimer?.cancel();
      _rideStatusSyncTimer = null;
      return ((fareAmount != null && fareAmount > 0) ? fareAmount : 0) / 100;
    } finally {
      if (_isCurrentAction(actionGeneration)) {
        _isActionInFlight = false;
        _restoreTripAfterFailedAction(tripBeforeAction, actionGeneration);
      }
    }
  }

  Future<void> reset() async {
    final actionGeneration = ++_actionGeneration;
    _clearLocalRideState(clearLastFailure: true);
    _isRideCompletionPending = false;
    _isActionInFlight = true;
    await _sessionCoordinator.clearActiveRideSession();
    if (!_isCurrentAction(actionGeneration)) return;
    _isActionInFlight = false;
    emit(const RideFlowInitial());
  }

  void _clearLocalRideState({bool clearLastFailure = false}) {
    _waitTracker.clear();
    _stopRideStatusSyncTimer();
    _isRideCompletionPending = false;
    _activeRideId = null;
    _activeBookingReference = null;
    _activePassengerId = null;
    _activePassengerName = null;
    if (clearLastFailure) {
      _lastActionFailureMessage = null;
    }
  }

  @override
  Future<void> close() {
    ++_actionGeneration;
    _waitTracker.clear();
    _stopRideStatusSyncTimer();
    return super.close();
  }

  bool _isCurrentAction(int generation) {
    return !isClosed && generation == _actionGeneration;
  }
}
