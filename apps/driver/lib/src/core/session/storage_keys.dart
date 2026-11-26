abstract final class StorageKeys {
  static const String accessToken = 'jwt_token';
  static const String refreshToken = 'refresh_token';
  static const String driverId = 'driver_id';
  static const String driverName = 'driver_name';
  static const String driverPhone = 'driver_phone';
  static const String driverEmail = 'driver_email';
  static const String vehicleType = 'vehicle_type';
  static const String plateNumber = 'plate_number';
  static const String rating = 'rating';
  static const String driverOnlineStatus = 'driver_online_status';
  static const String driverOnlineSince = 'driver_online_since';
  static const String driverLastActive = 'driver_last_active';
  static const String passengerId = 'passenger_id';
  static const String activeRideId = 'active_ride_id';

  static const List<String> profileCacheKeys = [
    driverId,
    driverName,
    driverPhone,
    driverEmail,
    vehicleType,
    plateNumber,
    rating,
  ];
}
