import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/bloc/earnings/earnings_state.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';

class DriverEarningsCubit extends Cubit<DriverEarningsState> {
  final IDriverActivityRepository _repository;
  final SecureSessionService _sessionService;

  DriverEarningsCubit({
    required IDriverActivityRepository repository,
    required SecureSessionService sessionService,
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
