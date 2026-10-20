import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver/src/features/performance/presentation/bloc/driver_performance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class PerformanceCubit({
  required this._repository,
  required this._sessionService,
}) extends Cubit<PerformanceState> {
  this : super(const PerformanceInitial());

  final PerformanceRepository _repository;
  final SessionStore _sessionService;

  Future<void> load() async {
    if (isClosed || state.isLoading) return;
    emit(PerformanceLoading(stats: state.stats));

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
        (stats) => emit(PerformanceLoaded(stats)),
      );
    } catch (error) {
      _emitFailure(ErrorHandler.getErrorMessage(error));
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(PerformanceFailure(stats: state.stats, message: message));
  }

  void dismissError() {
    if (isClosed || state.errorMessage == null) return;
    final currentStats = state.stats;
    if (currentStats != null) {
      emit(PerformanceLoaded(currentStats));
    } else {
      emit(const PerformanceInitial());
    }
  }
}
