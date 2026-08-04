import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:shared_core/shared_core.dart';

class TrackDriverCubit extends Cubit<TrackDriverState> {
  final ITrackRepository _repository;
  final SecureSessionService _sessionService;
  final BackgroundTelemetryService? _backgroundTelemetryService;
  Timer? _ticker;
  bool _isSyncing = false;

  TrackDriverCubit({
    required ITrackRepository repository,
    required SecureSessionService sessionService,
    BackgroundTelemetryService? backgroundTelemetryService,
  }) : _repository = repository,
       _sessionService = sessionService,
       _backgroundTelemetryService = backgroundTelemetryService,
       super(const TrackDriverInitial());

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
    double destinationLat = 0,
    double destinationLng = 0,
  }) async {
    _ticker?.cancel();

    final session = _sessionService;
    if (rideId.isNotEmpty) {
      await session.saveActiveRideId(rideId);
    }
    final activeRideId = await session.readActiveRideId() ?? '';

    var routePoints = await _repository.getRoutePolyline(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    double progress = 0.0;
    var destinationRouteActive = false;

    _ticker = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (isClosed) return;
      if (_isSyncing) return;

      _isSyncing = true;
      bool handled = false;

      if (activeRideId.isNotEmpty) {
        final result = await _repository.getRideStatusUpdate(activeRideId);
        await result.fold(
          (failure) async {
            dev.log('Error fetching status update: ${failure.message}');
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
              await session.saveActiveRideId('');
              await _stopBackgroundTelemetry();
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
                  dev.log(
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

            if (rideUpdate.status == RideStatus.inTransit &&
                !destinationRouteActive) {
              routePoints = await _repository.getRoutePolyline(
                startLat: driverLat,
                startLng: driverLng,
                endLat: destinationLat,
                endLng: destinationLng,
              );
              progress = 0;
              destinationRouteActive = true;
            }

            final eta = _getEtaLabel(rideUpdate.status);

            emit(
              TrackDriverInProgress(
                driverLat: driverLat,
                driverLng: driverLng,
                progress: progress,
                eta: eta,
                routePoints: routePoints,
                status: rideUpdate.status,
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
          await _sessionService.saveActiveRideId('');
          await _stopBackgroundTelemetry();
          emit(
            TrackDriverCompleted(driverId: driverId, driverName: driverName),
          );
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
              status: RideStatus.accepted,
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
        await _sessionService.saveActiveRideId('');
      }
      await _stopBackgroundTelemetry();
    } catch (error) {
      dev.log('Error canceling trip in track cubit: $error');
    }
    emit(const TrackDriverCanceled());
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
    unawaited(_stopBackgroundTelemetry());
    return super.close();
  }

  Future<void> _stopBackgroundTelemetry() async {
    final service = _backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.stop();
    } catch (error) {
      dev.log('Unable to stop passenger background telemetry: $error');
    }
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
