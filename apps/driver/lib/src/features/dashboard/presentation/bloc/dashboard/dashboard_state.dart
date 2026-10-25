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
    this.activeRides = const [],
    this.activeBids = const <Map<String, dynamic>>[],
    this.submittedOffers = const <Map<String, dynamic>>[],
    this.isLoadingDispatch = false,
  });
  static const maxActiveBookings = 5;
  static const _unset = Object();

  final bool isOnline;
  final bool isLoadingStats;
  final bool hasLoadedStats;
  final double earnings;
  final int completedTrips;
  final String? errorMessage;
  final String? statsErrorMessage;
  final List<RideSnapshot> activeRides;
  RideSnapshot? get activeRide => activeRides.firstOrNull;
  bool get isAtBookingCapacity => activeRides.length >= maxActiveBookings;
  final List<Map<String, dynamic>> activeBids;
  final List<Map<String, dynamic>> submittedOffers;
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
    List<RideSnapshot>? activeRides,
    List<Map<String, dynamic>>? activeBids,
    List<Map<String, dynamic>>? submittedOffers,
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
      activeRides: activeRides ?? this.activeRides,
      activeBids: activeBids ?? this.activeBids,
      submittedOffers: submittedOffers ?? this.submittedOffers,
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
    activeRides,
    activeBids,
    submittedOffers,
    isLoadingDispatch,
  ];
}
