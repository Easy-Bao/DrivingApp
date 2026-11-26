import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideStatus', () {
    test('normalizes aliases and flags terminal states', () {
      expect(RideStatus.fromString('canceled'), RideStatus.cancelled);
      expect(RideStatus.fromString('IN_PROGRESS'), RideStatus.inTransit);
      expect(RideStatus.completed.isTerminal, isTrue);
      expect(RideStatus.cancelled.isTerminal, isTrue);
      expect(RideStatus.inTransit.isTerminal, isFalse);
      expect(RideStatus.fromString('bogus'), RideStatus.unknown);
    });
  });

  group('RideCounterparty', () {
    test('parses canonical and camelCase fields with value equality', () {
      final first = RideCounterparty.fromJson(const {
        'userId': ' user-1 ',
        'name': ' Alex ',
        'phone': ' +639123456789 ',
        'contact_allowed': true,
      });
      const second = RideCounterparty(
        userId: 'user-1',
        name: 'Alex',
        phone: '+639123456789',
        contactAllowed: true,
      );
      expect(first, second);
    });
  });

  group('RideSnapshot', () {
    test('parses driver and passenger ride fields consistently', () {
      final snapshot = RideSnapshot.fromJson(const {
        'id': 'ride-42',
        'booking_reference': 'BK-42',
        'status': 'completed',
        'pickup_name': 'Plaza',
        'dropoff_name': 'Airport',
        'driver_name': 'Sam',
        'vehicle_type': 'Tricycle',
        'plate_number': 'ABC-123',
        'driver_rating': 4.86,
        'fare': 55.5,
        'cash_settled': true,
      });

      expect(snapshot.isTerminal, isTrue);
      expect(snapshot.fareAmount, 5550);
      expect(snapshot.farePesos, 55.5);
      expect(snapshot.displayDriverName, 'Sam');
      expect(snapshot.displayDriverRating, '4.9');
      expect(snapshot.displayVehicleSummary, 'Tricycle • ABC-123');
      expect(snapshot.cashSettled, isTrue);
      expect(snapshot.copyWith(status: 'in_transit').isTerminal, isFalse);
    });
  });

  group('Profile', () {
    test('parses nested payloads and compares by value', () {
      final profile = Profile.fromJson(const {
        'profile': {
          'user_id': 'u-1',
          'fullName': 'Jordan',
          'phone_number': '09171234567',
          'rating': '4.7',
          'is_online': 'true',
        },
      });
      const expected = Profile(
        userId: 'u-1',
        name: 'Jordan',
        phone: '09171234567',
        rating: 4.7,
        isOnline: true,
      );
      expect(profile, expected);
    });
  });
}
