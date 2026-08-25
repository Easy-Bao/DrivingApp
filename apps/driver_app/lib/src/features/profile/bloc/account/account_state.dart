import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:equatable/equatable.dart';

class DriverAccountState extends Equatable {
  final DriverAccountSnapshot account;
  final bool isLoading;
  final String? errorMessage;

  const DriverAccountState({
    this.account = const DriverAccountSnapshot(),
    this.isLoading = false,
    this.errorMessage,
  });

  DriverAccountState copyWith({
    DriverAccountSnapshot? account,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverAccountState(
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [account, isLoading, errorMessage];
}
