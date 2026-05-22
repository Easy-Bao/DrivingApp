import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/core/services/map_provider.dart';
import 'track_driver_state.dart';

class TrackDriverCubit extends Cubit<TrackDriverState> {
  Timer? _ticker;

  TrackDriverCubit() : super(TrackDriverInitial());

  void startTracking({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    _ticker?.cancel();
    
    // Fetch route snap-to-road polyline
    final route = await MapProvider.getRoute(startLat, startLng, endLat, endLng);
    final List<List<double>>? routePoints = route?.polylinePoints;
    
    double progress = 0.0;
    
    _ticker = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (isClosed) return;
      progress += 0.1;
      if (progress >= 1.0) {
        timer.cancel();
        emit(TrackDriverCompleted());
      } else {
        double curLat;
        double curLng;
        
        if (routePoints != null && routePoints.isNotEmpty) {
          // Snap/interpolate along polyline points!
          final double fractionalIndex = progress * (routePoints.length - 1);
          final int index = fractionalIndex.floor();
          final int nextIndex = (index + 1).clamp(0, routePoints.length - 1);
          final double t = fractionalIndex - index;
          
          final p1 = routePoints[index];
          final p2 = routePoints[nextIndex];
          
          // Note: MapProvider route polylinePoints are stored as [lng, lat]
          curLat = p1[1] + (p2[1] - p1[1]) * t;
          curLng = p1[0] + (p2[0] - p1[0]) * t;
        } else {
          // Fallback to straight-line interpolation
          curLat = startLat + (endLat - startLat) * progress;
          curLng = startLng + (endLng - startLng) * progress;
        }
        
        final etaMinutes = ((1.0 - progress) * 10).ceil();
        emit(TrackDriverInProgress(
          driverLat: curLat,
          driverLng: curLng,
          progress: progress,
          eta: etaMinutes == 1 ? "1 min" : "$etaMinutes mins",
          routePoints: routePoints,
        ));
      }
    });
  }

  void cancelTrip() {
    _ticker?.cancel();
    emit(TrackDriverCanceled());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
