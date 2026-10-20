import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';

class const DispatchSnapshot({this.activeRide, required this.rideOffers}) {
  final RideSnapshot? activeRide;
  final List<Map<String, dynamic>> rideOffers;
}
