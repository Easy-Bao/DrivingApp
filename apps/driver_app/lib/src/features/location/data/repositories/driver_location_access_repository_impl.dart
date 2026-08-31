import 'package:maps/maps.dart';
import 'package:driver_app/src/features/location/domain/repositories/driver_location_access_repository.dart';

final class DriverLocationAccessRepositoryImpl
    implements DriverLocationAccessRepository {
  final _monitor = AccessStateMonitor<LocationAccessState>(
    stateChanges: () => LocationService.accessStateChanges,
    readState: LocationService.getAccessState,
  );

  @override
  Stream<LocationAccessState> get accessStateChanges => _monitor.changes;

  @override
  Future<LocationAccessState> startMonitoring() => _monitor.start();

  @override
  Future<LocationAccessState> refresh() => _monitor.refresh();

  @override
  Future<LocationAccessState> requestPermission() async {
    await LocationService.requestPermission();
    return refresh();
  }

  @override
  Future<bool> openLocationSettings() => LocationService.openLocationSettings();

  @override
  Future<bool> openAppSettings() => LocationService.openAppSettings();

  @override
  Future<void> dispose() async {
    await _monitor.dispose();
  }
}
