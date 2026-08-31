import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 8, 10, 12);

  Map<String, dynamic> validEvent({
    String type = 'ride.offer.created',
    int version = realtimeEventVersion,
  }) => {
    'id': 'event-1',
    'version': version,
    'type': type,
    'occurred_at': occurredAt.toIso8601String(),
    'scope': {'ride_id': 'ride-1', 'driver_id': 'driver-1'},
    'payload': {'offer_id': 'offer-1', 'fare_centavos': 12000},
  };

  test('parses a versioned realtime event into an exhaustive variant', () {
    final envelope = RealtimeEnvelope.fromJson(validEvent());
    final event = RealtimeEvent.fromEnvelope(envelope);

    expect(event, isA<RideOfferCreatedEvent>());
    expect(envelope.scope.rideId, 'ride-1');
    expect(envelope.payload['fare_centavos'], 12000);
    expect(envelope.occurredAt, occurredAt);
  });

  test('serializes the exact transport contract', () {
    final envelope = RealtimeEnvelope.fromJson(validEvent());

    expect(envelope.toJson(), validEvent());
  });

  test('preserves the driver pool scope used for open offers', () {
    final json = {
      ...validEvent(),
      'scope': {'passenger_id': 'passenger-1', 'driver_pool': true},
    };

    final envelope = RealtimeEnvelope.fromJson(json);

    expect(envelope.scope.driverPool, isTrue);
    expect(envelope.scope.toJson(), json['scope']);
  });

  test('rejects unsupported versions and malformed scopes', () {
    expect(
      () => RealtimeEnvelope.fromJson(validEvent(version: 2)),
      throwsFormatException,
    );
    expect(
      () => RealtimeEnvelope.fromJson({
        ...validEvent(),
        'scope': const <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });

  test('rejects an unknown event type and non-object payload', () {
    expect(
      () => RealtimeEnvelope.fromJson(validEvent(type: 'ride.deleted')),
      throwsFormatException,
    );
    expect(
      () => RealtimeEnvelope.fromJson({
        ...validEvent(),
        'payload': const <dynamic>[],
      }),
      throwsFormatException,
    );
  });
}
