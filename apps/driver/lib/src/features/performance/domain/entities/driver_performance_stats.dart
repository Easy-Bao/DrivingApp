import 'package:equatable/equatable.dart';

class const DriverPerformanceStats({
  required this.todayEarningsAmount,
  required this.todayCompletedTrips,
  required this.totalTrips,
  required this.completedTrips,
  required this.totalEarningsAmount,
  required this.averageRating,
  this.standing = const DriverStanding(),
  this.ratingDistribution = const [0, 0, 0, 0, 0],
}) extends Equatable {
  final int todayEarningsAmount;
  final int todayCompletedTrips;
  final int totalTrips;
  final int completedTrips;
  final int totalEarningsAmount;
  final double averageRating;
  final DriverStanding standing;
  final List<int> ratingDistribution;

  @override
  List<Object> get props => [
    todayEarningsAmount,
    todayCompletedTrips,
    totalTrips,
    completedTrips,
    totalEarningsAmount,
    averageRating,
    standing,
    ratingDistribution,
  ];
}

class const DriverStanding({
  this.settledTrips = 0,
  this.driverFaultCancellations = 0,
  this.passengerFaultCancellations = 0,
  this.systemFaultCancellations = 0,
  this.noFaultCancellations = 0,
  this.safetyRelatedCancellations = 0,
  this.pendingReviewCancellations = 0,
  this.adminOverrideCancellations = 0,
  this.completionRatePercent = 0,
  this.driverFaultCancellationRatePercent = 0,
}) extends Equatable {
  final int settledTrips;
  final int driverFaultCancellations;
  final int passengerFaultCancellations;
  final int systemFaultCancellations;
  final int noFaultCancellations;
  final int safetyRelatedCancellations;
  final int pendingReviewCancellations;
  final int adminOverrideCancellations;
  final double completionRatePercent;
  final double driverFaultCancellationRatePercent;

  @override
  List<Object> get props => [
    settledTrips,
    driverFaultCancellations,
    passengerFaultCancellations,
    systemFaultCancellations,
    noFaultCancellations,
    safetyRelatedCancellations,
    pendingReviewCancellations,
    adminOverrideCancellations,
    completionRatePercent,
    driverFaultCancellationRatePercent,
  ];
}
