import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:maps/maps.dart';

const _freshFixWait = Duration(milliseconds: 300);
const _initialFixWait = Duration(seconds: 5);

abstract interface class CurrentLocationDataSource {
  Future<Position?> getCurrentPosition();

  Stream<Position> watchCurrentPosition();
}

class DeviceCurrentLocationDataSource implements CurrentLocationDataSource {
  @override
  Future<Position?> getCurrentPosition() async {
    final cachedPosition = LocationService.lastPosition;
    final waitDuration = cachedPosition == null
        ? _initialFixWait
        : _freshFixWait;
    final currentPosition = await LocationService.getCurrentPosition().timeout(
      waitDuration,
      onTimeout: () => null,
    );
    return currentPosition ?? cachedPosition;
  }

  @override
  Stream<Position> watchCurrentPosition() {
    return LocationService.getPositionStream();
  }
}
