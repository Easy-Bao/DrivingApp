import 'package:passenger/src/features/active_ride/domain/entities/ride_update.dart';

final class const RideUpdateDto(final RideUpdate value) {
  factory RideUpdateDto.fromJson(Map<String, dynamic> json) {
    return RideUpdateDto(RideUpdate.fromJson(json));
  }

  RideUpdate toDomain() => value;
}
