import 'package:equatable/equatable.dart';
import 'package:shared_core/src/utils/safe_parse.dart';

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

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: SafeParse.toStringValue(json['id'] ?? json['user_id']),
      name: SafeParse.toStringValue(json['name']),
      vehicleType: SafeParse.toStringValue(
        json['vehicleType'] ?? json['vehicle_type'],
      ),
      plateNumber: SafeParse.toStringValue(
        json['plateNumber'] ?? json['plate_number'],
      ),
      rating: SafeParse.toDouble(json['rating']),
      lat: SafeParse.toDouble(json['lat']),
      lng: SafeParse.toDouble(json['lng']),
      distanceKm: SafeParse.toDouble(json['distanceKm'] ?? json['distance_km']),
      etaMinutes: SafeParse.toDouble(json['etaMinutes'] ?? json['eta_minutes']),
      score: SafeParse.toDouble(json['score']),
      onboardPassengerCount: _nullableInt(
        json['onboardPassengerCount'] ?? json['onboard_passenger_count'],
      ),
      avatarUrl: _nullableString(json['avatarUrl'] ?? json['avatar_url']),
      recentFeedback: _nullableString(
        json['recentFeedback'] ?? json['recent_feedback'],
      ),
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

int? _nullableInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}
