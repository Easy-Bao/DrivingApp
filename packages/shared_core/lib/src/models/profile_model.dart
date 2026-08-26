import 'package:shared_core/src/utils/safe_parse.dart';

class ProfileModel {
  const ProfileModel({
    this.id,
    this.userId,
    this.role,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.gender = '',
    this.avatarPath = '',
    this.preferredRideType = '',
    this.vehicleType = '',
    this.plateNumber = '',
    this.rating,
    this.isOnline,
  });

  final String? id;
  final String? userId;
  final String? role;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gender;
  final String avatarPath;
  final String preferredRideType;
  final String vehicleType;
  final String plateNumber;
  final double? rating;
  final bool? isOnline;

  factory ProfileModel.fromJson(Map<String, dynamic> response) {
    final payload = _payload(response);
    return ProfileModel(
      id: _readString(payload, const ['id', 'profile_id', 'profileId']),
      userId: _readString(payload, const ['user_id', 'userId']),
      role: _readString(payload, const ['role']),
      name: _readString(payload, const ['name', 'full_name', 'fullName']) ?? '',
      phone:
          _readString(payload, const [
            'phone',
            'phone_number',
            'phoneNumber',
          ]) ??
          '',
      email:
          _readString(payload, const [
            'email',
            'email_address',
            'emailAddress',
          ]) ??
          '',
      address:
          _readString(payload, const [
            'address',
            'home_address',
            'homeAddress',
          ]) ??
          '',
      gender: _readString(payload, const ['gender']) ?? '',
      avatarPath:
          _readString(payload, const ['avatar_path', 'avatarPath']) ?? '',
      preferredRideType:
          _readString(payload, const [
            'preferred_ride_type',
            'preferredRideType',
          ]) ??
          '',
      vehicleType:
          _readString(payload, const ['vehicle_type', 'vehicleType']) ?? '',
      plateNumber:
          _readString(payload, const ['plate_number', 'plateNumber']) ?? '',
      rating: _readDouble(payload, const [
        'rating',
        'average_rating',
        'averageRating',
      ]),
      isOnline: _readBool(payload, const ['is_online', 'isOnline']),
    );
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> response) {
    final nested = response['profile'] ?? response['user'] ?? response['data'];
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return response;
  }

  static String? _readString(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = SafeParse.toStringValue(values[key]).trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = SafeParse.toNullableDouble(values[key]);
      if (value != null && value.isFinite) return value;
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is bool) return value;
      if (value is String) {
        switch (value.trim().toLowerCase()) {
          case 'true':
          case '1':
            return true;
          case 'false':
          case '0':
            return false;
        }
      }
    }
    return null;
  }
}
