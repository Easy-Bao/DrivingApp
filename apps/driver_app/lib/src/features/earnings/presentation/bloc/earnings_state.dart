import 'package:equatable/equatable.dart';

class const DriverEarningsState({
  this.isLoading = false,
  this.data,
  this.errorMessage,
}) extends Equatable {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  DriverEarningsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
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
