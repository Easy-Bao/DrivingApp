import 'package:equatable/equatable.dart';

import 'package:maps/src/domain/entities/route.dart';

/// Identifies a route request independently of its map implementation.
class RouteRequestKey extends Equatable {
  final String originLat;
  final String originLng;
  final String destLat;
  final String destLng;
  final RoutePreference preference;
  final RouteProfile profile;
  final String excludePoints;

  RouteRequestKey({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required this.preference,
    required this.profile,
    required List<({double lat, double lng})> excludePoints,
  }) : originLat = _coordinateKey(originLat),
       originLng = _coordinateKey(originLng),
       destLat = _coordinateKey(destLat),
       destLng = _coordinateKey(destLng),
       excludePoints = excludePoints
           .map(
             (point) =>
                 '${_coordinateKey(point.lat)},${_coordinateKey(point.lng)}',
           )
           .join(';');

  @override
  List<Object?> get props => [
    originLat,
    originLng,
    destLat,
    destLng,
    preference,
    profile,
    excludePoints,
  ];
}

String _coordinateKey(double value) => value.toStringAsFixed(6);
