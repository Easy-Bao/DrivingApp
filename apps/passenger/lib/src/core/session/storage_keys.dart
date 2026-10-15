extension type const PassengerStorageKeys._(int _) {
  static const String jwtToken = 'jwt_token';
  static const String refreshToken = 'refresh_token';
  static const String driverId = 'driver_id';
  static const String passengerId = 'passenger_id';
  static const String activeRideId = 'active_ride_id';
  static const String activeBidSessionId = 'active_bid_session_id';

  static String chatReadAt(String rideId) => 'chat_read_at_${rideId.trim()}';
}
