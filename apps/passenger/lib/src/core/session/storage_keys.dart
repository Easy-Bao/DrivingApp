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

  static const List<String> profileCacheKeys = [
    'passenger_name',
    'passenger_email',
    'passenger_phone',
    'passenger_address',
    'passenger_gender',
    'passenger_avatar_path',
    'passenger_saved_places_v1',
  ];

  static String chatReadAt(String rideId) => 'chat_read_at_${rideId.trim()}';
}
