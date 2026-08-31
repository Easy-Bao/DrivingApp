import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  static const _unset = Object();

  final bool isOnline;
  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final String? errorMessage;
  final String? statsErrorMessage;
  final List<Map<String, dynamic>> activeTrips;
  final List<Map<String, dynamic>> activeBids;
  final bool isLoadingDispatch;

  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.earnings = 0.0,
    this.completedTrips = 0,
    this.errorMessage,
    this.statsErrorMessage,
    this.activeTrips = const <Map<String, dynamic>>[],
    this.activeBids = const <Map<String, dynamic>>[],
    this.isLoadingDispatch = false,
  });

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    double? earnings,
    int? completedTrips,
    Object? errorMessage = _unset,
    Object? statsErrorMessage = _unset,
    List<Map<String, dynamic>>? activeTrips,
    List<Map<String, dynamic>>? activeBids,
    bool? isLoadingDispatch,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      earnings: earnings ?? this.earnings,
      completedTrips: completedTrips ?? this.completedTrips,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      statsErrorMessage: identical(statsErrorMessage, _unset)
          ? this.statsErrorMessage
          : statsErrorMessage as String?,
      activeTrips: activeTrips ?? this.activeTrips,
      activeBids: activeBids ?? this.activeBids,
      isLoadingDispatch: isLoadingDispatch ?? this.isLoadingDispatch,
    );
  }

  @override
  List<Object?> get props => [
    isOnline,
    isLoadingStats,
    earnings,
    completedTrips,
    errorMessage,
    statsErrorMessage,
    activeTrips,
    activeBids,
    isLoadingDispatch,
  ];
}
