import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:equatable/equatable.dart';

class const DriverAccountState({
  this.account = const DriverAccountSnapshot(),
  this.isLoading = false,
  this.isSaving = false,
  this.errorMessage,
}) extends Equatable {
  final DriverAccountSnapshot account;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  DriverAccountState copyWith({
    DriverAccountSnapshot? account,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverAccountState(
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [account, isLoading, isSaving, errorMessage];
}
