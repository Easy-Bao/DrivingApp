import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';
import 'package:shared_core/shared_core.dart';

class LocationAccessRepository implements ILocationAccessRepository {
  final _monitor = AccessStateMonitor<LocationAccessState>(
    stateChanges: () => LocationService.accessStateChanges,
    readState: LocationService.getAccessState,
  );

  @override
  Stream<LocationAccessState> get accessStateChanges =>
      _monitor.changes;

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
