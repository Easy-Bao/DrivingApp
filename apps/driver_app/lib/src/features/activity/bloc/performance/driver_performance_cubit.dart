import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/bloc/performance/driver_performance_state.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';

class DriverPerformanceCubit extends Cubit<DriverPerformanceState> {
  DriverPerformanceCubit({
    required IDriverActivityRepository repository,
    required SecureSessionService sessionService,
  }) : _repository = repository,
       _sessionService = sessionService,
       super(const DriverPerformanceState());

  final IDriverActivityRepository _repository;
  final SecureSessionService _sessionService;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final driverId = await _sessionService.readDriverId() ?? '';
      if (driverId.trim().isEmpty) {
        _emitFailure('Your driver session is unavailable.');
        return;
      }

      final result = await _repository.fetchStats(driverId);
      if (isClosed) return;
      result.fold(
        (failure) => _emitFailure(ErrorHandler.getErrorMessage(failure)),
        (stats) => emit(
          state.copyWith(isLoading: false, stats: stats, clearError: true),
        ),
      );
    } catch (error) {
      _emitFailure(ErrorHandler.getErrorMessage(error));
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(isLoading: false, errorMessage: message));
  }
}
