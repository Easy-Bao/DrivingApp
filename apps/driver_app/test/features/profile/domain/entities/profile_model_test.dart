import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/src/features/profile/domain/entities/profile_model.dart';

void main() {
  test('normalizes nested snake-case profile payloads', () {
    final profile = ProfileModel.fromJson({
      'data': {
        'user_id': 7,
        'full_name': 'Ada Driver',
        'phone_number': 123456789,
        'email_address': 'ada@example.com',
        'vehicle_type': 'Sedan',
        'plate_number': 'ABC 123',
        'average_rating': '4.8',
        'is_online': 'true',
      },
    });

    expect(profile.userId, '7');
    expect(profile.name, 'Ada Driver');
    expect(profile.phone, '123456789');
    expect(profile.email, 'ada@example.com');
    expect(profile.vehicleType, 'Sedan');
    expect(profile.plateNumber, 'ABC 123');
    expect(profile.rating, 4.8);
    expect(profile.isOnline, isTrue);
  });

  test('prefers the first non-empty alias and supports camel-case fields', () {
    final profile = ProfileModel.fromJson({
      'profile': {
        'name': '  ',
        'fullName': 'Passenger Name',
        'phone': '',
        'phoneNumber': '+63 900',
        'emailAddress': 'passenger@example.com',
        'homeAddress': 'Home',
        'gender': 'Female',
        'avatar_path': '/tmp/passenger.png',
        'avatar_url': '/api/v1/passengers/7/avatar',
        'avatar_data': 'cGhvdG8=',
        'preferredRideType': 'solo',
        'rating': double.nan,
        'averageRating': 5,
        'isOnline': false,
      },
    });

    expect(profile.name, 'Passenger Name');
    expect(profile.phone, '+63 900');
    expect(profile.email, 'passenger@example.com');
    expect(profile.address, 'Home');
    expect(profile.gender, 'Female');
    expect(profile.avatarPath, '/tmp/passenger.png');
    expect(profile.avatarUrl, '/api/v1/passengers/7/avatar');
    expect(profile.avatarData, 'cGhvdG8=');
    expect(profile.preferredRideType, 'solo');
    expect(profile.rating, 5);
    expect(profile.isOnline, isFalse);
  });
}
