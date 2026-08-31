import 'package:auth/auth.dart';
import 'package:ride/ride.dart';
import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:shared_core/shared_core.dart';

class RideFlowCubit extends Cubit<RideFlowState> {
  final IDriverRideRepository _rideRepository;
  final SecureSessionService _sessionService;

  String? _activeRideId;
  String? _activePassengerId;
  String? _activePassengerName;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({
    required IDriverRideRepository rideRepository,
    required SecureSessionService sessionService,
  }) : _rideRepository = rideRepository,
       _sessionService = sessionService,
       super(const RideFlowInitial());

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
  }) {
    _activeRideId = rideId;
    _activePassengerId = passengerId;
    _activePassengerName = passengerName;
    if (status == 'arrived') {
      emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: 0,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    } else if (status == 'in_transit') {
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

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    _activeRideId = rideId;
    _activePassengerName = passengerName;

    final driverId = await _sessionService.readDriverId();
    if (driverId == null || driverId.isEmpty) {
      emit(RideFlowError(ErrorHandler.getErrorMessage(const AuthFailure())));
      return;
    }

    try {
      final result = await _rideRepository.acceptRide(
        rideId: rideId,
        driverId: driverId,
      );
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
      dev.log('Error accepting ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> arriveAtPickup(
    String passengerName, {
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;

    if (_activeRideId != null) {
      try {
        final result = await _rideRepository.updateRideStatus(
          rideId: _activeRideId!,
          status: RideStatus.arrived,
        );
        final failure = result.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
          return;
        }
      } catch (error) {
        dev.log('Error updating status to arrived: $error');
        emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
        return;
      }
    }

    emit(
      RideFlowWaitingPassenger(
        passengerName: passengerName,
        waitTimeSeconds: 0,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destLat: destLat,
        destLng: destLng,
      ),
    );
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return;
      _elapsedWaitTime++;
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
    });
  }

  Future<bool> startRide({
    required String passengerName,
    required double? destLat,
    required double? destLng,
    required double distanceKm,
    double? passengerLat,
    double? passengerLng,
  }) async {
    _waitTimer?.cancel();

    var resolvedDestLat = destLat;
    var resolvedDestLng = destLng;
    if (resolvedDestLat == null || resolvedDestLng == null) {
      final recoveredDestination = await _loadActiveRideDestination();
      resolvedDestLat = recoveredDestination?.$1;
      resolvedDestLng = recoveredDestination?.$2;
    }

    if (!_isValidCoordinatePair(resolvedDestLat, resolvedDestLng)) {
      emit(
        RideFlowError(
          ErrorHandler.getErrorMessage(const RouteCalculationFailure()),
        ),
      );
      return false;
    }

    if (_activeRideId != null) {
      try {
        final result = await _rideRepository.updateRideStatus(
          rideId: _activeRideId!,
          status: RideStatus.inTransit,
        );
        final failure = result.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
          return false;
        }
      } catch (error) {
        dev.log('Error updating status to in_transit: $error');
        emit(
          RideFlowError(ErrorHandler.getErrorMessage(const ServerFailure())),
        );
        return false;
      }
    }

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
  }

  Future<(double, double)?> _loadActiveRideDestination() async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) return null;

    try {
      RideSnapshot? ride;
      (await _rideRepository.fetchRide(
        rideId,
      )).fold((_) {}, (value) => ride = value);
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

  Future<RideSnapshot?> _loadCompletedRide() async {
    _waitTimer?.cancel();

    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return null;
    }

    try {
      RideSnapshot? ride;
      Failure? loadFailure;
      (await _rideRepository.fetchRide(
        rideId,
      )).fold((failure) => loadFailure = failure, (value) => ride = value);
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
        final result = await _rideRepository.updateRideStatus(
          rideId: rideId,
          status: RideStatus.completed,
        );
        final failure = result.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          emit(RideFlowError(ErrorHandler.getErrorMessage(failure)));
          return null;
        }
      }
      return ride;
    } catch (error) {
      dev.log('Error completing ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> completeRide() async {
    final ride = await _loadCompletedRide();
    if (ride == null) return null;

    final fareCentavos = ride.fareCentavos;
    if (fareCentavos == null || fareCentavos <= 0) {
      emit(RideFlowError(ErrorHandler.getErrorMessage(const ServerFailure())));
      return null;
    }
    return fareCentavos / 100;
  }

  Future<double?> confirmCashPayment() async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return null;
    }

    try {
      int? fareCentavos;
      Failure? settleFailure;
      (await _rideRepository.settleCash(rideId)).fold(
        (failure) => settleFailure = failure,
        (value) => fareCentavos = value,
      );
      if (fareCentavos == null) {
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
      final finalFare = fareCentavos! / 100;
      emit(RideFlowComplete(fare: finalFare));
      return finalFare;
    } catch (error) {
      dev.log('Error settling cash trip: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> endRide() async {
    final completedFare = await completeRide();
    if (completedFare == null) return null;
    return confirmCashPayment();
  }

  void reset() {
    _waitTimer?.cancel();
    _activeRideId = null;
    _activePassengerId = null;
    _activePassengerName = null;
    emit(const RideFlowInitial());
  }

  @override
  Future<void> close() {
    _waitTimer?.cancel();
    return super.close();
  }
}
