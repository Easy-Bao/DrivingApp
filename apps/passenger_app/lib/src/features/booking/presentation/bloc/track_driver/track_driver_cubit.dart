import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:session_service/session_service.dart';

/// Cubit responsible for tracking driver location and status updates during active passenger ride bookings.
class TrackDriverCubit extends Cubit<TrackDriverState> {
  final TrackRepository _repository;
  final SecureSessionService _sessionService;
  Timer? _ticker;
  bool _isSyncing = false;

  TrackDriverCubit({
    required TrackRepository repository,
    required SecureSessionService sessionService,
  }) : _repository = repository,
       _sessionService = sessionService,
       super(TrackDriverInitial());

  /// Starts periodic tracking of the driver's location and status for the active ride.
  ///
  /// Polls the repository every two seconds to fetch current status updates and maps
  /// coordinates into live [TrackDriverState] transitions. If the API fails or is not
  /// updated, simulates progress tracking cleanly along the route polyline using the
  /// provided driver details [driverId], [driverName], [vehiclePlate], and [vehicleType].
  Future<void> startTracking({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String rideId,
    required String driverId,
    required String driverName,
    required String vehiclePlate,
    required String vehicleType,
  }) async {
    _ticker?.cancel();

    final session = _sessionService;
    if (rideId.isNotEmpty) {
      await session.writeActiveRideId(rideId);
    }
    final activeRideId = await session.readActiveRideId() ?? '';

    final routePoints = await _repository.getRoutePolyline(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    double progress = 0.0;

    _ticker = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (isClosed) return;
      if (_isSyncing) return;

      _isSyncing = true;
      bool handled = false;

      if (activeRideId.isNotEmpty) {
        final result = await _repository.getRideStatusUpdate(activeRideId);
        await result.fold(
          (failure) async {
            debugPrint('Error fetching status update: ${failure.message}');
          },
          (rideUpdate) async {
            if (rideUpdate.status == RideStatus.completed) {
              timer.cancel();
              handled = true;
              emit(
                TrackDriverCompleted(
                  driverId: rideUpdate.driverId ?? '',
                  driverName: rideUpdate.driverName.isNotEmpty
                      ? rideUpdate.driverName
                      : 'Driver',
                ),
              );
              await session.deleteActiveRideId();
              _isSyncing = false;
              return;
            }

            double driverLat = startLat;
            double driverLng = startLng;
            bool locationFetched = false;

            final driverId = rideUpdate.driverId;
            if (driverId != null && driverId.isNotEmpty) {
              final locResult = await _repository.fetchDriverLocation(driverId);
              locResult.fold(
                (failure) {
                  debugPrint(
                    'Error fetching coordinate location: ${failure.message}',
                  );
                },
                (coordinate) {
                  driverLat = coordinate.$1;
                  driverLng = coordinate.$2;
                  locationFetched = true;
                },
              );
            }

            if (!locationFetched) {
              progress += 0.05;
              if (progress >= 1.0) progress = 0.99;
              final pos = _interpolate(
                progress: progress,
                routePoints: routePoints,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
              );
              driverLat = pos.lat;
              driverLng = pos.lng;
            }

            final eta = _getEtaLabel(rideUpdate.status);

            emit(
              TrackDriverInProgress(
                driverLat: driverLat,
                driverLng: driverLng,
                progress: progress,
                eta: eta,
                routePoints: routePoints,
                driverName: rideUpdate.driverName,
                vehiclePlate: rideUpdate.vehiclePlate,
                vehicleType: rideUpdate.vehicleType,
              ),
            );
            handled = true;
          },
        );
      }

      if (!handled && !isClosed) {
        progress += 0.1;
        if (progress >= 1.0) {
          timer.cancel();
          emit(TrackDriverCompleted(driverId: driverId, driverName: driverName));
        } else {
          final pos = _interpolate(
            progress: progress,
            routePoints: routePoints,
            startLat: startLat,
            startLng: startLng,
            endLat: endLat,
            endLng: endLng,
          );
          final etaMinutes = ((1.0 - progress) * 10).ceil();
          emit(
            TrackDriverInProgress(
              driverLat: pos.lat,
              driverLng: pos.lng,
              progress: progress,
              eta: etaMinutes == 1 ? '1 min' : '$etaMinutes mins',
              routePoints: routePoints,
              driverName: driverName,
              vehiclePlate: vehiclePlate,
              vehicleType: vehicleType,
            ),
          );
        }
      }

      _isSyncing = false;
    });
  }

  Future<void> cancelTrip() async {
    _ticker?.cancel();
    try {
      final rideId = await _sessionService.readActiveRideId() ?? '';
      if (rideId.isNotEmpty) {
        await _repository.updateRideStatus(rideId, RideStatus.cancelled);
        await _sessionService.deleteActiveRideId();
      }
    } catch (error) {
      debugPrint('Error canceling trip in track cubit: $error');
    }
    emit(TrackDriverCanceled());
  }

  String _getEtaLabel(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return 'En-route';
      case RideStatus.arrived:
        return 'Arrived';
      case RideStatus.inTransit:
        return 'In-transit';
      default:
        return 'Calculating...';
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }

  ({double lat, double lng}) _interpolate({
    required double progress,
    required List<List<double>>? routePoints,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    if (routePoints != null && routePoints.isNotEmpty) {
      final fractionalIndex = progress * (routePoints.length - 1);
      final index = fractionalIndex.floor();
      final nextIndex = (index + 1).clamp(0, routePoints.length - 1);
      final t = fractionalIndex - index;
      final p1 = routePoints[index];
      final p2 = routePoints[nextIndex];
      return (
        lat: p1[1] + (p2[1] - p1[1]) * t,
        lng: p1[0] + (p2[0] - p1[0]) * t,
      );
    }
    return (
      lat: startLat + (endLat - startLat) * progress,
      lng: startLng + (endLng - startLng) * progress,
    );
  }
}
