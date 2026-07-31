import 'dart:developer' as dev;

import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:driver_app/src/Features/Home/Presentation/Bloc/DashboardState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;
  final DriverOperationsClient? _operationsClient;

  DashboardCubit({
    required DashboardRepository repository,
    DriverOperationsClient? operationsClient,
  }) : _repository = repository,
       _operationsClient = operationsClient,
       super(const DashboardState());

  Future<void> loadOperatingStatus() async {
    final operationsClient = _operationsClient;
    if (operationsClient == null) return;
    try {
      final status = await operationsClient.getOperatingStatus();
      final driver = status['driver'];
      emit(
        state.copyWith(
          isOnline: driver is Map && driver['isOnline'] == true,
          blockingCode: status['blockingCode']?.toString(),
          blockingMessage: status['blockingCode'] == null
              ? null
              : status['blockingMessage']?.toString(),
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: driverOperationMessage(error)));
    }
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

    if (goingOnline) {
      emit(
        state.copyWith(
          isOnline: _operationsClient == null,
          isLoadingHeatmap: true,
          errorMessage: null,
        ),
      );
      if (_operationsClient != null) {
        try {
          await _operationsClient.setOnline(isOnline: true, lat: lat, lng: lng);
        } catch (error) {
          emit(
            state.copyWith(
              isOnline: false,
              isLoadingHeatmap: false,
              errorMessage: driverOperationMessage(error),
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            isOnline: true,
            blockingCode: null,
            blockingMessage: null,
            errorMessage: null,
          ),
        );
      }

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
      try {
        await _operationsClient?.setOnline(isOnline: false, lat: lat, lng: lng);
      } catch (error) {
        emit(state.copyWith(errorMessage: driverOperationMessage(error)));
        return;
      }
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
