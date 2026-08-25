import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';

class DriverAccountCubit extends Cubit<DriverAccountState> {
  final IDriverProfileRepository _repository;

  DriverAccountCubit({required IDriverProfileRepository repository})
    : _repository = repository,
      super(const DriverAccountState());

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final cached = _repository.getCachedAccount();
      emit(state.copyWith(account: cached, isLoading: false));

      final result = await _repository.refreshAccount();
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            isLoading: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (account) => emit(
          state.copyWith(account: account, isLoading: false, clearError: true),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }
}
