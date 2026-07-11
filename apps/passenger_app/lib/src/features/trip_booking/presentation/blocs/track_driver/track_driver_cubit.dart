import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackDriverCubit extends Cubit<TrackDriverState> {
  final TrackRepository _repository;
  Timer? _ticker;

  TrackDriverCubit({required TrackRepository repository})
    : _repository = repository,
      super(TrackDriverInitial());

  /// Starts tracking a driver's progress from [startLat,startLng] to [endLat,endLng].
  ///
  /// Fetches a route polyline then simulates movement along it every 1.5 seconds.
  Future<void> startTracking({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String? rideId,
  }) async {
    _ticker?.cancel();

    final prefs = await SharedPreferences.getInstance();
    if (rideId != null && rideId.isNotEmpty) {
      await prefs.setString('active_ride_id', rideId);
    }
    final activeRideId = prefs.getString('active_ride_id') ?? '';

    final routePoints = await _repository.getRoutePolyline(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    double progress = 0.0;

    _ticker = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (isClosed) return;

      bool handled = false;

      if (activeRideId.isNotEmpty) {
        try {
          final statusData = await PassengerApiService.getRideStatus(activeRideId);
          if (statusData != null) {
            final status = statusData['status'] as String?;
            if (status == 'completed') {
              timer.cancel();
              emit(TrackDriverCompleted());
              await prefs.remove('active_ride_id');
              return;
            }

            final driverId = statusData['driver_id'] as String?;
            final driverName = statusData['driver_name'] as String? ?? 'Driver';
            final vehiclePlate = statusData['plate_number'] as String? ?? '—';
            final vehicleType = statusData['vehicle_type'] as String? ?? 'Bao Bao';

            double driverLat = startLat;
            double driverLng = startLng;
            bool locationFetched = false;

            if (driverId != null && driverId.isNotEmpty) {
              try {
                final locData = await PassengerApiService.fetchDriverLocation(driverId);
                if (locData != null && locData['lat'] != null && locData['lng'] != null) {
                  driverLat = (locData['lat'] as num).toDouble();
                  driverLng = (locData['lng'] as num).toDouble();
                  locationFetched = true;
                }
              } catch (_) {}
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
              driverLat = pos.$1;
              driverLng = pos.$2;
            }

            String eta = 'Calculating...';
            if (status == 'accepted') {
              eta = 'En-route';
            } else if (status == 'arrived') {
              eta = 'Arrived';
            } else if (status == 'in_transit') {
              eta = 'In-transit';
            }

            emit(
              TrackDriverInProgress(
                driverLat: driverLat,
                driverLng: driverLng,
                progress: progress,
                eta: eta,
                routePoints: routePoints,
                driverName: driverName,
                vehiclePlate: vehiclePlate,
                vehicleType: vehicleType,
              ),
            );
            handled = true;
          }
        } catch (_) {}
      }

      if (!handled) {
        progress += 0.1;
        if (progress >= 1.0) {
          timer.cancel();
          emit(TrackDriverCompleted());
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
              driverLat: pos.$1,
              driverLng: pos.$2,
              progress: progress,
              eta: etaMinutes == 1 ? '1 min' : '$etaMinutes mins',
              routePoints: routePoints,
              driverName: 'Test Driver',
              vehiclePlate: 'XYZ 9999',
              vehicleType: 'Bao Bao',
            ),
          );
        }
      }
    });
  }

  /// Passenger canceled the trip.
  Future<void> cancelTrip() async {
    _ticker?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      final rideId = prefs.getString('active_ride_id') ?? '';
      if (rideId.isNotEmpty) {
        await PassengerApiService.updateRideStatus(rideId, 'canceled');
        await prefs.remove('active_ride_id');
      }
    } catch (_) {}
    emit(TrackDriverCanceled());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }

  /// Interpolates position along the polyline or falls back to straight-line.
  (double lat, double lng) _interpolate({
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
      // polylinePoints are [lng, lat]
      return (p1[1] + (p2[1] - p1[1]) * t, p1[0] + (p2[0] - p1[0]) * t);
    }
    return (
      startLat + (endLat - startLat) * progress,
      startLng + (endLng - startLng) * progress,
    );
  }
}
