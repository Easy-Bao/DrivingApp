extension type const StorageKeys._(int _) {
  static const String accessToken = 'jwt_token';
  static const String refreshToken = 'refresh_token';
  static const String driverId = 'driver_id';
  static const String passengerId = 'passenger_id';
  static const String activeRideId = 'active_ride_id';
  static const String activeBidSessionId = 'active_bid_session_id';
  static const String pendingBidSessionCreation =
      'pending_bid_session_creation';
  static const String pendingBidSessionCancellationId =
      'pending_bid_session_cancellation_id';

  static const String passengerName = 'passenger_name';
  static const String passengerEmail = 'passenger_email';
  static const String passengerPhone = 'passenger_phone';
  static const String passengerAddress = 'passenger_address';
  static const String passengerGender = 'passenger_gender';
  static const String passengerAvatarPath = 'passenger_avatar_path';
  static const String savedPlaces = 'passenger_saved_places_v1';

  static const List<String> profileCacheKeys = [
    passengerName,
    passengerEmail,
    passengerPhone,
    passengerAddress,
    passengerGender,
    passengerAvatarPath,
    savedPlaces,
  ];

  static String chatReadAt(String rideId) => 'chat_read_at_${rideId.trim()}';
}
