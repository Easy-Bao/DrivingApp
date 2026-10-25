import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';

class const DispatchSnapshot({
  this.activeRides = const [],
  required this.rideOffers,
}) {
  final List<RideSnapshot> activeRides;
  RideSnapshot? get activeRide => activeRides.firstOrNull;
  final List<Map<String, dynamic>> rideOffers;
}
