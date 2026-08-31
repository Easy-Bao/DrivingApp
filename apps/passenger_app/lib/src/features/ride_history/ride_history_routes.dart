import 'package:passenger_app/src/app/navigation/app_routes.dart';

abstract final class RideHistoryRoutes {
  static const String rideDetails = 'RideDetails';
  // Keep the existing path so saved/deep-linked passenger routes continue to work.
  static const String rideDetailsPath = 'activity/viewDetails';
  static const String passengerRating = 'PassengerRating';
  static const String passengerRatingPath = 'activity/rating';
  static const String passengerPayment = 'PassengerPayment';
  static const String passengerPaymentPath = 'activity/payment';
  static const String rideHistory = 'RideHistory';
  static const String rideHistoryPath = 'activity';
  static const String fullRideHistoryPath =
      '${AppRoutes.passengerModulePath}$rideHistoryPath';
}
