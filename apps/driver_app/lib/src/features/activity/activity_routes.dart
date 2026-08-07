import 'package:driver_app/src/core/routing/app_routes.dart';

abstract final class ActivityRoutes {
  static const String tripHistory = 'TripHistory';
  static const String tripHistoryPath = 'trips';
  static const String fullTripHistoryPath =
      '${AppRoutes.driverModulePath}$tripHistoryPath';
  static const String tripDetail = 'TripDetail';
  static const String tripDetailPath = 'earnings/trip-detail';
}
