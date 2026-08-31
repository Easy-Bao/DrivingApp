import 'package:driver_app/src/app/navigation/app_routes.dart';

abstract final class ProfileRoutes {
  static const String account = 'Account';
  static const String accountPath = 'account';
  static const String fullAccountPath =
      '${AppRoutes.driverModulePath}$accountPath';
  static const String personalDetails = 'DriverPersonalDetails';
  static const String personalDetailsPath = 'account/personal-details';
  static const String vehicleInformation = 'DriverVehicleInformation';
  static const String vehicleInformationPath = 'account/vehicle-information';
}
