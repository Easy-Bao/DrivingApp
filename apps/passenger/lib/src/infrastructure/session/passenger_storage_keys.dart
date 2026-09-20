// ignore: avoid_classes_with_only_static_members
abstract final class PassengerStorageKeys {
  static const String jwtToken = 'jwt_token';
  static const String refreshToken = 'refresh_token';
  static const String driverId = 'driver_id';
  static const String passengerId = 'passenger_id';
  static const String activeRideId = 'active_ride_id';

  static String chatReadAt(String rideId) => 'chat_read_at_${rideId.trim()}';
}
