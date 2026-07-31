import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/WaypointModel.g.dart';

@JsonSerializable()
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

  factory Waypoint.fromJson(Map<String, dynamic> json) =>
      _$WaypointFromJson(json);

  Map<String, dynamic> toJson() => _$WaypointToJson(this);

  @override
  List<Object?> get props => [id, lat, lng, name, isPickup, passengerId];
}

