import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:equatable/equatable.dart';

class DriverEarningsState extends Equatable {
  const DriverEarningsState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });

  final bool isLoading;
  final DriverEarningsSummary? data;
  final String? errorMessage;

  DriverEarningsState copyWith({
    bool? isLoading,
    DriverEarningsSummary? data,
    bool clearData = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverEarningsState(
      isLoading: isLoading ?? this.isLoading,
      data: clearData ? null : data ?? this.data,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, data, errorMessage];
}
