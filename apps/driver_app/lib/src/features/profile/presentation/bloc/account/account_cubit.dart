import 'package:driver_app/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class DriverAccountCubit extends Cubit<DriverAccountState> {
  final IDriverProfileRepository _repository;

  DriverAccountCubit({required IDriverProfileRepository repository})
    : _repository = repository,
      super(const DriverAccountState());

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, isSaving: false, clearError: true));

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

  Future<bool> updateAccount({
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String plateNumber,
  }) async {
    if (isClosed || state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _repository.updateAccount(
      currentAccount: state.account,
      name: name,
      phone: phone,
      email: email,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
        return false;
      },
      (account) {
        emit(
          state.copyWith(account: account, isSaving: false, clearError: true),
        );
        return true;
      },
    );
  }
}
