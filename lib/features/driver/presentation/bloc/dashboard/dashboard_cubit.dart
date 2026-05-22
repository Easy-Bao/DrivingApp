import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/features/driver/data/repositories/ride_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final RideRepository _rideRepository;

  DashboardCubit({required RideRepository rideRepository})
    : _rideRepository = rideRepository,
      super(
        const DashboardState(isOnline: false, surgeCells: [], isLoading: false),
      );

  Future<void> toggleOnline(double lat, double lng) async {
    final nextOnline = !state.isOnline;
    if (nextOnline) {
      emit(state.copyWith(isLoading: true, isOnline: true));
      try {
        // Fetch 10x10 surge heatmap using local coordinate seed
        final cells = await _rideRepository.getSurgeHeatmap(
          lat: lat,
          lng: lng,
          gridSize: 10,
          cellSize: 0.003,
          requestLats: [lat + 0.002, lat - 0.001, lat + 0.005],
          requestLngs: [lng - 0.002, lng + 0.003, lng + 0.001],
        );
        emit(state.copyWith(isLoading: false, surgeCells: cells));
      } catch (e) {
        emit(state.copyWith(isLoading: false, surgeCells: []));
      }
    } else {
      emit(state.copyWith(isOnline: false, surgeCells: []));
    }
  }
}
