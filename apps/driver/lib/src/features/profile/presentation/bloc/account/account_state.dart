import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:equatable/equatable.dart';

class const AccountState({
  this.account = const AccountSnapshot(),
  this.isLoading = false,
  this.isSaving = false,
  this.errorMessage,
}) extends Equatable {
  final AccountSnapshot account;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  AccountState copyWith({
    AccountSnapshot? account,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountState(
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [account, isLoading, isSaving, errorMessage];
}
