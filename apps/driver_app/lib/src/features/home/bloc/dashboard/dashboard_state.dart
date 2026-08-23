import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  static const _unset = Object();

  final bool isOnline;
  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final String? errorMessage;

  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.earnings = 0.0,
    this.completedTrips = 0,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    double? earnings,
    int? completedTrips,
    Object? errorMessage = _unset,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      earnings: earnings ?? this.earnings,
      completedTrips: completedTrips ?? this.completedTrips,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    isOnline,
    isLoadingStats,
    earnings,
    completedTrips,
    errorMessage,
  ];
}
