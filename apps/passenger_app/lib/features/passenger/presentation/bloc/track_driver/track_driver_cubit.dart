import 'dart:async';

import 'package:passenger_app/features/passenger/data/repositories/track_repository.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages real-time driver position tracking for the passenger.
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
  }) async {
    _ticker?.cancel();

    final routePoints = await _repository.getRoutePolyline(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    double progress = 0.0;

    _ticker = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (isClosed) return;
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
          ),
        );
      }
    });
  }

  /// Passenger canceled the trip.
  void cancelTrip() {
    _ticker?.cancel();
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
