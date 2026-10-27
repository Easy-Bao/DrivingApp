abstract interface class RideCompletionHandler {
  Future<void> afterRideCompleted({required String rideId});
}
