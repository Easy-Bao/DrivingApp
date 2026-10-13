abstract interface class RidePaymentCompletionHandler {
  Future<void> afterCashPayment({required String rideId});
}
