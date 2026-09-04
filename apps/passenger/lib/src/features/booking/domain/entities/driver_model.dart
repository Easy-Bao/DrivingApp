import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

class const DriverModel({
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
}) extends Equatable {
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

  bool get hasPassengerOnboard => (onboardPassengerCount ?? 0) > 0;

  String get displayName {
    final value = name.trim();
    return value.isEmpty ? 'Driver' : value;
  }

  String get vehicleSummary {
    final details = [
      vehicleType.trim(),
      plateNumber.trim(),
    ].where((value) => value.isNotEmpty).toList();
    return details.isEmpty
        ? 'Vehicle details unavailable'
        : details.join(' • ');
  }

  factory fromJson(Map<String, dynamic> json) {
    final {
      'id': rawId,
      'name': rawName,
      'vehicle_type': rawVehicleType,
      'plate_number': rawPlateNumber,
      'rating': rawRating,
      'lat': rawLatitude,
      'lng': rawLongitude,
      'distance_km': rawDistanceKm,
      'eta_minutes': rawEtaMinutes,
      'score': rawScore,
      'onboard_passenger_count': rawOnboardPassengerCount,
      'avatar_url': rawAvatarUrl,
      'recent_feedback': rawRecentFeedback,
    } = _canonicalPayload(
      json,
    );

    return DriverModel(
      id: SafeParse.toStringValue(rawId),
      name: SafeParse.toStringValue(rawName),
      vehicleType: SafeParse.toStringValue(rawVehicleType),
      plateNumber: SafeParse.toStringValue(rawPlateNumber),
      rating: SafeParse.toDouble(rawRating),
      lat: SafeParse.toDouble(rawLatitude),
      lng: SafeParse.toDouble(rawLongitude),
      distanceKm: SafeParse.toDouble(rawDistanceKm),
      etaMinutes: SafeParse.toDouble(rawEtaMinutes),
      score: SafeParse.toDouble(rawScore),
      onboardPassengerCount: _nullableInt(rawOnboardPassengerCount),
      avatarUrl: _nullableString(rawAvatarUrl),
      recentFeedback: _nullableString(rawRecentFeedback),
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

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'id': json['id'] ?? json['user_id'],
  'name': json['name'] ?? json['driver_name'] ?? json['driverName'],
  'vehicle_type': json['vehicleType'] ?? json['vehicle_type'],
  'plate_number': json['plateNumber'] ?? json['plate_number'],
  'rating': json['rating'],
  'lat': json['lat'],
  'lng': json['lng'],
  'distance_km': json['distanceKm'] ?? json['distance_km'],
  'eta_minutes': json['etaMinutes'] ?? json['eta_minutes'],
  'score': json['score'],
  'onboard_passenger_count':
      json['onboardPassengerCount'] ?? json['onboard_passenger_count'],
  'avatar_url': json['avatarUrl'] ?? json['avatar_url'],
  'recent_feedback': json['recentFeedback'] ?? json['recent_feedback'],
};

int? _nullableInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}
