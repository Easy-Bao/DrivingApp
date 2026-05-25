import 'package:BaoRide/features/driver/data/repositories/dashboard_repository.dart';
import 'package:BaoRide/features/driver/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the driver's dashboard state.
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit({required DashboardRepository repository})
    : _repository = repository,
      super(const DashboardState());

  /// Loads all dashboard stats in parallel.
  Future<void> loadStats() async {
    emit(state.copyWith(isLoadingStats: true));
    try {
      final results = await Future.wait([
        _repository.getTodayEarnings(),
        _repository.getTodayTrips(),
        _repository.getHoursOnline(),
      ]);
      emit(
        state.copyWith(
          isLoadingStats: false,
          todayEarnings: results[0] as double,
          todayTrips: results[1] as int,
          hoursOnline: results[2] as double,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingStats: false));
    }
  }

  /// Toggles driver online/offline status.
  ///
  /// When going online, fetches the surge heatmap for the current location.
  Future<void> toggleOnline({required double lat, required double lng}) async {
    final goingOnline = !state.isOnline;

    if (goingOnline) {
      emit(state.copyWith(isOnline: true, isLoadingHeatmap: true));
      try {
        final cells = await _repository.getSurgeHeatmap(
          lat: lat,
          lng: lng,
          gridSize: 10,
          cellSize: 0.003,
          requestLats: [lat + 0.002, lat - 0.001, lat + 0.005],
          requestLngs: [lng - 0.002, lng + 0.003, lng + 0.001],
        );
        emit(state.copyWith(isLoadingHeatmap: false, surgeCells: cells));
      } catch (_) {
        emit(state.copyWith(isLoadingHeatmap: false, surgeCells: []));
      }
    } else {
      emit(state.copyWith(isOnline: false, surgeCells: []));
    }
  }
}
