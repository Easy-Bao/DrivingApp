import 'package:maps/src/domain/entities/place.dart';

class PlaceDto {
  final Place place;

  const PlaceDto(this.place);

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    return PlaceDto(Place.fromJson(json));
  }

  Place toDomain() => place;

  Map<String, dynamic> toJson() => place.toJson();
}
