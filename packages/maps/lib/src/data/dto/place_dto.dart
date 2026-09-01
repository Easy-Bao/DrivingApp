import 'package:maps/src/domain/entities/place.dart';

class const PlaceDto(this.place) {
  final Place place;

  factory fromJson(Map<String, dynamic> json) {
    return PlaceDto(Place.fromJson(json));
  }

  Place toDomain() => place;

  Map<String, dynamic> toJson() => place.toJson();
}
