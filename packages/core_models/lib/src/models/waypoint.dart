import 'package:freezed_annotation/freezed_annotation.dart';

part 'waypoint.freezed.dart';
part 'waypoint.g.dart';

/**
 * Waypoint represents geographical coordinates in a travel path.
 */
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
