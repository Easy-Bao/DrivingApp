import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_state.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
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

    List<List<double>>? routePoints;

    double progress = 0.0;
    DateTime? pickupRouteLastAttempt;
    DateTime? destinationRouteLastAttempt;
    var trackingCompleted = false;

    Future<void> syncTracking() async {
      if (isClosed || _isSyncing || trackingCompleted || activeRideId.isEmpty) {
        return;
      }

      _isSyncing = true;
      try {
        final result = await _repository.getRideStatusUpdate(activeRideId);
        await result.fold(
          (failure) async {
            dev.log('Error fetching status update: ${failure.message}');
          },
          (rideUpdate) async {
            if (isClosed) return;
            if (rideUpdate.status == RideStatus.completed) {
              trackingCompleted = true;
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
              return;
            }

            double? driverLat;
            double? driverLng;
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

            if (!locationFetched) return;

            final targetLat =
                rideUpdate.destinationLat ??
                (destinationLat == 0 ? null : destinationLat);
            final targetLng =
                rideUpdate.destinationLng ??
                (destinationLng == 0 ? null : destinationLng);
            final now = DateTime.now();
            if (rideUpdate.status != RideStatus.inTransit &&
                _canRetryRoute(pickupRouteLastAttempt, now)) {
              pickupRouteLastAttempt = now;
              final candidate = await _repository.getRoutePolyline(
                startLat: driverLat!,
                startLng: driverLng!,
                endLat: endLat,
                endLng: endLng,
              );
              if (_hasRouteGeometry(candidate)) {
                routePoints = candidate;
              }
            }
            if (rideUpdate.status == RideStatus.inTransit &&
                targetLat != null &&
                targetLng != null &&
                _canRetryRoute(destinationRouteLastAttempt, now)) {
              destinationRouteLastAttempt = now;
              final candidate = await _repository.getRoutePolyline(
                startLat: driverLat!,
                startLng: driverLng!,
                endLat: targetLat,
                endLng: targetLng,
              );
              if (_hasRouteGeometry(candidate)) {
                routePoints = candidate;
                progress = 0;
              }
            }

            final eta = _getEtaLabel(rideUpdate.status);

            if (!isClosed) {
              emit(
                TrackDriverInProgress(
                  driverLat: driverLat!,
                  driverLng: driverLng!,
                  progress: progress,
                  eta: eta,
                  routePoints: routePoints,
                  status: rideUpdate.status,
                  driverName: rideUpdate.driverName,
                  vehiclePlate: rideUpdate.vehiclePlate,
                  vehicleType: rideUpdate.vehicleType,
                ),
              );
            }
          },
        );
      } catch (error, stackTrace) {
        dev.log(
          'Error synchronizing driver tracking',
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        _isSyncing = false;
      }
    }

    await syncTracking();
    if (!trackingCompleted && !isClosed) {
      _ticker = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(syncTracking()),
      );
    }
  }

  bool _canRetryRoute(DateTime? lastAttempt, DateTime now) {
    return lastAttempt == null ||
        now.difference(lastAttempt) >= const Duration(seconds: 6);
  }

  bool _hasRouteGeometry(List<List<double>>? points) {
    return points != null &&
        points.where((point) {
              return point.length >= 2 &&
                  point[0].isFinite &&
                  point[1].isFinite &&
                  point[0] >= -180 &&
                  point[0] <= 180 &&
                  point[1] >= -90 &&
                  point[1] <= 90;
            }).length >=
            2;
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
}
