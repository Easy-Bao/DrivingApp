import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing the driver dashboard lifecycle: daily earnings, trips,
/// hours online, and surge heatmap grid. Uses [DashboardRepository] returning
/// `Either<Failure, T>` for type-safe error propagation.
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit({required DashboardRepository repository})
    : _repository = repository,
      super(const DashboardState());

  Future<void> loadStats() async {
    emit(state.copyWith(isLoadingStats: true, errorMessage: null));
    try {
      final results = await Future.wait([
        _repository.getTodayEarnings(),
        _repository.getTodayTrips(),
        _repository.getHoursOnline(),
      ]);

      // Collect the first failure across all three parallel requests, or
      // extract success values if all three returned Right.
      String? firstFailureMessage;
      double todayEarnings = 0.0;
      int todayTrips = 0;
      double hoursOnline = 0.0;

      results[0].fold(
        (failure) => firstFailureMessage ??= failure.message,
        (value) => todayEarnings = value as double,
      );
      results[1].fold(
        (failure) => firstFailureMessage ??= failure.message,
        (value) => todayTrips = value as int,
      );
      results[2].fold(
        (failure) => firstFailureMessage ??= failure.message,
        (value) => hoursOnline = value as double,
      );

      if (firstFailureMessage != null) {
        emit(
          state.copyWith(
            isLoadingStats: false,
            errorMessage: firstFailureMessage,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isLoadingStats: false,
          todayEarnings: todayEarnings,
          todayTrips: todayTrips,
          hoursOnline: hoursOnline,
          errorMessage: null,
        ),
      );
    } catch (error) {
      debugPrint('Error loading driver dashboard stats: $error');
      emit(
        state.copyWith(
          isLoadingStats: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> toggleOnline({required double lat, required double lng}) async {
    final goingOnline = !state.isOnline;

    if (goingOnline) {
      emit(
        state.copyWith(
          isOnline: true,
          isLoadingHeatmap: true,
          errorMessage: null,
        ),
      );

      final heatmapResult = await _repository.getSurgeHeatmap(
        lat: lat,
        lng: lng,
        gridSize: 10,
        cellSize: 0.003,
        requestLats: [lat + 0.002, lat - 0.001, lat + 0.005],
        requestLngs: [lng - 0.002, lng + 0.003, lng + 0.001],
      );

      heatmapResult.fold(
        (failure) {
          debugPrint('Error loading surge heatmap: ${failure.message}');
          emit(
            state.copyWith(
              isLoadingHeatmap: false,
              surgeCells: const [],
              errorMessage: failure.message,
            ),
          );
        },
        (cells) {
          emit(
            state.copyWith(
              isLoadingHeatmap: false,
              surgeCells: cells,
              errorMessage: null,
            ),
          );
        },
      );
    } else {
      emit(
        state.copyWith(
          isOnline: false,
          surgeCells: const [],
          errorMessage: null,
        ),
      );
    }
  }
}
