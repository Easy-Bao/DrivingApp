import 'package:passenger_app/src/app/navigation/app_routes.dart';

abstract final class ActivityRoutes {
  static const String activityViewDetails = 'ActivityViewDetails';
  static const String activityViewDetailsPath = 'activity/viewDetails';
  static const String passengerRating = 'PassengerRating';
  static const String passengerRatingPath = 'activity/rating';
  static const String passengerPayment = 'PassengerPayment';
  static const String passengerPaymentPath = 'activity/payment';
  static const String activity = 'Activity';
  static const String activityPath = 'activity';
  static const String fullActivityPath =
      '${AppRoutes.passengerModulePath}$activityPath';
}
