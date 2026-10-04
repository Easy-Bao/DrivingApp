import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
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
  int _elapsedWaitTime = 0;
  DateTime? _waitingUntil;
  DateTime? _waitStartedAt;
  bool _isActionInFlight = false;
  int _actionGeneration = 0;

  this : super(const RideFlowInitial());

  String? get activeRideId => _activeRideId;
  String? get activePassengerId => _activePassengerId;
  String get activePassengerName => _activePassengerName ?? 'Passenger';

  void resumeRide({
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
  }) {
    final typedRideId = RideId.tryParse(rideId);
    if (typedRideId == null) {
      emit(const RideFlowError('This trip is no longer active.'));
      return;
    }
    ++_actionGeneration;
    _waitTimer?.cancel();
    _isActionInFlight = false;
    _activeRideId = typedRideId.normalized;
    _activePassengerId = passengerId;
    _activePassengerName = passengerName;
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
  }

  bool get canMarkPassengerNoShow {
    final waitingUntil = _waitingUntil;
    return waitingUntil != null &&
        !DateTime.now().toUtc().isBefore(waitingUntil);
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

    final driverId = await _sessionService.readDriverId();
    if (!_isCurrentAction(actionGeneration)) return;
    if (driverId == null || driverId.isEmpty) {
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
        emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
        return;
      }

      emit(
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
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
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    if (_isActionInFlight) return;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;
    _waitingUntil = null;

    try {
      RideSnapshot? arrivedRide;
      Failure? arrivalFailure;
      if (_activeRideId != null) {
        (await _rideRepository.markArrivedResult(
          rideId: _activeRideId!,
          latitude: driverLat,
          longitude: driverLng,
        )).fold(
          (failure) => arrivalFailure = failure,
          (value) => arrivedRide = value,
        );
        if (arrivalFailure != null) {
          emit(RideFlowError(ErrorHandler.getErrorMessage(arrivalFailure!)));
          return;
        }
        _waitingUntil = arrivedRide?.waitingUntil;
      }

      _waitStartedAt = arrivedRide?.arrivedAt ?? DateTime.now().toUtc();
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
      (await _rideRepository.markPassengerNoShowResult(_activeRideId!)).fold(
        (failure) => noShowFailure = failure,
        (_) {},
      );
      if (!_isCurrentAction(actionGeneration)) return false;
      if (noShowFailure != null) {
        emit(RideFlowError(ErrorHandler.getErrorMessage(noShowFailure!)));
        return false;
      }
      _waitTimer?.cancel();
      _activeRideId = null;
      _activePassengerId = null;
      _activePassengerName = null;
      _waitingUntil = null;
      _waitStartedAt = null;
      _elapsedWaitTime = 0;
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
    double? passengerLat,
    double? passengerLng,
  }) async {
    if (_isActionInFlight) return false;
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

      if (_activeRideId != null) {
        final result = await _rideRepository.updateRideStatusResult(
          rideId: _activeRideId!,
          status: RideStatus.inTransit,
        );
        if (!_isCurrentAction(actionGeneration)) return false;
        final failure = result.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
          return false;
        }
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

  Future<RideSnapshot?> _loadCompletedRide(int actionGeneration) async {
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
        final result = await _rideRepository.updateRideStatusResult(
          rideId: rideId,
          status: RideStatus.completed,
        );
        if (!_isCurrentAction(actionGeneration)) return null;
        final failure = result.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
          return null;
        }
      }
      return ride;
    } catch (error) {
      if (!_isCurrentAction(actionGeneration)) return null;
      dev.log('Error completing ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> completeRide() async {
    if (_isActionInFlight) return null;
    final actionGeneration = ++_actionGeneration;
    _isActionInFlight = true;
    _waitTimer?.cancel();
    try {
      final ride = await _loadCompletedRide(actionGeneration);
      if (!_isCurrentAction(actionGeneration) || ride == null) return null;

      final fareAmount = ride.fareAmount;
      if (fareAmount == null || fareAmount <= 0) {
        emit(
          RideFlowError(ErrorHandler.getErrorMessage(const ServerFailure())),
        );
        return null;
      }
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
        (await _rideRepository.fetchRideResult(rideId)).fold(
          (_) {},
          (value) => ride = value,
        );
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

  Future<double?> endRide() async {
    final completedFare = await completeRide();
    if (completedFare == null) return null;
    return confirmCashPayment();
  }

  void reset() {
    ++_actionGeneration;
    _waitTimer?.cancel();
    _activeRideId = null;
    _activePassengerId = null;
    _activePassengerName = null;
    _waitingUntil = null;
    _waitStartedAt = null;
    _elapsedWaitTime = 0;
    _isActionInFlight = false;
    emit(const RideFlowInitial());
  }

  @override
  Future<void> close() {
    ++_actionGeneration;
    _waitTimer?.cancel();
    return super.close();
  }

  bool _isCurrentAction(int generation) {
    return !isClosed && generation == _actionGeneration;
  }
}
