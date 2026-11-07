class StorageKeys {
  static const String accessToken = 'jwt_token';
  static const String refreshToken = 'refresh_token';
  static const String driverId = 'driver_id';
  static const String driverOnlineStatus = 'driver_online_status';
  static const String driverOnlineSince = 'driver_online_since';
  static const String driverLastActive = 'driver_last_active';
  static const String passengerId = 'passenger_id';
  static const String activeRideId = 'active_ride_id';

  static const List<String> profileCacheKeys = [
    'driver_id',
    'driver_name',
    'driver_phone',
    'driver_email',
    'vehicle_type',
    'plate_number',
    'rating',
  ];
}
