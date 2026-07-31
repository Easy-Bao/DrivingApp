import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/PlaceModel.g.dart';

@JsonSerializable()
class PlaceModel extends Equatable {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? category;
  final double? distanceKm;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.category,
    this.distanceKm,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) =>
      _$PlaceModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        fullAddress,
        latitude,
        longitude,
        category,
        distanceKm,
      ];
}

