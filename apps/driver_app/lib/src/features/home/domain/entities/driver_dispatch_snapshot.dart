class DriverDispatchSnapshot {
  const DriverDispatchSnapshot({
    required this.activeTrips,
    required this.rideOffers,
  });

  final List<Map<String, dynamic>> activeTrips;
  final List<Map<String, dynamic>> rideOffers;
}
