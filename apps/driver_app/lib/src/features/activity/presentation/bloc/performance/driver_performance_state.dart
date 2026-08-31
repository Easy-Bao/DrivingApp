import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:equatable/equatable.dart';

sealed class DriverPerformanceState extends Equatable {
  const DriverPerformanceState();

  bool get isLoading => this is DriverPerformanceLoading;

  DriverActivityStats? get stats => switch (this) {
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

final class DriverPerformanceInitial extends DriverPerformanceState {
  const DriverPerformanceInitial({this.stats});

  @override
  final DriverActivityStats? stats;

  @override
  List<Object?> get props => [stats];
}

final class DriverPerformanceLoading extends DriverPerformanceState {
  const DriverPerformanceLoading({this.stats});

  @override
  final DriverActivityStats? stats;

  @override
  List<Object?> get props => [stats];
}

final class DriverPerformanceLoaded extends DriverPerformanceState {
  const DriverPerformanceLoaded(this.stats);

  @override
  final DriverActivityStats stats;

  @override
  List<Object?> get props => [stats];
}

final class DriverPerformanceFailure extends DriverPerformanceState {
  const DriverPerformanceFailure({this.stats, required this.message});

  @override
  final DriverActivityStats? stats;
  final String message;

  @override
  List<Object?> get props => [stats, message];
}
