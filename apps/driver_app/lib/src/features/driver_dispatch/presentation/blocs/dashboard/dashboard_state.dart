import 'package:core_models/core_models.dart';
import 'package:equatable/equatable.dart';

/// Dashboard State component defining application state or layout.
class DashboardState extends Equatable {
  final bool isOnline;
  final bool isLoadingStats;
  final bool isLoadingHeatmap;
  final double todayEarnings;
  final int todayTrips;
  final double hoursOnline;
  final List<HeatmapCell> surgeCells;
  final String? errorMessage;

  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.isLoadingHeatmap = false,
    this.todayEarnings = 0.0,
    this.todayTrips = 0,
    this.hoursOnline = 0.0,
    this.surgeCells = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    bool? isLoadingHeatmap,
    double? todayEarnings,
    int? todayTrips,
    double? hoursOnline,
    List<HeatmapCell>? surgeCells,
    String? errorMessage,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingHeatmap: isLoadingHeatmap ?? this.isLoadingHeatmap,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayTrips: todayTrips ?? this.todayTrips,
      hoursOnline: hoursOnline ?? this.hoursOnline,
      surgeCells: surgeCells ?? this.surgeCells,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isOnline,
    isLoadingStats,
    isLoadingHeatmap,
    todayEarnings,
    todayTrips,
    hoursOnline,
    surgeCells,
    errorMessage,
  ];
}
