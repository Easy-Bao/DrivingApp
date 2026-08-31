import 'package:equatable/equatable.dart';

class DriverDashboardStats extends Equatable {
  final double earnings;
  final int completedTrips;

  const DriverDashboardStats({
    required this.earnings,
    required this.completedTrips,
  });

  @override
  List<Object> get props => [earnings, completedTrips];
}
