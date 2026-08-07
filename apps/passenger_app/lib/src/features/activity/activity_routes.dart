import 'package:passenger_app/src/core/routing/app_routes.dart';

abstract final class ActivityRoutes {
  static const String viewAllRecentActivity = 'ViewAllRecentActivity';
  static const String viewAllRecentActivityPath = 'activity/view-all';
  static const String viewAllSuggestions = 'ViewAllSuggestions';
  static const String activityViewDetails = 'ActivityViewDetails';
  static const String activityViewDetailsPath = 'activity/viewDetails';
  static const String activityTrackDriver = 'ActivityTrackDriver';
  static const String activityTrackDriverPath = 'activity/trackDriver';
  static const String rating = 'Rating';
  static const String passengerRating = 'PassengerRating';
  static const String passengerRatingPath = 'activity/rating';
  static const String passengerPayment = 'PassengerPayment';
  static const String passengerPaymentPath = 'activity/payment';
  static const String activity = 'Activity';
  static const String activityPath = 'activity';
  static const String fullActivityPath =
      '${AppRoutes.passengerModulePath}$activityPath';
  static const String rideHistory = 'RideHistory';
}
