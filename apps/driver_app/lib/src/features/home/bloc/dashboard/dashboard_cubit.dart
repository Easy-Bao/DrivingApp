import 'dart:developer' as dev;

import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final IDashboardRepository _repository;

  DashboardCubit({required IDashboardRepository repository})
    : _repository = repository,
      super(const DashboardState());

  Future<void> initialize() async {
    final onlineStatusResult = await _repository.getPersistedOnlineStatus();
    onlineStatusResult.fold(
      (failure) =>
          dev.log('Unable to restore driver online status: ${failure.message}'),
      (isOnline) => emit(state.copyWith(isOnline: isOnline)),
    );
    await loadStats();
  }

  Future<void> loadStats() async {
    emit(state.copyWith(isLoadingStats: true, errorMessage: null));
    try {
      final results = await Future.wait([
        _repository.getTodayEarnings(),
        _repository.getTodayTrips(),
        _repository.getHoursOnline(),
      ]);

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
      dev.log('Error loading driver dashboard stats: $error');
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

    final updateResult = await _repository.updateOnlineStatus(
      isOnline: goingOnline,
      lat: lat,
      lng: lng,
    );

    if (updateResult.isLeft()) {
      updateResult.fold(
        (failure) => emit(state.copyWith(errorMessage: failure.message)),
        (_) {},
      );
      return;
    }

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
        requestLats: const [],
        requestLngs: const [],
      );

      heatmapResult.fold(
        (failure) {
          dev.log('Error loading surge heatmap: ${failure.message}');
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

  Future<void> forceOffline({required double lat, required double lng}) async {
    if (!state.isOnline) return;

    final updateResult = await _repository.updateOnlineStatus(
      isOnline: false,
      lat: lat,
      lng: lng,
    );

    updateResult.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(
          isOnline: false,
          surgeCells: const [],
          errorMessage: null,
        ),
      ),
    );
  }
}
