import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:equatable/equatable.dart';

sealed class const DriverPerformanceState() extends Equatable {
  bool get isLoading => this is DriverPerformanceLoading;

  DriverPerformanceStats? get stats => switch (this) {
    DriverPerformanceInitial(:final stats) => stats,
    DriverPerformanceLoading(:final stats) => stats,
    DriverPerformanceLoaded(:final stats) => stats,
    DriverPerformanceFailure(:final stats) => stats,
  };

  String? get errorMessage => switch (this) {
    DriverPerformanceFailure(:final message) => message,
    DriverPerformanceInitial() ||
    DriverPerformanceLoading() ||
    DriverPerformanceLoaded() => null,
  };
}

final class const DriverPerformanceInitial({this.stats})
    extends DriverPerformanceState {
  @override
  final DriverPerformanceStats? stats;

  @override
  List<Object?> get props => [stats];
}

final class const DriverPerformanceLoading({this.stats})
    extends DriverPerformanceState {
  @override
  final DriverPerformanceStats? stats;

  @override
  List<Object?> get props => [stats];
}

final class const DriverPerformanceLoaded(this.stats)
    extends DriverPerformanceState {
  @override
  final DriverPerformanceStats stats;

  @override
  List<Object?> get props => [stats];
}

final class const DriverPerformanceFailure({this.stats, required this.message})
    extends DriverPerformanceState {
  @override
  final DriverPerformanceStats? stats;
  final String message;

  @override
  List<Object?> get props => [stats, message];
}
