import 'package:maps/maps.dart';

abstract interface class DriverLocationAccessRepository {
  Stream<LocationAccessState> get accessStateChanges;

  Future<LocationAccessState> startMonitoring();

  Future<LocationAccessState> refresh();

  Future<LocationAccessState> requestPermission();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();

  Future<void> dispose();
}
