import 'package:core_domain/src/internal/json_parsing.dart';
import 'package:equatable/equatable.dart';

class const Profile({
  this.id,
  this.userId,
  this.role,
  this.name = '',
  this.phone = '',
  this.email = '',
  this.address = '',
  this.gender = '',
  this.avatarPath = '',
  this.avatarUrl = '',
  this.avatarData = '',
  this.vehicleType = '',
  this.plateNumber = '',
  this.rating,
  this.isOnline,
}) extends Equatable {
  final String? id;
  final String? userId;
  final String? role;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gender;
  final String avatarPath;
  final String avatarUrl;
  final String avatarData;
  final String vehicleType;
  final String plateNumber;
  final double? rating;
  final bool? isOnline;

  factory fromJson(Map<String, dynamic> response) {
    final payload = _payload(response);
    return Profile(
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
      avatarUrl: _readString(payload, const ['avatar_url', 'avatarUrl']) ?? '',
      avatarData:
          _readString(payload, const ['avatar_data', 'avatarData']) ?? '',
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
      final value = readTrimmedNonEmpty(values[key]);
      if (value != null) return value;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = readNullableDouble(values[key]);
      if (value != null) return value;
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = readNullableBool(values[key]);
      if (value != null) return value;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    role,
    name,
    phone,
    email,
    address,
    gender,
    avatarPath,
    avatarUrl,
    avatarData,
    vehicleType,
    plateNumber,
    rating,
    isOnline,
  ];
}
