import 'package:core_models/core_models.dart';
import 'package:equatable/equatable.dart';

/// All fields default to empty/zero — the UI can distinguish between
/// "not yet loaded" and "loaded as zero" using [isLoadingStats].
class DashboardState extends Equatable {
  final bool isOnline;
  final bool isLoadingStats;
  final bool isLoadingHeatmap;
  final double todayEarnings;
  final int todayTrips;
  final double hoursOnline;
  final List<HeatmapCell> surgeCells;

  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.isLoadingHeatmap = false,
    this.todayEarnings = 0.0,
    this.todayTrips = 0,
    this.hoursOnline = 0.0,
    this.surgeCells = const [],
  });

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    bool? isLoadingHeatmap,
    double? todayEarnings,
    int? todayTrips,
    double? hoursOnline,
    List<HeatmapCell>? surgeCells,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingHeatmap: isLoadingHeatmap ?? this.isLoadingHeatmap,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayTrips: todayTrips ?? this.todayTrips,
      hoursOnline: hoursOnline ?? this.hoursOnline,
      surgeCells: surgeCells ?? this.surgeCells,
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
  ];
}
