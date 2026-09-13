import 'package:equatable/equatable.dart';

class const DriverPerformanceStats({
  required this.todayEarningsAmount,
  required this.todayCompletedTrips,
  required this.totalTrips,
  required this.completedTrips,
  required this.totalEarningsAmount,
  required this.averageRating,
}) extends Equatable {
  final int todayEarningsAmount;
  final int todayCompletedTrips;
  final int totalTrips;
  final int completedTrips;
  final int totalEarningsAmount;
  final double averageRating;

  @override
  List<Object> get props => [
    todayEarningsAmount,
    todayCompletedTrips,
    totalTrips,
    completedTrips,
    totalEarningsAmount,
    averageRating,
  ];
}
