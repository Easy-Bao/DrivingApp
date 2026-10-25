import 'package:maps/src/domain/entities/location_access_state.dart';

abstract interface class LocationAccessRepository {
  Stream<LocationAccessState> get accessStateChanges;

  Future<LocationAccessState> startMonitoring();

  Future<LocationAccessState> refresh();

  Future<LocationAccessState> requestPermission();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();

  Future<void> dispose();
}
