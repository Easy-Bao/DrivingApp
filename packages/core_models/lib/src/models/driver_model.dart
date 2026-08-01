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

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Driver',
      vehicleType: json['vehicleType'] as String? ?? json['vehicle_type'] as String? ?? 'Bao Bao',
      plateNumber: json['plateNumber'] as String? ?? json['plate_number'] as String? ?? 'Unknown',
      rating: (json['rating'] as num? ?? 5.0).toDouble(),
      lat: (json['lat'] as num? ?? 0.0).toDouble(),
      lng: (json['lng'] as num? ?? 0.0).toDouble(),
      distanceKm: (json['distanceKm'] as num? ?? json['distance_km'] as num? ?? 0.0).toDouble(),
      etaMinutes: (json['etaMinutes'] as num? ?? json['eta_minutes'] as num? ?? 0.0).toDouble(),
      score: (json['score'] as num? ?? 0.0).toDouble(),
      hasPassengerOnboard: json['hasPassengerOnboard'] as bool? ?? json['has_passenger_onboard'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      recentFeedback: json['recentFeedback'] as String? ?? json['recent_feedback'] as String?,
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
      'hasPassengerOnboard': hasPassengerOnboard,
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
        hasPassengerOnboard,
        avatarUrl,
        recentFeedback,
      ];
}
