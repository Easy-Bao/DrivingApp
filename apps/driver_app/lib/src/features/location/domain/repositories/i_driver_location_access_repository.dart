import 'package:driver_app/src/core/location/location.dart';

abstract interface class IDriverLocationAccessRepository {
  Stream<LocationAccessState> get accessStateChanges;

  Future<LocationAccessState> startMonitoring();

  Future<LocationAccessState> refresh();

  Future<LocationAccessState> requestPermission();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();

  Future<void> dispose();
}
