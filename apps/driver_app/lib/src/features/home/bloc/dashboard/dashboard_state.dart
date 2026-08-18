import 'package:driver_app/src/features/home/data/models/heatmap_cell_model.dart';
import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  static const _unset = Object();

  final bool isOnline;
  final bool isLoadingStats;
  final bool isLoadingHeatmap;
  final double earnings;
  final int completedTrips;
  final List<HeatmapCell> surgeCells;
  final String? errorMessage;

  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.isLoadingHeatmap = false,
    this.earnings = 0.0,
    this.completedTrips = 0,
    this.surgeCells = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    bool? isLoadingHeatmap,
    double? earnings,
    int? completedTrips,
    List<HeatmapCell>? surgeCells,
    Object? errorMessage = _unset,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingHeatmap: isLoadingHeatmap ?? this.isLoadingHeatmap,
      earnings: earnings ?? this.earnings,
      completedTrips: completedTrips ?? this.completedTrips,
      surgeCells: surgeCells ?? this.surgeCells,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    isOnline,
    isLoadingStats,
    isLoadingHeatmap,
    earnings,
    completedTrips,
    surgeCells,
    errorMessage,
  ];
}
