import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:equatable/equatable.dart';

class DriverPerformanceState extends Equatable {
  const DriverPerformanceState({
    this.isLoading = false,
    this.stats,
    this.errorMessage,
  });

  final bool isLoading;
  final DriverActivityStats? stats;
  final String? errorMessage;

  DriverPerformanceState copyWith({
    bool? isLoading,
    DriverActivityStats? stats,
    bool clearStats = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverPerformanceState(
      isLoading: isLoading ?? this.isLoading,
      stats: clearStats ? null : stats ?? this.stats,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, errorMessage];
}
