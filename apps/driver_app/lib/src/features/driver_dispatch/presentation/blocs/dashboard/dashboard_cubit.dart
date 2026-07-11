import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/**
 * Cubit responsible for managing the driver's online/offline status, stats,
 * and surge heatmap display on the dashboard map view.
 */
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit({required DashboardRepository repository})
    : _repository = repository,
      super(const DashboardState());

  /**
   * Loads all driver dashboard stats (earnings, trip counts, online hours) in parallel.
   */
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
    } catch (error) {
      debugPrint('Error loading driver dashboard stats: $error');
      emit(state.copyWith(isLoadingStats: false));
    }
  }

  /**
   * Toggles the driver's active online/offline dispatch status.
   * Fetches local surge heatmap cells immediately upon going online.
   */
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
      } catch (error) {
        debugPrint('Error loading surge heatmap: $error');
        emit(state.copyWith(isLoadingHeatmap: false, surgeCells: const []));
      }
    } else {
      emit(state.copyWith(isOnline: false, surgeCells: const []));
    }
  }
}
