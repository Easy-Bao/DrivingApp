import 'package:equatable/equatable.dart';
import 'package:BaoRide/src/rust/models/fare_models.dart';

class DashboardState extends Equatable {
  final bool isOnline;
  final List<HeatmapCell> surgeCells;
  final bool isLoading;

  const DashboardState({
    required this.isOnline,
    required this.surgeCells,
    required this.isLoading,
  });

  DashboardState copyWith({
    bool? isOnline,
    List<HeatmapCell>? surgeCells,
    bool? isLoading,
  }) {
    return DashboardState(
      isOnline: isOnline ?? this.isOnline,
      surgeCells: surgeCells ?? this.surgeCells,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [isOnline, surgeCells, isLoading];
}
