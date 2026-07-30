import 'package:core_models/core_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/dashboard_state.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(false) bool isOnline,
    @Default(false) bool isLoadingStats,
    @Default(false) bool isLoadingHeatmap,
    @Default(0.0) double todayEarnings,
    @Default(0) int todayTrips,
    @Default(0.0) double hoursOnline,
    @Default([]) List<HeatmapCell> surgeCells,
    String? errorMessage,
  }) = _DashboardState;
}
