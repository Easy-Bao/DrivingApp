import 'package:equatable/equatable.dart';

import 'package:maps/src/domain/entities/route.dart';

class RouteRequestKey extends Equatable {
  RouteRequestKey({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required this.preference,
    required this.profile,
    required List<({double latitude, double longitude})> excludePoints,
  })  : originLatitude = _coordinateKey(originLatitude),
        originLongitude = _coordinateKey(originLongitude),
        destinationLatitude = _coordinateKey(destinationLatitude),
        destinationLongitude = _coordinateKey(destinationLongitude),
        excludePoints = excludePoints
            .map(
              (point) =>
                  '${_coordinateKey(point.latitude)},${_coordinateKey(point.longitude)}',
            )
            .join(';');

  final String originLatitude;
  final String originLongitude;
  final String destinationLatitude;
  final String destinationLongitude;
  final RoutePreference preference;
  final RouteProfile profile;
  final String excludePoints;

  @override
  List<Object?> get props => [
    originLatitude,
    originLongitude,
    destinationLatitude,
    destinationLongitude,
    preference,
    profile,
    excludePoints,
  ];
}

String _coordinateKey(double value) => value.toStringAsFixed(6);
