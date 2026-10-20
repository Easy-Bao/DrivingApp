import 'package:equatable/equatable.dart';

class const DashboardStats({
  required this.earnings,
  required this.completedTrips,
}) extends Equatable {
  final double earnings;
  final int completedTrips;

  @override
  List<Object> get props => [earnings, completedTrips];
}
