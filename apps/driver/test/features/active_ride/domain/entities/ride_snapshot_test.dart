import 'package:flutter_test/flutter_test.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';

void main() {
  test('flags long-open active trips without changing their status', () {
    final now = DateTime.utc(2026, 10, 24, 12);
    RideSnapshot trip(String status, {int age = 16, double duration = 5}) =>
        RideSnapshot(
          id: 'trip',
          status: status,
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
          createdAt: now.subtract(Duration(minutes: age)),
          durationMinutes: duration,
        );
    expect(trip('accepted', age: 14).needsRecoveryReview(now), isFalse);
    expect(trip('accepted').needsRecoveryReview(now), isTrue);
    expect(trip('completed', age: 500).needsRecoveryReview(now), isFalse);
    expect(trip('cancelled', age: 500).needsRecoveryReview(now), isFalse);
    expect(trip('in_transit', age: 59).needsRecoveryReview(now), isFalse);
    final active = trip('in_transit', age: 61);
    expect(active.needsRecoveryReview(now), isTrue);
    expect(active.status, 'in_transit');
    expect(
      trip('in_transit', age: 120, duration: 120).needsRecoveryReview(now),
      isFalse,
    );
    expect(
      trip('in_transit', age: 151, duration: 120).needsRecoveryReview(now),
      isTrue,
    );
    expect(trip('accepted', age: -10).needsRecoveryReview(now), isFalse);
  });

  test('uses authoritative creation and expired waiting timestamps', () {
    final now = DateTime.utc(2026, 10, 24, 12);
    final snapshot = RideSnapshot.fromJson({
      'id': 1,
      'status': 'accepted',
      'created_at': '2026-10-24T19:00:00+08:00',
    });
    expect(snapshot.createdAt, DateTime.utc(2026, 10, 24, 11));
    expect(snapshot.needsRecoveryReview(now), isTrue);
    final waiting = RideSnapshot(
      id: 'waiting',
      status: 'arrived',
      pickupName: 'Pickup',
      dropoffName: 'Dropoff',
      waitingUntil: now,
    );
    expect(waiting.needsRecoveryReview(now), isTrue);
    const missing = RideSnapshot(
      id: 'missing',
      status: 'in_transit',
      pickupName: 'Pickup',
      dropoffName: 'Dropoff',
    );
    expect(missing.needsRecoveryReview(now), isFalse);
  });

  test('destructures canonical and legacy snapshot fields', () {
    final snapshot = RideSnapshot.fromJson(const {
      'id': 303,
      'booking_reference': '701612345678901',
      'status': ' Accepted ',
      'pickup': 'Terminal A',
      'destination': 'Terminal B',
      'passengerId': 7,
      'passengerName': 'Passenger',
      'driverId': 42,
      'driverName': 'Nearby Driver',
      'vehicleType': 'Bao Bao',
      'plateNumber': 'ABC 1234',
      'pickupLat': '7.828',
      'pickupLng': 123.434,
      'dropoffLatitude': 7.9,
      'dropoffLongitude': '123.5',
      'distance': '4.5',
      'durationMinutes': 12,
      'fare': '125.50',
      'payment_status': 'UNPAID',
      'cash_outcome': 'UNPAID',
    });

    expect(snapshot.id, '303');
    expect(snapshot.bookingReference, '701612345678901');
    expect(snapshot.status, 'accepted');
    expect(snapshot.pickupName, 'Terminal A');
    expect(snapshot.dropoffName, 'Terminal B');
    expect(snapshot.passengerId, '7');
    expect(snapshot.passengerName, 'Passenger');
    expect(snapshot.driverId, '42');
    expect(snapshot.driverName, 'Nearby Driver');
    expect(snapshot.vehicleType, 'Bao Bao');
    expect(snapshot.plateNumber, 'ABC 1234');
    expect(snapshot.pickupLatitude, 7.828);
    expect(snapshot.pickupLongitude, 123.434);
    expect(snapshot.dropoffLatitude, 7.9);
    expect(snapshot.dropoffLongitude, 123.5);
    expect(snapshot.distanceKm, 4.5);
    expect(snapshot.durationMinutes, 12);
    expect(snapshot.fareAmount, 12550);
    expect(snapshot.farePesos, 125.5);
    expect(snapshot.paymentStatus, 'unpaid');
    expect(snapshot.cashOutcome, 'unpaid');
    expect(snapshot.cashReceivedAt, isNull);
    expect(snapshot.hasCashSettlement, isFalse);
  });

  test('recognizes a recorded cash outcome from the server snapshot', () {
    final snapshot = RideSnapshot.fromJson(const {
      'id': 7,
      'status': 'completed',
      'pickup_name': 'Pickup',
      'dropoff_name': 'Dropoff',
      'fare_amount': 1250,
      'payment_status': 'unpaid',
      'cash_outcome': 'unpaid',
      'cash_received_at': '2026-10-05T10:00:00Z',
    });

    expect(snapshot.hasCashSettlement, isTrue);
    expect(snapshot.cashReceivedAt, isNotNull);
  });

  test('keeps fallback identifiers and defaults for sparse snapshots', () {
    final snapshot = RideSnapshot.fromJson(const {
      'status': 'requested',
    }, fallbackId: 'session-303');

    expect(snapshot.id, 'session-303');
    expect(snapshot.status, 'requested');
    expect(snapshot.pickupName, 'Pickup');
    expect(snapshot.dropoffName, 'Dropoff');
    expect(snapshot.fareAmount, isNull);
    expect(snapshot.isTerminal, isFalse);
  });

  test('recognizes terminal ride statuses and cancellation spelling', () {
    const completedRide = RideSnapshot(
      id: 'completed-trip',
      status: 'completed',
      pickupName: 'Pickup',
      dropoffName: 'Dropoff',
    );
    const cancelledRide = RideSnapshot(
      id: 'cancelled-trip',
      status: 'CANCELED',
      pickupName: 'Pickup',
      dropoffName: 'Dropoff',
    );

    expect(completedRide.isTerminal, isTrue);
    expect(cancelledRide.isTerminal, isTrue);
  });
}
