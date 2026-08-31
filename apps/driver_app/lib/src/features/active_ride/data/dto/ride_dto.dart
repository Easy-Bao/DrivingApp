import 'package:driver_app/src/features/active_ride/domain/entities/ride_snapshot.dart';

final class RideDto {
  const RideDto(this.value);

  factory RideDto.fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) {
    return RideDto(RideSnapshot.fromJson(json, fallbackId: fallbackId));
  }

  final RideSnapshot value;

  RideSnapshot toDomain() => value;
}
