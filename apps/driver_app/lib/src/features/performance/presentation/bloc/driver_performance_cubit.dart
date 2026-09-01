import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver_app/src/features/performance/presentation/bloc/driver_performance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class DriverPerformanceCubit({
  required DriverPerformanceRepository repository,
  required DriverSessionStore sessionService,
}) extends Cubit<DriverPerformanceState> {
  this
    : _repository = repository,
      _sessionService = sessionService,
      super(const DriverPerformanceInitial());

  final DriverPerformanceRepository _repository;
  final DriverSessionStore _sessionService;

  Future<void> load() async {
    if (isClosed) return;
    emit(DriverPerformanceLoading(stats: state.stats));

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
        (stats) => emit(DriverPerformanceLoaded(stats)),
      );
    } catch (error) {
      _emitFailure(ErrorHandler.getErrorMessage(error));
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(DriverPerformanceFailure(stats: state.stats, message: message));
  }
}
