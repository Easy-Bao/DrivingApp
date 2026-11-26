import 'package:core_domain/core_domain.dart';

class const DispatchSnapshot({
  this.activeRides = const [],
  required this.rideOffers,
}) {
  final List<RideSnapshot> activeRides;
  RideSnapshot? get activeRide => activeRides.firstOrNull;
  final List<Map<String, dynamic>> rideOffers;
}
