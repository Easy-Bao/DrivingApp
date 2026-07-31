import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/DriverModel.g.dart';

@JsonSerializable()
class DriverModel extends Equatable {
  final String id;
  final String name;
  final String vehicleType;
  final String plateNumber;
  final double rating;
  final double lat;
  final double lng;
  final double distanceKm;
  final double etaMinutes;
  final double score;
  final bool hasPassengerOnboard;
  final String? avatarUrl;
  final String? recentFeedback;

  const DriverModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.plateNumber,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.etaMinutes,
    required this.score,
    this.hasPassengerOnboard = false,
    this.avatarUrl,
    this.recentFeedback,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      _$DriverModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriverModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        vehicleType,
        plateNumber,
        rating,
        lat,
        lng,
        distanceKm,
        etaMinutes,
        score,
        hasPassengerOnboard,
        avatarUrl,
        recentFeedback,
      ];
}

