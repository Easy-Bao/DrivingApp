import 'package:passenger_app/src/app/navigation/app_routes.dart';

abstract final class SavedPlacesRoutes {
  static const String places = 'SavedPlaces';
  static const String placesPath = 'account/saved-places';
  static const String fullPlacesPath =
      '${AppRoutes.passengerModulePath}$placesPath';
}
