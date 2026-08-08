import 'package:geolocator/geolocator.dart';
import 'package:passenger_app/src/core/location/location.dart';

abstract interface class CurrentLocationDataSource {
  Future<Position?> getCurrentPosition();

  Stream<Position> watchCurrentPosition();
}

class DeviceCurrentLocationDataSource implements CurrentLocationDataSource {
  @override
  Future<Position?> getCurrentPosition() {
    return LocationService.getCurrentPosition();
  }

  @override
  Stream<Position> watchCurrentPosition() {
    return LocationService.getPositionStream();
  }
}
