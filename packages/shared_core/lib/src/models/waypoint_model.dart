import 'package:equatable/equatable.dart';

class Waypoint extends Equatable {
  final String id;
  final double lat;
  final double lng;
  final String name;
  final bool isPickup;
  final String passengerId;

  const Waypoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.name,
    required this.isPickup,
    required this.passengerId,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id'] as String? ?? '',
      lat: (json['lat'] as num? ?? 0.0).toDouble(),
      lng: (json['lng'] as num? ?? 0.0).toDouble(),
      name: json['name'] as String? ?? '',
      isPickup:
          json['isPickup'] as bool? ?? json['is_pickup'] as bool? ?? false,
      passengerId:
          json['passengerId'] as String? ??
          json['passenger_id'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'name': name,
      'isPickup': isPickup,
      'passengerId': passengerId,
    };
  }

  @override
  List<Object?> get props => [id, lat, lng, name, isPickup, passengerId];
}
