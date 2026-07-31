import 'package:core_models/core_models.dart';
import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final bool isOnline;
  final bool isLoadingStats;
  final bool isLoadingHeatmap;
  final double todayEarnings;
  final int todayTrips;
  final double hoursOnline;
  final List<HeatmapCell> surgeCells;
  final String? errorMessage;
  final String? blockingCode;
  final String? blockingMessage;

  static const Object _unset = Object();

  const DashboardState({
    this.isOnline = false,
    this.isLoadingStats = false,
    this.isLoadingHeatmap = false,
    this.todayEarnings = 0.0,
    this.todayTrips = 0,
    this.hoursOnline = 0.0,
    this.surgeCells = const [],
    this.errorMessage,
    this.blockingCode,
    this.blockingMessage,
  });

  DashboardState copyWith({
    bool? isOnline,
    bool? isLoadingStats,
    bool? isLoadingHeatmap,
    double? todayEarnings,
    int? todayTrips,
    double? hoursOnline,
    List<HeatmapCell>? surgeCells,
    Object? errorMessage = _unset,
    Object? blockingCode = _unset,
    Object? blockingMessage = _unset,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingHeatmap: isLoadingHeatmap ?? this.isLoadingHeatmap,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayTrips: todayTrips ?? this.todayTrips,
      hoursOnline: hoursOnline ?? this.hoursOnline,
      surgeCells: surgeCells ?? this.surgeCells,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      blockingCode: identical(blockingCode, _unset)
          ? this.blockingCode
          : blockingCode as String?,
      blockingMessage: identical(blockingMessage, _unset)
          ? this.blockingMessage
          : blockingMessage as String?,
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
    blockingCode,
    blockingMessage,
  ];
}
