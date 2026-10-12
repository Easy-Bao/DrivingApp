import 'package:equatable/equatable.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.hasLoadedStats = false,
    this.earnings = 0.0,
    this.completedTrips = 0,
    this.errorMessage,
    this.statsErrorMessage,
    this.activeRide,
    List<Map<String, dynamic>> activeBids = const <Map<String, dynamic>>[],
    this.isLoadingDispatch = false,
  }) : activeBids = activeRide == null
           ? activeBids
           : const <Map<String, dynamic>>[];
  static const _unset = Object();

  final bool isOnline;
  final bool isLoadingStats;
  final bool hasLoadedStats;
  final double earnings;
  final int completedTrips;
  final String? errorMessage;
  final String? statsErrorMessage;
  final RideSnapshot? activeRide;
  final List<Map<String, dynamic>> activeBids;
  final bool isLoadingDispatch;

  bool get hasActiveRide => activeRide != null;

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    bool? hasLoadedStats,
    double? earnings,
    int? completedTrips,
    Object? errorMessage = _unset,
    Object? statsErrorMessage = _unset,
    Object? activeRide = _unset,
    List<Map<String, dynamic>>? activeBids,
    bool? isLoadingDispatch,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      hasLoadedStats: hasLoadedStats ?? this.hasLoadedStats,
      earnings: earnings ?? this.earnings,
      completedTrips: completedTrips ?? this.completedTrips,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      statsErrorMessage: identical(statsErrorMessage, _unset)
          ? this.statsErrorMessage
          : statsErrorMessage as String?,
      activeRide: identical(activeRide, _unset)
          ? this.activeRide
          : activeRide as RideSnapshot?,
      activeBids: activeBids ?? this.activeBids,
      isLoadingDispatch: isLoadingDispatch ?? this.isLoadingDispatch,
    );
  }

  @override
  List<Object?> get props => [
    isOnline,
    isLoadingStats,
    hasLoadedStats,
    earnings,
    completedTrips,
    errorMessage,
    statsErrorMessage,
    activeRide,
    activeBids,
    isLoadingDispatch,
  ];
}
