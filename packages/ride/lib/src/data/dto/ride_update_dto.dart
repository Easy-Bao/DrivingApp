import 'package:ride/src/domain/entities/ride_update.dart';

final class RideUpdateDto {
  const RideUpdateDto(this.value);

  factory RideUpdateDto.fromJson(Map<String, dynamic> json) {
    return RideUpdateDto(RideUpdate.fromJson(json));
  }

  final RideUpdate value;

  RideUpdate toDomain() => value;
}
