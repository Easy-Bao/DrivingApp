import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:driver_app/src/features/earnings/presentation/bloc/earnings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class DriverEarningsCubit extends Cubit<DriverEarningsState> {
  final DriverEarningsRepository _repository;
  final DriverSessionStore _sessionService;

  DriverEarningsCubit({
    required DriverEarningsRepository repository,
    required DriverSessionStore sessionService,
  }) : _repository = repository,
       _sessionService = sessionService,
       super(const DriverEarningsState());

  Future<void> load() async {
    if (isClosed) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final driverId = await _sessionService.readDriverId() ?? '';
      if (driverId.trim().isEmpty) {
        _emitFailure('Your driver session is unavailable.');
        return;
      }

      final result = await _repository.fetchEarningsSummary(driverId);
      if (isClosed) return;
      result.fold(
        (failure) => _emitFailure(ErrorHandler.getErrorMessage(failure)),
        (data) => emit(
          state.copyWith(isLoading: false, data: data, clearError: true),
        ),
      );
    } catch (error) {
      _emitFailure(ErrorHandler.getErrorMessage(error));
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(isLoading: false, clearData: true, errorMessage: message),
    );
  }
}
