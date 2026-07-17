import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/waypoint_model.freezed.dart';
part 'generated/waypoint_model.g.dart';

@freezed
abstract class Waypoint with _$Waypoint {
  const factory Waypoint({
    required String id,
    required double lat,
    required double lng,
    required String name,
    required bool isPickup,
    required String passengerId,
  }) = _Waypoint;

  factory Waypoint.fromJson(Map<String, dynamic> json) =>
      _$WaypointFromJson(json);
}
