import 'package:equatable/equatable.dart';

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
  final int? onboardPassengerCount;
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
    this.onboardPassengerCount,
    this.avatarUrl,
    this.recentFeedback,
  });

  bool get hasPassengerOnboard => (onboardPassengerCount ?? 0) > 0;

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      vehicleType:
          json['vehicleType'] as String? ??
          json['vehicle_type'] as String? ??
          '',
      plateNumber:
          json['plateNumber'] as String? ??
          json['plate_number'] as String? ??
          '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      distanceKm:
          (json['distanceKm'] as num? ?? json['distance_km'] as num? ?? 0.0)
              .toDouble(),
      etaMinutes:
          (json['etaMinutes'] as num? ?? json['eta_minutes'] as num? ?? 0.0)
              .toDouble(),
      score: (json['score'] as num? ?? 0.0).toDouble(),
      onboardPassengerCount:
          (json['onboardPassengerCount'] as num?)?.toInt() ??
          (json['onboard_passenger_count'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      recentFeedback:
          json['recentFeedback'] as String? ??
          json['recent_feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'rating': rating,
      'lat': lat,
      'lng': lng,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'score': score,
      'onboardPassengerCount': onboardPassengerCount,
      'avatarUrl': avatarUrl,
      'recentFeedback': recentFeedback,
    };
  }

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
    onboardPassengerCount,
    avatarUrl,
    recentFeedback,
  ];
}
