import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:equatable/equatable.dart';

sealed class const PerformanceState() extends Equatable {
  bool get isLoading => this is PerformanceLoading;

  PerformanceStats? get stats => switch (this) {
    PerformanceInitial(:final stats) => stats,
    PerformanceLoading(:final stats) => stats,
    PerformanceLoaded(:final stats) => stats,
    PerformanceFailure(:final stats) => stats,
  };

  String? get errorMessage => switch (this) {
    PerformanceFailure(:final message) => message,
    PerformanceInitial() || PerformanceLoading() || PerformanceLoaded() => null,
  };
}

final class const PerformanceInitial({this.stats}) extends PerformanceState {
  @override
  final PerformanceStats? stats;

  @override
  List<Object?> get props => [stats];
}

final class const PerformanceLoading({this.stats}) extends PerformanceState {
  @override
  final PerformanceStats? stats;

  @override
  List<Object?> get props => [stats];
}

final class const PerformanceLoaded(this.stats) extends PerformanceState {
  @override
  final PerformanceStats stats;

  @override
  List<Object?> get props => [stats];
}

final class const PerformanceFailure({this.stats, required this.message})
    extends PerformanceState {
  @override
  final PerformanceStats? stats;
  final String message;

  @override
  List<Object?> get props => [stats, message];
}
