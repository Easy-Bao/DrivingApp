import 'dart:async';

import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';

class LocationAccessRepository implements ILocationAccessRepository {
  final StreamController<LocationAccessState> _accessStateController =
      StreamController<LocationAccessState>.broadcast();

  StreamSubscription<LocationAccessState>? _serviceStatusSubscription;
  LocationAccessState? _lastAccessState;
  Future<LocationAccessState>? _refreshInFlight;

  @override
  Stream<LocationAccessState> get accessStateChanges =>
      _accessStateController.stream;

  @override
  Future<LocationAccessState> startMonitoring() async {
    _serviceStatusSubscription ??= LocationService.accessStateChanges.listen(
      _publish,
      onError: (_) => unawaited(refresh()),
    );
    return refresh();
  }

  @override
  Future<LocationAccessState> refresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final refresh = _readAndPublish();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<LocationAccessState> _readAndPublish() async {
    final accessState = await LocationService.getAccessState();
    _publish(accessState);
    return accessState;
  }

  void _publish(LocationAccessState accessState) {
    if (_lastAccessState == accessState || _accessStateController.isClosed) {
      return;
    }
    _lastAccessState = accessState;
    _accessStateController.add(accessState);
  }

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
    await _serviceStatusSubscription?.cancel();
    await _accessStateController.close();
  }
}
