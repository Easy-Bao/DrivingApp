import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:equatable/equatable.dart';

class EarningsState extends Equatable {
  const EarningsState({this.isLoading = false, this.data, this.errorMessage});

  final bool isLoading;
  final EarningsSummary? data;
  final String? errorMessage;

  EarningsState copyWith({
    bool? isLoading,
    EarningsSummary? data,
    bool clearData = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EarningsState(
      isLoading: isLoading ?? this.isLoading,
      data: clearData ? null : data ?? this.data,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, data, errorMessage];
}
