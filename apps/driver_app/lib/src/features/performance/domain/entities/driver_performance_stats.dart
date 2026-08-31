import 'package:equatable/equatable.dart';

class DriverPerformanceStats extends Equatable {
  const DriverPerformanceStats({
    required this.todayEarningsCentavos,
    required this.todayCompletedTrips,
    required this.totalTrips,
    required this.completedTrips,
    required this.totalEarningsCentavos,
    required this.averageRating,
  });

  final int todayEarningsCentavos;
  final int todayCompletedTrips;
  final int totalTrips;
  final int completedTrips;
  final int totalEarningsCentavos;
  final double averageRating;

  @override
  List<Object> get props => [
    todayEarningsCentavos,
    todayCompletedTrips,
    totalTrips,
    completedTrips,
    totalEarningsCentavos,
    averageRating,
  ];
}
