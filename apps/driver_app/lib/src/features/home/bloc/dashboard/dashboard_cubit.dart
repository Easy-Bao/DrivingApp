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
      final result = await _repository.getDashboardStats();
      result.fold(
        (failure) => emit(
          state.copyWith(
            isLoadingStats: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (stats) => emit(
          state.copyWith(
            isLoadingStats: false,
            earnings: stats.earnings,
            completedTrips: stats.completedTrips,
            errorMessage: null,
          ),
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

  Future<void> toggleOnline({
    required double lat,
    required double lng,
    bool? requestedOnline,
  }) async {
    final goingOnline = requestedOnline ?? !state.isOnline;

    final updateResult = await _repository.updateOnlineStatus(
      isOnline: goingOnline,
      lat: lat,
      lng: lng,
    );

    if (updateResult.isLeft()) {
      updateResult.fold(
        (failure) => emit(
          state.copyWith(
            isOnline: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (_) {},
      );
      return;
    }

    if (goingOnline) {
      emit(state.copyWith(isOnline: true, errorMessage: null));
    } else {
      emit(state.copyWith(isOnline: false, errorMessage: null));
    }
  }

  Future<void> forceOffline({required double lat, required double lng}) async {
    final updateResult = await _repository.updateOnlineStatus(
      isOnline: false,
      lat: lat,
      lng: lng,
    );

    updateResult.fold(
      (failure) => emit(
        state.copyWith(
          isOnline: false,
          errorMessage: ErrorHandler.getErrorMessage(failure),
        ),
      ),
      (_) => emit(state.copyWith(isOnline: false, errorMessage: null)),
    );
  }

  Future<bool> refreshOnlinePresence({
    required double lat,
    required double lng,
  }) async {
    if (!state.isOnline) return false;

    final updateResult = await _repository.updateOnlineStatus(
      isOnline: true,
      lat: lat,
      lng: lng,
    );
    return updateResult.fold((failure) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)));
      return false;
    }, (_) => true);
  }
}
