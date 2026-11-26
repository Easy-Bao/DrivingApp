import 'package:core_domain/core_domain.dart';

final class const RideDto(final RideSnapshot value) {
  factory fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    return RideDto(RideSnapshot.fromJson(json, fallbackId: fallbackId));
  }

  RideSnapshot toDomain() => value;
}
